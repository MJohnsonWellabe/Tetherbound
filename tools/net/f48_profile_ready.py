"""Package immutable actual producer saves and reviewed input routes for F48.

Input JSON: provenance, configuration_profile (a generated full overlay profile),
and starts. Each start has sources (host plus distinct portable guests),
route_pack (provenance/routes/outcomes), and origin (actual native producer run).
Start names are loop, behind, boss_four, or the six original transactions.
--require-complete requires the three default CI suites and every transaction.
This tool never adds stock, poses, stations, cards, flags, rewards or receipts.
Output is still unverified mechanics input; native original oracles must pass.
"""
from __future__ import annotations

import argparse
import json
import math
import shutil
from pathlib import Path

import f48_profile_fixture as fixture

SUITES = {"loop", "behind", "boss_four"}
OPERATIONS = set(fixture.OPERATIONS)
DEFAULT_REQUIRED = {"loop", "behind"} | OPERATIONS
CONFIGURATION_FILES = {"stations.json", "essence.json", "traits.json", "multiplayer.json", "hud.json", "alpha_respawns.json"}


def require_fields(row: dict, names: set[str], label: str) -> None:
    fixture.require(set(row) == names, f"Unknown or missing {label} fields")


def counts(character: dict) -> dict[str, int]:
    result: dict[str, int] = {}
    for stack in character["inventory"]:
        if isinstance(stack, dict):
            result[stack["id"]] = result.get(stack["id"], 0) + stack["n"]
    return result


def prerequisite(name: str, inputs: list[dict]) -> None:
    """Read prerequisite carriers; never call or mimic a producer's outcome."""
    world = inputs[0]["world"]
    if name in {"loop", "boss_four"}:
        fixture.require("defeated_warden" not in world.get("flags", {}).get("flags", []),
                        "Original boss start already defeated Warden; never reset its progression")
        for source in inputs:
            personal = source["character"]["redesign_character"]
            fixture.require("meadows" not in personal.get("relics_held", []) and
                            counts(source["character"]).get("tidewake_portal_key", 0) == 0,
                            "Pre-boss start already holds its reward; use the actual earlier producer snapshot")
    if name == "behind":
        personal = inputs[1]["character"]["redesign_character"]
        fixture.require("meadows" not in personal.get("relics_held", []) and
                        "tidewake" not in personal.get("portal_unlocks", []) and
                        counts(inputs[1]["character"]).get("tidewake_portal_key", 0) == 0,
                        "Behind guest must retain honest original progress")
    if name not in OPERATIONS:
        return
    owner = inputs[1]["character"]
    personal = owner["redesign_character"]
    if name == "craft":
        fixture.require(any(record.get("id") == "forge" and record.get("paid") is True and
                            record.get("removed", False) is False for record in world.get("placed_buildings", [])
                            if isinstance(record, dict)) and counts(owner).get("rootstone", 0) >= 2 and
                        counts(owner).get("ironwood", 0) >= 1,
                        "Prepared craft input requires its declared paid Forge and original actual material balances")
    if name in {"release", "essence_spend"}:
        altar_records = [record for record in world.get("placed_buildings", [])
                         if isinstance(record, dict) and record.get("id") == "altar" and
                         record.get("paid") is True and record.get("removed", False) is False]
        journals = world.get("reward_deliveries", {})
        fixture.require(any(row.get("kind") == "altar_building" and row.get("status") == "accepted" and
                            row.get("intent", {}).get("record") in altar_records and
                            row.get("receipt") in inputs[0]["character"]["redesign_character"].get("transaction_receipts", [])
                            for row in journals.values() if isinstance(row, dict)),
                        "Prepared Altar input needs the actual accepted paid-building journal and original owner receipt")
    if name == "release":
        caught = [row for row in personal["creatures"].values()
                  if row.get("captured_from", {}).get("kind") == "wild" and
                  row["captured_from"].get("world_namespace") and
                  row["captured_from"].get("spawn_id") and
                  type(row["captured_from"].get("spawn_generation")) in (int, float) and
                  math.isfinite(row["captured_from"]["spawn_generation"]) and
                  1 <= row["captured_from"]["spawn_generation"] <= 2147483647 and
                  int(row["captured_from"]["spawn_generation"]) == row["captured_from"]["spawn_generation"]]
        fixture.require(len(owner["party"]) > 1 and caught,
                        "Release requires an actual caught wild companion; no provenance is fabricated")
    if name == "key":
        fixture.require(counts(owner).get("tidewake_portal_key", 0) >= 1 and
                        "tidewake" not in personal.get("portal_unlocks", []),
                        "Prepared key start needs its actual owned unspent key")
    if name == "relic":
        fixture.require("meadows" in personal.get("relics_held", []) and
                        "meadows" not in personal.get("relics_hung", []),
                        "Prepared relic start needs its actual held unhung relic")
    if name == "feast":
        fixture.require(counts(owner).get("feast_t1_ground", 0) >= 1 and
                        "master_t1" in personal.get("master_wins", []) and
                        "feast_t1" in personal.get("feast_recipes", []),
                        "Prepared feast start needs an actual cooked feast, never a stock grant")


