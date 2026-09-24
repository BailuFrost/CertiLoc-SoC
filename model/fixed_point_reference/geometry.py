"""阶段1几何数据通路的位精确定点参考模型。"""

from __future__ import annotations

from dataclasses import dataclass
import math
from typing import Iterable, Sequence

from .config import DEFAULT_CONFIG, FixedConfig
from .cordic import cordic_sincos, degrees_to_phase
from .fixed_math import (
    decode_signed,
    encode_signed,
    round_half_away_from_zero,
    round_shift,
    rounded_divide,
    saturate_signed,
)


@dataclass(frozen=True)
class FixedPoint:
    """两个signed Q16.16原始整数坐标。"""

    x_raw: int
    y_raw: int

    @classmethod
    def from_metres(cls, x_m: float, y_m: float, config: FixedConfig = DEFAULT_CONFIG) -> "FixedPoint":
        x_raw, x_saturated = encode_signed(x_m, config.coordinate_fraction_bits, config.coordinate_bits)
        y_raw, y_saturated = encode_signed(y_m, config.coordinate_fraction_bits, config.coordinate_bits)
        if x_saturated or y_saturated:
            raise OverflowError("坐标超出Q16.16范围")
        return cls(x_raw, y_raw)

    @property
    def x_m(self) -> float:
        return decode_signed(self.x_raw, DEFAULT_CONFIG.coordinate_fraction_bits)

    @property
    def y_m(self) -> float:
        return decode_signed(self.y_raw, DEFAULT_CONFIG.coordinate_fraction_bits)


@dataclass(frozen=True)
class FixedHalfPlane:
    """Q2.30系数和具有46个小数位的常数项。"""

    a_raw: int
    b_raw: int
    c_raw: int

    def evaluate(self, point: FixedPoint) -> int:
        return self.a_raw * point.x_raw + self.b_raw * point.y_raw - self.c_raw


@dataclass(frozen=True)
class IntersectionResult:
    point: FixedPoint | None
    parallel: bool
    saturated: bool
    residual_raw: int | None


@dataclass(frozen=True)
class ClipResult:
    vertices: tuple[FixedPoint, ...]
    parallel_edge: bool
    arithmetic_saturated: bool
    capacity_overflow: bool
    quantization_margin_used: bool

    @property
    def trusted(self) -> bool:
        return not (self.parallel_edge or self.arithmetic_saturated or self.capacity_overflow)


@dataclass(frozen=True)
class FixedLocalizationResult:
    vertices: tuple[FixedPoint, ...]
    diameter_squared_raw: int
    farthest_indices: tuple[int, int]
    trusted: bool
    parallel_edge: bool
    arithmetic_saturated: bool
    capacity_overflow: bool
    quantization_margin_used: bool

    @property
    def diameter_squared_m2(self) -> float:
        return self.diameter_squared_raw / float(1 << (2 * DEFAULT_CONFIG.coordinate_fraction_bits))


def _outward_coordinate(value_m: float, config: FixedConfig) -> int:
    scaled = value_m * (1 << config.coordinate_fraction_bits)
    if scaled > 0.0:
        raw = math.ceil(scaled)
    elif scaled < 0.0:
        raw = math.floor(scaled)
    else:
        raw = 0
    saturated, overflow = saturate_signed(raw, config.coordinate_bits)
    if overflow:
        raise OverflowError("初始多边形坐标超出Q16.16范围")
    return saturated


def regular_circumscribed_polygon_fixed(config: FixedConfig = DEFAULT_CONFIG) -> list[FixedPoint]:
    """生成720边初始多边形，并对每个坐标分量向外量化。"""

    half_sector = math.pi / config.polygon_side_count
    vertex_radius = config.radius_m / math.cos(half_sector)
    vertices: list[FixedPoint] = []
    for index in range(config.polygon_side_count):
        angle = (index + 0.5) * 2.0 * math.pi / config.polygon_side_count
        vertices.append(
            FixedPoint(
                _outward_coordinate(vertex_radius * math.cos(angle), config),
                _outward_coordinate(vertex_radius * math.sin(angle), config),
            )
        )
    return vertices


