"""生成T02黄金向量、初始多边形ROM和数值误差报告。"""

from __future__ import annotations

import csv
import json
import math
from pathlib import Path
import random
import sys

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from fpga_stage1.model.floating_reference.geometry import localize_float
from fpga_stage1.model.fixed_point_reference.config import DEFAULT_CONFIG
from fpga_stage1.model.fixed_point_reference.cordic import (
    atan_table,
    cordic_sincos,
    degrees_to_phase,
    inverse_gain_raw,
    phase_to_degrees,
)
from fpga_stage1.model.fixed_point_reference.fixed_math import unsigned_hex
from fpga_stage1.model.fixed_point_reference.geometry import (
    FixedPoint,
    bearing_halfplanes_fixed,
    localize_fixed,
    regular_circumscribed_polygon_fixed,
    segment_intersection_fixed,
)


ROOT = Path(__file__).resolve().parents[1]
VECTOR_DIR = ROOT / "tb" / "vectors"
REPORT_DIR = ROOT / "reports"
RANDOM_SEED = 20260919


def _cordic_scan() -> dict[str, float | int]:
    config = DEFAULT_CONFIG
    full_turn = 1 << config.phase_bits
    maximum_sine_error = 0.0
    maximum_cosine_error = 0.0
    maximum_vector_norm_error = 0.0
    maximum_residual = 0
    saturation_count = 0
    for phase in range(full_turn):
        result = cordic_sincos(phase, config)
        angle = 2.0 * math.pi * phase / full_turn
        sine_error = abs(result.sine - math.sin(angle))
        cosine_error = abs(result.cosine - math.cos(angle))
        norm_error = abs(math.hypot(result.sine, result.cosine) - 1.0)
        maximum_sine_error = max(maximum_sine_error, sine_error)
        maximum_cosine_error = max(maximum_cosine_error, cosine_error)
        maximum_vector_norm_error = max(maximum_vector_norm_error, norm_error)
        maximum_residual = max(maximum_residual, abs(result.residual_phase_raw))
        saturation_count += int(result.saturated)
    return {
        "phase_count": full_turn,
        "maximum_sine_error": maximum_sine_error,
        "maximum_cosine_error": maximum_cosine_error,
        "maximum_vector_norm_error": maximum_vector_norm_error,
        "maximum_residual_phase_lsb": maximum_residual,
        "saturation_count": saturation_count,
    }


def _write_cordic_vectors() -> int:
    config = DEFAULT_CONFIG
    rng = random.Random(RANDOM_SEED)
    phases = {
        0,
        1,
        (1 << config.phase_bits) // 4 - 1,
        (1 << config.phase_bits) // 4,
        (1 << config.phase_bits) // 4 + 1,
        (1 << config.phase_bits) // 2,
        3 * (1 << config.phase_bits) // 4,
        (1 << config.phase_bits) - 1,
        degrees_to_phase(1.005),
        degrees_to_phase(359.0),
    }
    phases.update(rng.randrange(1 << config.phase_bits) for _ in range(64))
    path = VECTOR_DIR / "cordic_q2_30_vectors.csv"
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.writer(stream)
        writer.writerow(
            [
                "phase_u18",
                "angle_deg",
                "sin_q2_30",
                "cos_q2_30",
                "sin_hex",
                "cos_hex",
                "residual_phase_lsb",
            ]
        )
        for phase in sorted(phases):
            result = cordic_sincos(phase, config)
            writer.writerow(
                [
                    phase,
                    f"{phase_to_degrees(phase, config):.12f}",
                    result.sine_raw,
                    result.cosine_raw,
                    unsigned_hex(result.sine_raw, 32),
                    unsigned_hex(result.cosine_raw, 32),
                    result.residual_phase_raw,
                ]
            )
    return len(phases)


