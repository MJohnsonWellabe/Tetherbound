#!/usr/bin/env python3
"""BAND1-D1 cadence probe -- longest dead-travel interval along the Lower
Meadows spine, before and after this pass's corridor content.

Run:  python3 tools/_probe_band1_cadence.py

WHY THIS EXISTS
----------------
GATE_D_LANE_CONTRACT.md and prompt 62 both ask for the longest dead-travel
interval in metres, measured, not guessed. tools/_probe_chapter_map.py counts
content per band but says nothing about WHERE it sits along the route, so a
band can pass that probe's counts while still having one 800m stretch with
nothing in it -- which is exactly the shape the 2026-08-21 owner playtest
complained about ("pond-to-village travel feels long, bare and boring") and
exactly what tools/_probe_chapter_map.py's own baseline table could not show.

METHOD
------
1. Build band1_lower_meadows's spine as a polyline from terrain_playground.json
   `trail.bands[0].points`, and its cumulative arc length.
2. Project every authored point of interest (trainer, wild spawn cluster
   centre, harvest node, prop cluster anchor) onto that polyline: the nearest
   arc-length position and the lateral (off-spine) distance at that point.
3. A POI counts as "on the route" if its lateral distance is under
   ON_ROUTE_LATERAL_M -- close enough that a player walking the spine notices
   it without detouring. A POI further off (the meadowhart glade, by design)
   does not fill a dead-travel gap; it is optional content, not route content,
   and counting it would hide the exact problem this probe exists to catch.
4. Sort the on-route arc-length positions, including the spine's own start and
   end, and report the largest consecutive gap.

This is a straight-line/polyline model, not a real driven walk -- it does not
know about terrain grade, water, or the corridor's actual walkable width. It
is a floor check: if the biggest gap here is still huge, a real playthrough
cannot be better. `--before` restricts the POI list to entries whose `order`
is below 1000 (this band's pre-BAND1-D1 authored content), letting one run
print both the old and new longest gap for comparison.
"""

import json
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BAND_DIR = os.path.join(ROOT, "data", "config", "bands", "band1_lower_meadows")
TERRAIN_PATH = os.path.join(ROOT, "data", "config", "terrain_playground.json")

ON_ROUTE_LATERAL_M = 60.0


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
    """Cumulative arc length at each vertex, and total length."""
    lengths = [0.0]
    for i in range(1, len(points)):
        x0, z0 = points[i - 1]
        x1, z1 = points[i]
        lengths.append(lengths[-1] + math.hypot(x1 - x0, z1 - z0))
    return lengths


def project(points, lengths, px, pz):
    """Nearest arc-length position and lateral distance for (px, pz)."""
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


def pois(before_only=False):
    """(label, x, z, order) for every trainer, wild cluster, harvest node and
    prop cluster anchor authored in band1."""
    out = []

    trainers = load(os.path.join(BAND_DIR, "trainers.json"))["trainers"]
    for t in trainers:
        order = int(t.get("order", -1))
        if before_only and order >= 1000:
            continue
        pos = t.get("position")
        if not pos:
            continue
        out.append(("trainer:%s" % t.get("id", "?"), float(pos[0]), float(pos[1]), order))

    spawns = load(os.path.join(BAND_DIR, "spawns.json"))["spawns"]
    for s in spawns:
        order = int(s.get("order", -1))
        if before_only and order >= 1000:
            continue
        c = s.get("centre")
        if not c or len(c) != 3:
            continue
        out.append(("wild:%s" % s.get("species", "?"), float(c[0]), float(c[2]), order))

    harvest = load(os.path.join(BAND_DIR, "harvest.json"))["nodes"]
    for h in harvest:
        order = int(h.get("order", -1))
        if before_only and order >= 1000:
            continue
        at = h.get("at")
        if not at or len(at) != 2:
            continue
        out.append(("harvest:%s" % h.get("item", "?"), float(at[0]), float(at[1]), order))

    props = load(os.path.join(BAND_DIR, "props.json"))["clusters"]
    for p in props:
        order = int(p.get("order", -1))
        if before_only and order >= 1000:
            continue
        cluster_props = p.get("props", [])
        if not cluster_props:
            continue
        # anchor = this cluster's first prop, same convention every cluster's
        # own "_why": "the cluster's anchor" comment already uses.
        anchor = cluster_props[0]
        at = anchor.get("at")
        if not at or len(at) != 2:
            continue
        out.append(("prop:%s" % p.get("name", "?"), float(at[0]), float(at[1]), order))

    return out


def report(label, before_only):
    points = spine_points()
    lengths = arc_lengths(points)
    total = lengths[-1]

    on_route_arcs = [0.0, total]  # the spine's own two ends always count
    off_route = []
    for name, x, z, order in pois(before_only=before_only):
        arc, lat = project(points, lengths, x, z)
        if arc is None:
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
    print("spine length: %.0fm" % total)
    print("on-route POIs (<=%.0fm lateral): %d" % (ON_ROUTE_LATERAL_M, len(on_route_arcs) - 2))
    print("largest dead-travel gaps (m):")
    for gap, a, b in gaps[:5]:
        print("  %6.0fm  (arc %.0f -> %.0f)" % (gap, a, b))
    if off_route:
        print("off-route (optional-detour) POIs, not counted toward gaps:")
        for name, arc, lat in sorted(off_route, key=lambda x: x[1]):
            print("  %-28s arc=%.0f lateral=%.0fm" % (name, arc, lat))
    print()


if __name__ == "__main__":
    report("BEFORE (pre-BAND1-D1, order < 1000)", before_only=True)
    report("AFTER (current band1 content)", before_only=False)
