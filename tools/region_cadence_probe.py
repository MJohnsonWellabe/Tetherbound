#!/usr/bin/env python3
"""Region cadence probe — measures dead travel along the authored Meadows spine.

WHY THIS EXISTS
---------------
`docs/owner/TETHERBOUND_MEADOWS_MIDGAME_FUN_REBUILD.md` section 12 sets
the authoritative cadence target:

    During required traversal, the player should rarely go more than roughly
    60-90 seconds without seeing or encountering a meaningful reason to fight,
    catch, gather, investigate, prepare, change direction, or anticipate
    something clearly visible ahead.

That is an experience target expressed in seconds. This probe converts it into
metres of authored world and then measures the world against it, so that
"the Meadows feels dead" stops being a vibe and becomes a file reference and a
number.

WHAT IT MEASURES
----------------
The authored spine is `terrain_playground.json -> trail.bands[]` (OW5C, the
South-Bridge-to-stronghold-gate route). Band 0 has no spine entry -- it is the
village, authored in `paths.routes` -- so it is handled separately.

For every point of interest (POI) the probe computes the interval of the spine
from which that POI is within the notice radius R. A POI at perpendicular
offset d from the spine covers the arc-length interval

    [s - sqrt(R^2 - d^2), s + sqrt(R^2 - d^2)]

(nothing at all, if d > R). Union those intervals; whatever is left uncovered is
a stretch of required traversal with nothing of interest in sight. That
uncovered run, in metres, is the dead-travel measurement.

This is deliberately more honest than "distance between POIs": a cluster of six
things followed by 700m of nothing scores badly here, as it should, whereas an
average-gap metric would hide it.

SPEED CONVERSION
----------------
From `data/config/movement.json`: walk 5.0 m/s, sprint 8.6 m/s. Sprint is
stamina-limited (stamina 100, drain 12/s, exhausted below 10, regen 18/s after
1.1s), so sustained sprint is impossible. The realistic cruise is a sprint/walk
sawtooth:

    sprint (100 -> 10 stamina) = 7.5s covering 64.5m
    walk while regenerating    = 1.1s + 5.0s = 6.1s covering 30.5m
    ------------------------------------------------------------
    13.6s covering 95.0m  ->  6.99 m/s sustained

So the 60-90s target is:
    walking player   : 300 - 450 m
    sprint-cruise    : 419 - 629 m

The probe reports gaps against both. A stretch that busts 90s even at
sprint-cruise (>629m) is dead by any reading and is reported as FAIL.

USAGE
    python3 tools/region_cadence_probe.py [--radius 80] [--json]
"""

import argparse
import json
import math
import os
import sys
from collections import defaultdict

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

WALK_MS = 5.0
SPRINT_MS = 8.6
# sustained sprint/walk sawtooth, derived in the docstring above
CRUISE_MS = 6.99

TARGET_S_LOW = 60.0
TARGET_S_HIGH = 90.0

BANDS = [
    "band1_lower_meadows",
    "band2_stone_and_root",
    "band3_the_river_lock",
    "band4_upper_meadows_ironwood",
    "band5_stronghold_approach",
]


def load(path):
    with open(os.path.join(REPO, path)) as f:
        return json.load(f)


# ---------------------------------------------------------------- spine


def polyline_length(pts):
    return sum(
        math.dist(pts[i], pts[i + 1]) for i in range(len(pts) - 1)
    )


def project_onto_polyline(pts, p):
    """Return (arclength_of_closest_point, perpendicular_distance)."""
    best = (0.0, float("inf"))
    acc = 0.0
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        abx, aby = b[0] - a[0], b[1] - a[1]
        seg = math.hypot(abx, aby)
        if seg == 0:
            continue
        t = ((p[0] - a[0]) * abx + (p[1] - a[1]) * aby) / (seg * seg)
        t = max(0.0, min(1.0, t))
        cx, cy = a[0] + abx * t, a[1] + aby * t
        d = math.hypot(p[0] - cx, p[1] - cy)
        if d < best[1]:
            best = (acc + seg * t, d)
        acc += seg
    return best


