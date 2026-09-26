#!/usr/bin/env python3
"""Copy the earned chain's final save into the repo fixture and write PROVENANCE.json.

    tools/earned_saves/assemble_fixture.py <chain_root> <seed> "<runner command>"

Reads each segment's receipt.json under <chain_root>/<segment>/, refuses unless
all seven passed, copies <chain_root>/warden/save/ to
tests/fixtures/earned_saves/c1_arrival/save/ and refuses above 20 MB.
"""
import json
import os
import shutil
import subprocess
import sys

SEGMENTS = ["opening_team", "camp_tournament", "bridge", "warrens", "relay", "hall", "warden"]
LIMIT = 20 * 1024 * 1024
REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DEST = os.path.join(REPO, "tests", "fixtures", "earned_saves", "c1_arrival")


def size_of(path):
    return sum(os.path.getsize(os.path.join(d, f)) for d, _, fs in os.walk(path) for f in fs)


def main():
    root, seed, command = sys.argv[1], int(sys.argv[2]), sys.argv[3]
    segments = []
    for name in SEGMENTS:
        with open(os.path.join(root, name, "receipt.json")) as fh:
            receipt = json.load(fh)
        if not receipt.get("passed"):
            sys.exit("segment %s did not pass" % name)
        segments.append(receipt)
    source = os.path.join(root, "warden", "save")
    total = size_of(source)
    if total > LIMIT:
        sys.exit("final save is %d bytes (> 20 MB); not copying" % total)
    if os.path.isdir(os.path.join(DEST, "save")):
        shutil.rmtree(os.path.join(DEST, "save"))
    os.makedirs(DEST, exist_ok=True)
    shutil.copytree(source, os.path.join(DEST, "save"))
    sha = subprocess.check_output(["git", "-C", REPO, "rev-parse", "HEAD"], text=True).strip()
    final = segments[-1]
    provenance = {
        "fixture": "earned C1 handoff: trainer at the Cloudreach arrival after the physical Rift crossing",
        "world_seed": seed,
        "source_sha": sha,
        "runner_command": command,
        "injections": 0,
        "total_wall_seconds": round(sum(s["wall_seconds"] for s in segments), 1),
        "save_bytes": total,
        "legendary_species": "veridian",
        "final_location": final["location"],
        "final_party": final["party_after"],
        "disclosures": [
            "TB_WORLD_SEED pins the world roll for every segment; the fresh save stores the same seed.",
            "Segments are separate processes joined by Game.save_game(1) and the production title Load list.",
            "Veridian accepted through the full-belt farewell ceremony: the lowest-level earned member was let go "
            "(tools/earned_saves/warden_accept.gd). The inherited helper receipt 'meadows_ending_settled' keeps its "
            "hard-coded 'release_pending_legendary_keep_earned_five' label; 'veridian_accepted' is the actual choice.",
            "Every helper workaround is disclosed in tools/earned_saves/BLOCKERS.md (B1-B12) with per-beat receipts: "
            "bench/road/pre-Warden Satchel care (between_fight_care, pre_warden_bench_care), delayed-dialogue prompt "
            "presses, the Warden reward read-out, the F05 spatial accept prompt, and the acknowledgement walk on the "
            "forward roads reversed (warren_undertrail and the B3 mound detour). None writes a flag, item, party member or position.",
        ] + [d for s in segments for d in s.get("disclosures", [])],
        "segments": [{k: s[k] for k in (
            "segment", "passed", "wall_seconds", "game_day", "game_clock_seconds", "location",
            "flags_gained", "flags_total", "party_before", "party_after", "key_items", "free_build",
            "helper_receipts")} for s in segments],
    }
    with open(os.path.join(DEST, "PROVENANCE.json"), "w") as fh:
        json.dump(provenance, fh, indent=1, sort_keys=True)
    print("fixture %s: %d bytes save, %.0f s wall" % (DEST, total, provenance["total_wall_seconds"]))


if __name__ == "__main__":
    main()
