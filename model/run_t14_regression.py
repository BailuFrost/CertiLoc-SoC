"""T14随机、边界和RTL联合回归向量生成器。"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
import math
from pathlib import Path
import random
import statistics
import sys
from typing import Iterable, Sequence

PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from fpga_stage1.model.fixed_point_reference.config import DEFAULT_CONFIG
from fpga_stage1.model.fixed_point_reference.cordic import degrees_to_phase
from fpga_stage1.model.fixed_point_reference.geometry import (
    FixedLocalizationResult,
    FixedPoint,
    bearing_halfplanes_fixed,
    clip_halfplane_fixed,
    diameter_squared_fixed,
    regular_circumscribed_polygon_fixed,
)
from fpga_stage1.model.floating_reference.geometry import localize_float


DEFAULT_SEED = 0x14_15_B301
DEFAULT_RANDOM_CASES = 1000
RTL_CASE_LIMIT = 24
# 每次交点回写最多引入约1个坐标LSB；T14以2个LSB作为连续裁剪的
# 可追溯包含性容差，同时仍由结果flags[0]报告量化裕量已经参与判定。
CONTAINMENT_TOLERANCE_RAW = 2 * DEFAULT_CONFIG.eps_halfplane_raw


@dataclass(frozen=True)
class RegressionCase:
    """一组带可选真源的阶段1观测。"""

    name: str
    category: str
    observations: tuple[tuple[float, float, float], ...]
    source: tuple[float, float] | None


@dataclass(frozen=True)
class EvaluatedCase:
    """软件回归结果及可导出到RTL的原始观测。"""

    case: RegressionCase
    observations_raw: tuple[tuple[int, int, int], ...]
    fixed: FixedLocalizationResult
    float_vertex_count: int
    float_diameter_squared: float
    diameter_error_m2: float
    vertex_hausdorff_m: float
    true_source_contained: bool | None
    invariant_failures: tuple[str, ...]


def _bearing(sensor_x: float, sensor_y: float, source_x: float, source_y: float) -> float:
    return math.degrees(math.atan2(source_y - sensor_y, source_x - sensor_x)) % 360.0


def _make_consistent_case(
    rng: random.Random,
    index: int,
    observation_count: int,
    category: str = "random_consistent",
) -> RegressionCase:
    source_radius = rng.uniform(0.0, 1500.0)
    source_angle = rng.uniform(0.0, 2.0 * math.pi)
    source_x = source_radius * math.cos(source_angle)
    source_y = source_radius * math.sin(source_angle)
    observations: list[tuple[float, float, float]] = []
    base_angle = rng.uniform(0.0, 2.0 * math.pi)
    for sensor_index in range(observation_count):
        sensor_angle = base_angle + 2.0 * math.pi * sensor_index / observation_count
        sensor_angle += rng.uniform(-0.12, 0.12)
        sensor_radius = rng.uniform(900.0, 1700.0)
        sensor_x = sensor_radius * math.cos(sensor_angle)
        sensor_y = sensor_radius * math.sin(sensor_angle)
        ideal_bearing = _bearing(sensor_x, sensor_y, source_x, source_y)
        noisy_bearing = (ideal_bearing + rng.uniform(-0.72, 0.72)) % 360.0
        observations.append((sensor_x, sensor_y, noisy_bearing))
    return RegressionCase(
        name=f"{category}_{index:04d}",
        category=category,
        observations=tuple(observations),
        source=(source_x, source_y),
    )


def _boundary_cases(rng: random.Random) -> list[RegressionCase]:
    circle_source = (1790.0, 0.0)
    circle_sensors = ((-1700.0, 0.0), (0.0, -1700.0), (1700.0, 500.0))
    cases = [
        RegressionCase(
            "cross_zero",
            "phase_boundary",
            ((-1000.0, -10.0, 359.5), (-1000.0, 10.0, 0.5)),
            (1000.0, 0.0),
        ),
        RegressionCase(
            "opposing_empty",
            "empty_region",
            ((-1000.0, 0.0, 180.0), (1000.0, 0.0, 0.0)),
            None,
        ),
        RegressionCase(
            "negative_coordinates",
            "coordinate_boundary",
            ((-1700.0, -1600.0, 45.0), (1700.0, -1600.0, 135.0)),
            (0.0, 100.0),
        ),
        RegressionCase(
            "circle_boundary",
            "coordinate_boundary",
            tuple(
                (sensor_x, sensor_y, _bearing(sensor_x, sensor_y, *circle_source))
                for sensor_x, sensor_y in circle_sensors
            ),
            circle_source,
        ),
    ]
    cases.append(_make_consistent_case(rng, 0, 20, "maximum_observations"))
    source = (120.0, -75.0)
    near_parallel: list[tuple[float, float, float]] = []
    for sensor_x in (-1500.0, -500.0, 500.0, 1500.0):
        sensor_y = 1300.0 + sensor_x * 0.001
        near_parallel.append((sensor_x, sensor_y, _bearing(sensor_x, sensor_y, *source)))
    cases.append(
        RegressionCase(
            "near_parallel_bearings",
            "near_parallel",
            tuple(near_parallel),
            source,
        )
    )
    return cases


def build_cases(seed: int, random_count: int) -> list[RegressionCase]:
    rng = random.Random(seed)
    cases = _boundary_cases(rng)
    for index in range(random_count):
        observation_count = rng.randint(2, 20)
        cases.append(_make_consistent_case(rng, index, observation_count))
    return cases


def _quantize_observations(
    observations: Sequence[tuple[float, float, float]],
) -> tuple[tuple[int, int, int], ...]:
    result: list[tuple[int, int, int]] = []
    for sensor_x, sensor_y, bearing_deg in observations:
        sensor = FixedPoint.from_metres(sensor_x, sensor_y)
        result.append((sensor.x_raw, sensor.y_raw, degrees_to_phase(bearing_deg)))
    return tuple(result)


def _localize_raw(
    observations_raw: Sequence[tuple[int, int, int]],
) -> tuple[FixedLocalizationResult, tuple[str, ...]]:
    current = tuple(regular_circumscribed_polygon_fixed())
    parallel_edge = False
    arithmetic_saturated = False
    capacity_overflow = False
    quantization_margin_used = False
    applied_planes = []
    invariant_failures: list[str] = []
    for observation_index, (sensor_x, sensor_y, phase) in enumerate(observations_raw):
        sensor = FixedPoint(sensor_x, sensor_y)
        for plane_index, plane in enumerate(bearing_halfplanes_fixed(sensor, phase)):
            clipped = clip_halfplane_fixed(current, plane)
            current = clipped.vertices
            applied_planes.append(plane)
            parallel_edge = parallel_edge or clipped.parallel_edge
            arithmetic_saturated = arithmetic_saturated or clipped.arithmetic_saturated
            capacity_overflow = capacity_overflow or clipped.capacity_overflow
            quantization_margin_used = quantization_margin_used or clipped.quantization_margin_used
            if len(current) > DEFAULT_CONFIG.maximum_vertex_count:
                invariant_failures.append(f"obs{observation_index}.plane{plane_index}:capacity")
            for vertex in current:
                if any(previous.evaluate(vertex) < -CONTAINMENT_TOLERANCE_RAW for previous in applied_planes):
                    invariant_failures.append(f"obs{observation_index}.plane{plane_index}:halfplane")
                    break
            if not current:
                break
        if not current:
            break
    maximum, indices, distance_overflow = diameter_squared_fixed(current)
    arithmetic_saturated = arithmetic_saturated or distance_overflow
    fixed = FixedLocalizationResult(
        current,
        maximum,
        indices,
        not (parallel_edge or arithmetic_saturated or capacity_overflow),
        parallel_edge,
        arithmetic_saturated,
        capacity_overflow,
        quantization_margin_used,
    )
    return fixed, tuple(invariant_failures)


def _hausdorff_distance_m(fixed_vertices: Sequence[FixedPoint], float_vertices: Sequence[object]) -> float:
    if not fixed_vertices and not float_vertices:
        return 0.0
    if not fixed_vertices or not float_vertices:
        return math.inf
    fixed_points = [(point.x_m, point.y_m) for point in fixed_vertices]
    float_points = [(float(point.x), float(point.y)) for point in float_vertices]

    def directed(first: Iterable[tuple[float, float]], second: Sequence[tuple[float, float]]) -> float:
        return max(
            min(math.hypot(x_value - other_x, y_value - other_y) for other_x, other_y in second)
            for x_value, y_value in first
        )

    return max(directed(fixed_points, float_points), directed(float_points, fixed_points))


def evaluate_case(case: RegressionCase) -> EvaluatedCase:
    observations_raw = _quantize_observations(case.observations)
    fixed, invariant_failures = _localize_raw(observations_raw)
    quantized_observations = tuple(
        (x_raw / 65536.0, y_raw / 65536.0, phase * 360.0 / (1 << 18))
        for x_raw, y_raw, phase in observations_raw
    )
    floating = localize_float(quantized_observations)
    source_contained: bool | None = None
    if case.source is not None:
        source = FixedPoint.from_metres(*case.source)
        source_contained = all(
            plane.evaluate(source) >= -DEFAULT_CONFIG.eps_halfplane_raw
            for sensor_x, sensor_y, phase in observations_raw
            for plane in bearing_halfplanes_fixed(FixedPoint(sensor_x, sensor_y), phase)
        )
    return EvaluatedCase(
        case=case,
        observations_raw=observations_raw,
        fixed=fixed,
        float_vertex_count=len(floating.vertices),
        float_diameter_squared=floating.diameter_squared,
        diameter_error_m2=abs(fixed.diameter_squared_m2 - floating.diameter_squared),
        vertex_hausdorff_m=_hausdorff_distance_m(fixed.vertices, floating.vertices),
        true_source_contained=source_contained,
        invariant_failures=invariant_failures,
    )


def _result_flags(result: FixedLocalizationResult) -> int:
    flags = 1 << 6
    if result.quantization_margin_used:
        flags |= 1 << 0
    if result.parallel_edge:
        flags |= 1 << 1
    if result.arithmetic_saturated:
        flags |= 1 << 2
    if result.capacity_overflow:
        flags |= 1 << 3
    return flags


def _region_type(vertex_count: int, trusted: bool) -> int:
    if not trusted:
        return 0xFF
    if vertex_count == 0:
        return 0x00
    if vertex_count == 1:
        return 0x01
    if vertex_count == 2:
        return 0x02
    return 0x03


def write_rtl_vectors(evaluated: Sequence[EvaluatedCase], vector_dir: Path) -> int:
    vector_dir.mkdir(parents=True, exist_ok=True)
    selected = list(evaluated[:RTL_CASE_LIMIT])
    observation_offset = 0
    vertex_offset = 0
    metadata_lines: list[str] = []
    observation_lines: list[str] = []
    vertex_lines: list[str] = []
    manifest: list[dict[str, object]] = []
    for case_index, item in enumerate(selected):
        fixed = item.fixed
        flags = _result_flags(fixed)
        region = _region_type(len(fixed.vertices), fixed.trusted)
        # 256位布局：obs_offset[15:0], obs_count[4:0], vertex_offset[15:0],
        # vertex_count[10:0], distance[65:0], trusted, region[7:0], flags[7:0]。
        packed = observation_offset
        packed |= len(item.observations_raw) << 16
        packed |= vertex_offset << 21
        packed |= len(fixed.vertices) << 37
        packed |= fixed.diameter_squared_raw << 48
        packed |= int(fixed.trusted) << 114
        packed |= region << 115
        packed |= flags << 123
        metadata_lines.append(f"{packed:064x}")
        for x_raw, y_raw, phase in item.observations_raw:
            observation_lines.append(f"{phase & 0x3ffff:08x}{y_raw & 0xffffffff:08x}{x_raw & 0xffffffff:08x}")
        for vertex in fixed.vertices:
            vertex_lines.append(f"{vertex.x_raw & 0xffffffff:08x}{vertex.y_raw & 0xffffffff:08x}")
        manifest.append(
            {
                "index": case_index,
                "name": item.case.name,
                "category": item.case.category,
                "observation_count": len(item.observations_raw),
                "vertex_count": len(fixed.vertices),
                "trusted": fixed.trusted,
                "region_type": region,
                "distance_squared_raw": fixed.diameter_squared_raw,
                "error_flags": flags,
            }
        )
        observation_offset += len(item.observations_raw)
        vertex_offset += len(fixed.vertices)
    (vector_dir / "t14_case_meta.mem").write_text("\n".join(metadata_lines) + "\n", encoding="ascii")
    (vector_dir / "t14_observations.mem").write_text("\n".join(observation_lines) + "\n", encoding="ascii")
    (vector_dir / "t14_expected_vertices.mem").write_text("\n".join(vertex_lines) + "\n", encoding="ascii")
    (vector_dir / "t14_regression_manifest.json").write_text(
        json.dumps({"case_count": len(selected), "cases": manifest}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return len(selected)


def _finite_values(values: Iterable[float]) -> list[float]:
    return [value for value in values if math.isfinite(value)]


def write_reports(evaluated: Sequence[EvaluatedCase], seed: int, output_dir: Path) -> dict[str, object]:
    output_dir.mkdir(parents=True, exist_ok=True)
    diameter_errors = _finite_values(item.diameter_error_m2 for item in evaluated)
    vertex_errors = _finite_values(item.vertex_hausdorff_m for item in evaluated)
    invariant_failures = [item.case.name for item in evaluated if item.invariant_failures]
    containment_failures = [item.case.name for item in evaluated if item.true_source_contained is False]
    empty_mismatch = [
        item.case.name
        for item in evaluated
        if (len(item.fixed.vertices) == 0) != (item.float_vertex_count == 0)
    ]
    summary: dict[str, object] = {
        "seed": seed,
        "case_count": len(evaluated),
        "category_counts": {
            category: sum(item.case.category == category for item in evaluated)
            for category in sorted({item.case.category for item in evaluated})
        },
        "maximum_observation_count": max(len(item.observations_raw) for item in evaluated),
        "maximum_fixed_vertex_count": max(len(item.fixed.vertices) for item in evaluated),
        "untrusted_case_count": sum(not item.fixed.trusted for item in evaluated),
        "quantization_margin_case_count": sum(item.fixed.quantization_margin_used for item in evaluated),
        "invariant_failures": invariant_failures,
        "true_source_containment_failures": containment_failures,
        "empty_classification_mismatches": empty_mismatch,
        "diameter_error_m2": {
            "maximum": max(diameter_errors, default=0.0),
            "mean": statistics.fmean(diameter_errors) if diameter_errors else 0.0,
            "p95": sorted(diameter_errors)[int(0.95 * (len(diameter_errors) - 1))] if diameter_errors else 0.0,
        },
        "vertex_hausdorff_m": {
            "maximum": max(vertex_errors, default=0.0),
            "mean": statistics.fmean(vertex_errors) if vertex_errors else 0.0,
            "p95": sorted(vertex_errors)[int(0.95 * (len(vertex_errors) - 1))] if vertex_errors else 0.0,
        },
        "pass": not invariant_failures and not containment_failures,
    }
    (output_dir / "t14_software_regression.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    markdown = f"""# T14软件随机与边界回归报告

