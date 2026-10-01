"""F37 non-engine audit. Never substitutes for native/player/device evidence."""
from pathlib import Path
import argparse
import hashlib
import json
import math
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
BASE = "7f18f5e75dc2744bb283bb1c3576da4e5d61b87d"

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path)
    args = parser.parse_args()
    checks = []
    def check(value, label):
        assert value, label
        checks.append(label)
    def read(path):
        return (ROOT / path).read_text(encoding="utf-8")
    def data(path):
        return json.loads(read(path))
    cfg = data("data/config/ripplet_traversal.json")
    species = data("data/creatures/species.json")["species"]["ripplet"]
    human = data("data/config/water_swimming.json")["human"]
    check(species["rideable"]["required_realm"] == "water", "Ripplet mount scoped to Tidewake")
    check(species["rideable"]["requires_item"] == species["swim_mount"]["requires_item"] == "", "No saddle or Stone gate")
    check(species["swim_mount"]["speed_mps"] == cfg["surface_speed_m_s"] > human["speed_m_s"], "Surface tuning is faster than human")
    check(species["swim_mount"]["stamina_capacity"] == cfg["stamina_capacity"], "Existing creature stamina carrier reused")
    check(0 <= cfg["current_multiplier"] < 1, "Ordinary-current resistance configured")
    check(cfg["dive_seconds"] == 20 and cfg["dive_depth_m"] < cfg["minimum_dive_depth_m"], "Bounded dive has seabed clearance")
    check(not cfg["presentation_enabled"], "Unjudged visual content remains flag-off")
    check(6 <= len(cfg["sites"]) + len(cfg["routes"]) <= 10, "Optional content within authored count")
    ids = [r["id"] for r in cfg["sites"] + cfg["routes"]]
    check(len(ids) == len(set(ids)), "Stable site and route identities unique")
    items = data("data/items/items.json")["items"]
    items.update(data("data/config/water_crafting.json")["item_registration_proposals"])
    for row in cfg["sites"]:
        check(row["item"] in items and row["count"] > 0, "Registered optional yield: " + row["id"])
        outputs = row.get("outputs",{row["item"]:row["count"]})
        check(all(item in items and item in ["tide_pearl", "essence_water", "attuned_water"] and count > 0 for item,count in outputs.items()), "Registered optional essence/ingredient yield: " + row["id"])
        check(row["kind"] in ["cache", "node"], "Typed sunken placement: " + row["id"])
        if row["kind"] == "node": check(row["respawn_days"] > 0, "Host-day respawn: " + row["id"])
    world = data("data/config/water_world.json")
    for row in cfg["sites"]:
        x, y, z = row["position"]
        nearest = min(math.hypot(x-r["center_xz_m"][0],z-r["center_xz_m"][1])-r["shore_radius_m"] for r in world["islands"])
        conservative_depth = nearest * world["terrain"].get("outer_shore_slope", .35)
        check(conservative_depth >= cfg["minimum_dive_depth_m"], "Base radial seabed clearance (not bake): " + row["id"])
        check(abs(y - (-cfg["dive_depth_m"] + species["water_mount_geometry"]["surface_origin_offset_m"] + species["rideable"]["mount_offset"][1])) < 3.6, "Authored pickup within submerged rider reach: " + row["id"])
    for row in cfg["routes"]:
        check(row["optional"] and row["radius_m"] > 0 and row["from"] != row["to"], "Optional ordinary-movement route: " + row["id"])
        check(row["speed_m_s"] > cfg["surface_speed_m_s"], "Submerged route value: " + row["id"])
    for path in ["data/config/water_world.json", "data/config/water_roster.json", "project.godot", "autoload/world_state.gd", "scripts/net/session.gd", "docs/STATE.md"]:
        old = subprocess.check_output(["git", "show", BASE + ":" + path], cwd=ROOT)
        check(old.replace(b"\r\n",b"\n") == (ROOT/path).read_bytes().replace(b"\r\n",b"\n"), "Required routes/shared carriers/defaults unchanged: " + path)
    gd_files = [
        "scripts/player/ripplet_traversal.gd", "scripts/world/ripplet_water_service.gd",
        "scripts/world/ripplet_sunken_rules.gd", "scripts/world/ripplet_sunken_content.gd",
        "scripts/player/swim_controller.gd", "scripts/save/water_traversal_save.gd",
        "scripts/world/riding_controller.gd", "scripts/world/water_riding_controller.gd",
        "scripts/world/water_mounted_swim.gd", "scripts/world/water_world.gd",
        "scripts/combat/water_encounter_director.gd", "scripts/net/world_ledger.gd",
        "scripts/net/ledger_rpc.gd", "tools/net/proof_peer_runner.gd",
        "tools/net/proof_steps_f37.gd", "tests/test_f37_ripplet_traversal.gd", "tests/smoke_f37_ripplet.gd",
    ]
    from gdtoolkit.parser import parser as gdparser
    hashes = {}
    for path in gd_files:
        source = read(path)
        gdparser.parse(source)
        check(True, "GDScript grammar parse (not Godot typecheck): " + path)
        hashes[path] = hashlib.sha256(source.encode()).hexdigest()
        for resource in re.findall(r'(?:preload|load)\("res://([^"\n]+)"\)',source):
            check((ROOT/resource).is_file(), "Static resource exists: " + resource)
    for path in ["docs/design/CREATURES.md","docs/design/SYSTEMS.md","docs/design/WORLD.md","docs/design/TRAINING.md","docs/design/UX.md","docs/design/MULTIPLAYER.md","docs/GAME_BIBLE.md"]:
        check(not re.search(r"Ripplet.{0,80}Teleport|Teleport.{0,80}Ripplet",read(path)),"No live Ripplet Teleport promise: " + path)
    report = {"kind":"non_engine_source_audit", "baseline":BASE, "head_before_commit":subprocess.check_output(["git","rev-parse","HEAD"],cwd=ROOT,text=True).strip(), "checks":checks, "count":len(checks), "source_sha256":hashes, "runtime":"PENDING ROOT queue; no Godot/import/render/export/device run", "criteria":"F37#0-4 OPEN; grammar/data/source preservation only"}
    if args.out:
        args.out.parent.mkdir(parents=True,exist_ok=True)
        args.out.write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    print(f"F37 source audit PASS: {len(checks)} checks; native and acceptance evidence pending")

if __name__ == "__main__": main()
