"""阶段1 UART二进制协议的可执行参考模型。"""

from __future__ import annotations

from dataclasses import dataclass
from enum import IntEnum, IntFlag
import struct
from typing import Sequence

# 帧起始符，2字节
SOF = bytes((0xA5, 0x5A))
# 协议版本号，1字节，位于帧头6字节的第1个字节
PROTOCOL_VERSION = 0x01
MAX_PAYLOAD_LENGTH = 244
MAX_FRAME_LENGTH = 2 + 6 + MAX_PAYLOAD_LENGTH + 2
MAX_VERTEX_CHUNK = 16
INTERBYTE_TIMEOUT_CYCLES = 10_000_000

# PC 到 FPGA 的命令
class Command(IntEnum):
    GET_INFO = 0x01
    SET_CONFIG = 0x10
    LOAD_OBSERVATIONS = 0x11
    START_LOCALIZATION = 0x12
    GET_STATUS = 0x13
    READ_RESULT = 0x14
    ABORT = 0x1F

# FPGA 到 PC 的响应
class Response(IntEnum):
    ACK = 0x80
    INFO = 0x81
    STATUS = 0x82
    RESULT_HEADER = 0x90
    RESULT_VERTICES = 0x91
    ERROR = 0xFF


class ErrorCode(IntEnum):
    # 可恢复错误
    NONE = 0x00  # 无错误
    BAD_VERSION = 0x01  # 协议版本不一致，如vertion不是0x01
    UNSUPPORTED_COMMAND = 0x02  # 命令码未知
    INVALID_LENGTH = 0x03  # len不合法
    CRC_MISMATCH = 0x04  # CRC错误
    RX_TIMEOUT = 0x05
    PARAMETER_RANGE = 0x06  # 固定参数设置超出范围
    BUSY = 0x07
    OBSERVATION_COUNT = 0x08  # 观测数量不合法，不在2-20内
    RESERVED_NONZERO = 0x09  # 协议中要求为0的字段出现了非零值
    RESULT_UNAVAILABLE = 0x0A  # 发起读取时，没有可读取结果
    # 计算引擎报错，出现报错后 result_trusted 置零
    VERTEX_CAPACITY = 0x20  # 顶点数量超出1024
    ARITHMETIC_OVERFLOW = 0x21  # 数据位宽溢出
    PARALLEL_EDGE = 0x22  # 线段与半平面边界近似平行，交点计算分母过小，无法可靠执行普通除法
    CORDIC_TIMEOUT = 0x23
    ILLEGAL_STATE = 0x24  # 状态机进入异常状态

# 定位后的多边形类型
class RegionType(IntEnum):
    EMPTY = 0x00
    POINT = 0x01  # 顶点（多边形退化得到）
    SEGMENT = 0x02  # 线段（多边形退化得到）
    POLYGON = 0x03  # 多边形
    INVALID = 0xFF


class ResultReadKind(IntEnum):
    HEADER = 0x00
    VERTICES = 0x01

# 已支持的功能和固定参数
class CapabilityFlag(IntFlag):
    FIXED_RADIUS = 1 << 0  # 定位区域半径固定为1800
    FIXED_BEARING_DELTA = 1 << 1  # 示向角误差固定为1.005
    VERTEX_PAGING = 1 << 2  # 顶点分页读取
    CORE_CYCLE_COUNTER = 1 << 3  # 统计运算周期数
    ITERATIVE_CORDIC = 1 << 4  # 使用CORDIC
    COLLINEARITY_NOT_CHECKED = 1 << 5  # 没有完整的多定点共线检测


class EngineState(IntEnum):
    IDLE = 0x00
    RECEIVE = 0x01
    LOAD_INITIAL_POLYGON = 0x02
    CORDIC = 0x03
    CLIP = 0x04
    DIAMETER = 0x05
    RESULT_READY = 0x06
    TRANSMIT = 0x07
    ERROR_REPORT = 0xFE
    ILLEGAL = 0xFF


class ResultFlag(IntFlag):
    QUANTIZATION_MARGIN_USED = 1 << 0
    PARALLEL_EDGE = 1 << 1
    ARITHMETIC_OVERFLOW = 1 << 2
    VERTEX_CAPACITY = 1 << 3
    CORDIC_TIMEOUT = 1 << 4
    ILLEGAL_STATE = 1 << 5
    COLLINEARITY_NOT_CHECKED = 1 << 6
    ABORTED = 1 << 7


class ProtocolError(ValueError):
    """携带协议错误码的解析异常。"""

    def __init__(self, code: ErrorCode, message: str) -> None:
        super().__init__(message)
        self.code = code


