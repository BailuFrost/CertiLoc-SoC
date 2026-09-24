"""单次随机板级定位工具的离线单元测试。"""

from __future__ import annotations

import math
import unittest
from unittest.mock import patch

from fpga_stage1.model.protocol_reference import (
    Command,
    Frame,
    RegionType,
    Response,
    ResultFlag,
    pack_ack,
    pack_info,
    pack_result_header,
    pack_result_vertices,
    pack_status,
)
from fpga_stage1.tools.test_plot import (
    bearing_to_raw,
    coordinate_from_raw,
    coordinate_to_raw,
    decode_error_flags,
    execute_localization,
    generate_observations,
    plot_result,
    polygon_centroid,
)
from fpga_stage1.tools.t15_board_validation import ResultHeader


class BoardLocalizationPlotTests(unittest.TestCase):
    def test_fixed_point_conversion_uses_half_away_from_zero(self) -> None:
        self.assertEqual(coordinate_to_raw(0.5 / 65536.0), 1)
        self.assertEqual(coordinate_to_raw(-0.5 / 65536.0), -1)
        self.assertEqual(coordinate_from_raw(65536), 1.0)
        self.assertEqual(bearing_to_raw(360.0), 0)

    def test_random_observations_are_reproducible_and_protocol_legal(self) -> None:
        first, target_first = generate_observations(6, 20260924, 0.75)
        second, target_second = generate_observations(6, 20260924, 0.75)
        self.assertEqual(first, second)
        self.assertEqual(target_first, target_second)
        self.assertEqual(len(first), 6)
        for item in first:
            self.assertLessEqual(abs(item.bearing_noise_deg), 0.75)
            self.assertGreaterEqual(item.raw.bearing_phase_u18, 0)
            self.assertLess(item.raw.bearing_phase_u18, 1 << 18)

    def test_centroid_and_error_flag_decoding(self) -> None:
        centroid = polygon_centroid(((0.0, 0.0), (2.0, 0.0), (2.0, 2.0), (0.0, 2.0)))
        self.assertIsNotNone(centroid)
        assert centroid is not None
        self.assertTrue(math.isclose(centroid[0], 1.0))
        self.assertTrue(math.isclose(centroid[1], 1.0))
        descriptions = decode_error_flags(
            int(ResultFlag.QUANTIZATION_MARGIN_USED | ResultFlag.COLLINEARITY_NOT_CHECKED)
        )
        self.assertEqual(len(descriptions), 2)

    def test_plot_is_shown_without_writing_a_file(self) -> None:
        try:
            import matplotlib  # noqa: F401
        except ModuleNotFoundError:
            self.skipTest("matplotlib未安装")
        observations, reference_target = generate_observations(4, 20260924, 0.75)
        vertices = ((-2.0, -1.0), (3.0, -1.0), (3.0, 2.0), (-2.0, 2.0))
        header = ResultHeader(
            job_sequence=4,
            trusted=True,
            region_type=3,
            vertex_count=4,
            diameter_squared_raw=0,
            farthest_first=0,
            farthest_second=2,
            core_cycles=100,
            error_flags=0,
        )
        with patch("matplotlib.pyplot.show") as show_mock:
            plot_result(observations, vertices, header, reference_target)
        show_mock.assert_called_once_with()

    def test_single_localization_protocol_sequence(self) -> None:
        observations, _ = generate_observations(2, 20260924, 0.75)
        raw_vertices = ((-65536, 0), (65536, 0))
        responses = [
            Frame(Response.INFO, 1, pack_info()),
            Frame(Response.ACK, 2, pack_ack(Command.SET_CONFIG)),
            Frame(Response.ACK, 3, pack_ack(Command.LOAD_OBSERVATIONS)),
            Frame(Response.ACK, 4, pack_ack(Command.START_LOCALIZATION)),
            Frame(
                Response.STATUS,
                5,
                pack_status(6, True, True, RegionType.SEGMENT, 2, 1, 2, 0x40, 1234),
            ),
            Frame(
                Response.RESULT_HEADER,
                6,
                pack_result_header(4, True, RegionType.SEGMENT, 2, 4 << 32, 0, 1, 1234, 0x40),
            ),
            Frame(Response.RESULT_VERTICES, 7, pack_result_vertices(4, 0, raw_vertices)),
        ]

        class FakeClient:
            def transact(self, command: Command, payload: bytes = b"") -> tuple[Frame, float]:
                del command, payload
                return responses.pop(0), 0.0

        info, header, status, vertices, _ = execute_localization(
            FakeClient(), observations, 1.0  # type: ignore[arg-type]
        )
        self.assertEqual(info, pack_info())
        self.assertEqual(header.core_cycles, 1234)
        self.assertTrue(status.result_valid)
        self.assertEqual(vertices, raw_vertices)
        self.assertFalse(responses)


if __name__ == "__main__":
    unittest.main()
