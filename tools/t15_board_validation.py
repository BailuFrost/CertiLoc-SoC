"""Basys 3阶段1板级UART、性能与压力验证工具。"""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import struct
import sys
import time
from typing import Protocol

PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from fpga_stage1.model.fixed_point_reference.geometry import localize_fixed
from fpga_stage1.model.protocol_reference import (
    Command,
    Frame,
    ObservationRaw,
    Response,
    ResultReadKind,
    decode_frame,
    pack_observations,
    pack_read_result,
    pack_set_config,
    unpack_u66_le,
)


class ByteTransport(Protocol):
    """板测客户端所需的最小字节传输接口。"""

    def write(self, data: bytes) -> int: ...

    def read(self, size: int) -> bytes: ...

    def reset_input_buffer(self) -> None: ...


@dataclass(frozen=True)
class ResultHeader:
    job_sequence: int
    trusted: bool
    region_type: int
    vertex_count: int
    diameter_squared_raw: int
    farthest_first: int
    farthest_second: int
    core_cycles: int
    error_flags: int


@dataclass(frozen=True)
class Status:
    state: int
    result_valid: bool
    result_trusted: bool
    region_type: int
    observation_count: int
    active_observation_index: int
    vertex_count: int
    error_flags: int
    core_cycles: int


def parse_status(payload: bytes) -> Status:
    if len(payload) != 16:
        raise ValueError(f"STATUS长度应为16，实际为{len(payload)}")
    values = struct.unpack("<BBBBBBHII", payload)
    return Status(
        state=values[0],
        result_valid=bool(values[1]),
        result_trusted=bool(values[2]),
        region_type=values[3],
        observation_count=values[4],
        active_observation_index=values[5],
        vertex_count=values[6],
        error_flags=values[7],
        core_cycles=values[8],
    )


def parse_result_header(payload: bytes) -> ResultHeader:
    if len(payload) != 27:
        raise ValueError(f"RESULT_HEADER长度应为27，实际为{len(payload)}")
    job_sequence, trusted, region_type, vertex_count = struct.unpack_from("<HBBH", payload, 0)
    farthest_first, farthest_second, core_cycles, error_flags = struct.unpack_from(
        "<HHII", payload, 15
    )
    return ResultHeader(
        job_sequence=job_sequence,
        trusted=bool(trusted),
        region_type=region_type,
        vertex_count=vertex_count,
        diameter_squared_raw=unpack_u66_le(payload[6:15]),
        farthest_first=farthest_first,
        farthest_second=farthest_second,
        core_cycles=core_cycles,
        error_flags=error_flags,
    )


def parse_result_vertices(payload: bytes) -> tuple[int, int, tuple[tuple[int, int], ...]]:
    if len(payload) < 16 or (len(payload) - 8) % 8:
        raise ValueError("RESULT_VERTICES载荷长度非法")
    job_sequence, start_index, count, reserved = struct.unpack_from("<HHB3s", payload, 0)
    if reserved != b"\x00\x00\x00" or len(payload) != 8 + 8 * count:
        raise ValueError("RESULT_VERTICES头或计数非法")
    vertices = tuple(struct.unpack_from("<ii", payload, 8 + 8 * index) for index in range(count))
    return job_sequence, start_index, vertices


class ProtocolClient:
    """严格按一次请求、一次响应顺序访问阶段1协议。"""

    def __init__(self, transport: ByteTransport) -> None:
        self.transport = transport
        self.sequence = 0

    def _read_exact(self, size: int) -> bytes:
        result = bytearray()
        while len(result) < size:
            chunk = self.transport.read(size - len(result))
            if not chunk:
                raise TimeoutError(f"串口读取超时：需要{size}字节，只收到{len(result)}字节")
            result.extend(chunk)
        return bytes(result)

    def _read_frame(self) -> Frame:
        previous = -1
        while True:
            current = self._read_exact(1)[0]
            if previous == 0xA5 and current == 0x5A:
                break
            previous = current
        header = self._read_exact(6)
        payload_length = int.from_bytes(header[4:6], "little")
        tail = self._read_exact(payload_length + 2)
        return decode_frame(b"\xa5\x5a" + header + tail)

    def transact(self, command: Command, payload: bytes = b"") -> tuple[Frame, float]:
        self.sequence = (self.sequence + 1) & 0xFFFF
        request = Frame(int(command), self.sequence, payload).encode()
        started = time.perf_counter()
        if self.transport.write(request) != len(request):
            raise IOError("串口未完整写入请求帧")
        response = self._read_frame()
        elapsed = time.perf_counter() - started
        if response.sequence != self.sequence:
            raise ValueError(f"响应SEQ不匹配：期望{self.sequence}，实际{response.sequence}")
        if response.command == int(Response.ERROR):
            failed_command, error_code, engine_state, _, context = struct.unpack("<BBBBI", response.payload)
            raise RuntimeError(
                f"FPGA ERROR failed_cmd=0x{failed_command:02x} code=0x{error_code:02x} "
                f"state=0x{engine_state:02x} context=0x{context:08x}"
            )
        return response, elapsed


