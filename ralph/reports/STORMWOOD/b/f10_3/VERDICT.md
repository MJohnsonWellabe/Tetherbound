# F10#3 witness: readable lightning and Surge phase cues without HUD

Criterion: ACCEPTANCE §6.1 F10 / S2, WORLD §5.2 — "readable lightning (1.2 s
telegraph / 3 m radius) and Surge phase cues without HUD". Lane STORMWOOD-B,
branch `tb/stormwood-b-f10-3-lightning-read`, base origin/main.

## Result

**F10#3 NOT passed.** Per question, judge answers decoded against the key:

| Question | Verdict | Evidence |
|---|---|---|
| Q1 phases nameable without text | **NO (partial)** | Calm 2/2 (img_05, img_08) and Break 2/2 (img_04, img_12) right; Building 0/2 (img_00, img_09 both called "Break"); Fading 0/2 confidently (img_06, img_10 "Building or Fading", low). Judge: "Building vs Fading is NOT distinguishable." |
| Q2a warning reads as ~3 m ground zone | **radius YES, zone NO** | Radius estimated 2.8-3.3 m (spec 3 m). "Mainly a thin, bright magenta ring ... closer to a selection or target circle than to 'get out of this area'." |
| Q2b time to leave | **NO** | "Nothing shows progress through the 1.2 s"; the 0.3 s and 0.8 s frames look alike in stills. (The rim chirp pulse exists in motion under normal motion and is off by design under reduced motion; a still cannot show it.) |
| Q3 reduced: flashes gentle, warning clear | **YES, with a gap** | "No sky white-out, and the magenta ring ... is just as clear." Harsh flash named only in img_02 (normal motion, expected). Judge put reduced img_03/img_11 in the flashing set because a decorative distant sky bolt was visible (reduced motion keeps bolts by design). Reduced impact img_13 "barely identifiable as a strike" (see gaps). |
| Q4 same storm day and night | **YES** | "One storm: YES ... Day vs night: NO, not reliably." Night warning (img_03, img_11) as clear as day (img_01, img_07). The owner's pinned-storm ruling holds. |

No code was changed. Every defect the judge found is a look defect (ring
fill/shape, bolt art, flash grade, phase grade), which the coordinator's 20:31
UTC owner direction cedes to Codex; they are proposed as Codex-queue rows below.

## What was rendered

Production CameraRig/Camera3D following the real Player at the Surge-capture
strip stand (Cinder Verge `verge_glass_01`, (-604, 772)), HUD CanvasLayers
hidden, compatibility renderer (opengl3) under xvfb, software GL. One settled
frame per phase, then in Break one staged strike played through
`StormwoodLightning._receive` (client path, the host's warning+impact events;
presentation only, disclosed) 7 m ahead of the camera, which lands on the
trainer. Tool: `ralph/reports/STORMWOOD/b/f10_3/capture_f10_3.gd` (wrapper of
`tools/capture_stormwood_reduced_motion.gd` -> `tools/capture_stormwood_surge_phases.gd`).

| Set | World hour | Motion | Warning frames (surge-clock s into the 1.2 s warning at grab) | Impact |
|---|---|---|---|---|
| `frames/normal_h12_*` | 12 (day) | normal | t030 = 0.30 s (18 ticks), t080 = 0.80 s (48 ticks), exact tick stepping | 2 frames after impact, flash_level 0.84 |
| `frames/reduced_h00_*` | 0 (night) | reduced | t030 grabbed at 0.64 s, t080 at 0.77 s (tick cap 4, capture drift) | flash_level 0.0; see gaps |

`contact_sheet.jpg` is every frame, labelled. `frames_reduced.json` is the
per-frame staging record of the reduced run (the normal run's JSON was not
written: the process was stopped after its day half for time; its frames were
already on disk). `time_of_day` reads "day" in the JSON at hour 0 because the
owner's pinned storm (stormwood_surge.json `storm_base.pin_time_of_day`)
presents every hour as the reference preset; `world_hour` 0.0 is the clock.

Commands (from the worktree root, after `git sparse-checkout disable` and two
`godot --headless --path . --import`):

```
XDG_DATA_HOME=$(mktemp -d) xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x720 \
  --script res://ralph/reports/STORMWOOD/b/f10_3/capture_f10_3.gd -- \
  --motion=normal --out=<scratch>/normal --label=normal --only=quick          # day half used
XDG_DATA_HOME=$(mktemp -d) xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x720 \
  --script res://ralph/reports/STORMWOOD/b/f10_3/capture_f10_3.gd -- \
  --motion=reduced --hours=0 --tick-cap=4 --out=<scratch>/reduced --label=reduced --only=quick
python3 sheet.py <scratch> ralph/reports/STORMWOOD/b/f10_3 ralph/reports/STORMWOOD/b/f10_3/blind   # PIL: 960x540 JPGs, sheet, shuffled blind copies
```

## Code-blind judge

