"""quick_judge.py: stand lookup from job.json, overlay apply/revert (byte-identical) and finish assembly."""
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

HERE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HERE))
import quick_judge as qj

# Deliberately odd formatting, key order and floats: a json round-trip would change these bytes.
ORIGINAL = b'{\n\t"readout_side_enabled": false,  "plate": 0.850,\n "nested": {"arm": {"enabled": false, "_why": "x"}},\n "keep": [1, 2.0e0]\n}'


def sha(b):
    return hashlib.sha256(b).hexdigest()


class StandLookup(unittest.TestCase):
    def test_f39_23_stands_come_from_job_json(self):
        p = qj.plan(["F39#23"])
        self.assertEqual(len(p["launches"]), 1)
        e = p["launches"][0]
        self.assertEqual(e["script"], "tools/phase2_capture_catch.gd")
        self.assertEqual(e["args"], ["--biome=tidewake", "--seed=2042"])
        self.assertEqual(e["frames"], ["tidewake__catching__catch_low", "tidewake__catching__catch_high",
                                       "tidewake__catching__01-aiming-full-health"])
        self.assertTrue(all(s["launch"] == 1 for s in p["stands"]))
        self.assertEqual(e["out_parent"], "res://ralph/reports/VISUAL/phase2/tidewake")

    def test_catalogue_id_resolves_to_board_row(self):
        self.assertEqual(qj.load_items()["P2-114"]["board_row"], "F39#23")

    def test_every_job_frame_maps_to_exactly_one_launch(self):
        items = qj.load_items()
        rows = sorted({it["board_row"] for it in items.values()})
        for r in rows:
            p = qj.plan([r])
            want = [f["id"] for f in items[r]["frames"]]
            got = [s["frame"] for s in p["stands"]]
            self.assertEqual(got, want, r)
            self.assertTrue(all(s["launch"] for s in p["stands"]), r)

    def test_creature_launches_share_one_boot_and_narrow_poses(self):
        p = qj.plan(["F38#1"])
        self.assertEqual(len(p["launches"]), 1)
        n = p["launches"][0]["narrow"]
        self.assertIn("--only=terrapup,veridian", n)
        self.assertIn("--poses=fainted,resting", n)

    def test_base_key_ignores_judging_tools_and_reports_only(self):
        for path in ("tools/visual_judge/quick_judge.py", "ralph/reports/x.json", "docs/TECHNICAL.md", "README.md"):
            self.assertFalse(qj._keep(path), path)
        for path in ("data/config/capture_readout_visual.json", "scripts/ui/capture_reticle.gd",
                     "tools/phase2_capture_catch.gd", "assets/x.png.import"):
            self.assertTrue(qj._keep(path), path)

    def test_unknown_item_is_refused(self):
        with self.assertRaises(SystemExit):
            qj.plan(["F99#1"])


