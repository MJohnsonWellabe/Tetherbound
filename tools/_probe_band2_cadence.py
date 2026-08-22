#!/usr/bin/env python3
"""BAND2-63 cadence probe -- what does the player actually meet, in order,
crossing South Bridge (z=1360) to the Band 2/3 handoff (z=3180)?

Run:  python3 tools/_probe_band2_cadence.py

Complements tests/smoke_warrens.gd (dungeon geometry/guardian/clear/prize) and
tests/smoke_traversal.gd (corridor collision, quarry stats), neither of which
answers the question prompt 63's evidence run actually asks: walking the band
in order, how far apart are the "reasons to stop", and where is the longest
stretch of dead road? Built the same way tools/_probe_chapter_map.py already
is -- read the shipped config, not a live client, because the band's content
is entirely position data and a straight-line ordering along z tells the real
story cheaply.

This is a straight-line distance along z only (no route factor), same
simplification tools/_probe_pacing.py makes and names explicitly -- it
UNDERSTATES real walked distance over a heightfield with switchbacked loops,
so the "longest gap" figure below is a floor, not a ceiling.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def load(path):
    return json.loads((ROOT / path).read_text())


def main():
    band_dir = "data/config/bands/band2_stone_and_root"
    spawns = load(f"{band_dir}/spawns.json")["spawns"]
    trainers = load(f"{band_dir}/trainers.json")["trainers"]
    harvest = load(f"{band_dir}/harvest.json")["nodes"]
    props = load(f"{band_dir}/props.json")["clusters"]
    quarry = load("data/config/old_quarry.json")
    warrens = load("data/config/burrow_warrens.json")

    beats = []
    beats.append((1360.0, "SOUTH BRIDGE (band start)"))
    for s in spawns:
        z = s["centre"][2]
        tag = " (night)" if s.get("time") == "night" else ""
        beats.append((z, "wild: %s x%d%s" % (s["species"], s.get("count", 1), tag)))
    for t in trainers:
        beats.append((t["position"][1], "trainer: %s" % t["name"]))
    for h in harvest:
        beats.append((h["at"][1], "gather: %s" % h["item"]))
    for p in props:
        # cluster centre = mean of its own prop positions
        xs = [pp["at"][1] for pp in p["props"]]
        beats.append((sum(xs) / len(xs), "props: %s" % p["name"]))
    beats.append((quarry["pylons"]["list"][0]["at"][1], "TEAM TETHER: quarry conduit head (lit)"))
    beats.append((warrens["site"]["at"][1], "BURROW WARRENS entrance"))
    beats.append((3180.0, "band end / River Lock handoff"))

    beats.sort(key=lambda b: b[0])

    print("=" * 78)
    print("band2_stone_and_root -- ordered beats, South Bridge to River Lock handoff")
    print("=" * 78)
    prev_z = None
    longest_gap = 0.0
    longest_gap_at = None
    for z, label in beats:
        gap = "" if prev_z is None else "  (+%dm)" % round(z - prev_z)
        print("  z=%6.0f  %s%s" % (z, label, gap))
        if prev_z is not None and z - prev_z > longest_gap:
            longest_gap = z - prev_z
            longest_gap_at = (prev_z, z)
        prev_z = z

    print()
    print("longest straight-line gap: %.0fm, between z=%.0f and z=%.0f" % (
        longest_gap, longest_gap_at[0], longest_gap_at[1]))
    print("band span: %.0fm; %d beats total -> one beat every %.0fm on average" % (
        3180.0 - 1360.0, len(beats), (3180.0 - 1360.0) / max(len(beats) - 1, 1)))

    # Rootstone comprehension: is there a recipe reachable with the first
    # deposit's yield alone, before any second trip?
    recipes = load("data/recipes/recipes_rootstone.json")["recipes"]
    first_deposit_yield = sum(
        n["amount"] for n in harvest if n["item"] == "rootstone" and n["order"] < 20)
    print()
    print("rootstone: first cluster (quarry floor, 5 deposits) yields %d" % first_deposit_yield)
    for rid, r in recipes.items():
        cost = next((c["n"] for c in r.get("cost", []) if c["id"] == "rootstone"), None)
        if cost is None:
            continue
        reachable = "YES, first visit" if cost <= first_deposit_yield else "needs a second gather"
        gated = r.get("unlocked_by")
        gate_note = (" [also needs flag '%s']" % gated) if gated else ""
        print("  %-16s costs %d rootstone -> %s%s" % (rid, cost, reachable, gate_note))


if __name__ == "__main__":
    main()
