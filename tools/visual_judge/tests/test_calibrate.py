"""calibrate.py on known numbers, anchor_tiles.py selection rules, and the anchor set's integrity."""
import json
from pathlib import Path
import random
import sys
import tempfile
import unittest

HERE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HERE))
import anchor_tiles
import calibrate

REFS = {"a": 4.0, "b": 5.0, "c": 6.0, "d": 7.0, "e": 7.4}


class Fit(unittest.TestCase):
    def test_exact_line_is_recovered(self):
        # reference = 2 * measured - 1 at measured 2.5, 3.0, 3.5, 4.0
        batch = {"anchors": {"a": [2.4, 2.5, 2.6], "b": 3.0, "c": [3.5], "d": 4.0},
                 "candidates": {"x": [3.0, 4.0, 5.0], "y": 6.0, "z": 4.1}}
        out = calibrate.calibrate(batch, REFS)
        self.assertEqual(out["fit"]["method"], "linear")
        self.assertAlmostEqual(out["fit"]["slope"], 2.0)
        self.assertAlmostEqual(out["fit"]["intercept"], -1.0)
        self.assertAlmostEqual(out["anchor_rmse"], 0.0)
        self.assertEqual(out["top_anchor_reference"], 7.0)
        x = out["candidates"]["x"]
        self.assertAlmostEqual(x["mapped_mean"], 7.0)
        self.assertEqual(x["mapped_judges"], [5.0, 7.0, 9.0])
        self.assertFalse(x["meets_bar"] or x["above_top_anchor"])
        z = out["candidates"]["z"]  # 7.2: above the top anchor, under the bar
        self.assertTrue(z["above_top_anchor"] and not z["meets_bar"])
        y = out["candidates"]["y"]
        self.assertEqual(y["mapped_mean"], 10.0)  # 11 clamped
        self.assertTrue(y["clamped"] and y["meets_bar"] and y["outside_anchor_range"] and y["above_top_anchor"])
        self.assertFalse(out["confirming_batch"])  # top anchor 7.0 < 7.35
        self.assertTrue(any("above the top anchor" in w and "confirm in" in w for w in out["warnings"]))
        self.assertFalse(any("offset fallback" in w for w in out["warnings"]))

    def test_one_and_two_and_three_anchor_batches_are_refused(self):
        for anchors in ({"a": 4.0}, {"a": 1.0, "d": 5.0}, {"a": 1.0, "b": 2.0, "d": 5.0}):
            with self.assertRaisesRegex(ValueError, "at least 4"):
                calibrate.calibrate({"anchors": anchors, "candidates": {"x": 4.5}}, REFS)

    def test_cli_refusal_exits_nonzero(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "b.json"
            p.write_text(json.dumps({"anchors": {"craft:after": 6.0, "craft:before": 3.7}, "candidates": {}}))
            with self.assertRaises(SystemExit) as cm:
                calibrate.main([str(p)])
            self.assertEqual(cm.exception.code, 2)

    def test_slope_outside_range_falls_back_with_warning(self):
        # measured spread 0.3 against reference spread 3 -> slope 10
        out = calibrate.calibrate({"anchors": {"a": 3.0, "b": 3.1, "c": 3.2, "d": 3.3}}, REFS)
        self.assertEqual(out["fit"]["method"], "offset")
        self.assertAlmostEqual(out["fit"]["least_squares_slope"], 10.0)
        self.assertAlmostEqual(out["fit"]["intercept"], 5.5 - 3.15)
        self.assertTrue(any("offset fallback" in w for w in out["warnings"]))

    def test_flat_anchors_fall_back_with_warning(self):
        out = calibrate.calibrate({"anchors": {"a": 4.0, "b": 4.0, "c": 4.0, "d": 4.0}}, REFS)
        self.assertEqual(out["fit"]["method"], "offset")
        self.assertTrue(any("offset fallback" in w for w in out["warnings"]))

    def test_fit_alone_uses_offset_under_three_points(self):
        f = calibrate.fit([(1.0, 4.0), (5.0, 7.0)])
        self.assertEqual(f["method"], "offset")
        self.assertAlmostEqual(f["intercept"], 2.5)

    def test_unknown_anchor_is_an_error(self):
        with self.assertRaises(KeyError):
            calibrate.calibrate({"anchors": {"zz": 5.0, "a": 1, "b": 2, "c": 3}}, REFS)

    def test_bar_is_inclusive(self):
        out = calibrate.calibrate({"anchors": {"a": 4.0, "b": 5.0, "c": 6.0, "e": 7.4},
                                   "candidates": {"x": 7.5}}, REFS)
        self.assertTrue(out["candidates"]["x"]["meets_bar"])
        self.assertTrue(out["candidates"]["x"]["above_top_anchor"])  # 7.5 > 7.4
        self.assertTrue(out["confirming_batch"])  # top anchor 7.4 >= 7.35
        self.assertTrue(any("confirming batch" in w for w in out["warnings"]))


class Tiles(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.anchors = anchor_tiles.load()

    def test_every_draw_spans_two_items(self):
        for n in (3, 4):
            for seed in range(2000):
                chosen = anchor_tiles.pick(self.anchors, n, random.Random(seed))
                self.assertEqual(len(chosen), n)
                self.assertEqual(len({g[0]["group"] for g in chosen}), n)
                self.assertGreaterEqual(len({g[0]["item"] for g in chosen}), 2, (n, seed))

    def test_too_many_pairs_is_a_clear_error(self):
        n = len(anchor_tiles.pair_groups(self.anchors))
        anchor_tiles.pick(self.anchors, n, random.Random(0))
        with self.assertRaisesRegex(ValueError, "exceeds"):
            anchor_tiles.pick(self.anchors, n + 1, random.Random(0))

    def test_include_forces_a_group(self):
        chosen = anchor_tiles.pick(self.anchors, 3, random.Random(1), include=["craft"])
        self.assertIn("craft", [g[0]["group"] for g in chosen])

    def test_key_must_be_outside_the_judge_folder(self):
        out = Path("/tmp/judge")
        self.assertFalse(anchor_tiles.key_outside(out, out))
        self.assertFalse(anchor_tiles.key_outside(out, out / "key.json"))
        self.assertFalse(anchor_tiles.key_outside(out, out / "sub" / "key.json"))
        self.assertTrue(anchor_tiles.key_outside(out, Path("/tmp/key.json")))
        self.assertTrue(anchor_tiles.key_outside(out, Path("/tmp/judge2/key.json")))

    def test_fewer_than_three_pairs_is_refused(self):
        with tempfile.TemporaryDirectory() as d:
            with self.assertRaisesRegex(ValueError, "at least 3"):
                anchor_tiles.build(Path(d) / "j", Path(d) / "k.json", 2, random.Random(0))


class AnchorSet(unittest.TestCase):
    def test_committed_anchors_are_usable(self):
        root = HERE.parents[1]
        doc = json.loads((HERE / "anchors" / "anchors.json").read_text())
        ids = [a["id"] for a in doc["anchors"]]
        self.assertEqual(len(ids), len(set(ids)))
        refs = sorted(a["reference"] for a in doc["anchors"])
        self.assertLessEqual(refs[0], 3.6)
        self.assertGreaterEqual(refs[-1], 7.5)
        for a in doc["anchors"]:
            self.assertTrue((root / a["sheet"]).is_file(), a["sheet"])
            x0, y0, x1, y1 = a["box"]
            self.assertTrue(x0 < x1 and y0 < y1, a["id"])
            if a["reference_judges"]:
                self.assertAlmostEqual(sum(a["reference_judges"]) / len(a["reference_judges"]),
                                       a["reference"], delta=0.011, msg=a["id"])


if __name__ == "__main__":
    unittest.main()