def generate(input_path: Path, output: Path, complete: bool) -> dict:
    pack = fixture.read(input_path)
    require_fields(pack, {"provenance", "configuration_profile", "starts"}, "producer bundle")
    fixture.require(isinstance(pack["provenance"], str) and pack["provenance"].strip(), "Disclose producer origins/shortcuts")
    starts = pack["starts"]
    fixture.require(isinstance(starts, dict) and starts and set(starts) <= SUITES | OPERATIONS,
                    "Use original named suites and six transactions only")
    if complete:
        fixture.require(DEFAULT_REQUIRED <= set(starts),
                        "Required CI bundle lacks an original suite/transaction; none is skipped")
    fixture.require(not output.exists(), "Fresh output required; never replace evidence or actual saved inputs")
    overlay = fixture.read(Path(pack["configuration_profile"]))
    fixture.require(overlay.get("configuration_scope") == "full", "Require separately reviewed full mechanics overlay")
    configurations = overlay.get("test_configuration", [])
    fixture.require(isinstance(configurations, list) and len(configurations) == len(CONFIGURATION_FILES) and
                    {Path(row["file"]).name for row in configurations} == CONFIGURATION_FILES,
                    "Require exact full configuration file set")
    prepared = {}
    for name, row in starts.items():
        require_fields(row, {"sources", "route_pack", "origin"}, "actual start")
        fixture.require(isinstance(row["origin"], str) and row["origin"].strip(), "Disclose actual producing native run")
        paths = [Path(path).resolve() for path in row["sources"]]
        fixture.require(len(paths) == (4 if name == "boss_four" else 2), "Use original distinct peer count")
        fixture.require(all(not output.is_relative_to(path) and not path.is_relative_to(output) for path in paths),
                        "Prepared output must be disjoint from every original source")
        inputs = [fixture.source_input(path, index == 0) for index, path in enumerate(paths)]
        fixture.require(len({source["id"] for source in inputs}) == len(inputs), "Never clone character identities")
        uids = [uid for source in inputs for uid in source["uids"]]
        fixture.require(len(set(uids)) == len(uids), "Never clone owned creature identities")
        routes = fixture.read(Path(row["route_pack"]))
        fixture.validate_pack(routes)
        prerequisite(name, inputs)
        prepared[name] = (row, inputs, routes)
    # Validate everything above before producing the immutable package.
    output.mkdir(parents=True, exist_ok=False)
    configuration_rows = []
    for row in configurations:
        source = Path(row["overlay_file"])
        original = fixture.ROOT / "data/config" / source.name
        fixture.require(fixture.digest(source) == row["sha256"] and
                        fixture.digest(original) == row["source_sha256"],
                        "Configuration bytes/source changed since reviewed overlay generation")
        target = output / "test-configuration/data/config" / source.name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
        configuration_rows.append(dict(row, overlay_file=str(target)))
    profile = {"provenance": "Immutable actual producer mechanics inputs; no earned campaign claim. " + pack["provenance"],
               "configuration_scope": "full", "test_configuration": configuration_rows,
               "suite_profiles": {}, "transaction_profiles": {}}
    manifest = {"acceptance_credit": False, "earned_checkpoint": False, "status": "OPEN_NATIVE_ORACLES_REQUIRED",
                "input_pack_sha256": fixture.digest(input_path), "mutations": [], "starts": {}}
    for name, (row, inputs, routes) in prepared.items():
        saves, documents = [], []
        for index, source in enumerate(inputs):
            destination = output / "starts" / name / f"peer-{index}"
            originals = [source["character_path"]]
            if index == 0:
                originals += [source["world_path"], source["slot_path"]]
            for original in originals:
                target = destination / original.relative_to(source["root"])
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(original, target)
                fixture.require(fixture.digest(target) == fixture.digest(original), "Original immutable input byte mismatch")
                documents.append({"source": str(original), "path": str(target), "sha256": fixture.digest(target)})
            saves.append(str(destination))
        start = {"saves": saves, "routes": routes["routes"], "outcomes": routes["outcomes"],
                 "provenance": row["origin"] + " Input routes: " + routes["provenance"]}
        profile["suite_profiles" if name in SUITES else "transaction_profiles"][name] = start
        manifest["starts"][name] = {"origin": row["origin"], "documents": documents,
                                   "route_pack_sha256": fixture.digest(Path(row["route_pack"]))}
        if "saves" not in profile or (len(profile["saves"]) == 4 and len(saves) == 2):
            profile.update({"saves": saves, "routes": {}, "outcomes": {}})
    fixture.write(output / "profile.json", profile)
    manifest["profile_sha256"] = fixture.digest(output / "profile.json")
    fixture.write(output / "producer-manifest.json", manifest)
    return manifest


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-pack", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--require-complete", action="store_true")
    args = parser.parse_args()
    try:
        manifest = generate(args.input_pack.resolve(), args.output.resolve(), args.require_complete)
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(json.dumps({"ok": False, "error": str(error)}))
        return 1
    print(json.dumps({"artifact_written": True, "acceptance_credit": False,
                      "status": manifest["status"], "starts": list(manifest["starts"])}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
