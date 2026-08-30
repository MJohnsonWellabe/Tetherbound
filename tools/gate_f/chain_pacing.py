#!/usr/bin/env python3
"""Turn a chained Gate F run into the numbers ACTIVE_GAME_PLAN.md section 5 asks for.

Reads every segment's telemetry/route.csv and telemetry/events.jsonl in one run
directory and reports, per segment and for the chapter:

  * play-clock duration and wall-clock duration (they are different clocks and
    the harness keeps them apart on purpose -- see operator_harness.gd _play_t);
  * distance walked, and the longest dead-travel run in metres AND in play
    seconds (section F: a dead-travel run ends on a meaningful interaction or on
    a POI within 30 m);
  * encounter cadence -- combats, catches, gathers, dialogues, rests, objective
    changes -- as counts and as gaps;
  * party composition at the start and end of each segment;
  * step verdicts and every defect raised.

    tools/gate_f/chain_pacing.py ralph/reports/gate-f-run-<stamp>
"""

import csv
import json
import os
import sys

CHAIN = ["S01", "S02", "S03", "S04", "S05", "S06", "S07", "S08", "S09",
         "S10a", "S10b", "S10c", "S10d", "S10e"]

# operator_harness.gd::_is_meaningful, verbatim. A dead-travel interval is the
# stretch between two of these.
MEANINGFUL = {
    "dialogue", "combat_start", "combat_hit", "combat_switch", "combat_end",
    "catch_throw", "catch_result", "gather", "craft", "build_place",
    "build_dismantle", "rest", "feed", "objective", "landmark_discover",
    "level_up",
}

# The cadence buckets the plan names: wild, trainer, resource, rest.
CADENCE = {
    "combat_start": "fight",
    "catch_result": "catch",
    "gather": "resource",
    "craft": "resource",
    "build_place": "build",
    "rest": "rest",
    "feed": "care",
    "dialogue": "talk",
    "objective": "objective",
    "level_up": "level",
    "landmark_discover": "landmark",
}


