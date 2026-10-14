"""Synthetic launcher receipt checks only; no engine or release proof."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import subprocess
import sys
import copy

spec = importlib.util.spec_from_file_location("piece_receipt", Path(__file__).resolve().parents[1]
                                           / "tools/earned_saves/validate_piece_receipt.py")
receipt = importlib.util.module_from_spec(spec)
spec.loader.exec_module(receipt)


class PieceReceiptLauncherTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="piece-receipt-UNIT-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name) / "checkpoint with spaces"
        (self.root / "save").mkdir(parents=True)
        # Synthetic carrier: this fixture tests launch refusal, not save decoding.
        (self.root / "save" / "slot_0.json").write_text("{}", encoding="utf-8")
        self.good = {"passed": True, "segment": "07b_calder", "after": {"realm": "water"}}
        self.route = {**self.good, "after": {"realm": "water", "uids": [f"unit-{i}" for i in range(5)],
                      "flags": [], "items": {}, "training": {"version": 1, "party": []}}}

    def write(self, value):
        (self.root / "receipt.json").write_text(json.dumps(value), encoding="utf-8")

    def test_only_matching_saved_pass_is_accepted(self):
        self.write(self.good)
        self.assertEqual(receipt.validate(self.root, "07b_calder"), self.good)
        with self.assertRaises(ValueError):
            receipt.validate(self.root, "07c_venn")
        (self.root / "save" / "slot_0.json").unlink()
        (self.root / "save").rmdir()
        with self.assertRaises(ValueError):
            receipt.validate(self.root, "07b_calder")

    def test_truthy_verdicts_and_incomplete_receipts_refuse(self):
        invalid = [None, [], {}, *({**self.good, "passed": value} for value in (False, 1, "true", None)),
                   *({**self.good, "after": value} for value in (None, [], {}, "state")),
                   {key: value for key, value in self.good.items() if key != "segment"}]
        for value in invalid:
            with self.subTest(value=value):
                self.write(value)
                with self.assertRaises(ValueError):
                    receipt.validate(self.root, "07b_calder")

    def test_missing_or_malformed_receipt_refuses(self):
        with self.assertRaises(OSError):
            receipt.validate(self.root, "07b_calder")
        (self.root / "receipt.json").write_text('{"passed":true,', encoding="utf-8")
        with self.assertRaises(ValueError):
            receipt.validate(self.root, "07b_calder")

    def test_absent_empty_or_directory_save_carrier_refuses(self):
        self.write(self.good)
        slot = self.root / "save" / "slot_0.json"
        slot.write_bytes(b"")
        with self.assertRaises(ValueError):
            receipt.validate(self.root, "07b_calder")
        slot.unlink()
        with self.assertRaises(ValueError):
            receipt.validate(self.root, "07b_calder")
        slot.mkdir()
        with self.assertRaises(ValueError):
            receipt.validate(self.root, "07b_calder")

    def test_route_preflight_refuses_missing_or_malformed_witnesses(self):
        def check():
            return receipt.validate(self.root, "07b_calder", require_route_state=True,
                                    expected_realm="water")
        for field in self.route["after"]:
            value = copy.deepcopy(self.route)
            del value["after"][field]
            self.write(value)
            with self.subTest(missing=field), self.assertRaises(ValueError):
                check()
        malformed = {"uids": [["same"] * 5, ["unit"] * 4, [[], "b", "c", "d", "e"]],
                     "flags": [None, {}, [1]], "items": [None, [], {"apple": True}, {"apple": -1},
                                                              {"apple": 1.5}, {"apple": float("inf")}],
                     "realm": ["stormwood", "", None], "training": [{}, [], None]}
        for field, values in malformed.items():
            for bad in values:
                value = copy.deepcopy(self.route)
                value["after"][field] = bad
                self.write(value)
                with self.subTest(field=field, value=bad), self.assertRaises(ValueError):
                    check()
        for items in ({}, {"apple": 2}, {"apple": 2.0}):
            value = copy.deepcopy(self.route)
            value["after"]["items"] = items
            self.write(value)
            self.assertEqual(check(), value)

    def test_four_peer_generator_requires_complete_predecessor_receipt(self):
        generator = Path(__file__).resolve().parents[1] / "tools/net/release_four_peer_scenario.py"
        def generate():
            return subprocess.run([sys.executable, str(generator), "tidewake", "07c_venn",
                                   "--checkpoint", str(self.root)], capture_output=True, text=True, timeout=10)
        for invalid in ([], self.good, {**self.good, "after": {}}, {**self.good, "passed": "true"},
                        {**self.route, "after": {**self.route["after"], "realm": "stormwood"}}):
            with self.subTest(receipt=invalid):
                self.write(invalid)
                result = generate()
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(result.stdout, "")
                self.assertNotIn("Traceback", result.stderr)
        self.write(self.route)
        result = generate()
        self.assertEqual(result.returncode, 0, result.stderr)
        scenario = json.loads(result.stdout)
        self.assertEqual(scenario["steps"][0]["args"]["from"], self.root.as_posix() + "/save")
        self.assertEqual(scenario["steps"][0]["args"]["piece_receipt"], self.root.as_posix() + "/receipt.json")
        self.assertEqual(scenario["steps"][0]["args"]["piece_predecessor"], "07b_calder")
        self.assertEqual(scenario["peers"], 4)
        (self.root / "save" / "slot_0.json").unlink()
        result = generate()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertNotIn("Traceback", result.stderr)


if __name__ == "__main__":
    unittest.main()