def _expect_response(frame: Frame, expected: Response) -> None:
    if frame.command != int(expected):
        raise ValueError(f"响应类型不匹配：期望0x{int(expected):02x}，实际0x{frame.command:02x}")


def _demo_observations() -> tuple[ObservationRaw, ...]:
    return (
        ObservationRaw(-1000 << 16, 0, 0),
        ObservationRaw(1000 << 16, 0, 1 << 17),
    )


def _read_all_vertices(client: ProtocolClient, header: ResultHeader) -> tuple[tuple[int, int], ...]:
    vertices: list[tuple[int, int]] = []
    while len(vertices) < header.vertex_count:
        start = len(vertices)
        count = min(16, header.vertex_count - start)
        frame, _ = client.transact(
            Command.READ_RESULT,
            pack_read_result(ResultReadKind.VERTICES, start, count),
        )
        _expect_response(frame, Response.RESULT_VERTICES)
        job_sequence, returned_start, chunk = parse_result_vertices(frame.payload)
        if job_sequence != header.job_sequence or returned_start != start:
            raise ValueError("顶点分页头与当前结果不一致")
        vertices.extend(chunk)
    return tuple(vertices)


def _wait_for_result(client: ProtocolClient, timeout_s: float) -> tuple[Status, float, int]:
    deadline = time.perf_counter() + timeout_s
    polling_started = time.perf_counter()
    polls = 0
    while time.perf_counter() < deadline:
        frame, _ = client.transact(Command.GET_STATUS)
        _expect_response(frame, Response.STATUS)
        status = parse_status(frame.payload)
        polls += 1
        if status.state == 0x06 and status.result_valid:
            return status, time.perf_counter() - polling_started, polls
        time.sleep(0.002)
    raise TimeoutError("等待定位结果超时")


def validate_board(
    client: ProtocolClient,
    stress_jobs: int,
    timeout_s: float,
) -> dict[str, object]:
    observations = _demo_observations()
    timing: dict[str, float] = {}
    frame, timing["get_info_roundtrip_s"] = client.transact(Command.GET_INFO)
    _expect_response(frame, Response.INFO)
    if len(frame.payload) != 24 or frame.payload[:2] != b"\x01\xb3":
        raise ValueError("INFO设备标识或长度不匹配")
    info_payload_hex = frame.payload.hex()
    frame, timing["set_config_roundtrip_s"] = client.transact(Command.SET_CONFIG, pack_set_config())
    _expect_response(frame, Response.ACK)
    frame, timing["load_observations_roundtrip_s"] = client.transact(
        Command.LOAD_OBSERVATIONS,
        pack_observations(observations),
    )
    _expect_response(frame, Response.ACK)

    full_started = time.perf_counter()
    frame, timing["start_ack_roundtrip_s"] = client.transact(Command.START_LOCALIZATION)
    _expect_response(frame, Response.ACK)
    start_sequence = frame.sequence
    status, timing["result_poll_s"], poll_count = _wait_for_result(client, timeout_s)
    frame, timing["result_header_roundtrip_s"] = client.transact(
        Command.READ_RESULT,
        pack_read_result(ResultReadKind.HEADER),
    )
    _expect_response(frame, Response.RESULT_HEADER)
    header = parse_result_header(frame.payload)
    vertices_started = time.perf_counter()
    vertices = _read_all_vertices(client, header)
    timing["result_vertices_roundtrip_s"] = time.perf_counter() - vertices_started
    timing["end_to_end_s"] = time.perf_counter() - full_started

    expected = localize_fixed(
        tuple(
            (
                observation.x_q16_16 / 65536.0,
                observation.y_q16_16 / 65536.0,
                observation.bearing_phase_u18 * 360.0 / (1 << 18),
            )
            for observation in observations
        )
    )
    expected_vertices = {(point.x_raw, point.y_raw) for point in expected.vertices}
    if header.job_sequence != start_sequence:
        raise ValueError("结果头未回填START命令序号")
    if header.vertex_count != len(expected.vertices) or set(vertices) != expected_vertices:
        raise ValueError("板级顶点与位精确模型不一致")
    if header.diameter_squared_raw != expected.diameter_squared_raw:
        raise ValueError("板级直径平方与位精确模型不一致")
    if header.core_cycles != status.core_cycles:
        raise ValueError("STATUS与RESULT_HEADER核心周期计数不一致")

    stress_cycle_counts: list[int] = []
    for _ in range(stress_jobs):
        frame, _ = client.transact(Command.START_LOCALIZATION)
        _expect_response(frame, Response.ACK)
        stress_status, _, _ = _wait_for_result(client, timeout_s)
        if not stress_status.result_trusted or stress_status.vertex_count != header.vertex_count:
            raise ValueError("连续任务出现状态污染或结果不可信")
        stress_cycle_counts.append(stress_status.core_cycles)

    return {
        "pass": True,
        "info_payload_hex": info_payload_hex,
        "result_header": asdict(header),
        "status": asdict(status),
        "vertices_raw": [list(vertex) for vertex in vertices],
        "timing": timing,
        "poll_count": poll_count,
        "core_time_us": header.core_cycles / 100.0,
        "stress_jobs": stress_jobs,
        "stress_cycle_min": min(stress_cycle_counts, default=None),
        "stress_cycle_max": max(stress_cycle_counts, default=None),
    }


