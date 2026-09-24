"""阶段1定位算法的双精度参考实现。

该实现只覆盖FPGA阶段1的功能边界：1800 m外接正多边形、示向角锥
半平面裁剪和顶点对穷举直径。不包含接收距离圆、最小包围圆或主动规划。
"""

from __future__ import annotations

from dataclasses import dataclass
import math
from typing import Iterable, Sequence


@dataclass(frozen=True)
class FloatPoint:
    """以米为单位的二维点。"""

    x: float
    y: float


@dataclass(frozen=True)
class FloatHalfPlane:
    """半平面 ``a*x + b*y - c >= 0``。"""

    a: float
    b: float
    c: float

    def evaluate(self, point: FloatPoint) -> float:
        return self.a * point.x + self.b * point.y - self.c


@dataclass(frozen=True)
class FloatLocalizationResult:
    """双精度定位结果。"""

    vertices: tuple[FloatPoint, ...]
    diameter_squared: float
    farthest_indices: tuple[int, int]


def regular_circumscribed_polygon(
    radius_m: float = 1800.0,
    side_count: int = 720,
) -> list[FloatPoint]:
    """生成以原点为圆心的外接正多边形，顶点按逆时针排列。"""

    if side_count < 3:
        raise ValueError("side_count必须不小于3")
    half_sector = math.pi / side_count
    vertex_radius = radius_m / math.cos(half_sector)
    return [
        FloatPoint(
            vertex_radius * math.cos((index + 0.5) * 2.0 * math.pi / side_count),
            vertex_radius * math.sin((index + 0.5) * 2.0 * math.pi / side_count),
        )
        for index in range(side_count)
    ]


def bearing_halfplanes(
    sensor: FloatPoint,
    bearing_deg: float,
    delta_deg: float = 1.005,
) -> tuple[FloatHalfPlane, FloatHalfPlane]:
    """将一次示向观测转换为下、上边界两个半平面。"""

    lower = math.radians(bearing_deg - delta_deg)
    upper = math.radians(bearing_deg + delta_deg)
    lower_a = -math.sin(lower)
    lower_b = math.cos(lower)
    upper_a = math.sin(upper)
    upper_b = -math.cos(upper)
    return (
        FloatHalfPlane(lower_a, lower_b, lower_a * sensor.x + lower_b * sensor.y),
        FloatHalfPlane(upper_a, upper_b, upper_a * sensor.x + upper_b * sensor.y),
    )


def _intersection(
    start: FloatPoint,
    end: FloatPoint,
    start_value: float,
    end_value: float,
) -> FloatPoint:
    denominator = start_value - end_value
    if denominator == 0.0:
        raise ZeroDivisionError("非退化裁剪边出现零分母")
    ratio = min(1.0, max(0.0, start_value / denominator))
    return FloatPoint(
        start.x + ratio * (end.x - start.x),
        start.y + ratio * (end.y - start.y),
    )


def _deduplicate(vertices: Iterable[FloatPoint], tolerance: float = 1.0e-10) -> list[FloatPoint]:
    result: list[FloatPoint] = []
    for point in vertices:
        if not result or math.hypot(point.x - result[-1].x, point.y - result[-1].y) > tolerance:
            result.append(point)
    if len(result) > 1 and math.hypot(
        result[0].x - result[-1].x,
        result[0].y - result[-1].y,
    ) <= tolerance:
        result.pop()
    return result


def clip_halfplane(
    vertices: Sequence[FloatPoint],
    plane: FloatHalfPlane,
    tolerance: float = 1.0e-9,
) -> list[FloatPoint]:
    """使用Sutherland-Hodgman规则进行一次半平面裁剪。"""

    if not vertices:
        return []
    output: list[FloatPoint] = []
    for index, start in enumerate(vertices):
        end = vertices[(index + 1) % len(vertices)]
        start_value = plane.evaluate(start)
        end_value = plane.evaluate(end)
        start_inside = start_value >= -tolerance
        end_inside = end_value >= -tolerance
        if start_inside and end_inside:
            output.append(end)
        elif start_inside and not end_inside:
            output.append(_intersection(start, end, start_value, end_value))
        elif not start_inside and end_inside:
            output.append(_intersection(start, end, start_value, end_value))
            output.append(end)
    return _deduplicate(output)


def diameter_squared(vertices: Sequence[FloatPoint]) -> tuple[float, tuple[int, int]]:
    """穷举全部顶点对并返回最大距离平方及顶点索引。"""

    if len(vertices) <= 1:
        return 0.0, (0, 0)
    maximum = -1.0
    indices = (0, 1)
    for first in range(len(vertices)):
        for second in range(first + 1, len(vertices)):
            dx = vertices[first].x - vertices[second].x
            dy = vertices[first].y - vertices[second].y
            candidate = dx * dx + dy * dy
            if candidate > maximum:
                maximum = candidate
                indices = (first, second)
    return maximum, indices


def localize_float(
    observations: Sequence[tuple[float, float, float]],
    radius_m: float = 1800.0,
    delta_deg: float = 1.005,
    side_count: int = 720,
) -> FloatLocalizationResult:
    """执行阶段1双精度定位流程。观测元素为 ``(x_m, y_m, bearing_deg)``。"""

    current = regular_circumscribed_polygon(radius_m, side_count)
    for sensor_x, sensor_y, bearing_deg in observations:
        planes = bearing_halfplanes(FloatPoint(sensor_x, sensor_y), bearing_deg, delta_deg)
        for plane in planes:
            current = clip_halfplane(current, plane)
            if not current:
                return FloatLocalizationResult((), 0.0, (0, 0))
    maximum, indices = diameter_squared(current)
    return FloatLocalizationResult(tuple(current), maximum, indices)
