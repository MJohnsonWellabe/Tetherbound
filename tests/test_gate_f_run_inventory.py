"""Run completion needs segment verdicts as well as paid evidence debts."""
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


SPEC = importlib.util.spec_from_file_location(
    "run_inventory", Path(__file__).resolve().parents[1] / "tools/gate_f/run_inventory.py")
INVENTORY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(INVENTORY)


class RunInventoryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.git = patch.object(INVENTORY, "_git_ignored", return_value={}).start()
        self.addCleanup(patch.stopall)

    def segment(self, name, complete=True, captures=None):
        folder = self.root / name
        folder.mkdir(exist_ok=True)
        (folder / "INVENTORY.json").write_text(json.dumps({
            "complete": complete, "captures": captures or {}}), encoding="utf-8")

    def collect(self):
        return INVENTORY.collect(str(self.root))

    def main(self):
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            return INVENTORY.main(["run_inventory.py", str(self.root)])

    def test_empty_run_fails_and_explains_missing_inventory(self):
        self.assertFalse(self.collect()["complete"])
        self.assertEqual(self.main(), 1)
        self.assertIn("no segment INVENTORY.json", (self.root / "RUN_INCOMPLETE.md").read_text())

    def test_incomplete_segment_fails_even_with_no_capture_debt(self):
        self.segment("S02")
        self.segment("S03", False)
        report = self.collect()
        self.assertEqual(report["segments_incomplete"], ["S03"])
        self.assertFalse(report["complete"])
        self.assertEqual(self.main(), 1)
        self.assertIn("S03", (self.root / "RUN_INCOMPLETE.md").read_text())

    def test_missing_malformed_or_nonboolean_completion_fails(self):
        for value in [None, "true", 1, False]:
            with self.subTest(value=value):
                self.segment("S03", value)
                self.assertFalse(self.collect()["complete"])
        path = self.root / "S03/INVENTORY.json"
        for text in ["{}", "invalid json"]:
            path.write_text(text, encoding="utf-8")
            self.assertEqual(self.collect()["segments_incomplete"], ["S03"])

    def test_complete_selected_segment_passes_and_clears_stale_marker(self):
        self.segment("S03")
        (self.root / "RUN_INCOMPLETE.md").write_text("stale")
        report = self.collect()
        self.assertTrue(report["complete"])
        self.assertEqual(report["segments"], ["S03"])
        self.assertEqual(self.main(), 0)
        self.assertFalse((self.root / "RUN_INCOMPLETE.md").exists())

    def test_paid_capture_does_not_override_failed_segment(self):
        self.segment("S03", False, {"rows": [{"id": "frame", "file": "shots/frame.png", "exists": True}]})
        shots = self.root / "S03/shots"
        shots.mkdir()
        (shots / "frame.png").write_bytes(b"nonempty evidence fixture")
        report = self.collect()
        self.assertEqual(report["captures"]["present"], 1)
        self.assertFalse(report["complete"])

    def test_delegated_capture_and_git_checks_still_apply(self):
        self.segment("S03", captures={"delegated": ["frame"], "delegated_to": "S03C"})
        self.assertFalse(self.collect()["complete"])
        self.segment("S03C", captures={"rows": [{"id": "frame", "file": "frame.png", "exists": True}]})
        self.assertFalse(self.collect()["complete"])
        shot = self.root / "S03C/frame.png"
        shot.write_bytes(b"nonempty evidence fixture")
        self.assertTrue(self.collect()["complete"])
        self.git.return_value = {str(shot): "fixture ignored rule"}
        self.assertFalse(self.collect()["complete"])

    def test_legacy_complete_true_cannot_hide_failed_steps(self):
        self.segment("S03")
        path = self.root / "S03/INVENTORY.json"
        inventory = json.loads(path.read_text())
        inventory["steps"] = {"fail": 5, "skipped": 0, "refused": 0}
        path.write_text(json.dumps(inventory))
        report = self.collect()
        self.assertFalse(report["complete"])
        self.assertEqual(report["segments_incomplete"], ["S03"])
        self.assertIn("steps.fail", report["evidence_errors"]["S03"][0])


if __name__ == "__main__":
    unittest.main()
