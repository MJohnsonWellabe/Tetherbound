"""Produce DISCLOSED F48 mechanics starts, never earned checkpoint evidence.

Example (ROOT runs the engine separately after source/route review):
  python tools/net/f48_profile_fixture.py --source <actual-host-user-dir> \
      --source <actual-guest-user-dir> --layout <layout.json> --output <fresh-dir> --origin <source-description>

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
import save_document

ROOT = Path(__file__).resolve().parents[2]
STOCK = {"stone": 10, "rootstone": 8, "ironwood": 4, "berries": 8,
         "attuned_ground": 2, "essence_ground": 100}
OPERATIONS = ("craft", "release", "feast", "key", "relic", "essence_spend")
PREBOSS_LEGACY_FLAGS = ("defeated_warden", "realm_key_cloudreach", "realm_heart_meadows_earned")
INPUTS = {"press", "move_to", "stick", "wait", "f48_button", "f48_build_cell", "f48_choice", "f48_fixture_trainer_fight", "f48_fixture_approach", "f48_fixture_join_boss"}
CONFIGS = ("data/config/stations.json", "data/config/essence.json",
           "data/config/traits.json", "data/config/multiplayer.json",
           "data/config/hud.json",
           "data/config/alpha_respawns.json",
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
    row = save_document.decode(json.loads(data))
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


def stock_inventory(original: list, items: dict, stock: dict | None = None) -> list:
    require(isinstance(original, list) and len(original) == 24, "Require original24slot inventory")
    slots = copy.deepcopy(original)
    for item, amount in (STOCK if stock is None else stock).items():
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


def preboss_legacy_world(inputs: list[dict]) -> tuple[dict, dict]:
    """Explicit initial mechanics setup, never resurrect an accepted typed win.

    Only three legacy world gates differ in the detached copy. Personal state,
    accepted legacy rewards, XP receipts and the original namespace remain.
    The production boss must still create its actual first typed event/receipt.
    """
    original = inputs[0]["world"]
    journals = original.get("reward_deliveries")
    require(isinstance(journals, dict), "Require the original complete journal")
    # This deliberately refuses ALL redesigned journal kinds, including a
    # retained foundation event whose boss duty has not reached its owner yet.
    require(all(isinstance(row, dict) and row.get("version") == 1 and
                not any(field in row for field in ("kind", "action", "duties", "after", "host_context"))
                for row in journals.values()),
            "Pre-boss legacy setup refuses any retained typed event or owner decision")
    for source in inputs:
        character = source["character"]
        personal = character["redesign_character"]
        require(personal.get("transaction_receipts") == [] and
                personal.get("relics_held") == [] and personal.get("relics_hung") == [] and
                personal.get("portal_unlocks") == [] and
                not any(isinstance(stack, dict) and stack.get("id") == "tidewake_portal_key"
                        and stack.get("n", 0) > 0 for stack in character["inventory"]),
                "Pre-boss legacy setup refuses any personal typed progression or boss entitlement")
    flags = original.get("flags", {}).get("flags")
    require(isinstance(flags, list) and all(isinstance(flag, str) for flag in flags) and
            len(set(flags)) == len(flags), "Require exact distinct original world flags")
    require("defeated_warden" in flags, "This explicit option is only for a legacy-completed mechanics source")
    result = copy.deepcopy(original)
    result["flags"]["flags"] = [flag for flag in flags if flag not in PREBOSS_LEGACY_FLAGS]
    require({key: value for key, value in result.items() if key != "flags"} ==
            {key: value for key, value in original.items() if key != "flags"} and
            {key: value for key, value in result["flags"].items() if key != "flags"} ==
            {key: value for key, value in original["flags"].items() if key != "flags"},
            "Pre-boss setup changed an undeclared world carrier")
    return result, {"scope": "DISCLOSED initial pre-boss mechanics setup, not earned progression",
                    "removed_legacy_world_flags": [flag for flag in flags if flag in PREBOSS_LEGACY_FLAGS],
                    "original_world_flags": flags, "initial_world_flags": result["flags"]["flags"],
                    "retained_journal_sha256": hashlib.sha256(json.dumps(journals, sort_keys=True,
                                                    separators=(",", ":"), allow_nan=False).encode()).hexdigest(),
                    "preserved": "Every original journal row, namespace, XP flag, character and owner receipt; no typed prior win"}


def generate(sources: list[Path], layout_path: Path, output: Path, route_pack: Path | None, origin: str,
             configuration_scope: str = "bootstrap", preboss_legacy_mechanics: bool = False,
             initial_kitchen_meadows_attachment: bool = False,
             initial_alpha_capture_orb: bool = False) -> dict:
    require(isinstance(origin, str) and bool(origin.strip()), "Disclose original native run and any earlier source setup")
    require(configuration_scope in ("bootstrap", "full"), "Unknown disclosed configuration scope")
    require(len(sources) in (2, 4), "Use two or four independently captured actual characters")
    require(not output.exists(), "Fresh output required; existing artifacts are never replaced")
    require(all(not output.is_relative_to(source) and not source.is_relative_to(output) for source in sources),
            "Fixture output must be disjoint from every original saved input")
    inputs = [source_input(source, index == 0) for index, source in enumerate(sources)]
    require(len({row["id"] for row in inputs}) == len(inputs), "Never clone/change character identities for peer count")
    all_uids = [uid for row in inputs for uid in row["uids"]]
    require(len(set(all_uids)) == len(all_uids), "Never clone/change owned creature identities")
    initial_world, preboss_disclosure = (preboss_legacy_world(inputs) if preboss_legacy_mechanics
                                       else (copy.deepcopy(inputs[0]["world"]), None))
    cfg = read(ROOT / "data/config/stations.json")
    layout = read(layout_path)
    records = layout_records(layout, cfg)
    kitchen_fixture = None
    if initial_kitchen_meadows_attachment:
        require(preboss_legacy_mechanics, "Initial Kitchen fixture requires strictly checked pre-boss typed-history absence")
        definitions = [row for row in cfg["attachments"] if row.get("id") == "kitchen_meadows"]
        require(len(definitions) == 1 and definitions[0].get("station_id") == "kitchen" and
                definitions[0].get("tier") == 1 and definitions[0].get("status") == "live" and
                definitions[0].get("registered") is True,
                "Actual first Meadows Kitchen attachment unavailable")
        parent = next(row for row in records if row["id"] == "kitchen")
        require(parent["yaw_deg"] == 0, "Bounded initial Kitchen socket requires disclosed yaw0")
        position = list(parent["position"])
        position[0] -= cfg["pieces"]["kitchen"]["size_m"][0] / 2 + cfg["attachment_spacing_m"]
        attachment = {"uid": "b3", "id": "kitchen_meadows", "paid": True, "removed": False,
                      "realm": "meadows", "position": position, "yaw_deg": 0,
                      "parent_uid": parent["uid"], "slot": 1}
        records.append(attachment)
        kitchen_fixture = {"scope": "DISCLOSED initial station attachment fixture; no earned payment or build transaction",
                           "record": attachment, "authored_cost_not_claimed_paid": definitions[0]["cost"],
                           "source_socket": "Actual StationRules.socket tier1 at yaw0: parentX−halfWidth−attachmentSpacing",
                           "personal_recipes_changed": False, "receipt_or_journal_created": False}
    require(inputs[0]["world"].get("placed_buildings") == [], "Bounded fixture requires originally empty station site")
    require(not any(isinstance(row, dict) and row.get("kind") in ("creature_training", "altar_building")
                    for row in inputs[0]["world"].get("reward_deliveries", {}).values()),
            "Initial stock/pose setup cannot rewrite a character bound to an existing full typed training after-state")
    require(vector(layout.get("stations", {}).get("altar")), "Declare planned actual Altar build target")
    require(vector(layout.get("actor_start")), "Declare finite initial actor fixture position")
    items = read(ROOT / "data/items/items.json")["items"]
    initial_stock = dict(STOCK)
    if initial_alpha_capture_orb:
        require(preboss_legacy_mechanics, "Capture orb stock must precede every typed producer journal")
        initial_stock["orb_basic"] = 1
    pack = read(route_pack) if route_pack else None
    if pack:
        validate_pack(pack)
    manifest = {"status": "OPEN_UNVALIDATED_MECHANICS_FIXTURE", "acceptance_credit": False,
                "earned_checkpoint": False, "original_input_origin": origin,
                "layout": {"path": str(layout_path), "sha256": digest(layout_path)},
                "source_files": {name: digest(ROOT / name) for name in CONFIGS + PRODUCERS},
                "inputs": [], "mutations": [], "gaps": []}
    routes = {"bootstrap_altar": [input_step("press", action="build_open"), input_step("wait", frames=30),
              input_step("f48_button", text="  Crafting"), input_step("wait", frames=15),
              input_step("f48_build_cell", id="altar"), input_step("wait", frames=30),
              input_step("press", action="build_place"), input_step("wait", frames=180),
              input_step("press", action="build_cancel")],
              "craft_prepare": prepare(layout, "forge"),
              "craft_reopen": prepare(layout, "forge"),
              "craft_commit": [input_step("f48_button", text="Refine Rootiron Ingot"), input_step("wait", frames=150)],
              "essence_spend_prepare": prepare(layout, "altar") + [input_step("f48_button", text="Creature training"), input_step("wait", frames=45)],
              "essence_spend_reopen": prepare(layout, "altar") + [input_step("f48_button", text="Creature training"), input_step("wait", frames=45)]}
    outcomes = {}
    profile = {"provenance": "DISCLOSED initial mechanics fixture: actual retained v28 characters/owned cards; "
               "added initial material stock, paid station records and starting pose. No earned campaign claim. "
               "Native producer, routes and terrain validation OPEN. See fixture-manifest.json. " + origin,
               "saves": [], "routes": routes, "outcomes": outcomes}
    if preboss_disclosure:
        manifest["preboss_legacy_mechanics"] = preboss_disclosure
        profile["provenance"] += " Explicit pre-boss legacy mechanics gates removed only in detached initial fixture; original rewards and all personal data retained."
    if kitchen_fixture:
        manifest["initial_kitchen_meadows_attachment_fixture"] = kitchen_fixture
        profile["provenance"] += " INITIAL Kitchen Spice rack attachment is a disclosed mechanics station fixture, not an earned upgrade/payment/transaction; real Master recipe, cooking and feed still required."
    if initial_alpha_capture_orb:
        profile["provenance"] += " One initial Basic Orb per actual character is disclosed stock for the real catch producer, never a caught companion or provenance grant."
    output.mkdir(parents=True, exist_ok=False)
    for index, row in enumerate(inputs):
        destination = output / f"peer-{index}"
        char = copy.deepcopy(row["character"])
        char["inventory"] = stock_inventory(char["inventory"], items, initial_stock)
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
            world = copy.deepcopy(initial_world)
            world["placed_buildings"] = records
            documents += [(row["world_path"], world), (row["slot_path"], read(row["slot_path"]))]
        pinned = []
        for original, document in documents:
            relative = original.relative_to(row["root"])
            target = destination / relative
            write(target, save_document.encode(document))
            pinned.append({"path": str(original), "sha256": digest(original),
                           "fixture_path": str(target), "fixture_sha256": digest(target)})
        manifest["inputs"].append({"peer": index, "character_id": row["id"], "owned_uids": row["uids"], "documents": pinned})
        manifest["mutations"].append({"peer": index, "initial_stock_added": initial_stock, "initial_pose": pose,
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
        for stage in ("prepare", "commit", "reopen"):
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
    manifest["gaps"].append("Master win/recipe, boss key/relic and ordinary reopen routes are not fabricated" +
                            ("; Kitchen remains tier0" if not kitchen_fixture else "; INITIAL Kitchen tier1 is separately disclosed, not earned"))
    if "defeated_warden" in initial_world.get("flags", {}).get("flags", []):
        manifest["gaps"].append("Original host legacy world already defeated Warden; no flag reset or new-loop boss eligibility claim")
    # Export a separately pinned test overlay; do not change production defaults.
    # ROOT applies these exact bytes only in its serialized isolated native
    # candidate. A bootstrap run refuses different effective configuration.
    configuration = []
    overrides = {"stations.json": ["runtime_enabled"],
                 "essence.json": ["altar_runtime_enabled", "altar_building_runtime_enabled"]}
    if configuration_scope == "full":
        overrides["stations.json"] += ["craft_runtime_enabled", "forge.runtime_enabled"]
        overrides["essence.json"].append("altar_remote_spend_enabled")
        overrides.update({"traits.json": ["runtime_enabled"],
                          "multiplayer.json": ["session.redesign_portal_runtime_enabled",
                                               "session.redesign_boss_handoff_runtime_enabled"],
                          "hud.json": ["new_system_screens.enabled"],
                          "alpha_respawns.json": ["runtime_enabled"]})
    for name, fields in overrides.items():
        source = ROOT / "data/config" / name
        effective = read(source)
        for field in fields:
            owner = effective
            components = field.split(".")
            for component in components[:-1]:
                require(isinstance(owner.get(component), dict), f"Missing mechanics configuration section: {name}/{field}")
                owner = owner[component]
            require(type(owner.get(components[-1])) is bool, f"Missing typed mechanics gate: {name}/{field}")
            owner[components[-1]] = True
        target = output / "test-configuration/data/config" / name
        target.parent.mkdir(parents=True, exist_ok=True)
        write(target, effective)
        configuration.append({"file": "res://data/config/" + name, "source_sha256": digest(source),
                              "sha256": digest(target), "overlay_file": str(target), "enabled_fields": fields})
    profile["test_configuration"] = configuration
    profile["configuration_scope"] = configuration_scope
    manifest["test_configuration"] = {"status": "DISCLOSED mechanics " + configuration_scope + " overlay only; production defaults unchanged; native execution OPEN",
                                      "files": configuration,
                                      "apply": "ROOT copies the exact overlay bytes to its isolated serialized native candidate, runs tools/net/f48_bootstrap.gd, then restores original configuration. No source flag or CI prerequisite waiver."}
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
    parser.add_argument("--configuration-scope", choices=("bootstrap", "full"), default="bootstrap",
                        help="Export separately pinned named-mechanics gates; never apply them to production source")
    parser.add_argument("--pre-boss-legacy-mechanics", action="store_true",
                        help="Explicit detached initial gate setup; refuses all prior typed journals/receipts and preserves legacy rewards")
    parser.add_argument("--initial-kitchen-meadows-attachment", action="store_true",
                        help="Explicit initial Kitchen tier1 station fixture; never an earned upgrade, receipt or payment claim")
    parser.add_argument("--origin", required=True, help="Original native run and disclosed earlier setup; never relabel as earned")
    parser.add_argument("--initial-alpha-capture-orb", action="store_true", help="Disclose one initial actual Basic Orb; no caught/provenance grant")
    args = parser.parse_args()
    try:
        manifest = generate([path.resolve() for path in args.source], args.layout.resolve(),
                            args.output.resolve(), args.route_pack.resolve() if args.route_pack else None,
                            args.origin, args.configuration_scope, args.pre_boss_legacy_mechanics,
                            args.initial_kitchen_meadows_attachment, args.initial_alpha_capture_orb)
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(json.dumps({"ok": False, "error": str(error)}))
        return 1
    print(json.dumps({"artifact_written": True, "status": manifest["status"],
                      "acceptance_credit": False, "open_gaps": len(manifest["gaps"]),
                      "profile": str(args.output.resolve() / "profile.json")}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
