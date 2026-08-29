# Handover — T1-NIGHT — 2026-08-30

Track 1 (Aesthetics) lane, scoped to the WorldLook/day-night keyframe path,
`art.json`'s day-cycle and moon/ambient keyframes, sun/moon configuration,
shadow settings for the night cycle, and `tools/_capture_day_night_transition.gd`.
Branch `ralph/T1-NIGHT`, off `origin/main` at `a97f3e84`, with
`origin/ralph/T1-SKY` (tip `698e2046`) merged forward first (clean merge, no
conflicts) — it carries the capture-parking fix, `capture_water.gd`'s clock
pin, and the golden-hour config fixes, all needed to see 22:00-02:00 correctly
at all.

## What I was asked

Judge 2 (`ralph/reports/JUDGE-VISUAL-2-2026-08-30.md`, subject 7a) measured
ground luma climbing through deep night instead of holding dark:

| Hour | 20:00 | 20:30 | 23:54 | 00:06 | 02:00 |
|---|---|---|---|---|---|
| ground luma | 44 | 43 | 53 | 56 | **78** |

02:00 was a flat pale-mint wash, ground brighter than sky, no shadow
direction, brighter than 17:54's own golden-hour ground. 22:00 was called
"the best night frame the game has produced" and had to survive untouched.
A second, smaller ask: diagnose (not necessarily fix) large rectangular
stair-step quantisation in the moonlit/shadow boundary at 22:00.

## Root cause — the backwards night ramp

`data/config/art.json`'s `times` block had exactly **three** keyframes before
this change: `day` (hour 8), `golden` (hour 18), `night` (hour 0/24).
`scripts/world/day_cycle.gd::interpolate_at()` walks keyframes sorted by hour
and blends linearly between whichever two bracket the current hour — so the
**entire** stretch from midnight to morning was one continuous 8-hour blend
from night's darkest, moodiest tuning straight to day's brightest, most
desaturated-toward-neutral numbers, starting the instant the clock crossed
hour 0.

At 02:00, `t = (2-0)/8 = 0.25` — a full quarter of the entire night→day swing
had already landed, two hours after the darkest keyframe and three hours
before `dark_from_hour`/`dark_to_hour` (20.0/5.0, already in art.json) even
say the world should stop counting as dark. Concretely, at that `t`: sun
energy rose from night's 0.55 toward day's 1.35 (already ~36% up, and per the
NIGHT-LIGHT keyframe's own comment ACES's toe means a modest rise near the
bottom of the range reads as a large perceptual jump), sun yaw/pitch had
already swung a third of the way toward day's completely different sun
position (killing the "one clear shadow direction" night is tuned for), and
sky ground/horizon colours and ambient/exposure/desaturation were all
partway toward day's much brighter, warmer, more saturated values. None of
this is a blend-math bug — T1-SKY's own handover already confirmed the blend
itself is correct once upstream config (weather, sun disc, clouds,
adjustment defaults) is; this is a **missing keyframe**. Three named
presets is not enough to hold "night" steady through the hours the game's
own `is_dark()` window (20:00-05:00) says should still read as night.

I independently re-derived the same trend from the already-committed
T1-SKY frames before touching anything (different sample patch than the
judge's, so different absolute numbers, same shape):

| Hour | 20:00 | 20:30 | 22:00 | 23:54 (23.90) | 00:06 (00.10) | 02:00 |
|---|---|---|---|---|---|---|
| ground luma (mine, before) | 44.1 | 41.5 | 53.4 | 60.6 | 63.0 | **84.9** |
| sky luma (mine, before) | 100.5 | 93.1 | 73.2 | 53.1 | 54.9 | 66.0 |

## The fix

Added a fourth keyframe, `dawn`, at `hour: 5.0` — exactly `dark_to_hour`, so
the game's own is-it-dark boundary and the visual's own boundary now agree.
Every `sun`/`sky`/`environment` value in `dawn` is copied verbatim from
`night`'s own tuned numbers (see `art.json`'s own NIGHT-LIGHT/VIS-WORLD/
T1-LIGHT comments on `night` for why each number is what it is — `dawn`'s
comment points back there rather than duplicating that history).

