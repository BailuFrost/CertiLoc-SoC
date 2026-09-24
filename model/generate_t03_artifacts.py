"""生成T03 UART协议黄金帧、CRC向量和验证报告。"""

from __future__ import annotations

import csv
import json
from pathlib import Path
import sys

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from fpga_stage1.model.protocol_reference import (
    Command,
    ErrorCode,
    Frame,
    ObservationRaw,
    RegionType,
    Response,
    ResultReadKind,
    crc16_ccitt_false,
    decode_frame,
    pack_ack,
    pack_error,
    pack_info,
    pack_observations,
    pack_read_result,
    pack_result_header,
    pack_result_vertices,
    pack_set_config,
    pack_status,
    validate_command_payload,
)


ROOT = Path(__file__).resolve().parents[1]
VECTOR_DIR = ROOT / "tb" / "vectors"
REPORT_DIR = ROOT / "reports"


def _record(name: str, direction: str, frame: Frame) -> dict[str, object]:
    encoded = frame.encode()
    decoded = decode_frame(encoded)
    if direction == "pc_to_fpga":
        validate_command_payload(decoded)
    return {
        "name": name,
        "direction": direction,
        "version": frame.version,
        "command": frame.command,
        "sequence": frame.sequence,
        "payload_length": len(frame.payload),
        "payload_hex": frame.payload.hex().upper(),
        "crc16": int.from_bytes(encoded[-2:], "little"),
        "crc_wire_hex": encoded[-2:].hex().upper(),
        "frame_hex": encoded.hex().upper(),
    }


def _build_records() -> list[dict[str, object]]:
    two_observations = (
        ObservationRaw(-1000 << 16, 0, 1895),
        ObservationRaw(1000 << 16, 0, 128727),
    )
    maximum_observations = tuple(
        ObservationRaw((index - 10) << 16, (10 - index) << 16, (index * 12345) % (1 << 18))
        for index in range(20)
    )
    vertices = tuple((index << 16, -(index << 15)) for index in range(16))
    frames = [
        ("get_info", "pc_to_fpga", Frame(Command.GET_INFO, 1)),
        ("set_config", "pc_to_fpga", Frame(Command.SET_CONFIG, 2, pack_set_config())),
        ("load_two_observations", "pc_to_fpga", Frame(Command.LOAD_OBSERVATIONS, 3, pack_observations(two_observations))),
        ("load_twenty_observations", "pc_to_fpga", Frame(Command.LOAD_OBSERVATIONS, 4, pack_observations(maximum_observations))),
        ("start_localization", "pc_to_fpga", Frame(Command.START_LOCALIZATION, 5)),
        ("get_status", "pc_to_fpga", Frame(Command.GET_STATUS, 6)),
        ("read_result_header", "pc_to_fpga", Frame(Command.READ_RESULT, 7, pack_read_result(ResultReadKind.HEADER))),
        ("read_result_vertices", "pc_to_fpga", Frame(Command.READ_RESULT, 8, pack_read_result(ResultReadKind.VERTICES, 32, 16))),
        ("abort", "pc_to_fpga", Frame(Command.ABORT, 9)),
        ("ack", "fpga_to_pc", Frame(Response.ACK, 3, pack_ack(Command.LOAD_OBSERVATIONS))),
        ("info", "fpga_to_pc", Frame(Response.INFO, 1, pack_info())),
        ("status", "fpga_to_pc", Frame(Response.STATUS, 6, pack_status(3, True, True, RegionType.POLYGON, 4, 4, 6, 0, 288431))),
        ("result_header", "fpga_to_pc", Frame(Response.RESULT_HEADER, 7, pack_result_header(5, True, RegionType.POLYGON, 6, (1 << 65) + 12345, 1, 4, 288431, 0))),
        ("result_vertices", "fpga_to_pc", Frame(Response.RESULT_VERTICES, 8, pack_result_vertices(5, 32, vertices))),
        ("crc_error", "fpga_to_pc", Frame(Response.ERROR, 3, pack_error(Command.LOAD_OBSERVATIONS, ErrorCode.CRC_MISMATCH, 0, 0))),
    ]
    return [_record(name, direction, frame) for name, direction, frame in frames]


def _write_vectors(records: list[dict[str, object]]) -> None:
    (VECTOR_DIR / "uart_protocol_frames.json").write_text(
        json.dumps(records, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    with (VECTOR_DIR / "uart_crc_vectors.csv").open("w", encoding="utf-8", newline="") as stream:
        writer = csv.writer(stream)
        writer.writerow(("name", "input_hex", "crc16_hex", "crc_wire_little_endian_hex"))
        writer.writerow(("ccitt_false_check", b"123456789".hex().upper(), "29B1", "B129"))
        for record in records:
            frame = bytes.fromhex(str(record["frame_hex"]))
            writer.writerow(
                (
                    record["name"],
                    frame[2:-2].hex().upper(),
                    f"{int(record['crc16']):04X}",
                    record["crc_wire_hex"],
                )
            )
    with (VECTOR_DIR / "uart_protocol_frames.mem").open("w", encoding="ascii", newline="\n") as stream:
        for record in records:
            stream.write(f"// {record['name']} payload={record['payload_length']}\n")
            for byte in bytes.fromhex(str(record["frame_hex"])):
                stream.write(f"{byte:02X}\n")


def _write_report(records: list[dict[str, object]]) -> None:
    maximum_frame = max(records, key=lambda item: int(item["payload_length"]))
    report = f"""# T03 UART协议验证报告

## 固定参数

| 项目 | 数值 |
|---|---:|
| SOF | A5 5A |
| VERSION | 01 |
| CRC | CRC-16/CCITT-FALSE |
| CRC参数 | poly=1021, init=FFFF, refin=false, refout=false, xorout=0000 |
| CRC线路字节序 | 小端，低字节先发送 |
| 最大Payload | 244字节 |
| 最大整帧 | 254字节 |
| 顶点分页上限 | 16个/帧 |
| 帧间字节超时 | 10,000,000个100 MHz周期，即100 ms |

## 生成结果

- 合法黄金帧：{len(records)}组；
- CRC标准检查串 `123456789`：0x{crc16_ccitt_false(b'123456789'):04X}；
- 最大黄金帧：`{maximum_frame['name']}`，Payload {maximum_frame['payload_length']}字节；
- 所有PC到FPGA黄金帧均通过CRC、长度和命令载荷语义校验；
- 距离平方按unsigned 66位编码为9字节，高6位保留为0；
- 结果顶点采用按需分页，不在定位完成后自动发送全部顶点。

## RTL使用边界

`packet_decoder`必须先完成整帧CRC验证，再一次性提交配置或观测。CRC错误、长度错误、超时和未知命令不得修改有效任务状态。该报告是Python协议模型证据，不是UART物理层、RTL仿真或Vivado综合证据。
"""
    (REPORT_DIR / "t03_uart_protocol_validation.md").write_text(report, encoding="utf-8")


def main() -> None:
    VECTOR_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    records = _build_records()
    _write_vectors(records)
    _write_report(records)
    print(json.dumps({
        "frame_count": len(records),
        "crc_check": f"0x{crc16_ccitt_false(b'123456789'):04X}",
        "maximum_payload_in_vectors": max(int(record["payload_length"]) for record in records),
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