def write_report(result: dict[str, object], output_dir: Path, port: str) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    result_with_context = {"port": port, "baud": 115200, **result}
    (output_dir / "t15_board_measurements.json").write_text(
        json.dumps(result_with_context, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    header = result["result_header"]
    timing = result["timing"]
    assert isinstance(header, dict) and isinstance(timing, dict)
    markdown = f"""# T15 Basys 3板级验证与性能实测

## 结论

板级UART、位精确结果核对和连续任务测试：**PASS**。测试串口为`{port}`，115200 bit/s、8N1。

## 实测结果

| 指标 | 数值 |
|---|---:|
| 核心周期数 | {header['core_cycles']} |
| 100 MHz核心时间 | {result['core_time_us']:.2f} us |
| 最终顶点数 | {header['vertex_count']} |
| 距离平方原始值 | {header['diameter_squared_raw']} |
| 端到端时间 | {timing['end_to_end_s']:.6f} s |
| 结果头往返 | {timing['result_header_roundtrip_s']:.6f} s |
| 顶点分页往返 | {timing['result_vertices_roundtrip_s']:.6f} s |
| 连续压力任务 | {result['stress_jobs']} |
| 压力周期范围 | {result['stress_cycle_min']} 至 {result['stress_cycle_max']} |

顶点集合和距离平方已与仓库内位精确定点模型逐位核对。UART往返时间包含主机、USB-UART和协议帧开销；核心时间按实现时钟100 MHz由FPGA周期计数换算。

## ILA证据

此脚本不读取Vivado ILA。请将同次捕获导出的CSV和`.ltx`放入本目录，并在总报告中记录触发条件、采样深度以及命令状态、RAM切换、顶点计数、约束/裁剪/直径握手的观察结论。
"""
    (output_dir / "t15_board_validation.md").write_text(markdown, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", required=True, help="Basys 3 USB-UART端口，例如COM5")
    parser.add_argument("--stress", type=int, default=1000, help="首个完整核对之后重复的任务数")
    parser.add_argument("--timeout", type=float, default=5.0, help="单个任务完成超时，单位秒")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=PROJECT_ROOT / "fpga_stage1" / "reports" / "t15_board",
    )
    arguments = parser.parse_args()
    if arguments.stress < 0:
        parser.error("--stress不能为负数")
    try:
        import serial
    except ModuleNotFoundError as error:
        raise SystemExit("缺少pyserial；请在板测Python环境安装pyserial后重试") from error
    with serial.Serial(arguments.port, 115200, timeout=arguments.timeout, write_timeout=arguments.timeout) as port:
        port.reset_input_buffer()
        result = validate_board(ProtocolClient(port), arguments.stress, arguments.timeout)
    write_report(result, arguments.output_dir, arguments.port)
    print(f"T15 board validation: PASS; report={arguments.output_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
