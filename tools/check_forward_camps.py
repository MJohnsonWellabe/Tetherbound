"""F34 non-engine data/source audit. Never reports runtime acceptance."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8-sig"))


def main():
    cfg = read("data/config/forward_camps.json")
    stations = read("data/config/stations.json")
    builds = read("data/items/buildables.json")
    assert cfg["runtime_enabled"] is True  # production gameplay enabled (data/config/forward_camps.json _scope)
    assert stations["forward_camp"]["maximum_per_character_per_biome"] == 1
    assert cfg["biomes"] == ["meadows", "tidewake", "cloudreach", "stormwood"]
    kit = cfg["recipes"]["forward_camp_kit"]
    assert kit["station_id"] == "workbench" and kit["station_tier"] == 0
    assert kit["cost"] == [{"id": "wood", "n": 8}, {"id": "fiber", "n": 6},
                           {"id": "stone", "n": 4}, {"id": "rootiron_ingot", "n": 1}]
    items = read("data/items/items.json")["items"]
    items.update(read("data/items/f32_materials.json").get("items", {}))
    for need in kit["cost"]:
        assert need["id"] in items, need["id"]
    assert kit["output"] == {"id": "forward_camp_kit", "n": 1}
    camp = builds["forward_camp_buildables"]
    assert len(camp) == 1 and camp[0]["id"] == "forward_camp"
    assert camp[0]["cost"] == [{"id": "forward_camp_kit", "n": 1}]
    assert "forward_camp" not in [row["id"] for row in builds["buildables"]]
    assert "forward_camp_kit" not in stations["recipe_routes"]["field_allowed"]
    files = ["autoload/game_state.gd", "autoload/item_db.gd", "scripts/build/build_placer.gd",
             "scripts/build/station_actions.gd", "scripts/net/world_ledger.gd",
             "scripts/ui/craft_panel.gd", "scripts/build/forward_camp.gd",
             "scripts/build/forward_camp_rules.gd", "scripts/build/forward_camp_actions.gd",
             "scripts/build/forward_camp_host.gd", "tests/test_forward_camp.gd",
             "tools/capture_forward_camp.gd"]
    for path in files:
        text = (ROOT / path).read_text(encoding="utf-8-sig")
        for resource in re.findall(r'preload\("res://([^"\n]+)"\)', text):
            assert (ROOT / resource).is_file(), (path, resource)
    # Optional grammar parser. This is not Godot typechecking or execution.
    from gdtoolkit.parser import parser
    for path in files:
        parser.parse((ROOT / path).read_text(encoding="utf-8-sig"))
    print(json.dumps({"check": "F34 static data/preload/grammar", "result": "PASS",
                      "gdscript_files": len(files), "runtime_acceptance": False}))


if __name__ == "__main__":
    main()
