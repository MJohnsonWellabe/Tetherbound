"""Synthetic checkpoint packaging controls; no gameplay/export acceptance."""
import base64
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
                         {"index": 1, "what": "load_save", "peer": 0, "ok": True, "verdict": "PASS",
                          "data": {"loaded_from": "retained/checkpoint/save", "predecessor": {
                              "save_directory": "retained/checkpoint/save", "save_sha256": {"slot_0.json": "b" * 64},
                              "receipt": {"present": False}, "provenance": {"present": False}}}},
                         {"index": 2, "what": "piece_wait", "peer": 0, "ok": True, "verdict": "PASS",
                          "data": {"segment": "07b_calder", "done": True, "passed": True, "failures": []}},
                         {"index": 3, "what": "hashes_agree", "peer": 0, "ok": True, "verdict": "PASS"}]}
        for peer in range(4):
            self.data["rows"].append({"index": 4, "what": "capture_saves", "peer": peer, "ok": True,
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
            bad["rows"][3]["data"][key] = value
            variants.append(bad)
        bad = copy.deepcopy(self.data)
        bad["rows"].pop()
        variants.append(bad)
        bad = copy.deepcopy(self.data)
        bad["rows"].pop(2)
        variants.append(bad)
        for bad in variants:
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                self.run_finalizer(bad)
            self.assertFalse(self.output.exists())

    def test_wrong_piece_or_capture_outside_proof_refuses(self):
        with self.assertRaises(ValueError):
            self.run_finalizer(segment="07c_venn")
        bad = copy.deepcopy(self.data)
        bad["rows"][3]["data"]["dir"] = str(self.root)
        with self.assertRaises(ValueError):
            self.run_finalizer(bad)
        self.assertFalse(self.output.exists())

    def set_metadata(self, key, document):
        raw = json.dumps(document, indent=2).encode("utf-8") + b"\r\n"
        self.data["rows"][0]["data"]["predecessor"][key] = {
            "present": True, "sha256": hashlib.sha256(raw).hexdigest(),
            "bytes_base64": base64.b64encode(raw).decode("ascii")}
        return raw

    def test_generated_predecessor_retains_exact_metadata_and_known_origins(self):
        prior = {"input_mode": "earned", "lineage": {"version": 1, "status": "generated",
                 "continuous_fresh_save": False, "origins": ["original generated arrival"]}}
        receipt_bytes = self.set_metadata("receipt", prior)
        fixture = Path(__file__).parent / "fixtures/earned_saves/tidewake_05_tidal/PROVENANCE.json"
        provenance_bytes = self.set_metadata("provenance", json.loads(fixture.read_text(encoding="utf-8")))
        receipt = self.run_finalizer()
        self.assertEqual(receipt["input_mode"], "generated_ancestry")
        self.assertFalse(receipt["lineage"]["continuous_fresh_save"])
        self.assertIn("original generated arrival", receipt["lineage"]["origins"])
        self.assertIn("legacy PROVENANCE declares generated ancestry", receipt["lineage"]["origins"])
        for key, name, raw in [("receipt", "receipt.json", receipt_bytes),
                               ("provenance", "PROVENANCE.json", provenance_bytes)]:
            self.assertEqual((self.output / "predecessor" / name).read_bytes(), raw)
            self.assertEqual(receipt["provenance"]["predecessor"][key]["sha256"], hashlib.sha256(raw).hexdigest())
        provenance = json.loads((self.output / "PROVENANCE.json").read_text())
        self.assertEqual(provenance["lineage"], receipt["lineage"])
        descendant = MODULE.inherited_lineage(receipt, provenance)
        self.assertEqual(descendant["status"], "generated")
        self.assertIn("original generated arrival", descendant["origins"])
        self.assertEqual(prior["lineage"]["origins"], ["original generated arrival"])

    def test_missing_lineage_never_fabricates_earned(self):
        self.set_metadata("receipt", {"input_mode": "earned", "passed": True})
        receipt = self.run_finalizer()
        self.assertEqual(receipt["input_mode"], "unproven_ancestry")
        self.assertEqual(receipt["lineage"]["status"], "unproven")
        self.assertEqual(MODULE.inherited_lineage({}, {})["status"], "unproven")
        earned = {"version": 1, "status": "earned", "continuous_fresh_save": True, "origins": []}
        self.assertEqual(MODULE.inherited_lineage({"lineage": earned}, {})["status"], "earned")
        self.assertEqual(MODULE.inherited_lineage({"lineage": earned}, {"prior_earned_play": False})["status"], "generated")

    def test_current_generated_guest_setup_overrides_inherited_earned(self):
        earned = {"version": 1, "status": "earned", "continuous_fresh_save": True, "origins": []}
        self.set_metadata("receipt", {"lineage": earned, "input_mode": "earned"})
        self.data["scenario"]["steps"] = [
            {"peer": 1, "action": "party_grant", "args": {"species": "terrapup", "level": 18}},
            {"peer": 1, "action": "story_flag", "args": {"flag": "realm_key_water"}},
            {"peer": 1, "action": "enter_realm", "args": {"actual_portal_fixture": "initial_hall_position"}},
            {"peer": 0, "action": "wait"}]
        receipt = self.run_finalizer()
        self.assertEqual(receipt["input_mode"], "generated_ancestry")
        self.assertFalse(receipt["lineage"]["continuous_fresh_save"])
        self.assertEqual(len(receipt["lineage"]["origins"]), 3)
        for action in ["party_grant", "story_flag", "enter_realm"]:
            self.assertTrue(any(action in origin for origin in receipt["lineage"]["origins"]))
        descendant = MODULE.inherited_lineage(receipt, receipt["provenance"])
        for origin in receipt["lineage"]["origins"]:
            self.assertIn(origin, descendant["origins"])

    def test_missing_or_corrupt_actual_host_predecessor_refuses_before_output(self):
        self.set_metadata("receipt", {"input_mode": "generated_arrival"})
        variants = []
        for change in ("missing", "guest", "duplicate", "late", "different_directory", "hash", "missing_presence"):
            bad = copy.deepcopy(self.data)
            load = bad["rows"][0]
            if change == "missing": bad["rows"].pop(0)
            elif change == "guest": load["peer"] = 1
            elif change == "duplicate": bad["rows"].append(copy.deepcopy(load))
            elif change == "late": load["index"] = 5
            elif change == "different_directory": load["data"]["loaded_from"] = "another/save"
            elif change == "hash": load["data"]["predecessor"]["receipt"]["sha256"] = "c" * 64
            elif change == "missing_presence": del load["data"]["predecessor"]["provenance"]
            variants.append((change, bad))
        for change, bad in variants:
            with self.subTest(change=change), self.assertRaises(ValueError):
                self.run_finalizer(bad)
            self.assertFalse(self.output.exists())


if __name__ == "__main__":
    unittest.main()