Because `night@0` and `dawn@5` are now **identical** dicts, `_blend_dict`
interpolates between two equal values across that whole 5-hour span — the
result cannot move no matter what `t` is, which is a genuine hold, not an
approximation. The real sunrise brightening — the sun/sky/environment swing
from night's numbers to day's — is now compressed into `dawn@5 -> day@8`'s
3-hour tail instead of being smeared (at the wrong end, immediately after the
darkest keyframe) across the entire 8-hour night-to-morning stretch. This
also directly fixes "moonlight from nowhere / no shadow direction": sun
pitch/yaw/colour/energy stay pinned at night's exact moonlit values for the
whole 0:00-5:00 stretch instead of drifting a third of the way toward day's
completely different sun position by 02:00.

22:00 sits in the untouched `golden@18 -> night@24` span and 23:54/00:06 sit
just inside the new `night@0 -> dawn@5` hold — none of the values that
produced "the best night frame the game has produced" changed.

## Before/after evidence

<!-- FILLED IN AFTER RE-RENDER -->

## Stair-step artefact at 22:00 — conclusion

<!-- FILLED IN AFTER THE SHADOW ATLAS A/B PROBE -->

## Done-verified vs done-unverified vs still-open

<!-- FILLED IN -->

## Exact commands

```
curl -fL -o g.zip https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip \
  && unzip -o g.zip && chmod +x Godot_v4.7-stable_linux.x86_64 \
  && mv Godot_v4.7-stable_linux.x86_64 /usr/local/bin/godot
godot --headless --path . --import   # twice; first pass exits non-zero cold

# Unit tests for the pure day-cycle math (unaffected by art.json content --
# uses its own inline fixture config)
godot --headless --path . --script tests/run_tests.gd -- --only=test_day_cycle.gd

# Day/night sweep (headline evidence, "after")
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x800 \
  --script tools/_capture_day_night_transition.gd
# -> res://shots/day_night/hour-*.png, ranger-camp viewpoint

# Shadow-atlas-size A/B probe (this session's diagnostic, now committed)
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x800 \
  --script tools/_probe_shadow_atlas.gd
# -> res://shots/day_night/shadow-atlas-{2048,4096}-hour-22.00.png
```

## What I learned that is NOT visible in the diff

- Three keyframes is not enough for a mood-driven day cycle once any two
  adjacent presets are far enough apart in look: whichever segment is
  longest in hours (here, night->day at 8h) gets a disproportionate share of
  its own transition happening far from either keyframe's own tuned moment,
  because the blend has no way to know that most of that span is supposed to
  read as "still night." A hold keyframe placed at the game's own semantic
  boundary (`dark_to_hour`) is cheap and keeps the visual and the gameplay
  definition of "night" in agreement, which they were not before.
- `art.json` already has a real precedent for testing (not assuming) whether
  `directional_shadow/size` explains a stair-step-shaped defect
  (`_comment_exposure_ev4_lighting`'s Barn investigation, which found a
  *different* shadow artefact was pixel-identical at 4096 vs 2048 and ruled
  the atlas out) — worth checking before reaching for that dial again, which
  is why I probed rather than assumed for this artefact too.

## Disagreements

<!-- FILLED IN IF ANY SURVIVE THE RENDER -->

## Full file footprint

- `data/config/art.json` — added `times.dawn` (hour 5.0, sun/sky/environment
  copied from `night`). No other day-cycle key, no moon/ambient key on
  `day`/`golden`/`night` themselves, touched. Nothing outside the `times`
  block touched.
- `tools/_probe_shadow_atlas.gd` (+ `.uid`) — new diagnostic tool, same
  one-shot-probe convention as `tools/_probe_golden_snap.gd`.
- `ralph/reports/T1-NIGHT/shots/**` — evidence frames.
- This file.

## What I would do next

<!-- FILLED IN -->