def read_events(path):
    out = []
    if not os.path.exists(path):
        return out
    with open(path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                out.append(json.loads(line))
            except ValueError:
                continue
    return out


def read_route(path):
    if not os.path.exists(path):
        return []
    with open(path, encoding="utf-8", errors="replace") as fh:
        return list(csv.DictReader(fh))


def f(row, key, default=0.0):
    try:
        return float(row.get(key) or default)
    except (TypeError, ValueError):
        return default


def segment_report(run_dir, seg):
    d = os.path.join(run_dir, seg)
    ev = read_events(os.path.join(d, "telemetry", "events.jsonl"))
    route = read_route(os.path.join(d, "telemetry", "route.csv"))
    r = {"id": seg, "present": os.path.isdir(d), "events": len(ev),
         "route_rows": len(route)}
    if not r["present"]:
        return r

    # Step verdicts are not in the event stream -- the harness puts its own
    # tally in INVENTORY.json and the per-step verdict lines in notes/. Read the
    # tally rather than re-deriving one that could disagree with the segment.
    verd = {}
    inv_path = os.path.join(d, "INVENTORY.json")
    if os.path.exists(inv_path):
        try:
            inv = json.load(open(inv_path))
            s = inv.get("steps", {})
            verd = {"PASS": s.get("pass", 0), "FAIL": s.get("fail", 0),
                    "SKIP": s.get("skipped", 0), "DELEGATED": s.get("delegated", 0),
                    "TOTAL": s.get("total", 0)}
            r["derailed"] = inv.get("derailed") or ""
            r["derailed_at"] = inv.get("derailed_at") or ""
            r["complete"] = inv.get("complete")
            r["harness_errors"] = inv.get("harness_errors") or []
        except (ValueError, OSError):
            pass

    defects = []
    cadence = {}
    marks = []          # (play_t, type) for every meaningful event
    for e in ev:
        t = e.get("type")
        if t == "defect":
            defects.append(e)
        if t in MEANINGFUL:
            marks.append((f(e, "t"), t))
        bucket = CADENCE.get(t)
        if bucket:
            cadence[bucket] = cadence.get(bucket, 0) + 1
    r["verdicts"] = verd
    r["defects"] = defects
    r["cadence"] = cadence

    if route:
        r["play_s"] = f(route[-1], "t")
        r["dead_peak_m"] = max(f(x, "dead_travel_m") for x in route)
        # Longest stretch with no meaningful mark, in play seconds -- but only
        # counting stretches the player actually TRAVELLED through.
        #
        # Without the movement filter this metric is dominated by the boot wait:
        # every segment opens with a 180 s world stand-up during which the
        # player does not exist yet, which is instrument cost, not a dead walk.
        # Section 5 asks for "travel without a meaningful gameplay or visual
        # pull", so a stretch where nobody moved is not one.
        moved_by_t = []
        prev = None
        acc = 0.0
        for row in route:
            p = (f(row, "x"), f(row, "z"))
            if prev is not None:
                step = ((p[0] - prev[0]) ** 2 + (p[1] - prev[1]) ** 2) ** 0.5
                if step < 5.0:
                    acc += step
            prev = p
            moved_by_t.append((f(row, "t"), acc))

        def travelled(a, b):
            """Metres walked between two play timestamps."""
            lo = hi = None
            for t, m in moved_by_t:
                if lo is None and t >= a:
                    lo = m
                if t <= b:
                    hi = m
            return 0.0 if lo is None or hi is None else max(0.0, hi - lo)

        ts = sorted(t for t, _ in marks)
        span_start, worst, worst_at, worst_m = 0.0, 0.0, 0.0, 0.0
        for t in ts + [r["play_s"]]:
            gap = t - span_start
            walked = travelled(span_start, t)
            # 5 m is a couple of strides: below that the player was standing
            # still, whatever the clock did.
            if walked >= 5.0 and gap > worst:
                worst, worst_at, worst_m = gap, span_start, walked
            span_start = t
        r["dead_peak_s"] = worst
        r["dead_peak_s_at"] = worst_at
        r["dead_peak_s_m"] = worst_m
        # Distance walked: route rows are 2 Hz, so summing per-row movement is a
        # lower bound on path length, not the harness's own per-frame figure.
        dist = 0.0
        prev = None
        regions = {}
        for row in route:
            p = (f(row, "x"), f(row, "z"))
            if prev is not None:
                step = ((p[0] - prev[0]) ** 2 + (p[1] - prev[1]) ** 2) ** 0.5
                if step < 5.0:
                    dist += step
            prev = p
            reg = row.get("region") or "?"
            regions[reg] = regions.get(reg, 0) + 1
        r["walk_m"] = dist
        r["regions"] = sorted(regions.items(), key=lambda kv: -kv[1])[:4]
        fr = [f(x, "frame_ms") for x in route if f(x, "frame_ms") > 0]
        r["frame_ms_med"] = sorted(fr)[len(fr) // 2] if fr else None
    return r


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: chain_pacing.py <run-dir>")
    run_dir = sys.argv[1]

    wall = {}
    log = os.path.join(run_dir, "CHAIN_LOG.tsv")
    if os.path.exists(log):
        with open(log) as fh:
            for row in csv.DictReader(fh, delimiter="\t"):
                try:
                    wall[row["segment"]] = int(row["wall_s"])
                except (KeyError, TypeError, ValueError):
                    pass

    reports = [segment_report(run_dir, s) for s in CHAIN]

    print("# chapter pacing —", run_dir)
    print()
    hdr = ("seg", "play_s", "wall_s", "walk_m", "dead_m", "dead_s", "P", "F",
           "SKIP", "defects", "ms")
    print("| " + " | ".join(hdr) + " |")
    print("|" + "---|" * len(hdr))
    tot_play = tot_wall = tot_walk = 0.0
    tp = tf = tk = 0
    for r in reports:
        if not r["present"]:
            print("| %s | — | — | — | — | — | — | — | — | — | — |" % r["id"])
            continue
        v = r.get("verdicts", {})
        tp += v.get("PASS", 0)
        tf += v.get("FAIL", 0)
        tk += v.get("SKIP", 0)
        tot_play += r.get("play_s", 0.0)
        tot_wall += wall.get(r["id"], 0)
        tot_walk += r.get("walk_m", 0.0)
        fm = r.get("frame_ms_med")
        print("| %s | %.0f | %s | %.0f | %.0f | %.0f | %d | %d | %d | %d | %s |" % (
            r["id"], r.get("play_s", 0), wall.get(r["id"], "—"),
            r.get("walk_m", 0), r.get("dead_peak_m", 0), r.get("dead_peak_s", 0),
            v.get("PASS", 0), v.get("FAIL", 0), v.get("SKIP", 0),
            len(r.get("defects", [])), ("%.1f" % fm) if fm else "—"))
    print("| **total** | **%.0f** (%.2f h) | **%.0f** (%.2f h) | **%.0f** | | | **%d** | **%d** | **%d** | | |"
          % (tot_play, tot_play / 3600.0, tot_wall, tot_wall / 3600.0,
             tot_walk, tp, tf, tk))

    print()
    print("## encounter cadence")
    buckets = sorted({b for r in reports for b in r.get("cadence", {})})
    print("| seg | " + " | ".join(buckets) + " |")
    print("|" + "---|" * (len(buckets) + 1))
    for r in reports:
        if not r["present"]:
            continue
        print("| %s | %s |" % (r["id"], " | ".join(
            str(r.get("cadence", {}).get(b, 0)) for b in buckets)))

    print()
    print("## defects")
    for r in reports:
        for d in r.get("defects", []):
            print("- **%s** `%s` — expected: %s / actual: %s" % (
                r["id"], d.get("severity_candidate", "?"),
                str(d.get("expected", ""))[:160],
                str(d.get("actual", d.get("observation", "")))[:240]))

    print()
    print("## regions visited")
    for r in reports:
        if r.get("regions"):
            print("- %s: %s" % (r["id"], ", ".join(
                "%s (%d rows)" % (k, v) for k, v in r["regions"])))


if __name__ == "__main__":
    main()
