"""Non-engine syntax/catalog/schema audit. Never native acceptance evidence."""
import hashlib
import json
from pathlib import Path

from gdtoolkit.parser import parser
from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parents[3]
SCRIPTS = [
    "scripts/world/bounty_board.gd",
    "scripts/world/bounty_host_adapter.gd",
    "scripts/world/bounty_interaction_adapter.gd",
    "scripts/net/character_action_rules.gd",
    "scripts/data/redesign_state.gd",
    "tests/test_bounty_board.gd",
]


def read(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8-sig"))


def main():
    for path in SCRIPTS:
        parser.parse((ROOT / path).read_text(encoding="utf-8-sig"))
    cfg = read("data/config/bounties.json")
    items = read("data/items/items.json")["items"]
    items.update(read("data/config/water_crafting.json")["item_registration_proposals"])
    # Match ItemDB's actual constructor; flag-off F32 items are not runtime.
    f32 = read("data/items/f32_materials.json")
    if f32["runtime_enabled"]:
        items.update(f32["items"])
    traits = {row["id"] for row in read("data/schema/traits.json")}
    materials = {row["biome"]: set(row["raws"]) for row in read("data/schema/material_tiers.json")}
    templates = cfg["templates"]
    assert cfg["runtime_enabled"] is False
    assert cfg["board_count"] == 3
    assert len({row["id"] for row in templates}) == len(templates) == 16
    for biome in ["meadows", "tidewake", "cloudreach", "stormwood"]:
        assert {r["kind"] for r in templates if r["biome"] == biome} == {
            "catch_trait", "defeat_alpha", "material_delivery", "rematch"
        }
    for row in templates:
        if row["kind"] == "catch_trait":
            assert row["trait"] in traits
        if row["kind"] == "material_delivery":
            assert row["item"] in materials[row["biome"]]
            assert row["item"] in items and row["count"] > 0, row["item"]
        for reward in row["rewards"]:
            assert reward["id"] in items and reward["n"] > 0, reward["id"]
    schema = read("data/schema/character_state.schema.json")
    Draft202012Validator.check_schema(schema)
    validator = Draft202012Validator(schema)
    defaults = read("data/schema/character_state.json")
    validator.validate(defaults)
    older = defaults.copy()
    older.pop("bounties")
    validator.validate(older)
    board = {
        "anchor_world": "world-test", "anchor_day": 1, "cycle": 1,
        "slots": [{"instance": hashlib.sha256(str(i).encode()).hexdigest(),
                   "template": templates[i]["id"], "complete": False} for i in range(3)],
    }
    issued = dict(defaults, bounties=board)
    validator.validate(issued)
    preserved = json.loads(json.dumps(issued))
    assert preserved == issued
    board["slots"].pop()
    assert list(validator.iter_errors(issued)), "partial issued board must refuse"
    result = {
        "scope": "source_only", "native_acceptance": False,
        "parsed_scripts": SCRIPTS, "templates": len(templates),
        "catalog_references": "pass", "additive_v28_defaults": "pass",
        "old_v28_without_carrier": "pass", "issued_board_schema": "pass",
        "partial_board_refusal": "pass", "json_carrier_roundtrip": "pass",
        "godot_typecheck_unit_reconnect_and_player_path": "pending_shared_queue",
    }
    (Path(__file__).parent / "source-checks.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
