#!/usr/bin/env python3
"""Turn a PLAYED Gate F journey's telemetry into a capture-lane segment that
photographs the same route, so the blind visual judge sees frames from where
the player actually went rather than from a capture tool posed at ideal stands.

    tools/gate_f/derive_gate2_route_captures.py <run-dir> [--segments S04,S05]
        [--every-s 90] [--max 28] [--out <segment.json>]

Reads <run-dir>/<segment>/telemetry/route.csv (2 Hz trace) and events.jsonl,
picks one sample every `--every-s` seconds of PLAY clock plus one at every
meaningful event the harness recorded (fight, dialogue, catch, gather, objective
change, landmark, region change), and writes a step-script for
`tools/gate_f/operator_harness.gd` that, from the segment's own entry save:

  * boots the real title screen and loads the seeded slot,
  * for each sample: pins the clock to the hour the trace recorded, teleports
    the player to the traced position (a DIAG step, marked as such), turns the
    real gameplay camera to the yaw the trace recorded, lets the world stream
    in, and takes a `capture` with the HUD on.

Why teleport and not walk. Under xvfb every physics frame is a rendered
1280x800 frame at several seconds each on llvmpipe (harness_config.json's
CD-7 note), so re-walking a ~2 km route for its frames would cost a day. The
route was already walked for real in the logic lane; this lane only has to
stand where that walk stood. The positions, headings and clock come from the
walk's own record, not from anyone's idea of a good stand.

The frames it takes are gameplay-camera frames: whatever the camera rig does
at that position (terrain occlusion, grass in the lens, the trainer's back)
is what the player would see, and is judged as such.
"""

import argparse
import csv
import json
import math
import os
import sys

MEANINGFUL = {
    "dialogue", "combat_start", "combat_end", "catch_result", "gather",
    "objective", "landmark_discover", "level_up", "region_enter",
}

# Events whose frame is worth more than a route sample: keep these even when
# they fall inside the sampling gap.
EVENT_LABEL = {
    "combat_start": "fight-starts",
    "combat_end": "fight-ends",
    "dialogue": "dialogue",
    "catch_result": "catch",
    "gather": "gather",
    "objective": "objective",
    "landmark_discover": "landmark",
    "level_up": "level-up",
    "region_enter": "region-change",
}


def read_route(path):
    rows = []
    if not os.path.exists(path):
        return rows
    with open(path, newline="", encoding="utf-8", errors="replace") as fh:
        for row in csv.DictReader(fh):
            try:
                rows.append({
                    "t": float(row["t"]),
                    "x": float(row["x"]), "y": float(row["y"]), "z": float(row["z"]),
                    "heading": float(row["heading"]),
                    "region": row.get("region", ""),
                    "clock_hour": float(row.get("clock_hour", 0.0) or 0.0),
                    "weather": row.get("weather", ""),
                    "dead_travel_m": float(row.get("dead_travel_m", 0.0) or 0.0),
                    "input_context": row.get("input_context", ""),
                })
            except (KeyError, ValueError):
                continue
    return rows


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
            except json.JSONDecodeError:
                continue
    return out


def camera_yaw_at(events, t):
    """The gameplay camera yaw (degrees) the harness recorded nearest to play time t."""
    best = None
    for ev in events:
        cam = ev.get("camera") or {}
        if "yaw" not in cam:
            continue
        dt = abs(float(ev.get("t", 0.0)) - t)
        if best is None or dt < best[0]:
            best = (dt, float(cam["yaw"]))
    return best[1] if best and best[0] <= 30.0 else None


def travel_yaw(rows, i):
    """Camera yaw that looks the way the trace was moving at row i, in the
    `face` step's convention (Godot yaw, degrees, 0 = facing -Z)."""
    j = min(len(rows) - 1, i + 4)
    k = max(0, i - 4)
    dx = rows[j]["x"] - rows[k]["x"]
    dz = rows[j]["z"] - rows[k]["z"]
    if abs(dx) + abs(dz) < 0.5:
        return rows[i]["heading"]
    return math.degrees(math.atan2(-dx, -dz))


