import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("phase_aggregate", ROOT / "tools/gate_f/aggregate_segment_phases.py")
AGG = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(AGG)


class PhaseAggregateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.run = self.root / "run"
        self.defs = self.root / "definitions"
        source_text = (ROOT / "tools/gate_f/segments/S03.json").read_text(encoding="utf-8")
        self.source = json.loads(source_text)
        self.plan = AGG.read(ROOT / "tools/gate_f/phase_plans/S03.json")
        source_path = self.defs / "segments/S03.json"
        source_path.parent.mkdir(parents=True)
        source_path.write_text(source_text, encoding="utf-8", newline="\n")
        self.phases, self.manifest = AGG.GEN.derive(self.source, self.plan, source_text)
        self.write(self.defs / "phase_plans/S03.json", self.plan)
        self.write(self.defs / "phase_plans/S03.manifest.json", self.manifest)
        initial = self.run / "S02/saves/S02-exit.json"
        self.write(initial, {"production_fixture": "S02"})
        self.write(self.run / "S02/INVENTORY.json", {"sha": "explicitly-inherited-prefix"})
        previous = AGG.sha(initial)
        for index, phase in enumerate(self.phases):
            name = phase["id"]
            declaration = phase["phase"]
            self.write(self.defs / f"segments/{name}.json", phase)
            folder = self.run / name
            save = folder / "saves" / declaration["output_save"]
            self.write(save, {"production_fixture": name})
            receipt = copy.deepcopy(declaration)
            receipt.update(input_sha256=previous, output_sha256=AGG.sha(save), metrics={
                "distance_m": [180, 350, 500][index], "trace_rows": [400, 900, 1500][index],
                "dead_travel_m": [2, 3, 10][index], "dead_travel_peak": [5, 8, 20][index],
                "since_interaction_s": 3.0})
            previous = receipt["output_sha256"]
            self.write(folder / "INVENTORY.json", {
                "complete": True, "segment": name, "sha": "frozen-revision", "phase": receipt,
                "evidence_lane": "logic",
                "steps": {"total": len(phase["steps"]), "ran": len(phase["steps"]), "fail": 0, "skipped": 0, "refused": 0},
                "captures": {"delegated": declaration["capture_ids"], "delegated_to": "S03C"}})
            self.write(folder / "telemetry/events.jsonl", {"type": "note", "fixture": "no gameplay execution claimed"})
            notes = folder / "notes" / f"{name}.md"
            notes.parent.mkdir(parents=True)
            notes.write_text("".join(f"### {s['id']} — step\n- verdict: {'DELEGATED' if s['action'] in AGG.DELEGABLE else 'PASS'}\n"
                                     for s in phase["steps"]), encoding="utf-8")

    def tearDown(self):
        self.temp.cleanup()

    @staticmethod
    def write(path, obj):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(obj, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")

    def collect(self):
        return AGG.collect(self.run, self.defs, "S03")

    def change_inventory(self, phase_id, callback):
        path = self.run / phase_id / "INVENTORY.json"
        inv = AGG.read(path)
        callback(inv)
        self.write(path, inv)

    def test_exact_original_coverage_hash_chain_and_inherited_prefix_are_explicit(self):
        result = self.collect()
        self.assertEqual(result["original_step_ids"], [s["id"] for s in self.source["steps"]])
        self.assertEqual(result["delegated_captures"], AGG.GEN.planned_captures(self.source["steps"]))
        self.assertEqual(result["input_provenance"]["origins"][0]["source_revision"], "explicitly-inherited-prefix")
        self.assertFalse(result["analytics"]["stitched_telemetry"])
        self.assertTrue(all(r["inventory_path"] and r["events_path"] and r["notes_path"] for r in result["receipts"]))

    def test_missing_or_erased_capture_debt_cannot_publish_complete(self):
        self.change_inventory("S03p1", lambda inv: inv["captures"].update(delegated=[]))
        with self.assertRaisesRegex(ValueError, "capture debt"):
            self.collect()

    def test_mechanical_step_cannot_be_marked_delegated(self):
        path = self.run / "S03p1/notes/S03p1.md"
        path.write_text(path.read_text(encoding="utf-8").replace("- verdict: PASS", "- verdict: DELEGATED", 1), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "expected PASS"):
            self.collect()

    def test_missing_or_failed_step_notes_cannot_hide_behind_complete_inventory(self):
        path = self.run / "S03p3/notes/S03p3.md"
        path.write_text(path.read_text(encoding="utf-8").replace("- verdict: PASS", "- verdict: FAIL", 1), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "step verdict"):
            self.collect()
        path.write_text("", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "every phase step"):
            self.collect()

    def test_original_thresholds_are_independently_rechecked(self):
        for field, value in [("distance_m", 419), ("trace_rows", 1199), ("dead_travel_m", 151)]:
            path = self.run / "S03p3/INVENTORY.json"
            original = AGG.read(path)
            inv = copy.deepcopy(original)
            inv["phase"]["metrics"][field] = value
            inv["phase"]["metrics"]["dead_travel_peak"] = 200
            self.write(path, inv)
            with self.assertRaisesRegex(ValueError, "metric predicate"):
                self.collect()
            self.write(path, original)

    def test_missing_nonfinite_fractional_or_regressing_metrics_are_rejected(self):
        path = self.run / "S03p2/INVENTORY.json"
        original = AGG.read(path)
        for changed in [{}, {"distance_m": float("nan")}, {"trace_rows": 900.5}, {"distance_m": 1}]:
            inv = copy.deepcopy(original)
            if not changed:
                inv["phase"]["metrics"] = {}
            else:
                inv["phase"]["metrics"].update(changed)
            self.write(path, inv)
            with self.assertRaisesRegex(ValueError, "metrics"):
                self.collect()
        self.write(path, original)

    def test_actual_initial_artifact_and_every_phase_save_hash_are_required(self):
        initial = self.run / "S02/saves/S02-exit.json"
        original = initial.read_bytes()
        initial.unlink()
        with self.assertRaisesRegex(ValueError, "external input"):
            self.collect()
        initial.write_bytes(original)
        self.write(self.run / "S03p2/saves/S03p2-exit.json", {"tampered": True})
        with self.assertRaisesRegex(ValueError, "hash mismatch"):
            self.collect()

    def test_mixed_revision_wrong_input_name_and_broken_hash_chain_are_rejected(self):
        path = self.run / "S03p2/INVENTORY.json"
        original = AGG.read(path)
        for where, key, value, error in [("inventory", "sha", "another", "mixed source"),
                                       ("phase", "input_save", "wrong.json", "declaration"),
                                       ("phase", "input_sha256", "wrong", "continuity")]:
            inv = copy.deepcopy(original)
            (inv if where == "inventory" else inv["phase"])[key] = value
            self.write(path, inv)
            with self.assertRaisesRegex(ValueError, error):
                self.collect()
        self.write(path, original)

    def test_original_and_added_step_mutations_or_manifest_mutation_are_rejected(self):
        path = self.defs / "segments/S03p1.json"
        original = AGG.read(path)
        for index in [0, -1]:
            phase = copy.deepcopy(original)
            phase["steps"][index]["action"] = "teleport"
            self.write(path, phase)
            with self.assertRaisesRegex(ValueError, "canonical source/templates"):
                self.collect()
        self.write(path, original)
        manifest = copy.deepcopy(self.manifest)
        manifest["capture_ids"] = []
        self.write(self.defs / "phase_plans/S03.manifest.json", manifest)
        with self.assertRaisesRegex(ValueError, "manifest"):
            self.collect()

    def test_windows_crlf_source_hash_normalizes_without_json_reserialization(self):
        path = self.defs / "segments/S03.json"
        text = path.read_text(encoding="utf-8")
        path.write_bytes(text.replace("\n", "\r\n").encode("utf-8"))
        self.assertEqual(self.collect()["source_sha256"], self.manifest["source_sha256"])

    def test_publication_is_explicit_hash_exact_and_never_overwrites_evidence(self):
        result = AGG.publish(self.run, self.defs, "S03")
        target = self.run / "S03"
        inv = AGG.read(target / "INVENTORY.json")
        self.assertTrue(inv["complete"])
        self.assertEqual(inv["execution"], "save_linked_phases")
        self.assertEqual(AGG.sha(target / "saves/S03-exit.json"), result["exit_save_sha256"])
        self.assertFalse((target / "telemetry/events.jsonl").exists())
        before = (target / "INVENTORY.json").read_bytes()
        with self.assertRaisesRegex(ValueError, "overwrite"):
            AGG.publish(self.run, self.defs, "S03")
        self.assertEqual(before, (target / "INVENTORY.json").read_bytes())


if __name__ == "__main__":
    unittest.main()
