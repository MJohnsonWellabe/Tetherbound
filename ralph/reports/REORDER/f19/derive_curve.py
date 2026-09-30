"""Reproduce F19's data-only curve candidate from the recorded main baseline.

This authors targets, not earned saves or gameplay evidence. Run from the repo.
Numeric edits preserve source formatting, positions, encounter ids and rewards.
"""
import copy
import json
import math
import pathlib
import re
import subprocess

BASE = "ddeadbc1eb9cc2f81693d69eded98ee9183579a1"
ROOT = pathlib.Path(__file__).resolve().parents[4]


def hand_off_rows():
    return {
        "warden_aldis": {"runtime_realm": "meadows", "relic_biome": "meadows", "portal_key_item": "tidewake_portal_key", "portal_key_id": "portal_key_tidewake", "next_biome": "tidewake"},
        "water_trainer_nerissa": {"runtime_realm": "water", "relic_biome": "tidewake", "portal_key_item": "cloudreach_portal_key", "portal_key_id": "portal_key_cloudreach", "next_biome": "cloudreach"},
        "captain_veyra_storm_anchor": {"runtime_realm": "cloudreach", "relic_biome": "cloudreach", "portal_key_item": "stormwood_portal_key", "portal_key_id": "portal_key_stormwood", "next_biome": "stormwood"},
        "captain_marrow_dynamo_core": {"runtime_realm": "stormwood", "relic_biome": "stormwood", "portal_key_item": "fifth_portal_key", "portal_key_id": "portal_key_biome5", "next_biome": "biome5"},
    }


def source(path):
    return subprocess.check_output(["git", "show", f"{BASE}:{path}"], cwd=ROOT).decode("utf-8")


def leaf_spans(text):
    """Collect JSON value spans by structural path; never rewrite prose numbers."""
    spans = {}
    decoder = json.JSONDecoder()

    def ws(pos):
        while pos < len(text) and text[pos].isspace():
            pos += 1
        return pos

    def value(pos, path):
        pos = ws(pos)
        start = pos
        if text[pos] == "{":
            pos = ws(pos + 1)
            while text[pos] != "}":
                key, end = decoder.raw_decode(text, pos)
                pos = value(ws(end) + 1, path + (key,))
                pos = ws(pos)
                if text[pos] == ",":
                    pos = ws(pos + 1)
                else:
                    break
            spans[path] = (start, pos + 1)
            return pos + 1
        if text[pos] == "[":
            pos = ws(pos + 1)
            index = 0
            while text[pos] != "]":
                pos = ws(value(pos, path + (index,)))
                index += 1
                if text[pos] == ",":
                    pos = ws(pos + 1)
                else:
                    break
            spans[path] = (start, pos + 1)
            return pos + 1
        _, end = decoder.raw_decode(text, pos)
        spans[path] = (start, end)
        return end

    value(0, ())
    return spans


def write_edits(path, change):
    text = source(path)
    old = json.loads(text)
    new = copy.deepcopy(old)
    change(new)
    spans = leaf_spans(text)
    patches = []
    def diff(before, after, keys=()):
        if before == after:
            return
        if isinstance(before, dict) and isinstance(after, dict) and before.keys() == after.keys():
            for key in before:
                diff(before[key], after[key], keys + (key,))
        elif isinstance(before, list) and isinstance(after, list) and len(before) == len(after):
            for index in range(len(before)):
                diff(before[index], after[index], keys + (index,))
        else:
            start, end = spans[keys]
            patches.append((start, end, json.dumps(after, ensure_ascii=False)))
    diff(old, new)
    for start, end, replacement in reversed(sorted(patches)):
        text = text[:start] + replacement + text[end:]
    json.loads(text)
    (ROOT / path).write_text(text, encoding="utf-8", newline="\n")


def half_down(value):
    return math.ceil(value - 0.5)


def levels(data, transform):
    if isinstance(data, dict):
        for key, value in data.items():
            if key in ("level", "ace_level") and isinstance(value, (int, float)):
                data[key] = transform(value)
            elif key in ("level_range", "level_band"):
                data[key] = [transform(x) for x in value]
            elif not key.startswith("_"):
                levels(value, transform)
    elif isinstance(data, list):
        for item in data:
            levels(item, transform)


def trainer_levels(data, transform, boss, boss_levels, key="team"):
    levels(data, transform)
    for row in data["trainers"]:
        if row["id"] == boss:
            for member, level in zip(row[key], boss_levels, strict=True):
                member["level"] = level
            if "ace_level" in row:
                row["ace_level"] = max(boss_levels)


