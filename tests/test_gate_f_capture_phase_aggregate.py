"""Real tiny PNGs inside clearly synthetic capture receipt fixtures; no engine."""
import copy
import importlib.util
import json
from pathlib import Path
import struct
import tempfile
import unittest
import zlib
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("capture_phase_aggregate", ROOT / "tools/gate_f/aggregate_segment_phases.py")
AGG = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(AGG)
RUN_SPEC = importlib.util.spec_from_file_location("capture_run_inventory", ROOT / "tools/gate_f/run_inventory.py")
RUN = importlib.util.module_from_spec(RUN_SPEC)
RUN_SPEC.loader.exec_module(RUN)


def tiny_png():
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xffffffff)
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(b"\0\x80\x40\x20")) + chunk(b"IEND", b""))


class CapturePhaseAggregate(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.run, self.defs = self.root / "run", self.root / "definitions"
        source_text = (ROOT / "tools/gate_f/segments/S03C.json").read_text(encoding="utf-8")
        template_text = (ROOT / "tools/gate_f/segments/S03.json").read_text(encoding="utf-8")
        self.source = json.loads(source_text)
        self.plan = AGG.read(ROOT / "tools/gate_f/phase_plans/S03C.json")
        self.text(self.defs / "segments/S03C.json", source_text)
        self.text(self.defs / "segments/S03.json", template_text)
        self.phases, manifest = AGG.GEN.derive(self.source, self.plan, source_text, template_text)
        self.write(self.defs / "phase_plans/S03C.json", self.plan)
        self.write(self.defs / "phase_plans/S03C.manifest.json", manifest)
        seed = self.run / "S02/saves/S02-exit.json"
        self.write(seed, {"fixture": "external inherited prefix"})
        previous = AGG.sha(seed)
        for index, phase in enumerate(self.phases):
            name, declaration = phase["id"], phase["phase"]
            folder = self.run / name
            self.write(self.defs / "segments" / (name + ".json"), phase)
            receipt = copy.deepcopy(declaration)
            receipt["input_sha256"] = previous
            receipt["output_sha256"] = ""
            if declaration["output_save"]:
                save = folder / "saves" / declaration["output_save"]
                self.write(save, {"fixture": name})
                previous = AGG.sha(save)
                receipt["output_sha256"] = previous
            receipt["metrics"] = {"distance_m": 20 * index, "trace_rows": 100 * index,
                                  "dead_travel_m": 0, "dead_travel_peak": 0, "since_interaction_s": 0}
            rows = []
            for step in phase["steps"]:
                for shot_id in AGG.GEN.planned_captures([step]):
                    relative = "shots/" + shot_id + ".png"
                    path = folder / relative
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_bytes(tiny_png())
                    rows.append({"id": shot_id, "step": step["id"], "action": step["action"],
                                 "file": relative, "bytes": path.stat().st_size, "exists": True, "reason": ""})
            self.write(folder / "shots/manifest.json", {"shots": rows})
            self.write(folder / "frames/manifest.json", {"frames": [], "written": 0, "absent": 0})
            self.write(folder / "INVENTORY.json", {"segment": name, "sha": "fixture-revision", "complete": True,
                "phase": receipt, "evidence_lane": "capture", "steps": {"total": len(phase["steps"]),
                "ran": len(phase["steps"]), "fail": 0, "skipped": 0, "refused": 0}, "captures": {
                "planned": len(rows), "present": len(rows), "absent": 0, "delegated": [],
                "owes": phase["owes"], "rows": rows}, "frames": {"written": 0, "absent": 0, "delegated_windows": []}})
            self.write(folder / "telemetry/events.jsonl", {"type": "note", "fixture": "not gameplay"})
            self.text(folder / "notes" / (name + ".md"), "".join(
                f"### {step['id']} — fixture\n- verdict: PASS\n" for step in phase["steps"]))

    @staticmethod
    def text(path, value):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(value, encoding="utf-8", newline="\n")

    def write(self, path, value):
        self.text(path, json.dumps(value) + "\n")

    def collect(self):
        return AGG.collect(self.run, self.defs, "S03C")

    def mutate(self, phase, callback):
        path = self.run / phase / "INVENTORY.json"
        value = AGG.read(path)
        callback(value)
        self.write(path, value)

    def test_exact_real_capture_union_terminal_no_save_and_raw_publication(self):
        result = self.collect()
        self.assertEqual([r["id"] for r in result["capture_rows"]], self.source["owes"])
        self.assertIsNone(result["exit_save_source"])
        self.assertEqual(result["exit_save_sha256"], "")
        self.assertTrue(all(r["sha256"] == AGG.sha(self.run / r["file"]) for r in result["capture_rows"]))
        AGG.publish(self.run, self.defs, "S03C")
        parent = self.run / "S03C"
        self.assertFalse((parent / "saves").exists())
        self.assertFalse((parent / "shots").exists())
        inv = AGG.read(parent / "INVENTORY.json")
        self.assertTrue(inv["complete"])
        self.assertEqual(inv["captures"]["path_scope"], "run_root")
        self.assertEqual(inv["captures"]["present"], 7)
        with self.assertRaisesRegex(ValueError, "overwrite"):
            AGG.publish(self.run, self.defs, "S03C")

    def test_missing_corrupt_png_and_wrong_byte_count_are_rejected(self):
        path = next((self.run / "S03Cp1/shots").glob("*.png"))
        original = path.read_bytes()
        for data in [b"not png", original[:-3], original[:20] + b"x" + original[21:]]:
            path.write_bytes(data)
            with self.assertRaises(ValueError): self.collect()
        path.unlink()
        with self.assertRaises(FileNotFoundError): self.collect()
        path.write_bytes(original)
        self.mutate("S03Cp1", lambda inv: inv["captures"]["rows"][0].update(bytes=1))
        with self.assertRaisesRegex(ValueError, "bytes"): self.collect()

    def test_delegated_capture_verdict_and_erased_debt_are_rejected(self):
        path = self.run / "S03Cp1/notes/S03Cp1.md"
        original = path.read_text(encoding="utf-8")
        step = next(s for s in self.phases[0]["steps"] if s["action"] == "capture")
        path.write_text(original.replace(f"### {step['id']} — fixture\n- verdict: PASS", f"### {step['id']} — fixture\n- verdict: DELEGATED"), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "expected PASS"): self.collect()
        path.write_text(original, encoding="utf-8")
        self.mutate("S03Cp1", lambda inv: inv["captures"].update(owes=[]))
        with self.assertRaisesRegex(ValueError, "capture IDs"): self.collect()

    def test_template_changed_or_terminal_output_claim_cannot_pass(self):
        template = self.defs / "segments/S03.json"
        original = template.read_text(encoding="utf-8")
        template.write_text(original + " ", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "manifest"): self.collect()
        template.write_text(original, encoding="utf-8")
        self.mutate("S03Cp3", lambda inv: inv["phase"].update(output_sha256="made-up"))
        with self.assertRaisesRegex(ValueError, "terminal capture"): self.collect()

    def test_terminal_input_chain_and_same_revision_are_still_required(self):
        path = self.run / "S03Cp3/INVENTORY.json"
        original = AGG.read(path)
        self.mutate("S03Cp3", lambda inv: inv["phase"].update(input_sha256="wrong"))
        with self.assertRaisesRegex(ValueError, "continuity"): self.collect()
        self.write(path, original)
        self.mutate("S03Cp3", lambda inv: inv.update(sha="different"))
        with self.assertRaisesRegex(ValueError, "revisions"): self.collect()

    def test_wrong_step_attribution_manifest_or_absent_recording_cannot_pass(self):
        path = self.run / "S03Cp1/INVENTORY.json"
        original = AGG.read(path)
        self.mutate("S03Cp1", lambda inv: inv["captures"]["rows"][0].update(step="unrelated"))
        with self.assertRaisesRegex(ValueError, "wrong step"): self.collect()
        self.write(path, original)
        self.mutate("S03Cp1", lambda inv: inv["frames"].update(absent=1))
        with self.assertRaisesRegex(ValueError, "frame ledger"): self.collect()
        self.write(path, original)
        self.write(self.run / "S03Cp1/shots/manifest.json", {"shots": []})
        with self.assertRaisesRegex(ValueError, "shot manifest"): self.collect()

    def test_capture_path_escape_and_reused_file_are_rejected(self):
        phase = next(p for p in self.phases if len(p["owes"]) >= 2)
        folder = self.run / phase["id"]
        inv = AGG.read(folder / "INVENTORY.json")
        shots = AGG.read(folder / "shots/manifest.json")
        inv["captures"]["rows"][1]["file"] = inv["captures"]["rows"][0]["file"]
        shots["shots"][1]["file"] = shots["shots"][0]["file"]
        self.write(folder / "INVENTORY.json", inv)
        self.write(folder / "shots/manifest.json", shots)
        with self.assertRaisesRegex(ValueError, "duplicate file"): self.collect()
        inv["captures"]["rows"][0]["file"] = "../outside.png"
        shots["shots"][0]["file"] = "../outside.png"
        self.write(folder / "INVENTORY.json", inv)
        self.write(folder / "shots/manifest.json", shots)
        with self.assertRaisesRegex(ValueError, "escapes"): self.collect()

    def test_run_inventory_counts_raw_captures_once_and_checks_aggregate_hashes(self):
        AGG.publish(self.run, self.defs, "S03C")
        with patch.object(RUN, "_git_ignored", return_value={}):
            report = RUN.collect(str(self.run))
            self.assertTrue(report["complete"], report["evidence_errors"])
            self.assertEqual(report["aggregate_aliases"], ["S03C"])
            self.assertEqual(report["captures"]["planned"], 7)
            self.assertTrue(all(len(row["taken_by"]) == 1 for row in report["captures"]["rows"]))
            self.assertTrue(all("S03C" not in row["owed_by"] for row in report["captures"]["rows"]))
            path = next((self.run / "S03Cp1/shots").glob("*.png"))
            data = bytearray(path.read_bytes())
            data[20] ^= 1
            path.write_bytes(data) # Still the same byte count; hash must detect it.
            report = RUN.collect(str(self.run))
            self.assertFalse(report["complete"])
            self.assertIn("S03C", report["segments_incomplete"])
            self.assertIn("SHA256", " ".join(report["evidence_errors"]["S03C"]))

    def test_run_inventory_refuses_escaped_alias_and_changed_raw_receipt(self):
        AGG.publish(self.run, self.defs, "S03C")
        path = self.run / "S03C/INVENTORY.json"
        original = AGG.read(path)
        changed = copy.deepcopy(original)
        changed["captures"]["rows"][0]["file"] = "../outside.png"
        changed["aggregate"]["capture_rows"][0]["file"] = "../outside.png"
        self.write(path, changed)
        with patch.object(RUN, "_git_ignored", return_value={}):
            self.assertFalse(RUN.collect(str(self.run))["complete"])
            self.write(path, original)
            self.mutate("S03Cp2", lambda inv: inv["steps"].update(fail=1))
            report = RUN.collect(str(self.run))
            self.assertFalse(report["complete"])
            self.assertIn("S03Cp2", report["segments_incomplete"])
            self.assertIn("S03C", report["segments_incomplete"])

    def test_recording_window_requires_real_frames_and_hashes_each_frame(self):
        phase = copy.deepcopy(self.phases[0])
        phase["steps"].append({"id": "fixture-window", "action": "record_start", "args": {"hz": 5}})
        folder = self.run / phase["id"]
        inv = AGG.read(folder / "INVENTORY.json")
        with self.assertRaisesRegex(ValueError, "no real frames"):
            AGG.verify_captures(self.run, folder, phase, inv)
        frame = folder / "frames/fixture.png"
        frame.write_bytes(tiny_png())
        self.write(folder / "frames/manifest.json", {"frames": [{"file": "frames/fixture.png",
            "segment": phase["id"], "t": 1}], "written": 1, "absent": 0})
        inv["frames"]["written"] = 1
        _, proofs = AGG.verify_captures(self.run, folder, phase, inv)
        self.assertEqual(proofs[0]["sha256"], AGG.sha(frame))
        self.assertEqual(proofs[0]["raw_phase"], phase["id"])


if __name__ == "__main__":
    unittest.main()