def _write_cordic_constants() -> None:
    config = DEFAULT_CONFIG
    constants = {
        "input_phase_bits": config.phase_bits,
        "internal_phase_bits": config.cordic_phase_bits,
        "iterations": config.cordic_iterations,
        "xy_bits": config.cordic_internal_bits,
        "xy_fraction_bits": config.cordic_internal_fraction_bits,
        "output_bits": config.trigonometric_bits,
        "output_fraction_bits": config.trigonometric_fraction_bits,
        "inverse_gain_raw": inverse_gain_raw(config),
        "inverse_gain_hex_36bit": unsigned_hex(inverse_gain_raw(config), 36),
        "atan_table_internal_phase_raw": list(atan_table(config)),
        "atan_table_hex_32bit": [
            unsigned_hex(value, config.cordic_phase_bits)
            for value in atan_table(config)
        ],
    }
    path = VECTOR_DIR / "cordic_constants.json"
    path.write_text(json.dumps(constants, ensure_ascii=False, indent=2), encoding="utf-8")


def _write_polygon_rom() -> dict[str, float | int]:
    config = DEFAULT_CONFIG
    vertices = regular_circumscribed_polygon_fixed(config)
    path = VECTOR_DIR / "initial_polygon_720_q16_16.mem"
    with path.open("w", encoding="ascii", newline="\n") as stream:
        for point in vertices:
            stream.write(
                unsigned_hex(point.x_raw, 32)
                + unsigned_hex(point.y_raw, 32)
                + "\n"
            )
    radii = [math.hypot(point.x_m, point.y_m) for point in vertices]
    theoretical = config.radius_m / math.cos(math.pi / config.polygon_side_count)
    return {
        "vertex_count": len(vertices),
        "minimum_vertex_radius_m": min(radii),
        "maximum_vertex_radius_m": max(radii),
        "theoretical_vertex_radius_m": theoretical,
        "maximum_vertex_radius_error_m": max(abs(radius - theoretical) for radius in radii),
    }


def _integration_cases() -> list[dict[str, object]]:
    source = (100.0, 50.0)
    sensors = [(-1000.0, 0.0), (1000.0, 0.0), (0.0, -1000.0), (0.0, 1000.0)]
    nominal = [
        (x_value, y_value, math.degrees(math.atan2(source[1] - y_value, source[0] - x_value)) % 360.0)
        for x_value, y_value in sensors
    ]
    return [
        {"name": "two_bearings", "observations": nominal[:2]},
        {"name": "four_bearings", "observations": nominal},
        {
            "name": "cross_zero",
            "observations": [(-1000.0, 20.0, 359.6), (-900.0, -20.0, 0.4)],
        },
        {
            "name": "incompatible",
            "observations": [(-1000.0, 0.0, 180.0), (1000.0, 0.0, 0.0)],
        },
    ]


def _write_geometry_vectors() -> list[dict[str, object]]:
    records: list[dict[str, object]] = []
    for case in _integration_cases():
        observations = case["observations"]
        floating = localize_float(observations)
        quantized_observations = [
            (x_value, y_value, phase_to_degrees(degrees_to_phase(bearing)))
            for x_value, y_value, bearing in observations
        ]
        quantized_delta_deg = phase_to_degrees(
            degrees_to_phase(DEFAULT_CONFIG.bearing_delta_deg)
        )
        floating_quantized = localize_float(
            quantized_observations,
            delta_deg=quantized_delta_deg,
        )
        fixed = localize_fixed(observations)
        float_diameter = math.sqrt(floating.diameter_squared)
        float_quantized_diameter = math.sqrt(floating_quantized.diameter_squared)
        fixed_diameter = math.sqrt(fixed.diameter_squared_m2)
        record = {
            "name": case["name"],
            "observations": observations,
            "float_vertex_count": len(floating.vertices),
            "fixed_vertex_count": len(fixed.vertices),
            "float_diameter_squared_m2": floating.diameter_squared,
            "float_quantized_phase_diameter_squared_m2": floating_quantized.diameter_squared,
            "fixed_diameter_squared_raw": fixed.diameter_squared_raw,
            "fixed_diameter_squared_m2": fixed.diameter_squared_m2,
            "diameter_squared_error_m2": abs(
                fixed.diameter_squared_m2 - floating.diameter_squared
            ),
            "diameter_error_m": abs(fixed_diameter - float_diameter),
            "quantized_path_diameter_error_m": abs(
                fixed_diameter - float_quantized_diameter
            ),
            "trusted": fixed.trusted,
            "parallel_edge": fixed.parallel_edge,
            "arithmetic_saturated": fixed.arithmetic_saturated,
            "capacity_overflow": fixed.capacity_overflow,
            "quantization_margin_used": fixed.quantization_margin_used,
            "vertices_q16_16": [
                {"x_raw": point.x_raw, "y_raw": point.y_raw}
                for point in fixed.vertices
            ],
        }
        records.append(record)
    path = VECTOR_DIR / "geometry_integration_vectors.json"
    path.write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")
    return records


