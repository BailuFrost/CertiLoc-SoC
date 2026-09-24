"""定宽整数和定点舍入辅助函数。"""

from __future__ import annotations

import math

# bit位有符号数的最大值与最小值
def signed_bounds(bits: int) -> tuple[int, int]:
    return -(1 << (bits - 1)), (1 << (bits - 1)) - 1

# 饱和截断
def saturate_signed(value: int, bits: int) -> tuple[int, bool]:
    minimum, maximum = signed_bounds(bits)
    if value < minimum:
        return minimum, True
    if value > maximum:
        return maximum, True
    return value, False

# 浮点数的四舍五入
def round_half_away_from_zero(value: float) -> int:
    """按绝对值五入的最近整数舍入，避免Python偶数舍入差异。"""

    if value >= 0.0:
        # 四舍五入，正数输入值+0.5后向下取整
        return math.floor(value + 0.5)
    return math.ceil(value - 0.5)

# 左右移运算后的四舍五入
# 这里不选择复用 round_half_away_from_zero 是防止右移后低位丢失
def round_shift(value: int, shift: int) -> int:
    """带符号整数右移并按最近值、半值远离零舍入。"""

    if shift < 0:
        return value << -shift
    if shift == 0:
        return value
    magnitude = abs(value)
    rounded = (magnitude + (1 << (shift - 1))) >> shift
    return rounded if value >= 0 else -rounded


def rounded_divide(numerator: int, denominator: int) -> int:
    """整数除法，商按最近值、半值远离零舍入。"""

    if denominator == 0:
        raise ZeroDivisionError("定点除法分母为零")
    sign = -1 if (numerator < 0) ^ (denominator < 0) else 1
    # 带余除法，余数大于0.5倍除数时，商+1,相当于对商进行四舍五入
    quotient, remainder = divmod(abs(numerator), abs(denominator))
    if remainder * 2 >= abs(denominator):
        quotient += 1
    return sign * quotient

# 浮点数的二进制转换，如转为32位Q16.16
# eg：1.5 -> 98304 -> 11000000000000000
def encode_signed(value: float, fraction_bits: int, bits: int) -> tuple[int, bool]:
    raw = round_half_away_from_zero(value * (1 << fraction_bits))
    # 饱和截断，防止 value 超出位数
    return saturate_signed(raw, bits)

# 二进制数转为浮点数
def decode_signed(raw: int, fraction_bits: int) -> float:
    return raw / float(1 << fraction_bits)

# 整数转16进制字符串输出
def unsigned_hex(value: int, bits: int) -> str:
    """将有符号或无符号整数编码为固定宽度二进制补码十六进制。"""

    mask = (1 << bits) - 1
    width = (bits + 3) // 4
    return f"{value & mask:0{width}X}"
