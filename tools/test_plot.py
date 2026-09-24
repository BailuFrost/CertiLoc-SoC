"""通过阶段1UART执行一次随机测向定位，在终端输出结果并显示坐标图。"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import math
from pathlib import Path
import random
import sys
import time


PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from fpga_stage1.model.protocol_reference import (
    Command,
    ObservationRaw,
    Response,
    ResultFlag,
    ResultReadKind,
    pack_observations,
    pack_read_result,
    pack_set_config,
)
from fpga_stage1.tools.t15_board_validation import (
    ProtocolClient,
    ResultHeader,
    Status,
    parse_result_header,
    parse_result_vertices,
    parse_status,
)


COORDINATE_SCALE = 1 << 16
PHASE_SCALE = 1 << 18
BEARING_DELTA_DEG = 732 * 360.0 / PHASE_SCALE
REGION_NAMES = {
    0x00: "空集",
    0x01: "点",
    0x02: "线段",
    0x03: "多边形",
    0xFF: "无效",
}


@dataclass(frozen=True)
class Observation:
    """以工程单位保存的一条随机测向观测。"""

    index: int
    x_m: float
    y_m: float
    bearing_deg: float
    bearing_noise_deg: float
    raw: ObservationRaw


def round_half_away_from_zero(value: float) -> int:
    """按阶段1数值契约执行最近值、半值远离零取整。"""

    magnitude = math.floor(abs(value) + 0.5)
    return magnitude if value >= 0.0 else -magnitude


def coordinate_to_raw(value_m: float) -> int:
    raw = round_half_away_from_zero(value_m * COORDINATE_SCALE)
    if not -(1 << 31) <= raw < (1 << 31):
        raise ValueError(f"坐标{value_m} m超出signed Q16.16范围")
    return raw


def bearing_to_raw(value_deg: float) -> int:
    normalized = value_deg % 360.0
    return round_half_away_from_zero(normalized * PHASE_SCALE / 360.0) % PHASE_SCALE


def coordinate_from_raw(raw: int) -> float:
    return raw / COORDINATE_SCALE


def generate_observations(
    count: int,
    seed: int,
    bearing_noise_limit_deg: float,
) -> tuple[tuple[Observation, ...], tuple[float, float]]:
    """围绕一个随机参考目标生成几何分散且保证可行的测向数据。"""

    if not 2 <= count <= 20:
        raise ValueError("观测数量必须在2至20之间")
    if not 0.0 <= bearing_noise_limit_deg <= 1.0:
        raise ValueError("随机示向噪声上限必须在0至1度之间")

    generator = random.Random(seed)
    target_radius = 400.0 * math.sqrt(generator.random())
    target_angle = generator.uniform(0.0, 2.0 * math.pi)
    target_x = target_radius * math.cos(target_angle)
    target_y = target_radius * math.sin(target_angle)
    phase_offset = generator.uniform(0.0, 2.0 * math.pi)
    observations: list[Observation] = []

    for index in range(count):
        nominal_angle = phase_offset + 2.0 * math.pi * index / count
        sensor_angle = nominal_angle + generator.uniform(-0.18, 0.18)
        sensor_distance = generator.uniform(800.0, 1250.0)
        x_m = target_x + sensor_distance * math.cos(sensor_angle)
        y_m = target_y + sensor_distance * math.sin(sensor_angle)
        ideal_bearing_deg = math.degrees(math.atan2(target_y - y_m, target_x - x_m)) % 360.0
        noise_deg = generator.uniform(-bearing_noise_limit_deg, bearing_noise_limit_deg)
        bearing_deg = (ideal_bearing_deg + noise_deg) % 360.0
        raw = ObservationRaw(
            coordinate_to_raw(x_m),
            coordinate_to_raw(y_m),
            bearing_to_raw(bearing_deg),
        )
        observations.append(
            Observation(index + 1, x_m, y_m, bearing_deg, noise_deg, raw)
        )

    return tuple(observations), (target_x, target_y)


def expect_response(command: Command, actual: int, expected: Response) -> None:
    if actual != int(expected):
        raise ValueError(
            f"命令0x{int(command):02x}响应类型错误："
            f"期望0x{int(expected):02x}，实际0x{actual:02x}"
        )


def wait_for_result(client: ProtocolClient, timeout_s: float) -> Status:
    deadline = time.perf_counter() + timeout_s
    while time.perf_counter() < deadline:
        frame, _ = client.transact(Command.GET_STATUS)
        expect_response(Command.GET_STATUS, frame.command, Response.STATUS)
        status = parse_status(frame.payload)
        if status.state == 0x06 and status.result_valid:
            return status
        time.sleep(0.002)
    raise TimeoutError("等待FPGA定位结果超时")


def read_all_vertices(
    client: ProtocolClient,
    header: ResultHeader,
) -> tuple[tuple[int, int], ...]:
    vertices: list[tuple[int, int]] = []
    while len(vertices) < header.vertex_count:
        start = len(vertices)
        count = min(16, header.vertex_count - start)
        frame, _ = client.transact(
            Command.READ_RESULT,
            pack_read_result(ResultReadKind.VERTICES, start, count),
        )
        expect_response(Command.READ_RESULT, frame.command, Response.RESULT_VERTICES)
        job_sequence, returned_start, chunk = parse_result_vertices(frame.payload)
        if job_sequence != header.job_sequence or returned_start != start:
            raise ValueError("顶点分页信息与当前定位结果不一致")
        vertices.extend(chunk)
    return tuple(vertices)


def execute_localization(
    client: ProtocolClient,
    observations: tuple[Observation, ...],
    timeout_s: float,
) -> tuple[bytes, ResultHeader, Status, tuple[tuple[int, int], ...], float]:
    frame, _ = client.transact(Command.GET_INFO)
    expect_response(Command.GET_INFO, frame.command, Response.INFO)
    if len(frame.payload) != 24 or frame.payload[:2] != b"\x01\xb3":
        raise ValueError("连接设备不是预期的阶段1 FPGA协议端点")
    info_payload = frame.payload

    frame, _ = client.transact(Command.SET_CONFIG, pack_set_config())
    expect_response(Command.SET_CONFIG, frame.command, Response.ACK)
    frame, _ = client.transact(
        Command.LOAD_OBSERVATIONS,
        pack_observations(tuple(item.raw for item in observations)),
    )
    expect_response(Command.LOAD_OBSERVATIONS, frame.command, Response.ACK)

    started = time.perf_counter()
    frame, _ = client.transact(Command.START_LOCALIZATION)
    expect_response(Command.START_LOCALIZATION, frame.command, Response.ACK)
    start_sequence = frame.sequence
    status = wait_for_result(client, timeout_s)
    frame, _ = client.transact(
        Command.READ_RESULT,
        pack_read_result(ResultReadKind.HEADER),
    )
    expect_response(Command.READ_RESULT, frame.command, Response.RESULT_HEADER)
    header = parse_result_header(frame.payload)
    if header.job_sequence != start_sequence:
        raise ValueError("结果所属任务序号与START_LOCALIZATION不一致")
    vertices = read_all_vertices(client, header)
    elapsed_s = time.perf_counter() - started
    return info_payload, header, status, vertices, elapsed_s


def decode_error_flags(flags: int) -> list[str]:
    names = {
        ResultFlag.QUANTIZATION_MARGIN_USED: "量化容差被使用",
        ResultFlag.PARALLEL_EDGE: "存在近似平行边",
        ResultFlag.ARITHMETIC_OVERFLOW: "算术溢出",
        ResultFlag.VERTEX_CAPACITY: "顶点容量溢出",
        ResultFlag.CORDIC_TIMEOUT: "CORDIC超时",
        ResultFlag.ILLEGAL_STATE: "非法状态",
        ResultFlag.COLLINEARITY_NOT_CHECKED: "未执行全局共线检查",
        ResultFlag.ABORTED: "任务被中止",
    }
    return [description for flag, description in names.items() if flags & int(flag)]


def polygon_centroid(vertices: tuple[tuple[float, float], ...]) -> tuple[float, float] | None:
    if not vertices:
        return None
    if len(vertices) < 3:
        return (
            sum(point[0] for point in vertices) / len(vertices),
            sum(point[1] for point in vertices) / len(vertices),
        )
    area_twice = 0.0
    centroid_x = 0.0
    centroid_y = 0.0
    for index, first in enumerate(vertices):
        second = vertices[(index + 1) % len(vertices)]
        cross = first[0] * second[1] - second[0] * first[1]
        area_twice += cross
        centroid_x += (first[0] + second[0]) * cross
        centroid_y += (first[1] + second[1]) * cross
    if abs(area_twice) < 1e-15:
        return (
            sum(point[0] for point in vertices) / len(vertices),
            sum(point[1] for point in vertices) / len(vertices),
        )
    return centroid_x / (3.0 * area_twice), centroid_y / (3.0 * area_twice)


def configure_chinese_font(plt) -> None:
    available = {font.name for font in plt.matplotlib.font_manager.fontManager.ttflist}
    for name in ("Microsoft YaHei", "SimHei", "Noto Sans CJK SC", "Arial Unicode MS"):
        if name in available:
            plt.rcParams["font.sans-serif"] = [name, "DejaVu Sans"]
            plt.rcParams["axes.unicode_minus"] = False
            break


def plot_result(
    observations: tuple[Observation, ...],
    vertices: tuple[tuple[float, float], ...],
    header: ResultHeader,
    reference_target: tuple[float, float],
    *,
    show: bool = True,
) -> None:
    try:
        import matplotlib.pyplot as plt
        from matplotlib.patches import Polygon
    except ModuleNotFoundError as error:
        raise RuntimeError("缺少matplotlib，无法生成坐标图") from error

    configure_chinese_font(plt)
    figure, (global_axes, detail_axes) = plt.subplots(
        1, 2, figsize=(13.4, 6.5), dpi=150, constrained_layout=True
    )
    vertex_x = [point[0] for point in vertices]
    vertex_y = [point[1] for point in vertices]

    global_axes.add_patch(
        plt.Circle(
            (0.0, 0.0), 1800.0, fill=False, color="#9BB7D4",
            linestyle="--", linewidth=1.2, label="目标圆盘",
        )
    )
    for observation in observations:
        angle = math.radians(observation.bearing_deg)
        lower_angle = math.radians(observation.bearing_deg - BEARING_DELTA_DEG)
        upper_angle = math.radians(observation.bearing_deg + BEARING_DELTA_DEG)
        end_x = observation.x_m + 2800.0 * math.cos(angle)
        end_y = observation.y_m + 2800.0 * math.sin(angle)
        wedge_points = [
            (observation.x_m, observation.y_m),
            (
                observation.x_m + 2800.0 * math.cos(lower_angle),
                observation.y_m + 2800.0 * math.sin(lower_angle),
            ),
            (
                observation.x_m + 2800.0 * math.cos(upper_angle),
                observation.y_m + 2800.0 * math.sin(upper_angle),
            ),
        ]
        global_axes.add_patch(
            Polygon(
                wedge_points,
                closed=True,
                facecolor="#009E73",
                edgecolor="none",
                alpha=min(0.10, 0.35 / len(observations)),
                label="±1.005°示向角锥" if observation.index == 1 else None,
            )
        )
        global_axes.plot(
            [observation.x_m, end_x], [observation.y_m, end_y],
            color="#4D4D4D", linestyle="--", linewidth=0.8,
            label="示向中心线" if observation.index == 1 else None,
        )
        for boundary_index, boundary_angle in enumerate((lower_angle, upper_angle)):
            boundary_x = observation.x_m + 2800.0 * math.cos(boundary_angle)
            boundary_y = observation.y_m + 2800.0 * math.sin(boundary_angle)
            global_axes.plot(
                [observation.x_m, boundary_x],
                [observation.y_m, boundary_y],
                color="#0072B2" if boundary_index == 0 else "#D55E00",
                linewidth=0.9,
                label=(
                    "示向误差边界"
                    if observation.index == 1 and boundary_index == 0
                    else None
                ),
            )
        global_axes.annotate(
            f"S{observation.index}", (observation.x_m, observation.y_m),
            xytext=(5, 5), textcoords="offset points", fontsize=8,
        )
    global_axes.scatter(
        [item.x_m for item in observations],
        [item.y_m for item in observations],
        s=38, color="#F58518", edgecolors="#7A3E00", label="检测点", zorder=5,
    )
    global_axes.scatter(
        [reference_target[0]], [reference_target[1]], marker="*", s=150,
        color="#54A24B", edgecolors="black", label="随机生成参考目标", zorder=7,
    )
    if len(vertices) >= 3:
        global_axes.add_patch(
            Polygon(
                vertices, closed=True, facecolor="#4C78A8", alpha=0.32,
                edgecolor="#1F4E78", linewidth=1.8, label="FPGA定位多边形",
            )
        )
    elif len(vertices) == 2:
        global_axes.plot(vertex_x, vertex_y, color="#1F4E78", linewidth=2.0, label="FPGA定位线段")
    elif len(vertices) == 1:
        global_axes.scatter(vertex_x, vertex_y, color="#1F4E78", marker="s", label="FPGA定位点")

    global_axes.set_xlim(-1950.0, 1950.0)
    global_axes.set_ylim(-1950.0, 1950.0)
    style_axes(global_axes, "随机检测点、示向线与FPGA定位结果")
    global_axes.legend(loc="upper right", fontsize=8)

    if vertices:
        if len(vertices) >= 3:
            detail_axes.add_patch(
                Polygon(
                    vertices, closed=True, facecolor="#4C78A8", alpha=0.32,
                    edgecolor="#1F4E78", linewidth=1.8, label="FPGA定位多边形",
                )
            )
        elif len(vertices) == 2:
            detail_axes.plot(vertex_x, vertex_y, color="#1F4E78", linewidth=2.0)
        detail_axes.scatter(vertex_x, vertex_y, color="#1F4E78", s=30, zorder=5)
        for index, point in enumerate(vertices):
            detail_axes.annotate(
                f"v{index}\n({point[0]:.3f}, {point[1]:.3f})",
                point, xytext=(6, 6), textcoords="offset points", fontsize=7,
            )
        if (
            header.farthest_first < len(vertices)
            and header.farthest_second < len(vertices)
        ):
            first = vertices[header.farthest_first]
            second = vertices[header.farthest_second]
            detail_axes.plot(
                [first[0], second[0]], [first[1], second[1]],
                color="#E45756", linewidth=2.0, label="最大直径",
            )
        centroid = polygon_centroid(vertices)
        if centroid is not None:
            detail_axes.scatter(
                [centroid[0]], [centroid[1]], marker="*", s=120,
                color="#FFBF00", edgecolors="black", label="多边形质心", zorder=7,
            )
        minimum_x, maximum_x = min(vertex_x), max(vertex_x)
        minimum_y, maximum_y = min(vertex_y), max(vertex_y)
        span = max(maximum_x - minimum_x, maximum_y - minimum_y, 8.0)
        padding = 0.35 * span + 2.0
        detail_axes.set_xlim(minimum_x - padding, maximum_x + padding)
        detail_axes.set_ylim(minimum_y - padding, maximum_y + padding)
        detail_axes.legend(loc="best", fontsize=8)
    else:
        detail_axes.text(0.5, 0.5, "定位区域为空", ha="center", va="center", transform=detail_axes.transAxes)
    style_axes(detail_axes, "FPGA返回顶点与最大直径")

    if show:
        plt.show()
    plt.close(figure)


def style_axes(axes, title: str) -> None:
    axes.set_aspect("equal", adjustable="box")
    axes.set_xlabel("x / m")
    axes.set_ylabel("y / m")
    axes.set_title(title)
    axes.axhline(0.0, color="#B0B0B0", linewidth=0.6, zorder=0)
    axes.axvline(0.0, color="#B0B0B0", linewidth=0.6, zorder=0)
    axes.grid(True, linestyle=":", color="#D0D0D0", linewidth=0.6)


def print_summary(
    seed: int,
    observations: tuple[Observation, ...],
    header: ResultHeader,
    vertices_raw: tuple[tuple[int, int], ...],
    elapsed_s: float,
) -> None:
    diameter_m = math.sqrt(header.diameter_squared_raw) / COORDINATE_SCALE
    flags = decode_error_flags(header.error_flags)
    print("=" * 72)
    print("FPGA 单次随机测向定位结果")
    print("=" * 72)
    print(f"随机种子          : {seed}")
    print(f"观测数量          : {len(observations)}")
    for item in observations:
        print(
            f"  S{item.index:02d}: ({item.x_m:10.4f}, {item.y_m:10.4f}) m, "
            f"示向角={item.bearing_deg:10.6f}°"
        )
    print(f"区域类型          : {REGION_NAMES.get(header.region_type, '未知')}")
    print(f"结果可信          : {'是' if header.trusted else '否'}")
    print(f"顶点数量          : {header.vertex_count}")
    for index, (x_raw, y_raw) in enumerate(vertices_raw):
        print(
            f"  v{index:02d}: ({coordinate_from_raw(x_raw):12.6f}, "
            f"{coordinate_from_raw(y_raw):12.6f}) m"
        )
    print(f"最大直径          : {diameter_m:.6f} m")
    print(
        f"最远顶点索引      : v{header.farthest_first}, "
        f"v{header.farthest_second}"
    )
    print(f"核心运行周期      : {header.core_cycles}")
    print(f"100 MHz核心时间   : {header.core_cycles / 100.0:.2f} us")
    print(f"UART端到端时间    : {elapsed_s:.6f} s")
    print(f"错误状态原始值    : 0x{header.error_flags:08X}")
    print(f"错误/状态说明     : {', '.join(flags) if flags else '无'}")


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", required=True, help="Basys 3 USB-UART端口，例如COM7")
    parser.add_argument("--count", type=int, default=6, help="随机观测数量，范围2至20")
    parser.add_argument("--seed", type=int, help="随机种子；省略时按当前时间生成")
    parser.add_argument(
        "--bearing-noise",
        type=float,
        default=0.75,
        help="示向角随机噪声绝对值上限，范围0至1度",
    )
    parser.add_argument("--timeout", type=float, default=5.0, help="串口及单次任务超时，单位秒")
    return parser.parse_args()


def configure_stdio() -> None:
    for stream in (sys.stdout, sys.stderr):
        reconfigure = getattr(stream, "reconfigure", None)
        if reconfigure is not None:
            reconfigure(encoding="utf-8", errors="replace")


def main() -> int:
    configure_stdio()
    arguments = parse_arguments()
    if not 2 <= arguments.count <= 20:
        raise SystemExit("--count必须在2至20之间")
    if arguments.timeout <= 0.0:
        raise SystemExit("--timeout必须大于0")
    seed = arguments.seed
    if seed is None:
        seed = time.time_ns() & 0xFFFFFFFF
    observations, reference_target = generate_observations(
        arguments.count,
        seed,
        arguments.bearing_noise,
    )

    try:
        import serial
    except ModuleNotFoundError as error:
        raise SystemExit("缺少pyserial；请先执行 pip install pyserial") from error
    try:
        import matplotlib  # noqa: F401
    except ModuleNotFoundError as error:
        raise SystemExit("缺少matplotlib；请先执行 pip install matplotlib") from error

    with serial.Serial(
        arguments.port,
        115200,
        timeout=arguments.timeout,
        write_timeout=arguments.timeout,
    ) as port:
        port.reset_input_buffer()
        _info, header, _status, vertices_raw, elapsed_s = execute_localization(
            ProtocolClient(port), observations, arguments.timeout
        )

    print_summary(seed, observations, header, vertices_raw, elapsed_s)
    vertices = tuple(
        (coordinate_from_raw(x_raw), coordinate_from_raw(y_raw))
        for x_raw, y_raw in vertices_raw
    )
    plot_result(observations, vertices, header, reference_target)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