def pick_samples(rows, events, every_s, cap):
    samples = []
    if not rows:
        return samples
    next_t = rows[0]["t"]
    last_region = None
    for i, row in enumerate(rows):
        label = None
        if row["region"] != last_region and last_region is not None:
            label = "region-change"
        last_region = row["region"]
        if row["t"] >= next_t:
            label = label or "route"
            next_t = row["t"] + every_s
        if label:
            samples.append((row["t"], label, i))
    # Event frames: the moments the pacing study calls meaningful.
    for ev in events:
        typ = str(ev.get("type", ""))
        if typ not in EVENT_LABEL:
            continue
        if typ == "combat_end":
            continue
        t = float(ev.get("t", 0.0))
        # Nearest trace row to the event.
        i = min(range(len(rows)), key=lambda n: abs(rows[n]["t"] - t))
        samples.append((t, EVENT_LABEL[typ], i))
    samples.sort()
    # Collapse samples closer than 6 s of play; event labels win over route.
    merged = []
    for t, label, i in samples:
        if merged and t - merged[-1][0] < 6.0:
            if merged[-1][1] == "route" and label != "route":
                merged[-1] = (t, label, i)
            continue
        merged.append((t, label, i))
    if len(merged) > cap:
        # Thin evenly across the whole segment, keeping the first and last
        # stands. Thinning only the plain "route" samples was not enough: a
        # tournament segment is nearly all event frames (dialogue, three
        # fights, eight level-ups) in ONE place, and a contact sheet weighted
        # 14-to-17 toward the arena tells the judge about the arena rather
        # than about the 2 km route the gate is actually about.
        step = (len(merged) - 1) / float(cap - 1) if cap > 1 else len(merged)
        merged = [merged[int(round(i * step))] for i in range(cap)]
    return merged


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("run_dir")
    ap.add_argument("--segments", default="S04,S05")
    ap.add_argument("--every-s", type=float, default=90.0)
    ap.add_argument("--max", default="28",
                    help="stands per segment; a single number, or one per segment "
                         "comma-separated (e.g. \"6,20\") -- the tournament is one place and "
                         "needs far fewer stands than the 2 km route south")
    ap.add_argument("--seed", default="run://S04-exit.json")
    ap.add_argument("--id", default="G2C")
    ap.add_argument("--out", default=None)
    ap.add_argument("--load-settle-frames", type=int, default=240)
    ap.add_argument("--resettle-frames", type=int, default=45)
    ap.add_argument("--look-frames", type=int, default=15)
    ap.add_argument("--face-frames", type=int, default=45,
                    help="physics frames the camera turn may spend. In capture mode EVERY physics "
                         "frame is a rendered frame (harness_config.json's CD-7 note), so a "
                         "generous turn budget is the single most expensive knob here")
    ap.add_argument("--face-tolerance", type=float, default=8.0)
    args = ap.parse_args()

    out = args.out or os.path.join(args.run_dir, "%s.json" % args.id)
    seg_names = [x.strip() for x in args.segments.split(",") if x.strip()]
    caps = [int(x) for x in str(args.max).split(",")]
    if len(caps) == 1:
        caps = caps * len(seg_names)
    if len(caps) != len(seg_names):
        raise SystemExit("--max needs one number, or one per segment (%d given for %d segments)"
                         % (len(caps), len(seg_names)))
    steps = []
    n = 0

    def step(action, title, **kw):
        nonlocal n
        n += 1
        s = {"id": "%s-%02d" % (args.id, n), "action": action, "title": title}
        s.update(kw)
        steps.append(s)
        return s

    step("note", "declare the lane", args={"text": (
        "CAPTURE lane derived by tools/gate_f/derive_gate2_route_captures.py from the PLAYED "
        "route in %s (segments %s). Every stand below is a position, heading and clock hour "
        "the logic lane's own 2 Hz trace recorded; nothing here is a posed stand." % (
            os.path.basename(os.path.abspath(args.run_dir)), args.segments))},
        expected="a note event carries the derivation into events.jsonl")
    step("wipe_saves", "empty the live save directory", args={"keep_slots": []},
         expected="no stale slot can be loaded by mistake")
    step("seed_save", "seed slot 4 from the route's entry save", args={"slot": 4, "from": args.seed},
         expected="the same save the played route started from")
    step("boot", "boot the real title screen", args={"scene": "title", "settle_frames": 30},
         expected="the title screen, focused")
    step("focus_move", "move focus to Load Game", args={"direction": "down", "times": 1},
         expected="focus on Load Game")
    step("press", "open the slot list", args={"control": "ui_accept", "hold": "tap"},
         expected="the slot list")
    step("press", "load the seeded slot", args={"control": "ui_accept", "hold": "tap"},
         expected="the world loads from slot 4")
    step("wait", "let the loaded world stand up", args={"frames": args.load_settle_frames},
         expected="terrain, scatter and the party are standing; priced in frames, not seconds, because every physics frame is a rendered frame here")
    step("assert", "the world owns input", args={"check": "input_context", "equals": "world"},
         expected="no modal is holding the loaded world", resync=True)

    owes = []
    for seg, cap in zip(seg_names, caps):
        seg_dir = os.path.join(args.run_dir, seg)
        rows = read_route(os.path.join(seg_dir, "telemetry", "route.csv"))
        events = read_events(os.path.join(seg_dir, "telemetry", "events.jsonl"))
        if not rows:
            print("derive: %s has no route.csv under %s; skipped" % (seg, seg_dir), file=sys.stderr)
            continue
        samples = pick_samples(rows, events, args.every_s, cap)
        print("derive: %s -> %d stands from %d trace rows / %d events" % (
            seg, len(samples), len(rows), len(events)))
        for t, label, i in samples:
            row = rows[i]
            yaw = camera_yaw_at(events, t)
            if yaw is None:
                yaw = travel_yaw(rows, i)
            shot_id = "G2-%s-%04d-%s" % (seg, int(t), label)
            owes.append(shot_id)
            clock = {"hour": round(row["clock_hour"], 2), "settle_frames": 2}
            if row["weather"]:
                clock["weather"] = row["weather"]
            step("pin_clock", "pin the clock to the trace's hour at t=%.0f s" % t, args=clock,
                 expected="the hour and weather the played route had here (%.2f h, %s)" % (
                     row["clock_hour"], row["weather"] or "clear"))
            step("teleport", "stand where the played route stood at t=%.0f s (%s)" % (t, label),
                 args={"at": [round(row["x"], 2), round(row["z"], 2)],
                       "resettle_frames": args.resettle_frames},
                 diag=True,
                 expected="DIAG: the trace's own position (%.1f, %.1f) in %s; the walk that produced it is in %s's route.csv" % (
                     row["x"], row["z"], row["region"] or "?", seg))
            step("face", "turn the gameplay camera to the trace's yaw", args={"yaw_deg": round(yaw, 1), "budget_frames": args.face_frames,
                       "tolerance_deg": args.face_tolerance},
                 expected="the real camera rig, steered by the right stick, at %.0f deg" % yaw)
            step("wait", "let the world stream in around the stand", args={"frames": args.look_frames},
                 expected="grass, scatter and any wild spawn near this stand have arrived")
            step("capture", "capture %s" % shot_id,
                 args={"id": shot_id, "class": "G2", "hud": "on", "camera_kind": "gameplay",
                       "trigger": "played-route stand: %s at play t=%.0f s, %s, dead-travel %.0f m, input_context %s" % (
                           label, t, row["region"] or "?", row["dead_travel_m"], row["input_context"]),
                       "intended_proof": "what the player saw here on the played Gate 2 route"},
                 expected="a gameplay frame with the HUD on from this stand")

    segment = {
        "id": args.id,
        "title": "Gate 2 evidence run CAPTURE lane: frames from the played route (S04 tournament, S05 Lower Meadows -> pond -> detour -> South Bridge)",
        "lane": "journey",
        "evidence_lane": "capture",
        "owes": owes,
        "record_hz": 0,
        "_comment": (
            "GENERATED by tools/gate_f/derive_gate2_route_captures.py from the logic lanes' telemetry in this run "
            "directory. Do not hand-edit: re-run the generator. Every `teleport` here is a DIAG step and is "
            "recorded as one; the walking evidence is the logic lane's. This lane exists so the blind judge "
            "sees the route as played -- gameplay camera, HUD on, whatever spawned -- rather than posed stands."),
        "steps": steps,
    }
    with open(out, "w", encoding="utf-8") as fh:
        json.dump(segment, fh, indent=2)
        fh.write("\n")
    print("derive: wrote %s with %d steps, %d frames owed" % (out, len(steps), len(owes)))


if __name__ == "__main__":
    main()
