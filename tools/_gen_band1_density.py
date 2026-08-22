#!/usr/bin/env python3
"""BAND1-D1 density raise -- owner directive 2026-08-22 (Pokemon/Palworld/
Valheim density comparison): band1's authored wild population has to move
from ~24 creatures/1872m spine (~1 per 78m) to roughly 170-260 creatures
across 45-60 clusters, clusters of 3-5, spaced every 30-50m of route, plus
off-route habitat pockets.

This generates the ADDITIONAL spawns.json entries (order 1006+, inside
band1's reserved 1000-1999 range) and prints them as JSON fragments to splice
into data/config/bands/band1_lower_meadows/spawns.json by hand -- kept as a
throwaway generator script, not part of the shipped data path, so the
authored file stays the source of truth and every entry's `_why_d1` records
where it actually landed.

METHOD
------
Walk the real band1 spine polyline (terrain_playground.json trail.bands[0])
at ~40m arc-length steps. Skip the first ~55m (village hub -- already the
densest single area in the band, tournament block, existing trainers) and
the last ~40m (the run-in to the south_bridge_grunt gate, kept deliberately
clear per this band's own design note). For each step, offset laterally
(15-45m, alternating side) and place a cluster of 3-5, species chosen by
locale:
  - within ~80m of the pond centre (-342,507): pond species (mildly, to
    respect the "preserve the approved lush pond pocket" constraint -- these
    are placed at the pocket's OUTER edge, not inside it)
  - within ~120m of the oak grove ring (230,830): a grove-flavoured mix
  - otherwise: open-field species

Also emits a handful of off-route habitat pockets (70-160m lateral) so
leaving the spine is rewarded, not just walking it slower.
"""

import json
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TERRAIN_PATH = os.path.join(ROOT, "data", "config", "terrain_playground.json")

POND_CENTRE = (-342.0, 507.0)
GROVE_CENTRE = (230.0, 830.0)

FIELD_SPECIES = ["bramblebun", "mudsnout", "pipwing", "galecrest"]
POND_EDGE_SPECIES = ["paddlenewt", "mosshell", "brooktail", "reedwing"]
GROVE_SPECIES = ["mudsnout", "pipwing", "bramblebun"]


def spine_points():
    with open(TERRAIN_PATH) as f:
        terrain = json.load(f)
    for band in terrain["trail"]["bands"]:
        if band["id"] == "band1_lower_meadows":
            return [tuple(p) for p in band["points"]]
    raise SystemExit("band1 not found")


def arc_lengths(points):
    lengths = [0.0]
    for i in range(1, len(points)):
        x0, z0 = points[i - 1]
        x1, z1 = points[i]
        lengths.append(lengths[-1] + math.hypot(x1 - x0, z1 - z0))
    return lengths


def point_and_heading_at_arc(points, lengths, arc):
    for i in range(1, len(points)):
        if lengths[i - 1] <= arc <= lengths[i]:
            x0, z0 = points[i - 1]
            x1, z1 = points[i]
            seg_len = lengths[i] - lengths[i - 1]
            t = 0.0 if seg_len == 0 else (arc - lengths[i - 1]) / seg_len
            x = x0 + t * (x1 - x0)
            z = z0 + t * (z1 - z0)
            dx, dz = x1 - x0, z1 - z0
            seg_norm = math.hypot(dx, dz) or 1.0
            # perpendicular (left-hand) unit vector
            px, pz = -dz / seg_norm, dx / seg_norm
            return x, z, px, pz
    return points[-1][0], points[-1][1], 0.0, 1.0


def species_for(x, z):
    dpond = math.hypot(x - POND_CENTRE[0], z - POND_CENTRE[1])
    dgrove = math.hypot(x - GROVE_CENTRE[0], z - GROVE_CENTRE[1])
    if dpond <= 90.0:
        return POND_EDGE_SPECIES
    if dgrove <= 130.0:
        return GROVE_SPECIES
    return FIELD_SPECIES


