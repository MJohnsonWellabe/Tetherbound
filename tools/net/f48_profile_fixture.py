"""Produce DISCLOSED F48 mechanics starts, never earned checkpoint evidence.

Example (ROOT runs the engine separately after source/route review):
  python tools/net/f48_profile_fixture.py --source <actual-host-user-dir> \
      --source <actual-guest-user-dir> --layout <layout.json> --output <fresh-dir>

The required layout declares initial fixture station/actor positions. Terrain,
navigation, prompts and runtime gates still require actual native validation.
An optional --route-pack supplies independently reviewed ordinary routes and
fixed outcomes. Missing routes remain missing and the existing smoke fails.
No process, engine, production source, original save or receipt is changed.
"""
from __future__ import annotations

import argparse
import copy
import gzip
import hashlib
import json
import math
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STOCK = {"rootstone": 8, "ironwood": 4, "berries": 8,
         "attuned_ground": 2, "essence_ground": 100}
OPERATIONS = ("craft", "release", "feast", "key", "relic", "essence_spend")
INPUTS = {"press", "move_to", "stick", "wait", "f48_button"}
CONFIGS = ("data/config/stations.json", "data/config/essence.json",
           "data/config/traits.json", "data/config/multiplayer.json",
           "data/config/progression.json", "data/recipes/recipes_forge.json",
           "data/items/items.json")
PRODUCERS = ("scripts/net/session.gd", "scripts/ui/craft_panel.gd", "scripts/build/station_piece.gd",
             "autoload/world_state.gd")


def require(ok: bool, message: str) -> None:
    if not ok:
        raise ValueError(message)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read(path: Path) -> dict:
    data = path.read_bytes()
    if path.suffix == ".gz":
        data = gzip.decompress(data)
    row = json.loads(data)
    require(isinstance(row, dict), f"Expected object: {path}")
    return row