# ---------------------------------------------------------------- POIs


def band_pois(band):
    """Every authored reason-to-care in a band, as (kind, label, (x,z), extra_r).

    `extra_r` widens the notice radius for things that are physically large --
    a creature cluster with radius 15 is noticeable from 15m further out than a
    single berry bush.
    """
    out = []
    base = "data/config/bands/%s/" % band

    spawns = load(base + "spawns.json")["spawns"]
    for s in spawns:
        c = s["centre"]
        xz = (c[0], c[2]) if len(c) == 3 else (c[0], c[1])
        tag = "spawn"
        if s.get("elder"):
            tag = "spawn_elder"
        elif s.get("alpha"):
            tag = "spawn_alpha"
        out.append(
            (
                tag,
                "%s x%s" % (s["species"], s.get("count", 1)),
                xz,
                float(s.get("radius", 0.0)),
                {"order": s["order"], "time": s.get("time"), "weather": s.get("weather")},
            )
        )

    for t in load(base + "trainers.json")["trainers"]:
        p = t["position"]
        xz = (p[0], p[2]) if len(p) == 3 else (p[0], p[1])
        out.append(
            (
                "trainer",
                t["id"],
                xz,
                0.0,
                {"order": t["order"], "rank": t.get("rank"), "placed_by": t.get("placed_by")},
            )
        )

    for h in load(base + "harvest.json")["nodes"]:
        a = h["at"]
        out.append(
            ("harvest", "%s(%s)" % (h["item"], h["order"]), (a[0], a[1]), 0.0, {"order": h["order"]})
        )

    for c in load(base + "props.json")["clusters"]:
        ps = c["props"]
        cx = sum(p["at"][0] for p in ps) / len(ps)
        cz = sum(p["at"][1] for p in ps) / len(ps)
        spread = max(math.hypot(p["at"][0] - cx, p["at"][1] - cz) for p in ps)
        out.append(
            ("prop_cluster", c["name"], (cx, cz), spread, {"order": c["order"], "n": len(ps)})
        )

    return out


def code_placed_pois():
    """POIs that live in scripts/world/playground_world.gd, not in the band configs.

    Parsed out of the GDScript rather than duplicated here, so this probe cannot
    silently drift from the world it is measuring. These are real, one-time,
    high-value finds (TM discs, item caches, the Sunstone, the ruined watchtower,
    the gates) and leaving them out would overstate dead travel.
    """
    import re

    src = open(os.path.join(REPO, "scripts/world/playground_world.gd")).read()
    out = []

    m = re.search(r"const TM_AT := \{(.*?)\n\}", src, re.S)
    if m:
        for tid, x, z in re.findall(
            r'"(tm_[a-z_]+)":\s*Vector2\(([-\d.]+),\s*([-\d.]+)\)', m.group(1)
        ):
            out.append(("pickup_tm", tid, (float(x), float(z)), 0.0, {}))

    m = re.search(r"const CACHE_AT := \{(.*?)\n\}", src, re.S)
    if m:
        for cid, x, z in re.findall(
            r'"([a-z_]+)":\s*Vector2\(([-\d.]+),\s*([-\d.]+)\)', m.group(1)
        ):
            out.append(("pickup_cache", cid, (float(x), float(z)), 0.0, {}))

    for name, kind in [
        ("SUNSTONE_AT", "pickup_cache"),
        ("GATE_KEY_AT", "pickup_cache"),
        ("WATCHTOWER_AT", "structure"),
        ("SIGIL_GATE_AT", "structure"),
        ("GATE_AT", "structure"),
        ("SIGNPOST_AT", "signpost"),
        ("HOUSE_AT", "structure"),
    ]:
        mm = re.search(r"const %s := Vector2\(([-\d.]+),\s*([-\d.]+)\)" % name, src)
        if mm:
            out.append((kind, name, (float(mm.group(1)), float(mm.group(2))), 0.0, {}))

    return out