## 结论

固定随机种子为`0x{seed:x}`，共执行{len(evaluated)}组位精确定点/双精度对照；软件不变量与真源包含性总结果为**{'PASS' if summary['pass'] else 'FAIL'}**。

## 覆盖与结果

| 指标 | 结果 |
|---|---:|
| 用例总数 | {len(evaluated)} |
| 最大观测数 | {summary['maximum_observation_count']} |
| 最大定点顶点数 | {summary['maximum_fixed_vertex_count']} |
| 不可信结果数 | {summary['untrusted_case_count']} |
| 使用量化裕量的用例数 | {summary['quantization_margin_case_count']} |
| 半平面/容量不变量失败 | {len(invariant_failures)} |
| 带真值用例的包含性失败 | {len(containment_failures)} |
| 浮点/定点空域分类差异 | {len(empty_mismatch)} |
| 直径平方误差最大值（m²） | {summary['diameter_error_m2']['maximum']:.9f} |
| 顶点Hausdorff误差最大值（m） | {summary['vertex_hausdorff_m']['maximum']:.9f} |

边界集合固定包含跨0°相位、互斥空域、负坐标、目标圆边界、20条最大观测和近乎平行观测；其余为2至20条观测的可重复随机真源场景。

## 判定范围

本报告是Python双精度与位精确定点模型证据。RTL逐位结果、随机协议帧、分页边界和连续1000任务由XSim报告单独给出，软件PASS不替代RTL仿真或板级证据。
"""
    (output_dir / "t14_software_regression.md").write_text(markdown, encoding="utf-8")
    return summary


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seed", type=lambda value: int(value, 0), default=DEFAULT_SEED)
    parser.add_argument("--random-cases", type=int, default=DEFAULT_RANDOM_CASES)
    parser.add_argument(
        "--vector-dir",
        type=Path,
        default=PROJECT_ROOT / "fpga_stage1" / "tb" / "vectors",
    )
    parser.add_argument(
        "--report-dir",
        type=Path,
        default=PROJECT_ROOT / "fpga_stage1" / "reports",
    )
    arguments = parser.parse_args()
    if arguments.random_cases < 1:
        parser.error("--random-cases必须为正数")
    cases = build_cases(arguments.seed, arguments.random_cases)
    evaluated = [evaluate_case(case) for case in cases]
    rtl_case_count = write_rtl_vectors(evaluated, arguments.vector_dir)
    summary = write_reports(evaluated, arguments.seed, arguments.report_dir)
    print(
        f"T14 software regression: {'PASS' if summary['pass'] else 'FAIL'}; "
        f"cases={len(evaluated)} rtl_cases={rtl_case_count}"
    )
    return 0 if summary["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
