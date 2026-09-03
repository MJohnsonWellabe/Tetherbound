#!/usr/bin/env python3
"""WORLD-CONTENT walk-log probe -- per-category dead-travel gaps along the
Lower Meadows spine (trainers and gatherables measured separately), plus the
combined-POI gap tools/_probe_band1_cadence.py already reports.

Run:  python3 tools/_probe_band1_content_spacing.py

WHY A SEPARATE SCRIPT
----------------------
tools/_probe_band1_cadence.py answers "is there dead travel at all" by
blending every POI type (trainer, wild cluster, harvest node, prop) into one
gap list. docs/specs/BAND1_ROUTE_CONTRACT.md's WORLD-CONTENT slice asks a
narrower, harder question: no 250m of route without a GATHERABLE specifically,
and no 700m without a TRAINER specifically. A band can look dense on the
blended list while still leaving a long stretch with wildlife and scenery but
nothing to gather and nothing to fight -- this script measures those two
categories on their own, using the same polyline/arc-length/on-route-lateral
method the existing probe already established (ON_ROUTE_LATERAL_M=60).

Trainers placed in the village square (arc ~0-150, `placed_by: "village_npcs"`
or `order < 1000` tournament/village entries) are excluded from the trainer
gap count: the route contract's own reading starts counting "beyond the
village hub" at arc 150, and the village's own four challenges are not part
of the open-road ladder this measures.
"""

import json
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BAND_DIR = os.path.join(ROOT, "data", "config", "bands", "band1_lower_meadows")
TERRAIN_PATH = os.path.join(ROOT, "data", "config", "terrain_playground.json")

ON_ROUTE_LATERAL_M = 60.0
VILLAGE_HUB_ARC = 150.0


def load(path):
    with open(path) as f:
        return json.load(f)


def spine_points():
    terrain = load(TERRAIN_PATH)
    for band in terrain["trail"]["bands"]:
        if band["id"] == "band1_lower_meadows":
            return [tuple(p) for p in band["points"]]
    raise SystemExit("band1_lower_meadows not found in trail.bands")


def arc_lengths(points):
    lengths = [0.0]
    for i in range(1, len(points)):
        x0, z0 = points[i - 1]
        x1, z1 = points[i]
        lengths.append(lengths[-1] + math.hypot(x1 - x0, z1 - z0))
    return lengths


def project(points, lengths, px, pz):
    best_arc = None
    best_lat = None
    for i in range(1, len(points)):
        x0, z0 = points[i - 1]
        x1, z1 = points[i]
        dx, dz = x1 - x0, z1 - z0
        seg_len = math.hypot(dx, dz)
        if seg_len == 0:
            continue
        t = ((px - x0) * dx + (pz - z0) * dz) / (seg_len * seg_len)
        t = max(0.0, min(1.0, t))
        nx, nz = x0 + t * dx, z0 + t * dz
        lat = math.hypot(px - nx, pz - nz)
        arc = lengths[i - 1] + t * seg_len
        if best_lat is None or lat < best_lat:
            best_lat = lat
            best_arc = arc
    return best_arc, best_lat


def trainer_pois():
    trainers = load(os.path.join(BAND_DIR, "trainers.json"))["trainers"]
    out = []
    for t in trainers:
        if t.get("placed_by") == "village_npcs" or t.get("placed_by") == "tournament":
            continue
        pos = t.get("position")
        if not pos:
            continue
        out.append(("trainer:%s" % t.get("id", "?"), float(pos[0]), float(pos[1])))
    return out


def harvest_pois():
    harvest = load(os.path.join(BAND_DIR, "harvest.json"))["nodes"]
    out = []
    for h in harvest:
        item = str(h.get("item", ""))
        # Gatherable resources only (per the contract's "wood, stone, fiber or
        # berry node" wording) -- one-time pickup caches (potion_small,
        # orb_basic, travel_pack, revive) are a different content class and
        # are not counted toward this gap.
        if item not in ("wood", "stone", "fiber", "berries"):
            continue
        at = h.get("at")
        if not at or len(at) != 2:
            continue
        out.append(("harvest:%s:%s" % (item, h.get("order", "?")), float(at[0]), float(at[1])))
    return out


def report(label, pois, start_arc=0.0):
    points = spine_points()
    lengths = arc_lengths(points)
    total = lengths[-1]

    on_route_arcs = [start_arc, total]
    off_route = []
    for name, x, z in pois:
        arc, lat = project(points, lengths, x, z)
        if arc is None or arc < start_arc:
            continue
        if lat <= ON_ROUTE_LATERAL_M:
            on_route_arcs.append(arc)
        else:
            off_route.append((name, arc, lat))

    on_route_arcs.sort()
    gaps = [(on_route_arcs[i + 1] - on_route_arcs[i], on_route_arcs[i], on_route_arcs[i + 1])
            for i in range(len(on_route_arcs) - 1)]
    gaps.sort(reverse=True)

    print("== %s ==" % label)
    print("spine length: %.0fm (measured from arc %.0f)" % (total - start_arc, start_arc))
    print("on-route POIs (<=%.0fm lateral): %d" % (ON_ROUTE_LATERAL_M, len(on_route_arcs) - 2))
    print("gaps (m), largest first:")
    for gap, a, b in gaps:
        flag = "  <-- OVER TARGET" if False else ""
        print("  %6.0fm  (arc %.0f -> %.0f)%s" % (gap, a, b, flag))
    if off_route:
        print("off-route (not counted):")
        for name, arc, lat in sorted(off_route, key=lambda x: x[1]):
            print("  %-28s arc=%.0f lateral=%.0fm" % (name, arc, lat))
    print()
    return gaps


if __name__ == "__main__":
    g_trainer = report("TRAINERS beyond the village hub (target: no gap over 700m)",
                        trainer_pois(), start_arc=VILLAGE_HUB_ARC)
    g_harvest = report("GATHERABLES, whole route (target: no gap over 250m)",
                        harvest_pois(), start_arc=0.0)

    print("== SUMMARY ==")
    print("largest trainer gap:   %.0fm (target <= 700m)" % g_trainer[0][0])
    print("largest gatherable gap: %.0fm (target <= 250m)" % g_harvest[0][0])