def write(path: Path, row: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    data = (json.dumps(row, indent=2, ensure_ascii=False, allow_nan=False) + "\n").encode()
    if path.suffix == ".gz":
        data = gzip.compress(data, mtime=0)
    # Output is a fresh offline fixture directory, never a live save target.
    path.write_bytes(data)


def one_document(directory: Path, name: str) -> Path:
    candidates = list(directory.glob(f"*/{name}.json")) + list(directory.glob(f"*/{name}.json.gz"))
    require(len(candidates) == 1, f"Require exactly one authentic {name} carrier in {directory}")
    return candidates[0]


def source_input(directory: Path, host: bool) -> dict:
    require(directory.is_dir(), f"Actual saved-input directory missing: {directory}")
    char_path = one_document(directory / "characters/redesign-v28", "character")
    char = read(char_path)
    identity = char.get("character_id")
    require(char.get("version") == 28 and identity == char_path.parent.name,
            "Require original version28 character identity/path, without migration")
    party = char.get("party")
    mirrors = char.get("redesign_character", {}).get("creatures", {})
    require(isinstance(party, list) and 1 <= len(party) <= 5, "Original owned party unavailable")
    uids = [card.get("uid") for card in party]
    require(all(isinstance(uid, str) and uid for uid in uids) and len(set(uids)) == len(uids),
            "Original owned creature identities must be distinct")
    require(set(mirrors) == set(uids), "Original canonical creature mirrors do not match owned party")
    result = {"root": directory, "character_path": char_path, "character": char,
              "id": identity, "uids": uids}
    if host:
        world_path = one_document(directory / "worlds/redesign-v28", "world")
        world = read(world_path)
        require(world.get("version") == 28 and world.get("world_id") == world_path.parent.name,
                "Require original version28 host world identity/path")
        slots = list((directory / "saves/redesign-v28").glob("slot_*.json"))
        slots += list((directory / "saves/redesign-v28").glob("slot_*.json.gz"))
        require(len(slots) == 1, "Require exactly one original host slot locator")
        locator = read(slots[0])
        require(locator.get("version") == 28 and locator.get("split_locator") ==
                {"character_id": identity, "world_id": world["world_id"]},
                "Original host slot locator must bind these actual carriers")
        result.update(world_path=world_path, world=world, slot_path=slots[0])
    return result


def vector(value: object) -> bool:
    return (isinstance(value, list) and len(value) == 3 and
            all(type(n) in (int, float) and math.isfinite(n) for n in value))


def layout_records(layout: dict, cfg: dict) -> list[dict]:
    require(isinstance(layout.get("provenance"), str) and bool(layout["provenance"]),
            "Disclose declared/measured initial pose origin in layout.provenance")
    require(type(layout.get("native_validated")) is bool, "Declare layout.native_validated honestly")
    records = []
    # Altar placement is bound to an authentic typed paid-building journal.
    # A disclosed fixture cannot fabricate that journal or substitute paid:true.
    for index, station in enumerate(("forge", "kitchen"), 1):
        at = layout.get("stations", {}).get(station)
        require(vector(at), f"Declare finite initial {station} fixture position")
        # Bounded yaw0 footprint only; this is not a terrain/physics validator.
        sx, _, sz = cfg["pieces"][station]["size_m"]
        margin = cfg["placement_clearance_m"]
        x0, x1 = at[0] - sx / 2 - margin, at[0] + sx / 2 + margin
        z0, z1 = at[2] - sz / 2 - margin, at[2] + sz / 2 + margin
        cx, cz = cfg["homestead_plot"]["centre"]
        width, depth = cfg["homestead_plot"]["size_m"]
        require(cx - width / 2 <= x0 <= x1 <= cx + width / 2 and
                cz - depth / 2 <= z0 <= z1 <= cz + depth / 2, "Fixture station outside home plot")
        for excluded in cfg["homestead_plot"]["exclusions"]:
            lo, hi = excluded["min"], excluded["max"]
            require(x1 < lo[0] or hi[0] < x0 or z1 < lo[1] or hi[1] < z0,
                    f"Fixture {station} overlaps exclusion {excluded['id']}")
        records.append({"uid": f"b{index}", "id": station, "paid": True,
                        "removed": False, "realm": "meadows", "position": at, "yaw_deg": 0})
    return records


def stock_inventory(original: list, items: dict) -> list:
    require(isinstance(original, list) and len(original) == 24, "Require original24slot inventory")
    slots = copy.deepcopy(original)
    for item, amount in STOCK.items():
        require(item in items and type(items[item].get("stack")) is int,
                f"Fixture stock must be canonical item: {item}")
        cap = items[item]["stack"]
        for stack in slots:
            if isinstance(stack, dict) and stack.get("id") == item:
                addition = min(amount, max(0, cap - stack["n"]))
                stack["n"] += addition
                amount -= addition
        for index, stack in enumerate(slots):
            if stack is None and amount:
                addition = min(amount, cap)
                slots[index] = {"id": item, "n": addition}
                amount -= addition
        require(amount == 0, "Fixture materials do not fit original inventory capacity")
    return slots


def input_step(step_action: str, **args) -> dict:
    return {"action": step_action, "args": args}


def prepare(layout: dict, station: str) -> list:
    at = layout["stations"][station]
    offset = read(ROOT / "data/config/stations.json")["pieces"][station]["prompt_offset"]
    return [input_step("move_to", x=at[0], z=at[2] + offset[2] + 0.8,
                       close_enough=0.25, budget_frames=2400),
            input_step("press", action="interact"), input_step("wait", frames=45)]


def validate_pack(pack: dict) -> None:
    require(set(pack) == {"provenance", "routes", "outcomes"}, "Route pack has unknown/missing fields")
    require(bool(pack["provenance"]) and isinstance(pack["provenance"], str), "Disclose independent route origin")
    require(isinstance(pack["routes"], dict) and isinstance(pack["outcomes"], dict), "Route pack objects required")
    for name, steps in pack["routes"].items():
        require(isinstance(steps, list) and 1 <= len(steps) <= 1000, f"Missing/bounded route: {name}")
        for step in steps:
            require(isinstance(step, dict) and set(step) == {"action", "args"} and
                    step["action"] in INPUTS and isinstance(step["args"], dict), "Ordinary input only")
            args = step["args"]
            require(not set(args) & {"intent", "receipt", "expect", "expect_data", "continue_on_fail"},
                    "Routes cannot inject intents, receipts or their own verdicts")
            for field in ("frames", "gap_frames", "budget_frames", "times"):
                if field in args:
                    require(type(args[field]) is int and 0 <= args[field] <= (120 if field == "times" else 10000),
                            f"Unbounded ordinary input: {name}/{field}")


def generate(sources: list[Path], layout_path: Path, output: Path, route_pack: Path | None, origin: str) -> dict:
    require(isinstance(origin, str) and bool(origin.strip()), "Disclose original native run and any earlier source setup")
    require(len(sources) in (2, 4), "Use two or four independently captured actual characters")
    require(not output.exists(), "Fresh output required; existing artifacts are never replaced")
    require(all(not output.is_relative_to(source) and not source.is_relative_to(output) for source in sources),
            "Fixture output must be disjoint from every original saved input")
    inputs = [source_input(source, index == 0) for index, source in enumerate(sources)]
    require(len({row["id"] for row in inputs}) == len(inputs), "Never clone/change character identities for peer count")
    all_uids = [uid for row in inputs for uid in row["uids"]]
    require(len(set(all_uids)) == len(all_uids), "Never clone/change owned creature identities")
    cfg = read(ROOT / "data/config/stations.json")
    layout = read(layout_path)
    records = layout_records(layout, cfg)
    require(inputs[0]["world"].get("placed_buildings") == [], "Bounded fixture requires originally empty station site")
    require(not any(isinstance(row, dict) and row.get("kind") in ("creature_training", "altar_building")
                    for row in inputs[0]["world"].get("reward_deliveries", {}).values()),
            "Initial stock/pose setup cannot rewrite a character bound to an existing full typed training after-state")
    require(vector(layout.get("stations", {}).get("altar")), "Declare planned actual Altar build target")
    require(vector(layout.get("actor_start")), "Declare finite initial actor fixture position")
    items = read(ROOT / "data/items/items.json")["items"]
    pack = read(route_pack) if route_pack else None
    if pack:
        validate_pack(pack)
    manifest = {"status": "OPEN_UNVALIDATED_MECHANICS_FIXTURE", "acceptance_credit": False,
                "earned_checkpoint": False, "original_input_origin": origin,
                "layout": {"path": str(layout_path), "sha256": digest(layout_path)},
                "source_files": {name: digest(ROOT / name) for name in CONFIGS + PRODUCERS},
                "inputs": [], "mutations": [], "gaps": []}
    routes = {"craft_prepare": prepare(layout, "forge"),
              "craft_commit": [input_step("f48_button", text="Refine Rootiron Ingot"), input_step("wait", frames=150)],
              "essence_spend_prepare": prepare(layout, "altar") + [input_step("f48_button", text="Creature training"), input_step("wait", frames=45)]}
    outcomes = {}
    profile = {"provenance": "DISCLOSED initial mechanics fixture: actual retained v28 characters/owned cards; "
               "added initial material stock, paid station records and starting pose. No earned campaign claim. "
               "Native producer, routes and terrain validation OPEN. See fixture-manifest.json. " + origin,
               "saves": [], "routes": routes, "outcomes": outcomes}
    output.mkdir(parents=True, exist_ok=False)
    for index, row in enumerate(inputs):
        destination = output / f"peer-{index}"
        char = copy.deepcopy(row["character"])
        char["inventory"] = stock_inventory(char["inventory"], items)
        pose = copy.deepcopy(char["player_pose"])
        pose.update(position=layout["actor_start"], realm="meadows")
        pose["traversal"].update(mode="grounded", realm="meadows", safe_anchor=layout["actor_start"], velocity=[0, 0, 0])
        char["player_pose"] = pose
        # All earned flags, receipts, catches, cards, cap/history and mirrors stay unchanged.
        require({key: value for key, value in char.items() if key not in ("inventory", "player_pose")} ==
                {key: value for key, value in row["character"].items() if key not in ("inventory", "player_pose")},
                "Fixture mutated undeclared personal progression")
        documents = [(row["character_path"], char)]
        if index == 0:
            world = copy.deepcopy(row["world"])
            world["placed_buildings"] = records
            documents += [(row["world_path"], world), (row["slot_path"], read(row["slot_path"]))]
        pinned = []
        for original, document in documents:
            relative = original.relative_to(row["root"])
            target = destination / relative
            write(target, document)
            pinned.append({"path": str(original), "sha256": digest(original),
                           "fixture_path": str(target), "fixture_sha256": digest(target)})
        manifest["inputs"].append({"peer": index, "character_id": row["id"], "owned_uids": row["uids"], "documents": pinned})
        manifest["mutations"].append({"peer": index, "initial_stock_added": STOCK, "initial_pose": pose,
                                      "initial_paid_stations": records if index == 0 else []})
        profile["saves"].append(str(destination))
        card = char["party"][0]
        mirror = char["redesign_character"]["creatures"][card["uid"]]
        # Fixed independent source expectation, not computed from an actual
        # producer reply or from a copied post-action save. Refuse repricing.
        essence = read(ROOT / "data/config/essence.json")
        progression = read(ROOT / "data/config/progression.json")
        pinned_curve = (progression["level"]["xp_to_next_base"] == 40 and
                        progression["level"]["xp_to_next_exponent"] == 1.15 and
                        essence["essence_xp_value"] == 25 and
                        essence["level_cost_bands"][0] == {"minimum_level": 1, "maximum_level": 10, "multiplier": 1.0})
        if card.get("species_id") == "terrapup" and card.get("level") == 9 and card.get("creature_type") == "ground" \
                and mirror.get("cap_level") == 10 and mirror.get("breakthroughs") == [] and pinned_curve:
            available = sum(stack["n"] for stack in char["inventory"] if isinstance(stack, dict) and stack["id"] == "essence_ground")
            if index == 1:
                routes["essence_spend_commit"] = [input_step("f48_button", text=f"Ground Essence · Cost 20 · Have {available}"),
                                                  input_step("wait", frames=120)]
            outcomes[f"essence_spend_{index}"] = {"item_delta": {"essence_ground": -20},
                "creature": {"uid": card["uid"], "level": 10, "breakthroughs": []},
                "equals": {f"redesign_character/creatures/{card['uid']}/cap_level": 10}}
        else:
            manifest["gaps"].append(f"peer{index}: fixed Terrapup9→10/cap10/20essence oracle prerequisite unavailable; no repricing")
        wild = [uid for uid, mirror in char["redesign_character"]["creatures"].items()
                if mirror.get("captured_from", {}).get("kind") == "wild"]
        if not wild:
            manifest["gaps"].append(f"peer{index}: no authentic caught wild companion for release; none fabricated")
    if pack:
        routes.update(pack["routes"])
        outcomes.update(pack["outcomes"])
        profile["provenance"] += " Independent route pack: " + pack["provenance"]
        manifest["route_pack"] = {"path": str(route_pack), "sha256": digest(route_pack)}
    for operation in OPERATIONS:
        for stage in ("prepare", "commit", "retry"):
            if f"{operation}_{stage}" not in routes:
                manifest["gaps"].append(f"Actual ordinary {operation}_{stage} route unavailable; existing smoke fails")
    for operation in ("release", "feast", "essence_spend"):
        if f"{operation}_1" not in outcomes:
            manifest["gaps"].append(f"Independent exact {operation}_1 oracle unavailable; existing smoke fails")
    for filename, paths in (("stations.json", ("runtime_enabled", "craft_runtime_enabled", "forge.runtime_enabled")),
                            ("essence.json", ("altar_runtime_enabled", "altar_remote_spend_enabled", "altar_building_runtime_enabled")),
                            ("traits.json", ("runtime_enabled",)),
                            ("multiplayer.json", ("session.redesign_portal_runtime_enabled", "session.redesign_boss_handoff_runtime_enabled"))):
        config = read(ROOT / "data/config" / filename)
        for path in paths:
            value = config
            for part in path.split("."):
                value = value.get(part) if isinstance(value, dict) else None
            if value is not True:
                manifest["gaps"].append(f"Production gate {filename}:{path} is not enabled; source unchanged")
    manifest["gaps"].append("Actual native terrain/interaction/transaction/BOOL-save/ACK/cut proof remains OPEN")
    manifest["gaps"].append("Altar station deliberately absent: actual ordinary paid build and authentic altar_building journal required; no fixture receipt")
    session_source = (ROOT / "scripts/net/session.gd").read_text(encoding="utf-8")
    for method in ("homestead_start_refining", "homestead_actor_context", "homestead_commit_refine_unit"):
        if re.search(r"^func " + re.escape(method) + r"\(", session_source, re.MULTILINE) is None:
            manifest["gaps"].append(f"Ordinary Forge producer Session.{method} source unavailable; candidate button cannot complete")
    manifest["gaps"].append("Kitchen remains tier0; Master win/recipe, boss key/relic and original retry routes are not fabricated")
    if "defeated_warden" in inputs[0]["world"].get("flags", {}).get("flags", []):
        manifest["gaps"].append("Original host legacy world already defeated Warden; no flag reset or new-loop boss eligibility claim")
    write(output / "profile.json", profile)
    manifest["profile_sha256"] = digest(output / "profile.json")
    write(output / "fixture-manifest.json", manifest)
    return manifest


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", action="append", required=True, type=Path)
    parser.add_argument("--layout", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--route-pack", type=Path)
    parser.add_argument("--origin", required=True, help="Original native run and disclosed earlier setup; never relabel as earned")
    args = parser.parse_args()
    try:
        manifest = generate([path.resolve() for path in args.source], args.layout.resolve(),
                            args.output.resolve(), args.route_pack.resolve() if args.route_pack else None, args.origin)
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(json.dumps({"ok": False, "error": str(error)}))
        return 1
    print(json.dumps({"artifact_written": True, "status": manifest["status"],
                      "acceptance_credit": False, "open_gaps": len(manifest["gaps"]),
                      "profile": str(args.output.resolve() / "profile.json")}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