class Overlay(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.backup = self.root / "bk"
        (self.root / "data/config").mkdir(parents=True)
        self.a = self.root / "data/config/a.json"
        self.a.write_bytes(ORIGINAL)
        self.b = self.root / "data/config/b.json"
        self.b.write_bytes(b'{"x": {"enabled": false}}')

    def tearDown(self):
        self.tmp.cleanup()

    def test_apply_then_revert_is_byte_identical(self):
        ov = {"data/config/a.json": {"readout_side_enabled": True, "nested": {"arm": {"enabled": True}}},
              "data/config/b.json": ["x"],
              "data/config/new.json": {"made": True}}
        before = {p: sha(p.read_bytes()) for p in (self.a, self.b)}
        with qj.overlaid(ov, self.root, self.backup):
            d = json.loads(self.a.read_text())
            self.assertIs(d["readout_side_enabled"], True)
            self.assertIs(d["nested"]["arm"]["enabled"], True)
            self.assertEqual(d["nested"]["arm"]["_why"], "x")
            self.assertIs(json.loads(self.b.read_text())["x"]["enabled"], True)
            self.assertTrue((self.root / "data/config/new.json").exists())
        self.assertEqual({p: sha(p.read_bytes()) for p in (self.a, self.b)}, before)
        self.assertEqual(self.a.read_bytes(), ORIGINAL)
        self.assertFalse((self.root / "data/config/new.json").exists())
        self.assertFalse(self.backup.exists())

    def test_revert_runs_when_the_capture_fails(self):
        with self.assertRaises(RuntimeError):
            with qj.overlaid({"data/config/a.json": {"plate": 0.96}}, self.root, self.backup):
                raise RuntimeError("godot crashed")
        self.assertEqual(self.a.read_bytes(), ORIGINAL)

    def test_bad_overlay_reverts_files_already_written(self):
        ov = {"data/config/a.json": {"plate": 1.0}, "data/config/b.json": ["x.missing"]}
        with self.assertRaises(Exception):
            qj.apply_overlay(ov, self.root, self.backup)
        self.assertEqual(self.a.read_bytes(), ORIGINAL)
        self.assertFalse(self.backup.exists())

    def test_crash_leaves_backup_that_revert_restores(self):
        qj.apply_overlay({"data/config/a.json": {"plate": 0.96}}, self.root, self.backup)
        self.assertNotEqual(self.a.read_bytes(), ORIGINAL)
        with self.assertRaises(RuntimeError):   # second apply refused while one is live
            qj.apply_overlay({"data/config/b.json": ["x"]}, self.root, self.backup)
        self.assertEqual(qj.revert(self.root, self.backup), ["data/config/a.json"])
        self.assertEqual(self.a.read_bytes(), ORIGINAL)

    def test_already_on_flag_is_refused(self):
        self.b.write_bytes(b'{"x": {"enabled": true}}')
        with self.assertRaises(ValueError):
            qj.apply_overlay({"data/config/b.json": ["x"]}, self.root, self.backup)
        self.assertEqual(self.b.read_bytes(), b'{"x": {"enabled": true}}')

    def test_lane_bin_overlay_specs_load(self):
        self.assertEqual(qj.load_overlay("data/config/a.json:nested.arm data/config/b.json:x"),
                         {"data/config/a.json": ["nested.arm"], "data/config/b.json": ["x"]})


class FrameLookup(unittest.TestCase):
    def test_numbered_flight_frames_match_their_job_ids(self):
        with tempfile.TemporaryDirectory() as t:
            for name in ("01-launch.png", "02-glide.png", "03-landed.png"):
                (Path(t) / name).write_bytes(b"x")
            self.assertEqual(qj.find_frame(t, "meadows__flying__glide").name, "02-glide.png")
            self.assertEqual(qj.find_frame(t, "meadows__flying__landed").name, "03-landed.png")
            self.assertIsNone(qj.find_frame(t, "meadows__flying__perch"))


class Finish(unittest.TestCase):
    def test_assemble_maps_shuffled_sides_and_refuses_gaps(self):
        key = {"Ab": {"anchor": True, "A": "craft:after", "B": "craft:before"},
               "Cd": {"anchor": False, "label": "F39#23", "A": "/k/sides/F39_23_cand.jpg", "B": "/k/sides/F39_23_base.jpg"}}
        js = [{"Ab": {"A": {"bar_a": 6}, "B": {"bar_a": 4}}, "Cd": {"A": {"bar_a": 5.6, "defects": {"d": "FIXED"}}, "B": {"bar_a": 5}}}] * 3
        batch, defects = qj.assemble(key, js)
        self.assertEqual(batch["anchors"], {"craft:after": [6.0] * 3, "craft:before": [4.0] * 3})
        self.assertEqual(batch["candidates"], {"F39#23 cand": [5.6] * 3, "F39#23 base": [5.0] * 3})
        self.assertEqual(defects["F39#23 cand"][0], {"d": "FIXED"})
        with self.assertRaises(SystemExit):
            qj.assemble(key, [js[0], js[0], {"Ab": js[0]["Ab"]}])

    def test_judge_json_is_read_from_a_prose_reply(self):
        with tempfile.TemporaryDirectory() as t:
            p = Path(t) / "j1.txt"
            p.write_text('Defects first... {"x": 1} more\n```json\n{"sets": {"Ab": {"A": {"bar_a": 5.5, "defects": {}}}}, "top_changes": []}\n```\n')
            self.assertEqual(qj.judge_json(p)["Ab"]["A"]["bar_a"], 5.5)


if __name__ == "__main__":
    unittest.main()