def bearing_halfplanes_fixed(
    sensor: FixedPoint,
    bearing_phase_raw: int,
    config: FixedConfig = DEFAULT_CONFIG,
) -> tuple[FixedHalfPlane, FixedHalfPlane]:
    """使用位精确CORDIC生成一次观测的两个半平面。"""

    full_turn = 1 << config.phase_bits
    delta_phase = degrees_to_phase(config.bearing_delta_deg, config)
    lower_phase = (bearing_phase_raw - delta_phase) % full_turn
    upper_phase = (bearing_phase_raw + delta_phase) % full_turn
    lower = cordic_sincos(lower_phase, config)
    upper = cordic_sincos(upper_phase, config)
    lower_a = -lower.sine_raw
    lower_b = lower.cosine_raw
    upper_a = upper.sine_raw
    upper_b = -upper.cosine_raw
    return (
        FixedHalfPlane(
            lower_a,
            lower_b,
            lower_a * sensor.x_raw + lower_b * sensor.y_raw,
        ),
        FixedHalfPlane(
            upper_a,
            upper_b,
            upper_a * sensor.x_raw + upper_b * sensor.y_raw,
        ),
    )


def segment_intersection_fixed(
    start: FixedPoint,
    end: FixedPoint,
    start_value: int,
    end_value: int,
    plane: FixedHalfPlane,
    config: FixedConfig = DEFAULT_CONFIG,
) -> IntersectionResult:
    """计算裁剪边与边界的Q16.16交点。"""

    denominator = start_value - end_value
    if abs(denominator) <= config.eps_denominator_raw:
        return IntersectionResult(None, True, False, None)
    ratio_raw = rounded_divide(start_value << config.ratio_fraction_bits, denominator)
    ratio_raw = min(1 << config.ratio_fraction_bits, max(0, ratio_raw))
    x_raw = start.x_raw + round_shift(
        ratio_raw * (end.x_raw - start.x_raw),
        config.ratio_fraction_bits,
    )
    y_raw = start.y_raw + round_shift(
        ratio_raw * (end.y_raw - start.y_raw),
        config.ratio_fraction_bits,
    )
    x_raw, x_saturated = saturate_signed(x_raw, config.coordinate_bits)
    y_raw, y_saturated = saturate_signed(y_raw, config.coordinate_bits)
    point = FixedPoint(x_raw, y_raw)
    return IntersectionResult(
        point=point,
        parallel=False,
        saturated=x_saturated or y_saturated,
        residual_raw=plane.evaluate(point),
    )


def _deduplicate(vertices: Iterable[FixedPoint]) -> list[FixedPoint]:
    output: list[FixedPoint] = []
    for point in vertices:
        if not output or point != output[-1]:
            output.append(point)
    if len(output) > 1 and output[0] == output[-1]:
        output.pop()
    return output


