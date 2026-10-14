import copy
import unittest

from tools.compare_scatter_reader_receipts import compare


def receipt(arm):
    sources = ["res://data/scatter/playground/manifest.json", "res://data/config/grass_field.json",
               "res://data/config/vegetation.json", "res://scripts/world/scatter_bake.gd",
               "res://scripts/world/terrain_bake.gd", "res://scripts/data/band_content.gd",
               "res://project.godot", "res://tools/probe_scatter_reader_memory.gd"]
    row = {"records": 2, "sha256": "a" * 64}
    stages = ["ready", "decoded", "reordered_kept:trees", "retained_output"]
    return {"schema": 1, "scope": "SCATTER_READER_ONLY", "status": "COMPLETE", "arm": arm,
            "source_commit": "1" * 40, "pid": 71 if arm == "legacy" else 72, "godot_version": "test-fixture",
            "scene_loaded": False, "visual_acceptance": False, "memory_acceptance": False,
            "root_children": 0, "isolated_autoloads": {"autoload/Game": "*res://autoload/game_state.gd"},
            "source_sha256": {key: "b" * 64 for key in sources},
            "region_sha256": {"res://data/scatter/playground/region_0_0.bin": "c" * 64},
            "regions": 1, "suppressed_layers": {"grass": True}, "skipped_counts": {"grass": 3},
            "identity_bounds": {"trees": 8, "retired": 12},
            "raw_orders": {"kept": {"trees": copy.deepcopy(row)}, "drained": {}},
            "output_hashes": {"kept": {"trees": copy.deepcopy(row), "retired": {"records": 0, "sha256": "d" * 64}}, "drained": {}},
            "stages": [{"name": name, "elapsed_usec": index * 1000000, "memory_static_bytes": 100 + index * 500}
                       for index, name in enumerate(stages)],
            "started_utc": "2026-10-13T00:00:00", "ended_utc": "2026-10-13T00:00:05"}


class ReaderReceiptTests(unittest.TestCase):
    def test_parity_does_not_promote_static_counters_to_process_memory_proof(self):
        old, new = receipt("legacy"), receipt("compact")
        new["stages"][1]["memory_static_bytes"] -= 200
        result = compare(old, new)
        self.assertEqual(result["status"], "CONTENT_PARITY_PASS")
        self.assertEqual(result["godot_static_delta_compact_minus_legacy_bytes"]["decoded"], -200)
        self.assertFalse(result["process_memory_acceptance"])
        self.assertFalse(result["visual_acceptance"])

    def test_changed_raw_order_output_identity_or_retired_bound_is_rejected(self):
        for field in ("raw_orders", "output_hashes"):
            new = receipt("compact")
            new[field]["kept"]["trees"]["sha256"] = "e" * 64
            with self.subTest(field=field), self.assertRaises(ValueError):
                compare(receipt("legacy"), new)
        new = receipt("compact")
        new["identity_bounds"]["retired"] = 11
        with self.assertRaises(ValueError):
            compare(receipt("legacy"), new)

    def test_different_input_source_or_suppression_is_rejected(self):
        for field in ("source_sha256", "region_sha256"):
            new = receipt("compact")
            new[field][next(iter(new[field]))] = "e" * 64
            with self.subTest(field=field), self.assertRaises(ValueError):
                compare(receipt("legacy"), new)
        new = receipt("compact")
        new["suppressed_layers"] = {}
        with self.assertRaises(ValueError):
            compare(receipt("legacy"), new)

    def test_dropped_records_and_missing_phases_are_rejected(self):
        new = receipt("compact")
        new["output_hashes"]["kept"]["trees"]["records"] = 1
        with self.assertRaises(ValueError):
            compare(receipt("legacy"), new)
        new = receipt("compact")
        new["stages"].pop(2)
        with self.assertRaises(ValueError):
            compare(receipt("legacy"), new)

    def test_running_and_world_scene_receipts_are_rejected(self):
        for key, value in (("status", "RUNNING"), ("scene_loaded", True), ("memory_acceptance", True),
                           ("root_children", 1), ("isolated_autoloads", None)):
            new = receipt("compact")
            new[key] = value
            with self.subTest(key=key), self.assertRaises(ValueError):
                compare(receipt("legacy"), new)

    def test_unavailable_static_counter_stays_unavailable(self):
        old, new = receipt("legacy"), receipt("compact")
        old["stages"][0]["memory_static_bytes"] = 0
        result = compare(old, new)
        self.assertIsNone(result["godot_static_delta_compact_minus_legacy_bytes"]["decoded"])

    def test_map_serialization_order_does_not_change_valid_phase_order(self):
        old, new = receipt("legacy"), receipt("compact")
        for item in (old, new):
            item["raw_orders"]["kept"]["apple"] = {"records": 0, "sha256": "d" * 64}
            item["output_hashes"]["kept"]["apple"] = {"records": 0, "sha256": "d" * 64}
            item["stages"].insert(3, {"name": "reordered_kept:apple", "elapsed_usec": 3000000,
                                      "memory_static_bytes": 1500})
            item["stages"][-1]["elapsed_usec"] = 4000000
        new["raw_orders"]["kept"] = dict(sorted(new["raw_orders"]["kept"].items()))
        self.assertEqual(compare(old, new)["status"], "CONTENT_PARITY_PASS")


if __name__ == "__main__":
    unittest.main()
