#!/usr/bin/env python3
"""The chapter content map -- who and what stands in each region, from the data.

Run:  python3 tools/_probe_chapter_map.py

WHY THIS EXISTS
---------------
Prompt 59 asks for a chapter trainer map that makes it obvious "whether any long
region lacks human opposition entirely". Prompt 60 asks for a spawn siting audit
recording, per cluster, its region and habitat reason. Both were specified as
tables somebody writes down -- and a hand-written table is exactly what was
already wrong here: the repo HAD a progression curve, a band split and five
authored regions, and still shipped three regions with no wild creatures and one
with no trainers, because nothing counted.

So this counts, from `data/config/bands/*/` and `data/config/chapter_curve.json`,
and prints the map. `tests/test_chapter_content_map.gd` fails the build on the
two gaps this found; this tool is the readable version of the same question.
"""

import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import band_content


def load(rel):
    with open(os.path.join(ROOT, rel)) as f:
        return json.load(f)


CURVE = load("data/config/chapter_curve.json")
TRAINERS = band_content.load_config("data/config/trainers.json", "trainers")["trainers"]
SPAWNS = band_content.load_config("data/config/spawns.json", "spawns")["spawns"]
HARVEST = band_content.load_config("data/config/harvest.json", "nodes")["nodes"]
OBJECTIVES = load("data/progression/objectives.json")["main"]

# Trainers whose defeat is on the chapter's required line. Everything else is a
# trainer the player may walk past, which is the distinction prompt 59 wants the
# map to show.
REQUIRED = {o["flag_id"] for o in OBJECTIVES}
for o in OBJECTIVES:
    REQUIRED |= set(o.get("count_flags", []))


def region_of(z):
    for region in CURVE["regions"]:
        if z < region["z_to"]:
            return region
    return CURVE["regions"][-1]


def main():
    print("=" * 78)
    print("CHAPTER CONTENT MAP -- trainers, wild clusters and gatherables per region")
    print("=" * 78)

    gaps = []
    for region in CURVE["regions"]:
        rid = region["id"]
        team = region.get("team", {})
        mine_t = [t for t in TRAINERS if region_of(t["position"][1])["id"] == rid]
        mine_s = [s for s in SPAWNS if region_of(s["centre"][2])["id"] == rid]
        mine_h = [h for h in HARVEST if region_of(h["at"][1])["id"] == rid]

        print()
        print("%s   z < %.0f" % (rid, region["z_to"]))
        print("  team expected %s -> %s (%s members)   wild band %s   trainer band %s"
              % (team.get("enter"), team.get("exit"), team.get("expected_members"),
                 region.get("wild_band"), region.get("trainer_levels")))

        print("  trainers (%d):" % len(mine_t))
        for t in sorted(mine_t, key=lambda t: t["position"][1]):
            levels = [c["level"] for c in t["team"]]
            required = "required" if t.get("defeat_flag") in REQUIRED else "optional"
            print("    %-24s z=%-7.0f %-8s L%s"
                  % (t["id"], t["position"][1], required,
                     "-".join([str(min(levels)), str(max(levels))]) if len(levels) > 1 else str(levels[0])))
        if not mine_t:
            gaps.append("%s has NO trainers -- prompt 59: 'no major region is simply wild "
                        "traversal followed by one boss'" % rid)

        creatures = sum(s["count"] for s in mine_s)
        print("  wild clusters (%d, %d creatures):" % (len(mine_s), creatures))
        by_species = {}
        for s in mine_s:
            by_species[s["species"]] = by_species.get(s["species"], 0) + s["count"]
        if by_species:
            print("    " + ", ".join("%s x%d" % (k, v) for k, v in sorted(by_species.items())))
        else:
            gaps.append("%s has NO wild creatures -- prompt 60: 'no major late band has an "
                        "empty spawn population'" % rid)

        items = sorted({h["item"] for h in mine_h})
        print("  authored gatherables (%d nodes): %s"
              % (len(mine_h), ", ".join(items) if items else "none (wood/stone/fiber still "
                 "come from the scatter layers, which reach every band)"))

    print()
    print("=" * 78)
    if gaps:
        print("GAPS")
        for g in gaps:
            print("  !! " + g)
    else:
        print("No region is missing trainers or wild creatures.")
    print("=" * 78)
    return 1 if gaps else 0


if __name__ == "__main__":
    sys.exit(main())
