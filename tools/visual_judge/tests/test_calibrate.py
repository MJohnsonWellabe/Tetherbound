"""calibrate.py on known numbers, plus the committed anchor set's integrity."""
import json
from pathlib import Path
import sys
import unittest

HERE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HERE))
import calibrate

REFS = {"a": 4.0, "b": 5.0, "c": 6.0, "d": 7.0}


class Fit(unittest.TestCase):
    def test_exact_line_is_recovered(self):
        # reference = 2 * measured - 1 at measured 2.5, 3.0, 3.5, 4.0
        batch = {"anchors": {"a": [2.4, 2.5, 2.6], "b": 3.0, "c": [3.5], "d": 4.0},
                 "candidates": {"x": [3.0, 4.0, 5.0], "y": 6.0}}
        out = calibrate.calibrate(batch, REFS)
        self.assertEqual(out["fit"]["method"], "linear")
        self.assertAlmostEqual(out["fit"]["slope"], 2.0)
        self.assertAlmostEqual(out["fit"]["intercept"], -1.0)
        self.assertAlmostEqual(out["anchor_rmse"], 0.0)
        x = out["candidates"]["x"]
        self.assertAlmostEqual(x["mapped_mean"], 7.0)
        self.assertEqual(x["mapped_judges"], [5.0, 7.0, 9.0])
        self.assertFalse(x["meets_bar"])
        y = out["candidates"]["y"]
        self.assertEqual(y["mapped_mean"], 10.0)  # 11 clamped
        self.assertTrue(y["clamped"] and y["meets_bar"] and y["outside_anchor_range"])

    def test_two_points_fall_back_to_mean_offset(self):
        out = calibrate.calibrate({"anchors": {"a": 1.0, "d": 5.0}, "candidates": {"x": 4.5}}, REFS)
        self.assertEqual(out["fit"]["method"], "offset")
        self.assertAlmostEqual(out["fit"]["intercept"], 2.5)  # mean(3.0, 2.0)
        self.assertAlmostEqual(out["candidates"]["x"]["mapped_mean"], 7.0)

    def test_slope_outside_range_falls_back(self):
        # measured spread 0.3 against reference spread 3 -> slope 10
        out = calibrate.calibrate({"anchors": {"a": 3.0, "b": 3.1, "c": 3.2, "d": 3.3}}, REFS)
        self.assertEqual(out["fit"]["method"], "offset")
        self.assertAlmostEqual(out["fit"]["least_squares_slope"], 10.0)
        self.assertAlmostEqual(out["fit"]["intercept"], 5.5 - 3.15)
        self.assertTrue(out["warnings"])  # residuals of the offset map exceed the RMSE warning

    def test_unknown_anchor_is_an_error(self):
        with self.assertRaises(KeyError):
            calibrate.calibrate({"anchors": {"zz": 5.0}}, REFS)

    def test_bar_is_inclusive(self):
        out = calibrate.calibrate({"anchors": {"a": 4.0}, "candidates": {"x": 7.5}}, REFS)
        self.assertTrue(out["candidates"]["x"]["meets_bar"])


class AnchorSet(unittest.TestCase):
    def test_committed_anchors_are_usable(self):
        root = HERE.parents[1]
        doc = json.loads((HERE / "anchors" / "anchors.json").read_text())
        ids = [a["id"] for a in doc["anchors"]]
        self.assertEqual(len(ids), len(set(ids)))
        refs = sorted(a["reference"] for a in doc["anchors"])
        self.assertLessEqual(refs[0], 3.6)
        self.assertGreaterEqual(refs[-1], 7.3)
        for a in doc["anchors"]:
            self.assertTrue((root / a["sheet"]).is_file(), a["sheet"])
            x0, y0, x1, y1 = a["box"]
            self.assertTrue(x0 < x1 and y0 < y1, a["id"])
            if a["reference_judges"]:
                self.assertAlmostEqual(sum(a["reference_judges"]) / len(a["reference_judges"]),
                                       a["reference"], delta=0.011, msg=a["id"])


if __name__ == "__main__":
    unittest.main()
