"""Check S03's authored harvest stops against production nodes, without Godot."""
import json
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
ITEM_PROMPTS = {
    "wood": "Gather deadwood",
    "fiber": "Strip meadow grass",
    "stone": "Prise loose stones",
    "berries": "Pick berries",
}


def read(relative):
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


class HarvestRoutes(unittest.TestCase):
    def test_each_scripted_gather_reaches_a_unique_authored_node_of_the_right_type(self):
        nodes = read("data/config/bands/band1_lower_meadows/harvest.json")["nodes"]
        for lane in ("S03", "S03C"):
            steps = read(f"tools/gate_f/segments/{lane}.json")["steps"]
            seen = set()
            checked = 0
            for index, step in enumerate(steps):
                if step["action"] != "move_to" or not step.get("title", "").startswith("gather "):
                    continue
                with self.subTest(lane=lane, step=step["id"]):
                    item = step["title"].split()[1]
                    at = tuple(step["args"]["at"])
                    matched = [n for n in nodes if tuple(n["at"]) == at and n["item"] == item]
                    self.assertEqual(len(matched), 1, f"No unique authored {item} node at {at}")
                    self.assertNotIn(at, seen, "Script would revisit a depleted node")
                    seen.add(at)
                    use = steps[index + 1]
                    self.assertEqual(use["action"], "interact_with")
                    self.assertEqual(use["args"]["expect_prompt"], matched[0]["label"])
                    self.assertEqual(matched[0]["label"], ITEM_PROMPTS[item])
                    self.assertEqual(matched[0]["amount"], 3 if item == "berries" else 4)
                    checked += 1
            self.assertEqual(checked, 20, "The same twenty gathering opportunities must remain")


if __name__ == "__main__":
    unittest.main()