@dataclass(frozen=True)
class Frame:
    """去除SOF和CRC后的逻辑帧。"""

    command: int
    sequence: int
    payload: bytes = b""
    version: int = PROTOCOL_VERSION

    def encode(self) -> bytes:
        if not 0 <= self.command <= 0xFF:
            raise ValueError("command必须为8位无符号数")
        if not 0 <= self.sequence <= 0xFFFF:
            raise ValueError("sequence必须为16位无符号数")
        if len(self.payload) > MAX_PAYLOAD_LENGTH:
            raise ProtocolError(ErrorCode.INVALID_LENGTH, "Payload超过244字节")
        body = struct.pack(
            "<BBHH",
            self.version,
            self.command,
            self.sequence,
            len(self.payload),
        ) + self.payload
        checksum = crc16_ccitt_false(body)
        return SOF + body + struct.pack("<H", checksum)


@dataclass(frozen=True)
class ObservationRaw:
    """已经量化的单条观测。"""

    x_q16_16: int
    y_q16_16: int
    bearing_phase_u18: int


def crc16_ccitt_false(data: bytes) -> int:
    """CRC-16/CCITT-FALSE：poly=0x1021、init=0xFFFF、非反射、xorout=0。"""

    crc = 0xFFFF
    for byte in data:
        crc ^= byte << 8
        for _ in range(8):
            if crc & 0x8000:
                crc = ((crc << 1) ^ 0x1021) & 0xFFFF
            else:
                crc = (crc << 1) & 0xFFFF
    return crc


def decode_frame(encoded: bytes, *, require_version: bool = True) -> Frame:
    """解码并校验一帧；不接受尾随字节。"""

    if len(encoded) < 10:
        raise ProtocolError(ErrorCode.INVALID_LENGTH, "帧短于最小长度")
    if encoded[:2] != SOF:
        raise ProtocolError(ErrorCode.INVALID_LENGTH, "SOF不匹配")
    version, command, sequence, payload_length = struct.unpack_from("<BBHH", encoded, 2)
    if payload_length > MAX_PAYLOAD_LENGTH:
        raise ProtocolError(ErrorCode.INVALID_LENGTH, "LEN超过244")
    expected_length = 10 + payload_length
    if len(encoded) != expected_length:
        raise ProtocolError(ErrorCode.INVALID_LENGTH, "帧长度与LEN不一致")
    body = encoded[2:-2]
    received_crc = struct.unpack_from("<H", encoded, len(encoded) - 2)[0]
    if crc16_ccitt_false(body) != received_crc:
        raise ProtocolError(ErrorCode.CRC_MISMATCH, "CRC校验失败")
    if require_version and version != PROTOCOL_VERSION:
        raise ProtocolError(ErrorCode.BAD_VERSION, "协议版本不受支持")
    return Frame(command=command, sequence=sequence, payload=encoded[8:-2], version=version)


def scan_frames(stream: bytes) -> tuple[tuple[Frame, ...], tuple[ErrorCode, ...]]:
    """从含噪字节流中提取完整帧，并按SOF重叠规则重新同步。

    尾部不完整帧保留给调用方的流式缓冲，本函数不把它计为错误。
    """

    frames: list[Frame] = []
    errors: list[ErrorCode] = []
    cursor = 0
    while cursor + 2 <= len(stream):
        start = stream.find(SOF, cursor)
        if start < 0:
            break
        if len(stream) - start < 8:
            break
        payload_length = struct.unpack_from("<H", stream, start + 6)[0]
        if payload_length > MAX_PAYLOAD_LENGTH:
            errors.append(ErrorCode.INVALID_LENGTH)
            cursor = start + 1
            continue
        frame_length = 10 + payload_length
        if len(stream) - start < frame_length:
            break
        candidate = stream[start : start + frame_length]
        try:
            frames.append(decode_frame(candidate))
            cursor = start + frame_length
        except ProtocolError as error:
            errors.append(error.code)
            cursor = start + 1
    return tuple(frames), tuple(errors)


def pack_set_config() -> bytes:
    """生成阶段1唯一受支持的28字节配置。"""

    return struct.pack(
        "<IIQQHH",
        1800 << 16,
        732,
        1 << 30,
        1 << 30,
        720,
        1024,
    )


