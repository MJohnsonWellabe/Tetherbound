"""Night encounter composition and inherited wait budget; no engine or saves."""
import json
import math
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class NightFight(unittest.TestCase):
    def setUp(self):
        source = json.loads((ROOT / "tools/gate_f/segments/S03.json").read_text())
        self.steps = {step["id"]: step for step in source["steps"]}

    def test_selected_live_target_is_required_before_prescribed_capture(self):
        approach = self.steps["S03-217"]
        self.assertEqual(approach["action"], "move_to_entity")
        self.assertEqual(approach["args"]["within"], 2.0)
        self.assertTrue(approach["args"]["require_alive"])
        self.assertTrue(approach["args"]["require_engage_prompt"])
        engage = self.steps["S03-218"]
        self.assertEqual(engage["action"], "interact_with")
        self.assertTrue(engage["args"]["require_selected_engage"])
        self.assertFalse(engage["args"].get("optional", False))
        capture = self.steps["S03-220"]
        self.assertEqual(capture["action"], "capture")
        self.assertEqual(capture["args"]["id"], "GF-14-COMBAT-13a")
        self.assertIn("torch", capture["args"]["trigger"])

    def test_victory_is_bounded_by_replaced_attack_and_wait_allowance(self):
        fight = self.steps["S03-221"]
        self.assertEqual(fight["action"], "fight_until_resolved")
        args = fight["args"]
        self.assertTrue(args["require_victory"])
        previous_physics = 22 * 2 + 8 * 60
        previous_process = 22 * (2 + 30)
        # The existing FrameBudget fight pricing, including overshoot/edges.
        physics = args["budget_frames"] + args["gap_frames"] + 2
        process = 2 * math.ceil(args["budget_frames"] / (args["gap_frames"] + 3))
        self.assertLessEqual(physics + process, previous_physics + previous_process)
        self.assertGreaterEqual(args["quiet_frames"], 30)
        self.assertEqual(self.steps["S03-222"]["action"], "assert")
        self.assertEqual(self.steps["S03-222"]["args"], {"check": "combat_running", "equals": False})


if __name__ == "__main__":
    unittest.main()
