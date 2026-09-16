"""Pure generation/provenance tests; does not launch Godot or write game saves."""
import copy
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("segment_phases", ROOT / "tools/gate_f/derive_segment_phases.py")
GEN = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(GEN)


class SegmentPhases(unittest.TestCase):
    def setUp(self):
        self.text = (ROOT / "tools/gate_f/segments/S03.json").read_text(encoding="utf-8")
        self.source = json.loads(self.text)
        self.plan = json.loads((ROOT / "tools/gate_f/phase_plans/S03.json").read_text(encoding="utf-8"))
        self.phases, self.manifest = GEN.derive(self.source, self.plan, self.text)

    def test_original_step_union_is_identical_in_order_and_dictionary_content(self):
        union = [s for p in self.phases for s in p["steps"] if "_phase_added" not in s]
        self.assertEqual(union, self.source["steps"])
        # Byte-equivalent canonical encoding additionally pins nested payloads.
        self.assertEqual(json.dumps(union, sort_keys=True), json.dumps(self.source["steps"], sort_keys=True))
        ids = [s["id"] for p in self.phases for s in p["steps"]]
        self.assertEqual(len(ids), len(set(ids)))

    def test_debts_and_final_exit_are_preserved_without_synthetic_parent_verdict(self):
        captures = [c for p in self.phases for c in p["phase"]["capture_ids"]]
        self.assertEqual(captures, GEN.planned_captures(self.source["steps"]))
        self.assertTrue(all(p["capture_lane"] == self.source["capture_lane"] for p in self.phases))
        exports = [(p["id"], s["args"]["name"]) for p in self.phases for s in p["steps"] if s["action"] == "save_out"]
        self.assertEqual(exports, [("S03p1", "S03p1-exit.json"), ("S03p2", "S03p2-exit.json"), ("S03p3", "S03-exit.json")])
        self.assertNotIn("verdict", self.manifest)
        self.assertNotIn("S03", [p["id"] for p in self.phases])

    def test_added_seams_use_real_original_save_and_load_controls_without_party_selection(self):
        for p in self.phases:
            added = [s for s in p["steps"] if "_phase_added" in s]
            self.assertFalse(any(s.get("args", {}).get("control") == "party_cycle" for s in added))
            self.assertFalse(any(s["action"] in {"teleport", "force_aim"} for s in added))
            if p["phase"]["index"]:
                seed = next(s for s in added if s["action"] == "seed_save")
                self.assertEqual(seed["args"]["from"], "run://" + p["phase"]["input_save"])
                recalls = [s for s in added if s.get("args", {}).get("control") == "creature_recall"]
                self.assertEqual(len(recalls), 1)
                self.assertEqual(recalls[0]["_phase_added"]["template_step"], "S03-09a")
                self.assertEqual(sum(s["action"] == "press" and s["args"]["control"] == "ui_accept" for s in added if s["_phase_added"]["kind"] == "load"), 2)

    def test_non_world_or_out_of_order_boundaries_are_rejected(self):
        bad = copy.deepcopy(self.plan)
        bad["phases"][0]["through"] = "S03-39g"
        with self.assertRaisesRegex(ValueError, "world input"):
            GEN.derive(self.source, bad, self.text)
        bad = copy.deepcopy(self.plan)
        bad["phases"][1]["through"] = bad["phases"][0]["through"]
        with self.assertRaisesRegex(ValueError, "increasing"):
            GEN.derive(self.source, bad, self.text)

    def test_metrics_are_retained_as_original_assertions_and_declared_for_runtime_aggregation(self):
        checks = self.manifest["aggregate_metric_checks"]
        self.assertEqual(checks, [
            {"id": "S03-261", "args": {"check": "distance_above", "metres": 420.0}},
            {"id": "S03-262", "args": {"check": "route_rows_at_least", "rows": 1200}},
            {"id": "S03-263", "args": {"check": "dead_travel_below", "metres": 150.0}},
        ])
        final_ids = {s["id"] for s in self.phases[-1]["steps"]}
        self.assertTrue(all(check["id"] in final_ids for check in checks))
        self.assertTrue(all(p["phase"]["aggregate_metric_checks"] == checks for p in self.phases))

    def test_source_hash_matches_normalized_text_and_changes_with_real_source_edit(self):
        self.assertEqual(GEN.normalized_sha256(self.text), GEN.normalized_sha256(self.text.replace("\n", "\r\n")))
        self.assertNotEqual(GEN.normalized_sha256(self.text), GEN.normalized_sha256(self.text + " "))
        self.assertTrue(all(p["phase"]["source_sha256"] == self.manifest["source_sha256"] for p in self.phases))

    def test_saved_artifact_names_and_phase_ids_cannot_collide(self):
        for key in ["id", "output_save"]:
            bad = copy.deepcopy(self.plan)
            bad["phases"][1][key] = bad["phases"][0][key]
            with self.assertRaises(ValueError):
                GEN.derive(self.source, bad, self.text)

    def test_windows_case_insensitive_capture_lane_collision_is_rejected(self):
        bad = copy.deepcopy(self.plan)
        bad["phases"][-1]["id"] = "S03c"
        with self.assertRaises(ValueError):
            GEN.derive(self.source, bad, self.text)