def global_pois():
    """Landmarks and named regions -- the 'anticipate something visible ahead' tier."""
    out = code_placed_pois()
    m = load("data/config/map_landmarks.json")
    for l in m["landmarks"]:
        p = l["position"]
        out.append(
            ("landmark", l["id"], (p[0], p[1]), float(l.get("discover_radius", 0.0)), {"category": l.get("category")})
        )
    for r in m["regions"]:
        c = r["centre"]
        out.append(("region", r["id"], (c[0], c[1]), float(r.get("radius", 0.0)), {}))
    return out


# ---------------------------------------------------------------- coverage


def coverage_gaps(length, intervals):
    """Uncovered runs of [0, length] given a list of (start, end)."""
    if not intervals:
        return [(0.0, length)]
    ivs = sorted(intervals)
    merged = [list(ivs[0])]
    for a, b in ivs[1:]:
        if a <= merged[-1][1]:
            merged[-1][1] = max(merged[-1][1], b)
        else:
            merged.append([a, b])
    gaps = []
    cur = 0.0
    for a, b in merged:
        if a > cur:
            gaps.append((cur, min(a, length)))
        cur = max(cur, b)
        if cur >= length:
            break
    if cur < length:
        gaps.append((cur, length))
    return [(a, b) for a, b in gaps if b - a > 1e-6]


# Per-kind notice radius, in metres. A flat radius is a lie: a human standing on
# a ridge and a berry bush in long grass are not noticeable at the same distance,
# and using one number for both makes any world "pass".
NOTICE = {
    "landmark": 200.0,      # authored orientation features, often silhouetted
    "region": 150.0,        # named places
    "prop_cluster": 60.0,   # a camp, a work area, a ruin
    "trainer": 50.0,        # a standing human in grassland
    "spawn_elder": 70.0,    # deliberately larger//rarer individual
    "spawn_alpha": 70.0,
    "spawn": 40.0,          # ordinary creature cluster
    "harvest": 22.0,        # a bush, a deadwood pile, an ore lump
    "structure": 250.0,     # watchtower, gate, house -- built to be seen far off
    "signpost": 40.0,
    "pickup_tm": 35.0,      # a disc on the ground
    "pickup_cache": 30.0,
}

# Which kinds count for which cadence tier.
#   A = structural interest: something authored, distinct, worth changing
#       direction for. This is what "the Meadows feels dead" is actually about.
#   B = A plus gathering.
#   C = everything, ordinary respawning wildlife included.
TIER_A = {"landmark", "region", "prop_cluster", "trainer", "spawn_elder", "spawn_alpha",
          "structure", "signpost", "pickup_tm", "pickup_cache"}
TIER_B = TIER_A | {"harvest"}
TIER_C = TIER_B | {"spawn"}
TIERS = {"A_structural": TIER_A, "B_plus_gathering": TIER_B, "C_everything": TIER_C}


def analyse(band, spine, radius, kinds=None, scale=1.0):
    length = polyline_length(spine)
    pois = band_pois(band) + global_pois()
    intervals = []
    on_route = []
    for kind, label, xz, extra, meta in pois:
        if kinds is not None and kind not in kinds:
            continue
        s, d = project_onto_polyline(spine, xz)
        r = (NOTICE.get(kind, radius) * scale) + extra
        if d <= r:
            half = math.sqrt(max(0.0, r * r - d * d))
            intervals.append((s - half, s + half))
            on_route.append((s, d, kind, label, meta))
    gaps = coverage_gaps(length, intervals)
    on_route.sort()
    return {
        "band": band,
        "length_m": length,
        "radius_m": radius,
        "poi_total": len(pois),
        "poi_on_route": len(on_route),
        "on_route": on_route,
        "gaps": gaps,
        "covered_m": length - sum(b - a for a, b in gaps),
    }


def fmt_secs(m):
    return "%.0fs walk / %.0fs cruise" % (m / WALK_MS, m / CRUISE_MS)