def main():
    points = spine_points()
    lengths = arc_lengths(points)
    total = lengths[-1]

    START_SKIP = 55.0
    END_SKIP = 40.0
    STEP = 55.0

    order = 1006
    side = 1
    entries = []

    # Arcs already carrying a hand-authored BAND1-D1 corridor cluster (orders
    # 1002-1004: pipwing/bramblebun/mudsnout, each deliberately paired with a
    # nearby harvest node or the trail_camp prop cluster) -- skip generating
    # a near-duplicate on top of them rather than crowding two clusters into
    # one spot.
    EXISTING_ARCS = [1191.0, 1378.0, 1686.0]
    EXISTING_BUFFER = 30.0

    arc = START_SKIP
    idx = 0
    while arc < total - END_SKIP:
        if any(abs(arc - existing) < EXISTING_BUFFER for existing in EXISTING_ARCS):
            arc += STEP
            continue
        x, z, px, pz = point_and_heading_at_arc(points, lengths, arc)
        lateral = 15.0 + (idx % 3) * 12.0  # 15 / 27 / 39 m, cycling
        side = 1 if idx % 2 == 0 else -1
        cx = x + px * lateral * side
        cz = z + pz * lateral * side
        species_pool = species_for(cx, cz)
        species = species_pool[idx % len(species_pool)]
        count = 3 + (idx % 3)  # 3,4,5 cycling
        radius = 10.0 + count * 1.4
        entries.append({
            "order": order,
            "species": species,
            "count": count,
            "centre": [round(cx, 1), 0.0, round(cz, 1)],
            "radius": round(radius, 1),
            "_why_d1": "BAND1-D1-DENSITY. Owner directive 2026-08-22 (density comparison to Pokemon/Palworld/Valheim): route cluster at ~%.0fm arc, %.0fm lateral, %s side of the spine." % (arc, lateral, "left" if side > 0 else "right"),
        })
        order += 1
        idx += 1
        arc += STEP

    # Manual nudges for the handful of generated centres that land on top of
    # an authored structure/clearing (checked by hand against village.json,
    # terrain_playground.json crossings and this band's own vegetation.json
    # footprints -- the generator only knows the spine, not what stands
    # beside it).
    OVERRIDES = {
        # order 1019 landed at (-385.4,511.1)/r15.6, ~5m from the mill
        # (-382,514) and inside its own vegetation footprint/clearing --
        # pushed downstream along the shore instead, past the bridge_repair
        # site and still pond-edge species.
        1019: {"centre": [-345.0, 0.0, 595.0]},
    }
    for e in entries:
        if e["order"] in OVERRIDES:
            e.update(OVERRIDES[e["order"]])
            e["_why_d1"] += " Nudged off the mill/footbridge footprint by hand -- see tools/_gen_band1_density.py's own OVERRIDES."

    # A handful of off-route habitat pockets: further off the spine, so
    # leaving the trail is rewarded. Placed near real terrain features
    # already authored (pond far shore, grove ring, the open field the
    # galecrest/aggressor cluster already occupies) rather than blind offsets.
    off_route = [
        (-420.0, 610.0, "brooktail", 4, "far shore of the pond, past the approved lush pocket -- a second pond-edge pull for a player who circles the water rather than crossing at the mill."),
        (330.0, 780.0, "pipwing", 4, "the oak grove ring's own far side (leaves centre (230,830)), off the spine's (230,830) vertex by ~110m -- a grove interior pocket rather than another roadside cluster."),
        (-260.0, 950.0, "bramblebun", 5, "open field well west of the spine's eastward bulge through (360,910)/(430,1020) -- rewards cutting the corner instead of following the road's own longer arc."),
        (500.0, 1050.0, "galecrest", 3, "the open rise east of the spine near its (430,1020) apex -- a second galecrest sighting away from the practice-meadow original, echoing the 'upper ridge' aggressor role out here."),
        (-30.0, 1150.0, "mudsnout", 4, "a pocket short of the South Bridge approach, west of the spine's return swing through (30,1250) -- keeps the final stretch from reading as road-only even though the immediate run-in to the grunt checkpoint stays clear by design."),
    ]
    for x, z, species, count, why in off_route:
        radius = 12.0 + count * 1.4
        entries.append({
            "order": order,
            "species": species,
            "count": count,
            "centre": [x, 0.0, z],
            "radius": round(radius, 1),
            "_why_d1": "BAND1-D1-DENSITY off-route habitat pocket. %s" % why,
        })
        order += 1

    total_clusters_new = len(entries)
    total_creatures_new = sum(e["count"] for e in entries)
    print("// generated %d clusters, %d creatures (orders 1006-%d)" % (
        total_clusters_new, total_creatures_new, order - 1))
    for e in entries:
        print(json.dumps(e))


if __name__ == "__main__":
    main()
