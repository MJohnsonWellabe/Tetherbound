"""Regression checks for per-round evidence; no game assets required."""
import json
import tempfile
import unittest
from pathlib import Path

from PIL import Image

from phase2_compact_evidence import compact_round, verify_round


class CompactRoundTests(unittest.TestCase):
    def test_paginated_round_preserves_metadata_and_survives_raw_removal(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            raw = root / "raw"
            raw.mkdir()
            frames = []
            for index in range(25):
                Image.new("RGB", (192, 108), (index * 8, 20, 40)).save(raw / f"{index}.png")
                frames.append({"frame_id": f"frame_{index}", "file": f"res://raw/{index}.png",
                               "camera_position": [1, 2, 3]})
            source = raw / "manifest.json"
            source.write_text(json.dumps({"complete": False, "failures": ["unreached view"],
                                          "seed": 2042, "frames": frames}))
            out = root / "evidence"
            compact_round(source, out, "a" * 40, "godot --seed=2042", root)
            result = json.loads((out / "manifest.json").read_text())
            self.assertFalse(result["capture_metadata"]["complete"])
            self.assertEqual(result["capture_metadata"]["failures"], ["unreached view"])
            self.assertEqual(result["frames"][24]["capture"]["camera_position"], [1, 2, 3])
            for image in raw.glob("*.png"):
                image.unlink()
            verify_round(out, root)
            with self.assertRaises(ValueError):
                compact_round(source, out, "a" * 40, "repro", root)
            result["frames"][24]["tile_index"] = 1
            (out / "manifest.json").write_text(json.dumps(result))
            with self.assertRaises(AssertionError):
                verify_round(out, root)

    def test_creature_aliases_and_input_preflight(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            Image.new("RGB", (160, 90)).save(root / "creature.png")
            source = root / "capture.json"
            frame = {"id": "aquaryn", "path": "res://creature.png", "pose": "shiny_idle"}
            source.write_text(json.dumps({"frames": [frame]}))
            compact_round(source, root / "ok", "b" * 40, "creature capture", root)
            source.write_text(json.dumps({"frames": [frame, frame]}))
            with self.assertRaises(ValueError):
                compact_round(source, root / "duplicates", "b" * 40, "repro", root)
            self.assertFalse((root / "duplicates").exists())
            frame["path"] = "res://../outside.png"
            source.write_text(json.dumps({"frames": [frame]}))
            with self.assertRaises(ValueError):
                compact_round(source, root / "escape", "b" * 40, "repro", root)
            self.assertFalse((root / "escape").exists())


if __name__ == "__main__":
    unittest.main()
