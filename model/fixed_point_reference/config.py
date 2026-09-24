"""阶段1定点格式和容量的唯一配置来源。"""

from dataclasses import dataclass


@dataclass(frozen=True)
class FixedConfig:
    """位精确模型配置。

    半平面函数值的46个小数位来自Q2.30系数与Q16.16坐标的乘积。
    CORDIC内部使用32个小数位，比输出Q2.30多2个保护位。
    """

    # 坐标为2位Q16.16，第1位为符号位，2-16为整数部分（32768），17-32为小数部分
    coordinate_bits: int = 32
    coordinate_fraction_bits: int = 16
    # 输入的示向角为18位，精度约0.001度
    phase_bits: int = 18
    # CORDIC角度累加器使用更高精度，避免18位反正切表逐项量化累积误差。
    # 角度扩展为32位，输入的18位需右移14位
    cordic_phase_bits: int = 32 
    # 正弦和余弦采用Q2.30有符号数，第1位为符号位，第2位为整数部分（最大为1），3-32位为小数部分
    trigonometric_bits: int = 32
    trigonometric_fraction_bits: int = 30
    # 防止CORDIC迭代时的截断误差，扩展为36位，最后缩短为32位Q2.30
    cordic_internal_bits: int = 36
    cordic_internal_fraction_bits: int = 32
    # 迭代次数为18
    cordic_iterations: int = 18
    # 半平面函数的计算结果，最高不超过66位
    halfplane_value_bits: int = 66
    # 交点判断比值，设置为Q2.30，最大为1
    ratio_bits: int = 32
    ratio_fraction_bits: int = 30
    # 距离平方的位宽设置为66
    distance_squared_bits: int = 66
    # 多边形初始720边
    polygon_side_count: int = 720
    # 顶点上限为1024个
    maximum_vertex_count: int = 1024
    radius_m: float = 1800.0
    bearing_delta_deg: float = 1.005
    # 1个坐标LSB对应的半平面函数裕量，函数值具有46个小数位。
    eps_halfplane_raw: int = 1 << 30
    # 近并行判据采用相同量纲；T09若改变除法结构必须重新扫描。
    eps_denominator_raw: int = 1 << 30


DEFAULT_CONFIG = FixedConfig()