def clip_halfplane_fixed(
    vertices: Sequence[FixedPoint],
    plane: FixedHalfPlane,
    config: FixedConfig = DEFAULT_CONFIG,
) -> ClipResult:
    """执行一次位精确半平面裁剪并汇总数值状态。"""

    if not vertices:
        return ClipResult((), False, False, False, False)
    output: list[FixedPoint] = []
    parallel_edge = False
    arithmetic_saturated = False
    quantization_margin_used = False

    for index, start in enumerate(vertices):
        end = vertices[(index + 1) % len(vertices)]
        start_value = plane.evaluate(start)
        end_value = plane.evaluate(end)
        start_inside = start_value >= -config.eps_halfplane_raw
        end_inside = end_value >= -config.eps_halfplane_raw
        if start_inside and start_value < 0:
            quantization_margin_used = True
        if end_inside and end_value < 0:
            quantization_margin_used = True

        if start_inside and end_inside:
            output.append(end)
            continue
        if start_inside == end_inside:
            continue

        intersection = segment_intersection_fixed(
            start,
            end,
            start_value,
            end_value,
            plane,
            config,
        )
        parallel_edge = parallel_edge or intersection.parallel
        arithmetic_saturated = arithmetic_saturated or intersection.saturated
        if intersection.point is None:
            # 近并行跨界时保留内侧端点，同时将结果标记为不可信。
            output.append(start if start_inside else end)
        elif start_inside:
            output.append(intersection.point)
            if intersection.residual_raw is not None and intersection.residual_raw < 0:
                quantization_margin_used = True
        else:
            output.append(intersection.point)
            output.append(end)
            if intersection.residual_raw is not None and intersection.residual_raw < 0:
                quantization_margin_used = True

        if len(output) > config.maximum_vertex_count:
            return ClipResult(
                tuple(output[: config.maximum_vertex_count]),
                parallel_edge,
                arithmetic_saturated,
                True,
                quantization_margin_used,
            )

    cleaned = _deduplicate(output)
    capacity_overflow = len(cleaned) > config.maximum_vertex_count
    return ClipResult(
        tuple(cleaned[: config.maximum_vertex_count]),
        parallel_edge,
        arithmetic_saturated,
        capacity_overflow,
        quantization_margin_used,
    )


def diameter_squared_fixed(
    vertices: Sequence[FixedPoint],
    config: FixedConfig = DEFAULT_CONFIG,
) -> tuple[int, tuple[int, int], bool]:
    """穷举顶点对，距离平方具有32个小数位。"""

    if len(vertices) <= 1:
        return 0, (0, 0), False
    maximum = -1
    indices = (0, 1)
    overflow = False
    maximum_value = (1 << config.distance_squared_bits) - 1
    for first in range(len(vertices)):
        for second in range(first + 1, len(vertices)):
            dx = vertices[first].x_raw - vertices[second].x_raw
            dy = vertices[first].y_raw - vertices[second].y_raw
            candidate = dx * dx + dy * dy
            if candidate > maximum_value:
                candidate = maximum_value
                overflow = True
            if candidate > maximum:
                maximum = candidate
                indices = (first, second)
    return maximum, indices, overflow


def localize_fixed(
    observations: Sequence[tuple[float, float, float]],
    config: FixedConfig = DEFAULT_CONFIG,
) -> FixedLocalizationResult:
    """执行阶段1位精确定位流程。"""

    current = tuple(regular_circumscribed_polygon_fixed(config))
    parallel_edge = False
    arithmetic_saturated = False
    capacity_overflow = False
    quantization_margin_used = False
    for sensor_x, sensor_y, bearing_deg in observations:
        sensor = FixedPoint.from_metres(sensor_x, sensor_y, config)
        bearing_phase = degrees_to_phase(bearing_deg, config)
        for plane in bearing_halfplanes_fixed(sensor, bearing_phase, config):
            clipped = clip_halfplane_fixed(current, plane, config)
            current = clipped.vertices
            parallel_edge = parallel_edge or clipped.parallel_edge
            arithmetic_saturated = arithmetic_saturated or clipped.arithmetic_saturated
            capacity_overflow = capacity_overflow or clipped.capacity_overflow
            quantization_margin_used = quantization_margin_used or clipped.quantization_margin_used
            if not current:
                return FixedLocalizationResult(
                    (), 0, (0, 0),
                    not (parallel_edge or arithmetic_saturated or capacity_overflow),
                    parallel_edge, arithmetic_saturated, capacity_overflow,
                    quantization_margin_used,
                )
    maximum, indices, distance_overflow = diameter_squared_fixed(current, config)
    arithmetic_saturated = arithmetic_saturated or distance_overflow
    return FixedLocalizationResult(
        current,
        maximum,
        indices,
        not (parallel_edge or arithmetic_saturated or capacity_overflow),
        parallel_edge,
        arithmetic_saturated,
        capacity_overflow,
        quantization_margin_used,
    )
