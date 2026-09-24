"""T02双精度与位精确定点黄金模型单元测试。"""

from __future__ import annotations

import math
from pathlib import Path
import sys
import unittest

PROJECT_ROOT = Path(__file__).resolve().parents[3]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from fpga_stage1.model.floating_reference.geometry import (
    FloatHalfPlane,
    FloatPoint,
    clip_halfplane,
    localize_float,
)
from fpga_stage1.model.fixed_point_reference.config import DEFAULT_CONFIG
from fpga_stage1.model.fixed_point_reference.cordic import cordic_sincos, degrees_to_phase
from fpga_stage1.model.fixed_point_reference.geometry import (
    FixedHalfPlane,
    FixedPoint,
    clip_halfplane_fixed,
    diameter_squared_fixed,
    localize_fixed,
    regular_circumscribed_polygon_fixed,
    segment_intersection_fixed,
)


class TestCordic(unittest.TestCase):
    def test_cardinal_angles(self) -> None:
        scale = 1 << DEFAULT_CONFIG.trigonometric_fraction_bits
        cases = (
            (0.0, 0, scale),
            (90.0, scale, 0),
            (180.0, 0, -scale),
            (270.0, -scale, 0),
        )
        # 18次微旋转的理论剩余角量级约为2^-18 rad，对应Q2.30约数千LSB。
        tolerance = 8192
        for angle, expected_sine, expected_cosine in cases:
            result = cordic_sincos(degrees_to_phase(angle))
            self.assertLessEqual(abs(result.sine_raw - expected_sine), tolerance)
            self.assertLessEqual(abs(result.cosine_raw - expected_cosine), tolerance)
            self.assertFalse(result.saturated)

    def test_sampled_full_turn_error(self) -> None:
        full_turn = 1 << DEFAULT_CONFIG.phase_bits
        maximum_error = 0.0
        for phase in range(0, full_turn, 61):
            result = cordic_sincos(phase)
            angle = 2.0 * math.pi * phase / full_turn
            maximum_error = max(
                maximum_error,
                abs(result.sine - math.sin(angle)),
                abs(result.cosine - math.cos(angle)),
            )
        self.assertLess(maximum_error, 2.0e-5)


class TestGeometry(unittest.TestCase):
    def test_floating_clip_four_edge_states(self) -> None:
        square = [
            FloatPoint(-1.0, -1.0),
            FloatPoint(1.0, -1.0),
            FloatPoint(1.0, 1.0),
            FloatPoint(-1.0, 1.0),
        ]
        clipped = clip_halfplane(square, FloatHalfPlane(1.0, 0.0, 0.0))
        self.assertEqual(len(clipped), 4)
        self.assertTrue(all(point.x >= -1.0e-9 for point in clipped))

    def test_fixed_intersection(self) -> None:
        start = FixedPoint.from_metres(-1.0, 0.0)
        end = FixedPoint.from_metres(1.0, 0.0)
        plane = FixedHalfPlane(1 << 30, 0, 0)
        start_value = plane.evaluate(start)
        end_value = plane.evaluate(end)
        result = segment_intersection_fixed(start, end, start_value, end_value, plane)
        self.assertFalse(result.parallel)
        self.assertIsNotNone(result.point)
        assert result.point is not None
        self.assertEqual(result.point.x_raw, 0)
        self.assertEqual(result.point.y_raw, 0)

    def test_fixed_clip_and_diameter(self) -> None:
        square = tuple(
            FixedPoint.from_metres(x_value, y_value)
            for x_value, y_value in ((-1.0, -1.0), (1.0, -1.0), (1.0, 1.0), (-1.0, 1.0))
        )
        plane = FixedHalfPlane(1 << 30, 0, 0)
        clipped = clip_halfplane_fixed(square, plane)
        self.assertTrue(clipped.trusted)
        self.assertEqual(len(clipped.vertices), 4)
        self.assertTrue(all(point.x_raw >= 0 for point in clipped.vertices))
        distance_raw, _, overflow = diameter_squared_fixed(clipped.vertices)
        self.assertFalse(overflow)
        self.assertAlmostEqual(distance_raw / float(1 << 32), 5.0, places=6)

    def test_initial_polygon_capacity_and_radius(self) -> None:
        vertices = regular_circumscribed_polygon_fixed()
        self.assertEqual(len(vertices), 720)
        self.assertLess(len(vertices), DEFAULT_CONFIG.maximum_vertex_count)
        minimum_radius = min(math.hypot(point.x_m, point.y_m) for point in vertices)
        self.assertGreaterEqual(minimum_radius, DEFAULT_CONFIG.radius_m)

    def test_end_to_end_fixed_matches_float(self) -> None:
        source = (100.0, 50.0)
        sensors = ((-1000.0, 0.0), (1000.0, 0.0), (0.0, -1000.0), (0.0, 1000.0))
        observations = [
            (
                sensor_x,
                sensor_y,
                math.degrees(math.atan2(source[1] - sensor_y, source[0] - sensor_x)) % 360.0,
            )
            for sensor_x, sensor_y in sensors
        ]
        floating = localize_float(observations)
        fixed = localize_fixed(observations)
        self.assertTrue(fixed.trusted)
        self.assertGreater(len(fixed.vertices), 0)
        self.assertLess(
            abs(fixed.diameter_squared_m2 - floating.diameter_squared),
            5.0,
        )

    def test_incompatible_bearings_produce_empty_region(self) -> None:
        observations = [(-1000.0, 0.0, 180.0), (1000.0, 0.0, 0.0)]
        self.assertEqual(len(localize_float(observations).vertices), 0)
        self.assertEqual(len(localize_fixed(observations).vertices), 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
