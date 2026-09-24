"""18次迭代旋转模式CORDIC位精确模型。"""

from __future__ import annotations

from dataclasses import dataclass
import math

from .config import DEFAULT_CONFIG, FixedConfig
from .fixed_math import round_half_away_from_zero, round_shift, saturate_signed

# 迭代后输出三角函数值
@dataclass(frozen=True)
class CordicResult:
    """CORDIC的Q2.30输出和诊断信息。"""

    sine_raw: int
    cosine_raw: int
    # 完成迭代后的相位误差
    residual_phase_raw: int
    saturated: bool

    # trigonometric_fraction_bits 为30，表示输出的正弦值和余弦值的小数部分
    @property
    def sine(self) -> float:
        return self.sine_raw / float(1 << DEFAULT_CONFIG.trigonometric_fraction_bits)

    @property
    def cosine(self) -> float:
        return self.cosine_raw / float(1 << DEFAULT_CONFIG.trigonometric_fraction_bits)


def degrees_to_phase(angle_deg: float, config: FixedConfig = DEFAULT_CONFIG) -> int:
    """将角度编码为无符号整周相位。"""

    # phase_bits 为18，表示输入的示向角为18位
    full_turn = 1 << config.phase_bits
    normalized = angle_deg % 360.0
    return round_half_away_from_zero(normalized * full_turn / 360.0) % full_turn

# 无符号整周相位转角度
def phase_to_degrees(phase_raw: int, config: FixedConfig = DEFAULT_CONFIG) -> float:
    full_turn = 1 << config.phase_bits
    return (phase_raw % full_turn) * 360.0 / full_turn

# 计算并输出18次迭代的各个角度
def _atan_table(config: FixedConfig) -> tuple[int, ...]:
    # cordic_phase_bits 取32，为扩展后的角度位数
    full_turn = 1 << config.cordic_phase_bits
    return tuple(
        round_half_away_from_zero(math.atan(2.0**-index) * full_turn / (2.0 * math.pi))
        # cordic_iterations 为迭代次数，取18
        for index in range(config.cordic_iterations)
    )

# 计算并输出18次迭代后的模长变化倍数，用于后续相乘，保持模长一致
def _inverse_gain_raw(config: FixedConfig) -> int:
    gain = 1.0
    for index in range(config.cordic_iterations):
        gain *= math.sqrt(1.0 + 2.0 ** (-2 * index))
    return round_half_away_from_zero((1.0 / gain) * (1 << config.cordic_internal_fraction_bits))


def _reduce_quadrant(phase_raw: int, config: FixedConfig) -> tuple[int, int, int]:
    full_turn = 1 << config.phase_bits
    quarter_turn = full_turn >> 2
    half_turn = full_turn >> 1
    three_quarters = quarter_turn * 3
    phase = phase_raw % full_turn
    if phase < quarter_turn:
        return phase, 1, 1
    if phase < half_turn:
        return half_turn - phase, -1, 1
    if phase < three_quarters:
        return phase - half_turn, -1, -1
    return full_turn - phase, 1, -1


def cordic_sincos(
    phase_raw: int,
    config: FixedConfig = DEFAULT_CONFIG,
) -> CordicResult:
    """计算18位相位对应的Q2.30正弦和余弦。

    每轮都按有符号算术右移执行微旋转。内部整数不主动截断；函数会检查
    是否超出预定36位寄存器范围，并通过 ``saturated`` 报告。
    """

    residual, cosine_sign, sine_sign = _reduce_quadrant(phase_raw, config)
    residual <<= config.cordic_phase_bits - config.phase_bits
    x_value = _inverse_gain_raw(config)
    y_value = 0
    z_value = residual
    saturated = False
    minimum = -(1 << (config.cordic_internal_bits - 1))
    maximum = (1 << (config.cordic_internal_bits - 1)) - 1

    for index, angle_step in enumerate(_atan_table(config)):
        previous_x = x_value
        previous_y = y_value
        if z_value >= 0:
            x_value = previous_x - (previous_y >> index)
            y_value = previous_y + (previous_x >> index)
            z_value -= angle_step
        else:
            x_value = previous_x + (previous_y >> index)
            y_value = previous_y - (previous_x >> index)
            z_value += angle_step
        saturated = saturated or not (minimum <= x_value <= maximum and minimum <= y_value <= maximum)

    output_shift = config.cordic_internal_fraction_bits - config.trigonometric_fraction_bits
    cosine_raw = cosine_sign * round_shift(x_value, output_shift)
    sine_raw = sine_sign * round_shift(y_value, output_shift)
    cosine_raw, cosine_saturated = saturate_signed(cosine_raw, config.trigonometric_bits)
    sine_raw, sine_saturated = saturate_signed(sine_raw, config.trigonometric_bits)
    return CordicResult(
        sine_raw=sine_raw,
        cosine_raw=cosine_raw,
        residual_phase_raw=z_value,
        saturated=saturated or cosine_saturated or sine_saturated,
    )


def atan_table(config: FixedConfig = DEFAULT_CONFIG) -> tuple[int, ...]:
    """公开只读反正切表，供后续RTL规格直接使用。"""

    return _atan_table(config)


def inverse_gain_raw(config: FixedConfig = DEFAULT_CONFIG) -> int:
    """公开CORDIC初始增益补偿常量。"""

    return _inverse_gain_raw(config)
