"""T03 UART协议模型单元测试。"""

from __future__ import annotations

from pathlib import Path
import sys
import unittest

PROJECT_ROOT = Path(__file__).resolve().parents[3]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from fpga_stage1.model.protocol_reference import (
    Command,
    ErrorCode,
    Frame,
    MAX_FRAME_LENGTH,
    MAX_PAYLOAD_LENGTH,
    ObservationRaw,
    ProtocolError,
    ResultReadKind,
    crc16_ccitt_false,
    decode_frame,
    pack_observations,
    pack_read_result,
    pack_set_config,
    pack_u66_le,
    unpack_observations,
    unpack_read_result,
    unpack_set_config,
    unpack_u66_le,
    scan_frames,
    validate_command_payload,
)


class TestProtocol(unittest.TestCase):
    def test_crc_standard_check(self) -> None:
        self.assertEqual(crc16_ccitt_false(b"123456789"), 0x29B1)

    def test_empty_command_round_trip(self) -> None:
        encoded = Frame(Command.GET_INFO, 0x1234).encode()
        decoded = decode_frame(encoded)
        self.assertEqual(decoded.command, Command.GET_INFO)
        self.assertEqual(decoded.sequence, 0x1234)
        self.assertEqual(decoded.payload, b"")
        validate_command_payload(decoded)

    def test_crc_corruption_rejected(self) -> None:
        encoded = bytearray(Frame(Command.GET_STATUS, 7).encode())
        encoded[3] ^= 0x01
        with self.assertRaises(ProtocolError) as caught:
            decode_frame(bytes(encoded))
        self.assertEqual(caught.exception.code, ErrorCode.CRC_MISMATCH)

    def test_set_config_is_exact(self) -> None:
        values = unpack_set_config(pack_set_config())
        self.assertEqual(values["delta_phase_u18"], 732)
        corrupted = bytearray(pack_set_config())
        corrupted[0] ^= 0x01
        with self.assertRaises(ProtocolError) as caught:
            unpack_set_config(bytes(corrupted))
        self.assertEqual(caught.exception.code, ErrorCode.PARAMETER_RANGE)

    def test_observation_minimum_and_maximum(self) -> None:
        minimum = tuple(ObservationRaw(index, -index, index) for index in range(2))
        maximum = tuple(ObservationRaw(index, -index, index) for index in range(20))
        self.assertEqual(unpack_observations(pack_observations(minimum)), minimum)
        maximum_payload = pack_observations(maximum)
        self.assertEqual(len(maximum_payload), MAX_PAYLOAD_LENGTH)
        maximum_frame = Frame(Command.LOAD_OBSERVATIONS, 2, maximum_payload).encode()
        self.assertEqual(len(maximum_frame), MAX_FRAME_LENGTH)

    def test_observation_reserved_and_phase_bits(self) -> None:
        payload = bytearray(pack_observations((ObservationRaw(0, 0, 0), ObservationRaw(1, 1, 1))))
        payload[1] = 1
        with self.assertRaises(ProtocolError) as caught:
            unpack_observations(bytes(payload))
        self.assertEqual(caught.exception.code, ErrorCode.RESERVED_NONZERO)

        payload = bytearray(pack_observations((ObservationRaw(0, 0, 0), ObservationRaw(1, 1, 1))))
        payload[4 + 8 + 2] = 0x04
        with self.assertRaises(ProtocolError) as caught:
            unpack_observations(bytes(payload))
        self.assertEqual(caught.exception.code, ErrorCode.PARAMETER_RANGE)

    def test_read_result_paging(self) -> None:
        header = pack_read_result(ResultReadKind.HEADER)
        self.assertEqual(unpack_read_result(header), (ResultReadKind.HEADER, 0, 0))
        vertices = pack_read_result(ResultReadKind.VERTICES, 100, 16)
        self.assertEqual(unpack_read_result(vertices), (ResultReadKind.VERTICES, 100, 16))
        with self.assertRaises(ProtocolError):
            pack_read_result(ResultReadKind.VERTICES, 0, 17)

    def test_unsigned_66_bit_field(self) -> None:
        maximum = (1 << 66) - 1
        encoded = pack_u66_le(maximum)
        self.assertEqual(len(encoded), 9)
        self.assertEqual(unpack_u66_le(encoded), maximum)
        invalid = bytearray(encoded)
        invalid[8] |= 0x80
        with self.assertRaises(ProtocolError) as caught:
            unpack_u66_le(bytes(invalid))
        self.assertEqual(caught.exception.code, ErrorCode.RESERVED_NONZERO)

    def test_payload_length_limit(self) -> None:
        with self.assertRaises(ProtocolError) as caught:
            Frame(Command.SET_CONFIG, 1, bytes(MAX_PAYLOAD_LENGTH + 1)).encode()
        self.assertEqual(caught.exception.code, ErrorCode.INVALID_LENGTH)

    def test_stream_resynchronization(self) -> None:
        first = Frame(Command.GET_INFO, 1).encode()
        second = Frame(Command.GET_STATUS, 2).encode()
        corrupted = bytearray(first)
        corrupted[-1] ^= 0x80
        stream = b"\x00\xA5" + bytes(corrupted) + b"\xA5" + second
        frames, errors = scan_frames(stream)
        self.assertEqual(len(frames), 1)
        self.assertEqual(frames[0].command, Command.GET_STATUS)
        self.assertIn(ErrorCode.CRC_MISMATCH, errors)

    def test_overlapping_sof(self) -> None:
        encoded = Frame(Command.GET_INFO, 9).encode()
        frames, errors = scan_frames(b"\xA5" + encoded)
        self.assertEqual(errors, ())
        self.assertEqual(len(frames), 1)
        self.assertEqual(frames[0].sequence, 9)


if __name__ == "__main__":
    unittest.main(verbosity=2)
