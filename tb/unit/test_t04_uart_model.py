"""Unit tests for the T04 UART semantic model."""

from __future__ import annotations

import unittest

from fpga_stage1.model.uart_reference import CLKS_PER_BIT, frame_bits, line_samples, receive_from_line


class UartReferenceTests(unittest.TestCase):
    def test_lsb_first_frame_order(self) -> None:
        self.assertEqual(frame_bits(0xA5), (0, 1, 0, 1, 0, 0, 1, 0, 1, 1))

    def test_all_byte_values_round_trip(self) -> None:
        for data in range(256):
            with self.subTest(data=data):
                result = receive_from_line(line_samples(data))
                self.assertEqual(result.data, data)
                self.assertFalse(result.frame_error)

    def test_stop_bit_error_is_reported(self) -> None:
        result = receive_from_line(line_samples(0x3C, stop_bit=0))
        self.assertEqual(result.data, 0x3C)
        self.assertTrue(result.frame_error)

    def test_two_percent_transmitter_clock_mismatch(self) -> None:
        for scale in (0.98, 1.02):
            transmitter_clocks = round(CLKS_PER_BIT * scale)
            with self.subTest(transmitter_clocks=transmitter_clocks):
                result = receive_from_line(line_samples(0x96, transmitter_clocks))
                self.assertEqual(result.data, 0x96)
                self.assertFalse(result.frame_error)


if __name__ == "__main__":
    unittest.main()