class CaptureSegmentPhases(unittest.TestCase):
    def setUp(self):
        self.text = (ROOT / "tools/gate_f/segments/S03C.json").read_text(encoding="utf-8")
        self.source = json.loads(self.text)
        self.template = (ROOT / "tools/gate_f/segments/S03.json").read_text(encoding="utf-8")
        self.plan = json.loads((ROOT / "tools/gate_f/phase_plans/S03C.json").read_text(encoding="utf-8"))

    def derive(self):
        return GEN.derive(self.source, self.plan, self.text, self.template)

    def test_capture_originals_exact_debts_partitioned_and_no_terminal_save(self):
        phases, manifest = self.derive()
        self.assertEqual([s for p in phases for s in p["steps"] if "_phase_added" not in s], self.source["steps"])
        self.assertEqual([shot for p in phases for shot in p["owes"]], self.source["owes"])
        self.assertEqual(phases[-1]["phase"]["output_save"], "")
        self.assertTrue(phases[-1]["phase"]["terminal_capture"])
        self.assertFalse(any(s["action"] == "save_out" for s in phases[-1]["steps"]))
        self.assertEqual(manifest["canonical_output_save"], "")
        self.assertEqual(manifest["template_source_sha256"], GEN.normalized_sha256(self.template))
        for p in phases:
            for step in p["steps"]:
                if "_phase_added" in step:
                    self.assertEqual(step["_phase_added"]["template_source_sha256"], manifest["template_source_sha256"])

    def test_external_template_required_and_changes_invalidate_generated_contract(self):
        with self.assertRaisesRegex(ValueError, "template"):
            GEN.derive(self.source, self.plan, self.text)
        before = self.derive()[1]
        self.template += " \n"
        self.assertNotEqual(before["template_source_sha256"], self.derive()[1]["template_source_sha256"])

    def test_no_output_forbidden_for_logic_or_intermediate_capture_phase(self):
        self.source["evidence_lane"] = "logic"
        with self.assertRaisesRegex(ValueError, "final capture"):
            self.derive()
        self.source["evidence_lane"] = "capture"
        self.plan["phases"][0]["output_save"] = ""
        with self.assertRaisesRegex(ValueError, "nonterminal"):
            self.derive()

    def test_cuts_cannot_cross_record_or_background_sequence_windows(self):
        for action, args in [("record_start", {"hz": 5}),
                             ("capture_seq", {"id": "window", "seconds": 40, "hz": 5, "background": True})]:
            with self.subTest(action=action):
                source = copy.deepcopy(self.source)
                source["steps"].insert(1, {"id": "window-start", "action": action, "args": args})
                source["owes"] = GEN.planned_captures(source["steps"])
                with self.assertRaisesRegex(ValueError, "window"):
                    GEN.derive(source, self.plan, json.dumps(source), self.template)


if __name__ == "__main__":
    unittest.main()