def verdict(longest_m):
    if longest_m > TARGET_S_HIGH * CRUISE_MS:
        return "FAIL"
    if longest_m > TARGET_S_HIGH * WALK_MS:
        return "PARTIAL"
    return "PASS"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--radius", type=float, default=80.0,
                    help="notice radius in metres (default 80, matching map reveal_radius)")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    tp = load("data/config/terrain_playground.json")
    spines = {b["id"]: [tuple(p) for p in b["points"]] for b in tp["trail"]["bands"]}

    print("=" * 78)
    print("REGION CADENCE PROBE — dead travel along the authored Meadows spine")
    print("=" * 78)
    print("notice radius      : %.0f m" % args.radius)
    print("walk / cruise speed: %.1f / %.2f m/s" % (WALK_MS, CRUISE_MS))
    print("FUN sec12 target   : %.0f-%.0f s  =  %.0f-%.0f m walking, %.0f-%.0f m cruising"
          % (TARGET_S_LOW, TARGET_S_HIGH,
             TARGET_S_LOW * WALK_MS, TARGET_S_HIGH * WALK_MS,
             TARGET_S_LOW * CRUISE_MS, TARGET_S_HIGH * CRUISE_MS))
    print("PASS <= %.0fm | PARTIAL <= %.0fm | FAIL > %.0fm"
          % (TARGET_S_HIGH * WALK_MS, TARGET_S_HIGH * CRUISE_MS, TARGET_S_HIGH * CRUISE_MS))
    print()

    print("per-kind notice radii: %s" % NOTICE)
    print()

    allres = {}
    for tname, kinds in TIERS.items():
        print("=" * 78)
        print("TIER %s  (kinds: %s)" % (tname, ", ".join(sorted(kinds))))
        print("=" * 78)
        results = []
        for band in BANDS:
            r = analyse(band, spines[band], args.radius, kinds)
            results.append(r)
            gaps = r["gaps"]
            longest = max((b - a for a, b in gaps), default=0.0)
            print("-" * 78)
            print("%s" % band)
            print("  spine length     : %.0f m  (%s)" % (r["length_m"], fmt_secs(r["length_m"])))
            print("  POIs on route    : %d" % r["poi_on_route"])
            print("  spine covered    : %.0f m (%.1f%%)"
                  % (r["covered_m"], 100.0 * r["covered_m"] / r["length_m"]))
            print("  dead runs >100m  : %d" % len([1 for a, b in gaps if b - a > 100]))
            print("  LONGEST DEAD RUN : %.0f m  (%s)  -> %s"
                  % (longest, fmt_secs(longest), verdict(longest)))
            for a, b in sorted(gaps, key=lambda g: g[0] - g[1])[:5]:
                if b - a < 150:
                    continue
                print("      %7.0f m .. %7.0f m   = %6.0f m  (%s)"
                      % (a, b, b - a, fmt_secs(b - a)))
            kinds_ct = defaultdict(int)
            for _, _, k, _, _ in r["on_route"]:
                kinds_ct[k] += 1
            print("  on-route mix     : %s" % dict(kinds_ct))
        allres[tname] = results
        print()

    print("=" * 78)
    print("SUMMARY — longest dead run per band per tier (metres)")
    print("=" * 78)
    print("%-32s %14s %14s %14s" % ("band", "A structural", "B +gathering", "C everything"))
    for i, band in enumerate(BANDS):
        row = []
        for tname in ("A_structural", "B_plus_gathering", "C_everything"):
            r = allres[tname][i]
            longest = max((b - a for a, b in r["gaps"]), default=0.0)
            row.append("%6.0f %-7s" % (longest, verdict(longest)))
        print("%-32s %14s %14s %14s" % (band, *row))
    total = sum(r["length_m"] for r in allres["A_structural"])
    print()
    print("  total authored spine: %.0f m  (%s), one way, no backtracking"
          % (total, fmt_secs(total)))

    if args.json:
        with open(os.path.join(REPO, "cadence_probe.json"), "w") as f:
            json.dump(
                {t: [{k: v for k, v in r.items() if k != "on_route"} for r in rs]
                 for t, rs in allres.items()}, f, indent=1
            )

    return 0


if __name__ == "__main__":
    sys.exit(main())