def _intersection_residual_scan(sample_count: int = 20000) -> dict[str, int]:
    config = DEFAULT_CONFIG
    rng = random.Random(RANDOM_SEED)
    maximum_absolute_residual = 0
    accepted_negative_count = 0
    parallel_count = 0
    for _ in range(sample_count):
        sensor = FixedPoint.from_metres(rng.uniform(-1800.0, 1800.0), rng.uniform(-1800.0, 1800.0))
        phase = rng.randrange(1 << config.phase_bits)
        plane = bearing_halfplanes_fixed(sensor, phase, config)[0]
        start = FixedPoint.from_metres(rng.uniform(-1800.0, 1800.0), rng.uniform(-1800.0, 1800.0))
        end = FixedPoint.from_metres(rng.uniform(-1800.0, 1800.0), rng.uniform(-1800.0, 1800.0))
        start_value = plane.evaluate(start)
        end_value = plane.evaluate(end)
        if (start_value >= 0) == (end_value >= 0):
            continue
        result = segment_intersection_fixed(start, end, start_value, end_value, plane, config)
        if result.parallel:
            parallel_count += 1
            continue
        if result.residual_raw is not None:
            maximum_absolute_residual = max(maximum_absolute_residual, abs(result.residual_raw))
            accepted_negative_count += int(
                -config.eps_halfplane_raw <= result.residual_raw < 0
            )
    return {
        "sample_count": sample_count,
        "maximum_absolute_residual_raw": maximum_absolute_residual,
        "eps_halfplane_raw": config.eps_halfplane_raw,
        "eps_denominator_raw": config.eps_denominator_raw,
        "accepted_negative_residual_count": accepted_negative_count,
        "parallel_count": parallel_count,
    }


