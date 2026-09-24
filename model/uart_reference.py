"""T04 UART cycle-level semantic helpers.

The RTL uses an integer 868-clock bit period at 100 MHz.  This module keeps the
wire ordering and receiver sampling rules executable without depending on an HDL
simulator, so the testbench expectations have one explicit software source.
"""

from __future__ import annotations

from dataclasses import dataclass


SYSTEM_CLOCK_HZ = 100_000_000
UART_BAUD = 115_200
CLKS_PER_BIT = SYSTEM_CLOCK_HZ // UART_BAUD
HALF_BIT_CLKS = CLKS_PER_BIT // 2


@dataclass(frozen=True)
class UartReceiveResult:
    """Decoded byte and stop-bit status for one idealized 8N1 frame."""

    data: int
    frame_error: bool


def frame_bits(data: int, *, stop_bit: int = 1) -> tuple[int, ...]:
    """Return start, eight LSB-first data bits, and the requested stop bit."""

    if not 0 <= data <= 0xFF:
        raise ValueError("UART data must fit in one byte")
    if stop_bit not in (0, 1):
        raise ValueError("stop_bit must be 0 or 1")
    return (0, *((data >> bit_index) & 1 for bit_index in range(8)), stop_bit)


def line_samples(data: int, clocks_per_bit: int = CLKS_PER_BIT, *, stop_bit: int = 1) -> list[int]:
    """Expand one UART frame into a system-clock sampled logic-level sequence."""

    if clocks_per_bit <= 0:
        raise ValueError("clocks_per_bit must be positive")
    return [level for level in frame_bits(data, stop_bit=stop_bit) for _ in range(clocks_per_bit)]


def receive_from_line(samples: list[int], receiver_clocks_per_bit: int = CLKS_PER_BIT) -> UartReceiveResult:
    """Decode one frame using the RTL's half-start then full-bit sampling schedule."""

    if receiver_clocks_per_bit < 2:
        raise ValueError("receiver_clocks_per_bit must be at least two")
    try:
        start_index = samples.index(0)
    except ValueError as error:
        raise ValueError("no UART start bit found") from error

    half_bit = receiver_clocks_per_bit // 2
    if start_index + half_bit >= len(samples) or samples[start_index + half_bit] != 0:
        raise ValueError("false UART start bit")

    data = 0
    for bit_index in range(8):
        sample_index = start_index + half_bit + (bit_index + 1) * receiver_clocks_per_bit
        if sample_index >= len(samples):
            raise ValueError("truncated UART data field")
        data |= (samples[sample_index] & 1) << bit_index

    stop_index = start_index + half_bit + 9 * receiver_clocks_per_bit
    if stop_index >= len(samples):
        raise ValueError("truncated UART stop bit")
    return UartReceiveResult(data=data, frame_error=samples[stop_index] != 1)