Separate cloud Claude session (session_01MF5wfY3vW9SZ1iFtCa3Xo8; it pushed its answers as commit fce2d136 on `tb/stormwood-b-f10-3-judge`), sparse checkout of
`blind/` only, told not to read code/json/markdown/history, given only the 14
shuffled images `blind/img_00..13.jpg` plus the neutral questions below (phase
names, 1.80 m trainer ruler, that some frames are reduced-flash / night
without saying which). Key (`blind_key.json`) was written after the answers.

Questions: Q1 name each phase/moment without text; Q2 does the warning read as
a ~3 m ground danger zone with time to leave; Q3 in the reduced-flash set are
flashes gentle while the warning stays clear; Q4 one storm day and night;
Q5 defects.

### Judge answers (verbatim)

Copied unedited into `JUDGE_ANSWERS.txt` in this folder (identical to
`fce2d136:ralph/reports/STORMWOOD/b/f10_3/blind/JUDGE_ANSWERS.txt`). Key
(`blind_key.json`): img_00 reduced_h00_building, 01 normal_h12_telegraph_t030,
02 normal_h12_impact, 03 reduced_h00_telegraph_t030, 04 normal_h12_break,
05 normal_h12_calm, 06 reduced_h00_fading, 07 normal_h12_telegraph_t080,
08 reduced_h00_calm, 09 normal_h12_building, 10 normal_h12_fading,
11 reduced_h00_telegraph_t080, 12 reduced_h00_break, 13 reduced_h00_impact.

## Expected vs observed

| Item | Expected (WORLD 5.2, UX 8, stormwood_surge.json) | Observed |
|---|---|---|
| Telegraph radius | 3 m | judged 2.8-3.3 m; rim at 3 m by config |
| Telegraph read | ground danger ZONE for 1.2 s | judged a thin selection/target ring; the dark fill is too subtle |
| Telegraph progress | readable time to leave | not visible in stills at 0.3 s vs 0.8 s |
| Phase cues | Calm/Building/Break/Fading nameable without HUD | Calm and Break yes; Building read as Break, Fading as Building-or-Fading |
| Reduced motion | sky flash x0.15, rim steady, ring and bolt stay | no white-out, ring clear (pass); reduced impact frame shows neither ring flare nor bolt (flash_level 0.0), see gaps |
| Normal impact | full sky flash + bolt + white-hot rim | flash_level 0.84, white rim; bolt judged "a flat, soft grey cylinder ... reads as a pillar or beacon" |
| Night merge | same purple storm every hour | same storm; night not distinguishable (pass) |

## Proposed Codex-queue rows (look; not edited here)

| Region | Defect | Frame | Suggested fix |
|---|---|---|---|
| Stormwood Break strike telegraph | Reads as a thin selection ring, not a danger zone; the dark fill is too weak on the dark path | frames/normal_h12_telegraph_t030.jpg, frames/reduced_h00_telegraph_t080.jpg | Translucent hazard-colour fill across the disc, thicker rim, and a filling or shrinking inner ring that completes at 1.2 s so a still shows progress (also the reduced-motion progress cue) |
| Stormwood strike impact | Bolt reads as a soft grey pillar/beacon, with no fork and no ground burst | frames/normal_h12_impact.jpg | Jagged forked bright core with glow, plus a ground spark/scorch burst at the ring |
| Stormwood strike impact flash (normal motion) | Whole-frame grey-white wash reads as a daytime overcast change | frames/normal_h12_impact.jpg | Cap or localise the sky flash amplitude (sky plus ring area), with a shorter decay |
| Stormwood Surge phase grade | Building indistinguishable from Break; Fading from Building | frames/*_building.jpg, frames/*_fading.jpg | Give Building and Fading a structural signature a still catches (e.g. Building: advancing dark cloud front; Fading: thinning rain with a brighter horizon gap/steam) |
| Stormwood path veins | Permanently glowing gold road veins read as a hazard and compete with the telegraph | all frames | Dim during Break or shift away from a hazard read |
| Stormwood Break decorative bolts | A distant sky bolt visible during a warning reads as "already striking elsewhere" | frames/reduced_h00_telegraph_t030.jpg | Suppress decorative bolts in view while a local warning is live |

## Remaining gaps

- Reduced-motion impact: `frames/reduced_h00_impact.jpg` shows no bolt or ring
  flare. That run used `--tick-cap=4`, so the two-frame capture after impact
  could advance up to about 10 ticks (0.17 s) against a 0.18 s bolt. The miss
  is most likely capture drift, not a proven defect. The earlier exact-tick
  witness `ralph/reports/SHARED-UI/f10-reduced-motion/reduced/staged_flash.jpg`
  (87124330) shows the bolt kept under reduced motion. __R3__
- The normal-motion night set and the reduced-motion day set were not rendered
  (time), so the day/night comparison crosses motion modes, which differ only
  in flashes.
- Telegraph frames are stills, so the rim chirp pulse (normal motion) was not
  judged. The reduced run's warning frames were grabbed at 0.64 s and 0.77 s,
  not 0.3 s and 0.8 s.
- F10#3 stays open: Q1 (Building/Fading) and Q2 (zone read, time to leave)
  fail. Both are look work ceded to Codex.
