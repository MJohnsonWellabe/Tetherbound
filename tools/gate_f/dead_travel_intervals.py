#!/usr/bin/env python3
"""List EVERY dead-travel interval in a Gate F segment, not just the longest.

    tools/gate_f/dead_travel_intervals.py <run-dir> <segment> [--over-s 60] [--min-m 5]

`chain_pacing.py` reports one number per segment (the worst gap); ROADMAP.md's
Gate 2 acceptance asks for the intervals themselves -- "no dead-travel interval
over ~60 s that is not intentional" -- which means each one has to be on the
record with where it starts, where it ends, what ended it, and how far the
player walked through it, so a reader can decide which are intentional.

Definition, matching operator_harness.gd::_is_meaningful and chain_pacing.py:
a dead-travel interval runs between two meaningful events (dialogue, a fight
starting or ending, a catch, a gather, a craft, a build, a rest, a feed, an
objective change, a landmark discovery, a level-up), or a POI coming within
30 m (the harness resets its own dead_travel_m meter on that, so the meter's
own resets are honoured here too). Time is PLAY seconds from route.csv. An
interval counts only if the player actually walked through it (>= --min-m
metres between consecutive 2 Hz rows, teleports excluded), so a boot wait or a
menu is not a dead walk.
"""

import argparse
import csv
import json
import os

MEANINGFUL = {
    "dialogue", "combat_start", "combat_hit", "combat_switch", "combat_end",
    "catch_throw", "catch_result", "gather", "craft", "build_place",
    "build_dismantle", "rest", "feed", "objective", "landmark_discover",
    "level_up",
}


def f(row, key, default=0.0):
    try:
        return float(row.get(key) or default)
    except (TypeError, ValueError):
        return default


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("run_dir")
    ap.add_argument("segment")
    ap.add_argument("--over-s", type=float, default=60.0)
    ap.add_argument("--min-m", type=float, default=5.0)
    args = ap.parse_args()
    d = os.path.join(args.run_dir, args.segment, "telemetry")
    route = list(csv.DictReader(open(os.path.join(d, "route.csv"), encoding="utf-8", errors="replace")))
    events = []
    for line in open(os.path.join(d, "events.jsonl"), encoding="utf-8", errors="replace"):
        line = line.strip()
        if line:
            try:
                events.append(json.loads(line))
            except ValueError:
                pass

    # Marks: meaningful events, plus every harness meter reset (a POI within
    # 30 m resets dead_travel_m to 0 between rows).
    marks = []
    for e in events:
        if e.get("type") in MEANINGFUL:
            what = e["type"]
            if what == "objective":
                what += ":" + str((e.get("objective") or {}).get("id", ""))
            elif what == "dialogue":
                if "opened" not in str(e.get("actual", "")):
                    continue  # one mark per conversation: its opening line
                what += ":" + str(e.get("observation", ""))[:40]
            elif what == "landmark_discover":
                what += ":" + str(e.get("observation", ""))[:48]
            marks.append((f(e, "t"), what))
    prev_dead = None
    for row in route:
        dead = f(row, "dead_travel_m")
        if prev_dead is not None and dead < prev_dead - 1.0 and prev_dead > 5.0:
            marks.append((f(row, "t"), "poi-within-30m (meter reset, poi %.0f m)" % f(row, "nearest_poi_dist_m")))
        prev_dead = dead
    marks.sort()

    def row_at(t):
        best = route[0]
        for r in route:
            if f(r, "t") <= t:
                best = r
            else:
                break
        return best

    def walked(a, b):
        """Metres walked between play times a and b, and the play time of the
        first stride in that span (a boot wait or a menu before the walk is
        instrument or UI time, not dead travel, so an interval is clocked from
        the moment the player actually moved)."""
        dist = 0.0
        prev = None
        first_move = None
        for r in route:
            t = f(r, "t")
            if t < a:
                continue
            if t > b:
                break
            p = (f(r, "x"), f(r, "z"))
            if prev is not None:
                step = ((p[0] - prev[0]) ** 2 + (p[1] - prev[1]) ** 2) ** 0.5
                if step < 5.0:
                    dist += step
                    if first_move is None and step >= 0.3:
                        first_move = t
            prev = p
        return dist, first_move if first_move is not None else a

    play_end = f(route[-1], "t")
    bounds = [(0.0, "segment start")] + marks + [(play_end, "segment end")]
    intervals = []
    for i in range(len(bounds) - 1):
        a, start_what = bounds[i]
        b, end_what = bounds[i + 1]
        m, moved_at = walked(a, b)
        if m < args.min_m:
            continue
        gap = b - moved_at
        if gap <= args.over_s:
            continue
        a = moved_at
        ra, rb = row_at(a), row_at(b)
        intervals.append({
            "start_s": a, "end_s": b, "gap_s": gap, "walked_m": m,
            "from": (f(ra, "x"), f(ra, "z"), ra.get("region", "")),
            "to": (f(rb, "x"), f(rb, "z"), rb.get("region", "")),
            "opened_by": start_what, "closed_by": end_what,
            "poi_near_end_m": f(rb, "nearest_poi_dist_m"),
        })
    print("%s: %d dead-travel interval(s) over %.0f s (play clock %.0f s, %d marks)" % (
        args.segment, len(intervals), args.over_s, play_end, len(marks)))
    for k, iv in enumerate(intervals, 1):
        print("  %d. t=%.0f-%.0f s (%.0f s, %.0f m walked)  from (%.0f, %.0f) %s  to (%.0f, %.0f) %s" % (
            k, iv["start_s"], iv["end_s"], iv["gap_s"], iv["walked_m"],
            iv["from"][0], iv["from"][1], iv["from"][2], iv["to"][0], iv["to"][1], iv["to"][2]))
        print("     opened by %s; closed by %s" % (iv["opened_by"], iv["closed_by"]))
    print("marks (play s: what):")
    for t, what in marks:
        print("  %7.1f  %s" % (t, what))


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:
        pass