def unpack_set_config(payload: bytes) -> dict[str, int]:
    if len(payload) != 28:
        raise ProtocolError(ErrorCode.INVALID_LENGTH, "SET_CONFIG载荷必须为28字节")
    radius, delta, eps_hp, eps_den, polygon_sides, maximum_vertices = struct.unpack(
        "<IIQQHH", payload
    )
    expected = struct.unpack("<IIQQHH", pack_set_config())
    if (radius, delta, eps_hp, eps_den, polygon_sides, maximum_vertices) != expected:
        raise ProtocolError(ErrorCode.PARAMETER_RANGE, "阶段1只接受冻结配置")
    return {
        "radius_q16_16": radius,
        "delta_phase_u18": delta,
        "eps_halfplane_raw": eps_hp,
        "eps_denominator_raw": eps_den,
        "polygon_side_count": polygon_sides,
        "maximum_vertex_count": maximum_vertices,
    }


def pack_observations(observations: Sequence[ObservationRaw]) -> bytes:
    if not 2 <= len(observations) <= 20:
        raise ProtocolError(ErrorCode.OBSERVATION_COUNT, "观测数量必须为2至20")
    payload = bytearray((len(observations), 0, 0, 0))
    for observation in observations:
        if not -(1 << 31) <= observation.x_q16_16 < (1 << 31):
            raise ProtocolError(ErrorCode.PARAMETER_RANGE, "x坐标超出signed Q16.16")
        if not -(1 << 31) <= observation.y_q16_16 < (1 << 31):
            raise ProtocolError(ErrorCode.PARAMETER_RANGE, "y坐标超出signed Q16.16")
        if not 0 <= observation.bearing_phase_u18 < (1 << 18):
            raise ProtocolError(ErrorCode.PARAMETER_RANGE, "相位超出18位范围")
        payload.extend(
            struct.pack(
                "<iiI",
                observation.x_q16_16,
                observation.y_q16_16,
                observation.bearing_phase_u18,
            )
        )
    return bytes(payload)


def unpack_observations(payload: bytes) -> tuple[ObservationRaw, ...]:
    if len(payload) < 4:
        raise ProtocolError(ErrorCode.INVALID_LENGTH, "观测载荷不足4字节")
    count = payload[0]
    if not 2 <= count <= 20:
        raise ProtocolError(ErrorCode.OBSERVATION_COUNT, "观测数量必须为2至20")
    if payload[1:4] != b"\x00\x00\x00":
        raise ProtocolError(ErrorCode.RESERVED_NONZERO, "观测保留字段必须为0")
    if len(payload) != 4 + count * 12:
        raise ProtocolError(ErrorCode.INVALID_LENGTH, "观测载荷长度与数量不一致")
    observations: list[ObservationRaw] = []
    for index in range(count):
        x_value, y_value, phase = struct.unpack_from("<iiI", payload, 4 + index * 12)
        if phase >> 18:
            raise ProtocolError(ErrorCode.PARAMETER_RANGE, "相位字段高14位必须为0")
        observations.append(ObservationRaw(x_value, y_value, phase))
    return tuple(observations)


def pack_read_result(
    kind: ResultReadKind,
    start_index: int = 0,
    maximum_vertices: int = 0,
) -> bytes:
    if kind == ResultReadKind.HEADER:
        if start_index != 0 or maximum_vertices != 0:
            raise ProtocolError(ErrorCode.PARAMETER_RANGE, "读取结果头时索引和数量必须为0")
    elif kind == ResultReadKind.VERTICES:
        if not 0 <= start_index < 1024:
            raise ProtocolError(ErrorCode.PARAMETER_RANGE, "顶点起始索引越界")
        if not 1 <= maximum_vertices <= MAX_VERTEX_CHUNK:
            raise ProtocolError(ErrorCode.PARAMETER_RANGE, "单次最多读取16个顶点")
    else:
        raise ProtocolError(ErrorCode.PARAMETER_RANGE, "未知结果读取类型")
    return struct.pack("<BBHB3s", int(kind), 0, start_index, maximum_vertices, b"\x00\x00\x00")


def unpack_read_result(payload: bytes) -> tuple[ResultReadKind, int, int]:
    if len(payload) != 8:
        raise ProtocolError(ErrorCode.INVALID_LENGTH, "READ_RESULT载荷必须为8字节")
    kind_raw, reserved, start_index, maximum_vertices, tail = struct.unpack("<BBHB3s", payload)
    if reserved != 0 or tail != b"\x00\x00\x00":
        raise ProtocolError(ErrorCode.RESERVED_NONZERO, "READ_RESULT保留字段必须为0")
    try:
        kind = ResultReadKind(kind_raw)
    except ValueError as exc:
        raise ProtocolError(ErrorCode.PARAMETER_RANGE, "未知结果读取类型") from exc
    pack_read_result(kind, start_index, maximum_vertices)
    return kind, start_index, maximum_vertices


