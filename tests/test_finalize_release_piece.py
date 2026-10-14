"""Synthetic checkpoint packaging controls; no gameplay/export acceptance."""
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location("finalize_piece", Path(__file__).resolve().parents[1]
                                            / "tools/net/finalize_release_piece.py")
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class FinalizePieceTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix="piece-finalizer-UNIT-")
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.proof = self.root / "proof with spaces"
        capture = self.proof / "peer-0" / "after"
        for path in ["saves/redesign-v28/slot_0.json", "worlds/redesign-v28/world/world.json",
                     "characters/redesign-v28/owner/character.json"]:
            file = capture / path
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_text('{"synthetic":true}', encoding="utf-8")
        self.output = self.root / "checkpoint"
        self.data = {"passed": True, "exit_code": 0, "failures": [], "source_commit": "a" * 40,
                     "run_id": "synthetic", "scenario": {"peers": 4}, "rows": [
                         {"index": 1, "what": "piece_wait", "peer": 0, "ok": True, "verdict": "PASS",
                          "data": {"segment": "07b_calder", "done": True, "passed": True, "failures": []}},
                         {"index": 2, "what": "hashes_agree", "peer": 0, "ok": True, "verdict": "PASS"}]}
        for peer in range(4):
            self.data["rows"].append({"index": 3, "what": "capture_saves", "peer": peer, "ok": True,
                                      "verdict": "PASS", "data": {"owner_readback": True,
                                      "owner_error": "", "copy_errors": [], "files": 3,
                                      "world_written": peer == 0, "owns_world": peer == 0,
                                      "dir": str(capture), "file_sha256": {
                                          file.relative_to(capture).as_posix(): hashlib.sha256(file.read_bytes()).hexdigest()
                                          for file in capture.rglob("*") if file.is_file()},
                                      "handoff": {"uids": ["one"], "flags": [],
                                      "items": {"coin": 20}, "realm": "water", "training": {"party": []}}}})

    def run_finalizer(self, data=None, segment="07b_calder"):
        (self.proof / "PROOF.json").write_text(json.dumps(data or self.data), encoding="utf-8")
        return MODULE.finalize(self.proof, segment, self.output)

    def test_success_copies_original_bytes_and_pins_proof(self):
        receipt = self.run_finalizer()
        self.assertIs(receipt["passed"], True)
        self.assertEqual(receipt["after"]["items"], {"coin": 20})
        self.assertEqual(len(receipt["provenance"]["save_sha256"]), 3)
        self.assertEqual((self.output / "save/saves/redesign-v28/slot_0.json").read_text(), '{"synthetic":true}')
        with self.assertRaises(ValueError):
            self.run_finalizer()

    def test_failed_incomplete_or_stale_witnesses_refuse_before_output(self):
        variants = []
        for key, value in [("passed", "true"), ("exit_code", False), ("exit_code", 1),
                           ("failures", ["late failure"]), ("source_commit", "unknown")]:
            bad = copy.deepcopy(self.data)
            bad[key] = value
            variants.append(bad)
        for key, value in [("owner_readback", False), ("copy_errors", ["copy failed"]),
                           ("owner_error", "stale"), ("world_written", False), ("handoff", {}), ("file_sha256", {})]:
            bad = copy.deepcopy(self.data)
            bad["rows"][2]["data"][key] = value
            variants.append(bad)
        bad = copy.deepcopy(self.data)
        bad["rows"].pop()
        variants.append(bad)
        bad = copy.deepcopy(self.data)
        bad["rows"].pop(1)
        variants.append(bad)
        for bad in variants:
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                self.run_finalizer(bad)
            self.assertFalse(self.output.exists())

    def test_wrong_piece_or_capture_outside_proof_refuses(self):
        with self.assertRaises(ValueError):
            self.run_finalizer(segment="07c_venn")
        bad = copy.deepcopy(self.data)
        bad["rows"][2]["data"]["dir"] = str(self.root)
        with self.assertRaises(ValueError):
            self.run_finalizer(bad)
        self.assertFalse(self.output.exists())


if __name__ == "__main__":
    unittest.main()