def derive():
    rewards = source("data/config/chapter_rewards.json")
    encoded = json.dumps(hand_off_rows(), indent=2, ensure_ascii=False).replace("\n", "\n  ")
    anchor = '  "materials": {'
    assert rewards.count(anchor) == 1
    rewards = rewards.replace(anchor, '  "boss_hand_offs": ' + encoded + ',\n' + anchor)
    json.loads(rewards)
    (ROOT / "data/config/chapter_rewards.json").write_text(rewards, encoding="utf-8", newline="\n")
    curve = json.loads(source("data/config/chapter_curve.json"))
    curve["_comment"] = "F19 / RD-10: authored four-chapter targets. biome_order.json alone owns chapter order; this file owns levels. Meadows regions retain their runtime z boundaries."
    curve["_comment_measurement"] = "These are redesign targets, not measured earned levels. The old combat-XP probe is superseded by hybrid leveling; F27/F47 must prove the earned route ledger. No fixture provenance is implied."
    curve["_comment_measurement_pacing"] = "RD-01 targets a 15–25 hour normal clear; F47 measures it. This data change supplies no timing evidence."
    curve["_comment_no_scaling"] = "Authored world-position tables never scale to player level. Portal keys are the sole inter-biome gate; recommended levels are guidance only."
    curve["chapters"] = {
        "meadows": {"team": {"enter": 3, "exit": 22}, "wild_band": [2, 20], "boss_levels": [21, 21, 21, 22, 22], "recommended_level": 3},
        "water": {"team": {"enter": 20, "exit": 33}, "wild_band": [18, 32], "boss_levels": [32, 32, 33, 33], "recommended_level": 20},
        "cloudreach": {"team": {"enter": 31, "exit": 44}, "wild_band": [29, 43], "boss_levels": [43, 43, 44], "recommended_level": 31},
        "stormwood": {"team": {"enter": 42, "exit": 55}, "wild_band": [40, 54], "boss_levels": [54, 54, 54, 55, 55], "recommended_level": 42},
    }
    splits = [(3, 9, 2, 6, 2, 7), (9, 12, 7, 10, 9, 16), (12, 15, 10, 13, 8, 18), (15, 18, 13, 17, 15, 18), (18, 22, 16, 20, 17, 22)]
    for row, (entry, exit_level, low, high, trainer_low, trainer_high) in zip(curve["regions"], splits, strict=True):
        row["team"].update(enter=entry, exit=exit_level)
        row["wild_band"] = [low, high]
        row["trainer_levels"] = [trainer_low, trainer_high]
        row["tuning"] = "F19 authored target; preserves ids, z boundaries, density and recovery. Earned hybrid-level solvency remains F27/F47 proof."
    curve["regions"][1]["tools"] = ["rootstone recipes", "riding saddle", "greater orb", "L10 Master and feast"]
    curve["regions"][1]["temptations"] = "Replacement catches stay within two levels of intended entry. Mudsnout evolves only at the L20 feast (RD-28)."
    curve["regions"][4]["tools"] = ["all Meadows tools", "L20 Master and feast", "Mudsnout evolution choice", "Best Creature"]
    curve["regions"][4]["tuning"] = "Band 5 remains the short authored cadence exception (D70/D78): no density, road supplies, waystop healing or recovery placement changed."
    curve["regions"][4]["temptations"] = "Veridian volunteers per participant against the actual five. The L20 feast offers Mudsnout's optional Tuskroot/Ashtusk evolution."
    curve["difficulty"]["warden_level"] = 21
    path = ROOT / "data/config/chapter_curve.json"
    path.write_text(json.dumps(curve, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")

    def meadow(data):
        for row in data["trainers"]:
            if row["id"] in {"captain_riverwatch", "captain_field", "captain_ridge", "patrol_ridgeline", "pasture_drover_juno", "lost_creature_rue", "stronghold_patrol", "stronghold_courtyard", "stronghold_elite", "stronghold_outer_watch", "stronghold_checkpoint"}:
                for member in row["team"]:
                    member["level"] += 2
            if row["id"] == "warden_aldis":
                for member, level in zip(row["team"], [21, 21, 21, 22, 22], strict=True):
                    member["level"] = level

    for file in sorted((ROOT / "data/config/bands").glob("*/trainers.json")):
        write_edits(file.relative_to(ROOT).as_posix(), meadow)
    # This is the existing tracked content mirror, not an earned save.
    # Keep original row identities and mirror only the matching level edits.
    write_edits("tests/fixtures/band_split_baseline/trainers.json", meadow)

    # Preserve alpha bonuses; combat's separately owned level_ceiling hunk
    # clamps only the authored leaders which could exceed the chapter exit.
    for band in ["band4_upper_meadows_ironwood", "band5_stronghold_approach"]:
        file = f"data/config/bands/{band}/spawns.json"
        text = source(file)
        bonuses = [4] if band.startswith("band4") else [2, 4]
        pattern = r'("level_bonus":\s*(?:' + "|".join(map(str, bonuses)) + r'),)'
        text = re.sub(pattern, r'\1 "level_ceiling": 20,', text)
        (ROOT / file).write_text(text, encoding="utf-8", newline="\n")

    def warrens(data):
        # Field ceiling grows 8→10. Preserve each resident strictly above it.
        for row in data["spawns"]:
            row["level"] += 2
        data["guardian"]["level"] += 2
    write_edits("data/config/burrow_warrens.json", warrens)

    cloud = lambda n: half_down(31 + (n - 19) * 13 / 15)
    def retired_entry_clauses(data, old_key):
        # F18's actual portal admission owns entry. These chapter clauses must
        # not require a second, obsolete world key after successful arrival.
        for act in data["acts"]:
            act["entry_flags"] = [flag for flag in act.get("entry_flags", []) if flag != old_key]
            for row in act["objectives"]:
                row["requires_flags"] = [flag for flag in row.get("requires_flags", []) if flag != old_key]
        entry = data.get("persistent_flags", {}).get("entry")
        if isinstance(entry, list):
            data["persistent_flags"]["entry"] = [flag for flag in entry if flag != old_key]
    def cloud_chapter(data):
        levels(data, cloud)
        retired_entry_clauses(data, "realm_key_cloudreach")
        data["acts"][0]["objectives"][0]["how"] = "Follow the cliff road to the first camp."
        data["story_problem"]["resolution"] = "Disable the network, defeat its captain, and restore Cloudreach's winds. The earned Stormwood Portal Key opens its arch in Crossing Hall."
        for act in data["acts"]:
            for objective in act["objectives"]:
                if objective["id"] == "cloudreach_claim_reward":
                    objective["how"] = "Bring your Wings of Cloudreach to the Hall Shrine, and use your Stormwood Portal Key at the Stormwood arch in Crossing Hall."
        for event in data["map_navigation"]["unlock_events"]:
            if event["flag_id"] == "stormward_route_revealed":
                event["world_change"] = "Stormward Overlook clears after the finale. The next realm is reached through its keyed arch in Crossing Hall."
        for reward in data["rewards"]["grants"]:
            if reward["id"] == "waterward_reveal":
                reward["definition_status"] = "crossing_hall_portal_destination"
        for change in data["aftermath"]["state_changes"]:
            if change["id"] == "waterward_route_visible":
                change["change"] = "Stormward Overlook clears as Cloudreach's winds return. The earned Stormwood Portal Key is used at Crossing Hall, not at a physical crossing here."
        # Wild endpoints follow the declared 29–43 envelope, not trainer formula.
        for table in data["encounter_tables"]:
            before = next(t for t in json.loads(source("data/config/cloudreach_chapter.json"))["encounter_tables"] if t["id"] == table["id"])
            table["level_range"] = [half_down(29 + (n - 18) * 14 / 15) for n in before["level_range"]]
        for row in data["trainer_ladder"]:
            if row["id"] == "captain_veyra_storm_anchor":
                row["level_band"] = [43, 44]
                for member, level in zip(row["team_contract"]["slots"], [43, 43, 44], strict=True):
                    member["level"] = level
        for member, level in zip(data["final_encounter"]["opposition_contract"]["slots"], [43, 43, 44], strict=True):
            member["level"] = level
    write_edits("data/config/cloudreach_chapter.json", cloud_chapter)

    def cloud_reward_dialogue(data):
        conversations = data["conversations"]
        conversations["cloudreach_aila_after_restoration"]["lines"][-1] = "Cloudreach's roads belong to its people again. When you're ready for another journey, Crossing Hall will be your starting point."
        reward = conversations["cloudreach_aila_final_reward"]["lines"]
        reward[1] = "You've earned the Wings of Cloudreach and the Stormwood Portal Key. Bring your Wings to the Hall Shrine in Crossing Hall: Skyborne lets you fly without spending stamina. You can choose one relic power at a time."
        reward[2]["text"] = "Take our thanks with you. Use the Stormwood Portal Key at the Stormwood arch in Crossing Hall when you're ready. Your Home Key brings you back to the Hall's Home Arch."
    write_edits("data/dialogue/cloudreach.json", cloud_reward_dialogue)

    water = lambda n: half_down(20 + (n - 43) * 13 / 12)
    def water_trainers(data):
        trainer_levels(data, water, "water_trainer_nerissa", [32, 32, 33, 33])
        data["_comment_combat"] = "F19 / RD-10: 12 critical and 12 optional encounters re-derived for Tidewake 20→33; Nerissa 32/32/33/33. No team species, placements, route gates or combat behaviors changed."
    write_edits("data/config/water_characters.json", water_trainers)
    def water_wild(data):
        for table in data["tables"]:
            table["level_range"] = [half_down(18 + (n - 43) * 14 / 12) for n in table["level_range"]]
        for row in data["named_encounters"]:
            row["level"] = water(row["level"])
            if row.get("region_level_exception"):
                row["region_level_exception"] = "F19: optional Tidecoil apex L32; normal wild tables remain within Tidewake 18–32."
        for row in data["scripted_encounter_references"]:
            row["level"] = water(row["level"])
    write_edits("data/config/water_encounters.json", water_wild)
    storm = lambda n: half_down(42 + (n - 32) * 13 / 12)
    write_edits("data/config/stormwood_trainers.json", lambda d: trainer_levels(d, storm, "captain_marrow_dynamo_core", [54, 54, 54, 55, 55], "party"))
    def storm_wild(data):
        for table in data["tables"]:
            table["level_range"] = [half_down(40 + (n - 30) * 14 / 13) for n in table["level_range"]]
        for row in data["named_encounters"]:
            row["level"] = storm(row["level"])
        data["legendary_placeholder"]["level"] = 55
        data["legendary_placeholder"]["catchable"] = False
    write_edits("data/config/stormwood_encounters.json", storm_wild)

    def cloud_npc_entry(data):
        for guard in data["dialogue_event_guards"]:
            if guard["conversation"] in ["cloudreach_aila_arrival", "cloudreach_maela_flight_trial"]:
                guard["requires_flags"] = [flag for flag in guard["requires_flags"] if flag != "realm_key_cloudreach"]
        for npc in data["npcs"]:
            if npc["id"] == "keeper_maela":
                for greeting in npc.get("greeting_when", []):
                    if greeting["conversation"] == "cloudreach_maela_flight_trial":
                        greeting["if_flag"] = [flag for flag in greeting["if_flag"] if flag != "realm_key_cloudreach"]
    write_edits("data/config/cloudreach_npc_runtime.json", cloud_npc_entry)

    def solmane(data):
        data["legendary"]["level"] = 44
        data["legendary"]["_comment_level"] = "F19: Cloudreach exit L44; volunteer offer, never a wild capture."
    write_edits("data/config/cloudreach_solmane_climax.json", solmane)
    write_edits("data/config/water_alpha.json", lambda d: d.update(level=26))
    write_edits("data/config/water_veilfall.json", lambda d: d.update(guardian_level=33))
    def water_roster(data):
        for row in data["species"].values():
            if isinstance(row.get("named_encounter"), dict):
                row["named_encounter"]["level"] = water(row["named_encounter"]["level"])
    write_edits("data/config/water_roster.json", water_roster)
    def water_regions(data):
        for row in data["regions"]:
            for key in ["team_level_start", "team_level_exit"]:
                row[key] = water(row[key])
    write_edits("data/config/water_world.json", water_regions)
    def dynamo(data):
        data["captive"]["placeholder_species"] = "fulgocobra"
        data["captive"]["level"] = 55
    write_edits("data/config/stormwood_dynamo.json", dynamo)
    def storm_chapter(data):
        data["final_encounter"]["legendary_level"] = 55
        retired_entry_clauses(data, "realm_key_stormwood")
        for act in data["acts"]:
            for objective in act.get("objectives", []):
                if objective["id"] == "stormwood_waterward_revealed":
                    objective["label"] = "Look over the cleared sky."
                    objective["how"] = "Take in the cleared sky, then use your Home Key to reach the Crossing Hall HOME ARCH. Walk the village road back to Grandpa."
                    objective["grants_flags"] = [flag for flag in objective["grants_flags"] if flag != "realm_key_water"]
                    objective["consumed_grants"] = {}
        data["rewards"]["next_realm_key"] = "portal_key_biome5"
    write_edits("data/config/stormwood_chapter.json", storm_chapter)


if __name__ == "__main__":
    derive()