def pack_u66_le(value: int) -> bytes:
    """将unsigned 66位距离平方编码到9字节小端字段，高6位必须为0。"""

    if not 0 <= value < (1 << 66):
        raise ProtocolError(ErrorCode.PARAMETER_RANGE, "距离平方超出66位")
    return value.to_bytes(9, "little")


def unpack_u66_le(encoded: bytes) -> int:
    if len(encoded) != 9:
        raise ProtocolError(ErrorCode.INVALID_LENGTH, "66位字段必须占9字节")
    value = int.from_bytes(encoded, "little")
    if value >> 66:
        raise ProtocolError(ErrorCode.RESERVED_NONZERO, "66位字段高6位必须为0")
    return value


def pack_ack(request_command: int, ack_code: int = 0, detail: int = 0) -> bytes:
    return struct.pack("<BBH", request_command, ack_code, detail)


def pack_info() -> bytes:
    capability_flags = int(
        CapabilityFlag.FIXED_RADIUS
        | CapabilityFlag.FIXED_BEARING_DELTA
        | CapabilityFlag.VERTEX_PAGING
        | CapabilityFlag.CORE_CYCLE_COUNTER
        | CapabilityFlag.ITERATIVE_CORDIC
        | CapabilityFlag.COLLINEARITY_NOT_CHECKED
    )
    return struct.pack(
        "<HBBIIBBBBBBHHH",
        0xB301,
        PROTOCOL_VERSION,
        capability_flags,
        100_000_000,
        115_200,
        16,
        30,
        18,
        18,
        20,
        MAX_VERTEX_CHUNK,
        720,
        1024,
        0,
    )


def pack_status(
    state: int,
    result_valid: bool,
    result_trusted: bool,
    region_type: RegionType,
    observation_count: int,
    active_observation_index: int,
    vertex_count: int,
    error_flags: int,
    core_cycles: int,
) -> bytes:
    return struct.pack(
        "<BBBBBBHII",
        state,
        int(result_valid),
        int(result_trusted),
        int(region_type),
        observation_count,
        active_observation_index,
        vertex_count,
        error_flags,
        core_cycles,
    )


def pack_result_header(
    job_sequence: int,
    trusted: bool,
    region_type: RegionType,
    vertex_count: int,
    diameter_squared_raw: int,
    farthest_first: int,
    farthest_second: int,
    core_cycles: int,
    error_flags: int,
) -> bytes:
    return (
        struct.pack(
            "<HBBH",
            job_sequence,
            int(trusted),
            int(region_type),
            vertex_count,
        )
        + pack_u66_le(diameter_squared_raw)
        + struct.pack(
            "<HHII",
            farthest_first,
            farthest_second,
            core_cycles,
            error_flags,
        )
    )


def pack_result_vertices(
    job_sequence: int,
    start_index: int,
    vertices: Sequence[tuple[int, int]],
) -> bytes:
    if not 1 <= len(vertices) <= MAX_VERTEX_CHUNK:
        raise ProtocolError(ErrorCode.PARAMETER_RANGE, "每个顶点块必须包含1至16个顶点")
    payload = bytearray(struct.pack("<HHB3s", job_sequence, start_index, len(vertices), b"\x00\x00\x00"))
    for x_value, y_value in vertices:
        payload.extend(struct.pack("<ii", x_value, y_value))
    return bytes(payload)


def pack_error(
    failed_command: int,
    error_code: ErrorCode,
    engine_state: int,
    context: int = 0,
) -> bytes:
    return struct.pack("<BBBBI", failed_command, int(error_code), engine_state, 0, context)


def validate_command_payload(frame: Frame) -> None:
    """在CRC通过后验证命令及载荷语义。"""

    try:
        command = Command(frame.command)
    except ValueError as exc:
        raise ProtocolError(ErrorCode.UNSUPPORTED_COMMAND, "未知命令") from exc
    if command in {
        Command.GET_INFO,
        Command.START_LOCALIZATION,
        Command.GET_STATUS,
        Command.ABORT,
    }:
        if frame.payload:
            raise ProtocolError(ErrorCode.INVALID_LENGTH, "该命令载荷必须为空")
    elif command == Command.SET_CONFIG:
        unpack_set_config(frame.payload)
    elif command == Command.LOAD_OBSERVATIONS:
        unpack_observations(frame.payload)
    elif command == Command.READ_RESULT:
        unpack_read_result(frame.payload)