def _write_report(
    cordic: dict[str, float | int],
    polygon: dict[str, float | int],
    intersections: dict[str, int],
    geometry_records: list[dict[str, object]],
    cordic_vector_count: int,
) -> None:
    config = DEFAULT_CONFIG
    maximum_geometry_error = max(
        float(record["diameter_squared_error_m2"])
        for record in geometry_records
    )
    maximum_diameter_error = max(
        float(record["diameter_error_m"])
        for record in geometry_records
    )
    maximum_quantized_path_diameter_error = max(
        float(record["quantized_path_diameter_error_m"])
        for record in geometry_records
    )
    untrusted_case_count = sum(not bool(record["trusted"]) for record in geometry_records)
    report = f"""# T02位精确定点黄金模型报告

## 配置

| 项目 | 数值 |
|---|---:|
| 坐标 | signed Q16.16，{config.coordinate_bits}位 |
| 相位 | unsigned {config.phase_bits}位整周相位 |
| CORDIC迭代 | {config.cordic_iterations}次 |
| CORDIC内部小数位 | {config.cordic_internal_fraction_bits}位 |
| 正余弦输出 | signed Q2.30，{config.trigonometric_bits}位 |
| 半平面函数小数位 | {config.coordinate_fraction_bits + config.trigonometric_fraction_bits}位 |
| 交点参数 | Q2.30 |
| 初始多边形 | {config.polygon_side_count}边、半径{config.radius_m:.0f} m |
| EPS_HP原始值 | {config.eps_halfplane_raw} |
| EPS_DEN原始值 | {config.eps_denominator_raw} |

## CORDIC全相位扫描

扫描了全部{cordic['phase_count']}个18位相位输入。

| 指标 | 结果 |
|---|---:|
| 最大正弦绝对误差 | {cordic['maximum_sine_error']:.12e} |
| 最大余弦绝对误差 | {cordic['maximum_cosine_error']:.12e} |
| 最大向量模长误差 | {cordic['maximum_vector_norm_error']:.12e} |
| 最大残余相位 | {cordic['maximum_residual_phase_lsb']} 个32位内部相位LSB |
| 饱和次数 | {cordic['saturation_count']} |
| 固化黄金向量数 | {cordic_vector_count} |

## 初始多边形ROM

| 指标 | 结果 |
|---|---:|
| 顶点数 | {polygon['vertex_count']} |
| 理论外接顶点半径 | {polygon['theoretical_vertex_radius_m']:.12f} m |
| 定点最小顶点半径 | {polygon['minimum_vertex_radius_m']:.12f} m |
| 定点最大顶点半径 | {polygon['maximum_vertex_radius_m']:.12f} m |
| 最大顶点半径量化误差 | {polygon['maximum_vertex_radius_error_m']:.12e} m |

ROM每行是64位十六进制字，格式为 ``{{x[31:0], y[31:0]}}``，共720行。

## 交点残差扫描

| 指标 | 结果 |
|---|---:|
| 随机样本数 | {intersections['sample_count']} |
| 最大边界残差原始值 | {intersections['maximum_absolute_residual_raw']} |
| EPS_HP原始值 | {intersections['eps_halfplane_raw']} |
| 使用负容差接纳次数 | {intersections['accepted_negative_residual_count']} |
| 近并行标志次数 | {intersections['parallel_count']} |

当前EPS值是T02模型基线，不是脱离RTL实现后的永久常量。T09实现除法器后，必须以完全相同的商位宽和舍入流水重新运行本扫描；若RTL除法算法不同，需重新冻结EPS。

## 端到端场景

| 场景 | 浮点顶点 | 定点顶点 | 直径误差/m | 量化输入下数据通路误差/m | 直径平方误差/m² | 可信 |
|---|---:|---:|---:|---:|---:|---|
"""
    for record in geometry_records:
        report += (
            f"| {record['name']} | {record['float_vertex_count']} | "
            f"{record['fixed_vertex_count']} | {record['diameter_error_m']:.9f} | "
            f"{record['quantized_path_diameter_error_m']:.9f} | "
            f"{record['diameter_squared_error_m2']:.9f} | "
            f"{record['trusted']} |\n"
        )
    report += f"""

场景中的最大直径绝对误差为{maximum_diameter_error:.9f} m，最大直径平方绝对误差为{maximum_geometry_error:.9f} m²。将观测相位和误差半角都量化到18位后的双精度结果作为基准时，最大定点数据通路直径误差为{maximum_quantized_path_diameter_error:.9f} m。两类比较共同覆盖输入角度编码与后续定点运算；不可信场景数为{untrusted_case_count}。空区域场景的浮点和定点输出均应为空。

## 位宽结论

- Q16.16坐标差需要33位有符号数。
- 单个坐标差平方最多需要64位无符号数；两项相加需要65位，采用66位输出保留余量。
- Q2.30系数与Q16.16坐标乘积需要64位有符号数并具有46个小数位。
- 两个乘积再减常数时采用66位有符号半平面函数通路。
- CORDIC内部36位、32个小数位，在全18位相位扫描中不得发生饱和。
- CORDIC输入为18位相位，角度累加器扩展为32位整周相位，避免反正切表逐项量化误差累积。

## 适用边界

本报告验证的是Python位精确语义模型。它为后续RTL提供事务级黄金结果，但不是Vivado仿真、综合、时序或下板证据。
"""
    (REPORT_DIR / "t02_fixed_point_error_report.md").write_text(report, encoding="utf-8")


def main() -> None:
    VECTOR_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    cordic = _cordic_scan()
    polygon = _write_polygon_rom()
    vector_count = _write_cordic_vectors()
    _write_cordic_constants()
    geometry_records = _write_geometry_vectors()
    intersections = _intersection_residual_scan()
    _write_report(cordic, polygon, intersections, geometry_records, vector_count)
    print(json.dumps({
        "cordic": cordic,
        "polygon": polygon,
        "intersections": intersections,
        "geometry_case_count": len(geometry_records),
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
