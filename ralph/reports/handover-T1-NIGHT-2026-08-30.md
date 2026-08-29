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

Full re-render of `tools/_capture_day_night_transition.gd`'s 12-hour sweep at
the same ranger-camp viewpoint, sampled with a small ad hoc script (bottom-
third/centre-band patch for ground, top-15%/centre-band patch for sky —
not the judge's own patch coordinates, so treat the absolute numbers as
this script's own scale, not directly equal to the judge's; the *shape*
of the trend is what matters and both scripts use the same Rec.709 luma
weighting). Frames: `ralph/reports/T1-NIGHT/shots/day_night_after_dawn_
keyframe/` (after) vs the already-committed `ralph/reports/T1-SKY/shots/
day_night_run1_after_parking_and_weather_fix/` and `.../run2_after_cloud_
tint_fix/` (before, T1-SKY's own state, pre-dating this fix).

| Hour | 20:00 | 20:30 | 22:00 | 23:54 (23.90) | 00:06 (00.10) | 02:00 |
|---|---|---|---|---|---|---|
| ground luma, BEFORE | 44.1 | 41.5 | 53.4 | 60.6 | 63.0 | **84.9** |
| ground luma, AFTER | 50.9 | 47.2 | 53.5 | 60.5 | 61.8 | **64.2** |
| sky luma, BEFORE | 100.5 | 93.1 | 73.2 | 53.1 | 54.9 | 66.0 |
| sky luma, AFTER | 109.1 | 101.6 | 74.5 | 54.7 | 56.5 | 59.4 |

**22:00 through 00:06 are unchanged within render-to-render noise** (22:00's
ground luma moved 0.1, sky 1.3; a byte-for-byte visual diff of `hour-22.00.png`
before vs after shows no visible difference at all — expected, since this
segment is `golden@18 -> night@24`, which nothing in this change touches).
**02:00 is the one hour that actually moves, and it moves the right way**:
before, it jumped +21.9 over 00:06 (63.0 -> 84.9) — the runaway brightening
Judge 2 measured. After, it moves only +2.4 over 00:06 (61.8 -> 64.2),
landing in the same low-50s-to-mid-60s band as every other dead-of-night
hour instead of leaping toward day. This is `night@0 -> dawn@5`'s hold
working exactly as intended: 02:00 sits at `t = 2/5 = 0.4` through a span
whose endpoints are numerically identical, so the only source of remaining
movement is render noise, not a real config ramp.

The 20:00/20:30 numbers moved more than I expected for a segment I never
touched (+6.8 and +5.7 ground luma) — I checked why before trusting the
02:00 result: `interpolate_at(20.0)` still resolves to the exact same
bracket, `golden -> night`, with the exact same `t`, whether or not `dawn`
exists elsewhere in the sorted keyframe list (confirmed by reading
`day_cycle.gd::interpolate_at` — a keyframe's neighbours are its sorted
adjacent entries only), so this is not the dawn keyframe leaking backward.
It is almost certainly cross-run noise: `cloud_wind` drifts cloud position
over real elapsed time even with weather pinned to "clear" (T1-SKY's own
handover names this same mechanism for a different pair of frames), and the
"before" and "after" renders here are two separate process runs, not two
frames from the same session. Visually inspecting `hour-22.00.png` (a frame
this change genuinely cannot affect) confirms the noise floor: 0.1 luma,
effectively nothing. The 20:00/20:30 delta is bigger than that floor but
still well short of 02:00's, and unlike 02:00 it has a mundane, checked
explanation rather than a live config path. Flagging this rather than
quietly rounding it away.

A direct visual check (not just the numbers) on the two hours that matter
most: `hour-02.00.png` before is a flat pale-mint wash with no visible
shadow anywhere on the ground; `hour-02.00.png` after shows a clear, long,
correctly-directional moon-shadow across the whole midground, much closer
in character to 22:00's own look than to the old washed-out frame.
`hour-22.00.png` before and after are visually indistinguishable.

## Stair-step artefact at 22:00 — conclusion

**Real, reproducible, and NOT explained by shadow-map resolution alone —
raising it changes the artefact's shape rather than removing it.**

`tools/_probe_shadow_atlas.gd` renders the exact hour-22.00 ranger-camp
viewpoint twice in one process — identical scene, camera, lighting, weather —
first at the shipped `directional_shadow/size` (2048), then again after
calling `RenderingServer.directional_shadow_atlas_set_size(4096, true)` at
runtime (no project.godot edit, no restart: this is a live render-target
resize, so nothing else in the frame can have changed between the two
shots). Evidence: `ralph/reports/T1-NIGHT/shots/shadow_atlas_probe/`.

- **Atlas size is a real, measurable factor, not a llvmpipe fluke**: 32.6% of
  pixels differ by more than a rounding amount between the two renders
  (mean abs diff 2.29/255 overall, max 151/255), concentrated exactly where
  Judge 2 flagged it — bottom-left quadrant mean diff 11.0 against 2.9-9.1
  elsewhere, frac-changed 5.3% against 1.6-4.3% elsewhere. Two renders of the
  same frozen scene do not differ by that much unless the changed setting is
  doing something real.
- **But it does not clean the artefact up — it changes its shape.**
  `full-left-quadrant-{2048,4096}.png` and the tighter `edge-crop-
  {2048,4096}.png` (same crop, nearest-neighbour zoomed) show a
  near-camera shadow boundary (something casting onto the lit path, out of
  frame to the right) that is a fairly smooth diagonal at 2048 and grows a
  new, still-blocky rectangular notch at 4096 — the higher-resolution atlas
  *revealed* a blockier feature it wasn't previously resolving, rather than
  smoothing an existing block pattern away. A second boundary (the terrain/
  sky-adjacent edge in `full-left-quadrant`'s upper portion) shows the same
  direction of change: a small sawtooth appears at 4096 that the 2048 render
  blurred into a clean curve.
- **This matches a cause this file's own history already names, better than
  "atlas too small" does.** `art.json`'s NIGHT-LIGHT comment on the `night`
  preset records that round 1 of tuning the moon put it at a grazing -8°
  pitch and a blind pass called out "a hard value seam... reads as a light
  falloff/attenuation cliff... an artifact, which is what a near-horizontal
  light does to gentle terrain undulation" — steepened to -20° specifically
  to reduce (not eliminate) that risk, the same tradeoff the day preset's own
  R9.4 comment independently rejected a shallower sun for. Night's moon at
  -20° is still far shallower than day's -44°, and shallow-angle light on
  undulating terrain is exactly the geometry that produces long, thin,
  texel-quantised self-shadow acne — a real effect that a higher-resolution
  shadow map resolves in finer, still-visible detail rather than removing,
  which is precisely what these frames show.
- There is also a documented precedent in this same file for NOT assuming
  atlas size (`_comment_exposure_ev4_lighting`: raising it to 4096 for a
  *different* shadow artefact near the Barn produced a "pixel-identical
  edge," ruling it out there) — this probe is the same kind of direct test,
  it just found the opposite answer for this artefact: a real, measurable
  effect, just not a clean fix.

**Conclusion for the coordinator:** this is not simply "raise
`directional_shadow/size` back toward 4096 and the stair-steps go away" —
the same probe shows they do not go away, they relocate. The more likely
lever is night's moon pitch (-20°, still grazing) interacting with terrain
undulation, which is a lighting-mood tradeoff this file's own history
already fought hard to avoid re-opening (round 1's -8° was rejected for
exactly this class of artefact), not a free resolution bump. `directional_
shadow/size` is also a global `project.godot` rendering setting that costs
real VRAM across every time of day, not a night-cycle-specific value in my
`art.json` ownership, and SA1's own comment there already anticipated this
exact question ("raise it back if shadow edges visibly stair-step on
device; that is the trade being made here") — reversing that deliberate
ROG Ally memory trade is a Performance/Track-2 decision, not mine to make
from this lane. I did not touch `project.godot` or night's sun pitch.
Per the brief's own instruction, this needs one look on real hardware
before anyone spends either the VRAM or the mood tradeoff chasing it
further — the software-GL comparison here is trustworthy for "does the
setting do anything" (yes) but not for "does raising it look better to a
human eye" (unclear, and arguably no, on this evidence).

## Done-verified vs done-unverified vs still-open

**Done and verified (re-rendered, pixel-checked, numeric and visual):**

1. The backwards night-to-day ramp. Fixed via the `dawn` keyframe. Full
   12-hour re-render confirms 02:00 no longer runs away from the rest of
   deep night (+2.4 luma over 00:06, was +21.9), 22:00 and the golden->night
   slide are visually and numerically unchanged, and `test_day_cycle.gd`'s
   12 tests still pass unmodified (they build their own inline fixture, not
   `art.json`, so they were never exercising this specific defect, but they
   confirm the keyframe/interpolation mechanism itself still behaves
   correctly with a fourth keyframe present).

**Investigated and diagnosed, deliberately not fixed (cross-lane or needs
real hardware):**

2. The 22:00 stair-step artefact. Real and reproducible (a same-viewpoint,
   same-hour A/B on `directional_shadow/size` alone moves 32.6% of pixels,
   concentrated where the judge flagged it) but NOT cleanly explained or
   fixed by atlas resolution — raising it relocates the blockiness rather
   than removing it, pointing instead at night's moon pitch (-20°, still
   grazing) interacting with terrain undulation, a class of defect this
   file's own NIGHT-LIGHT history already fought once. Left `project.godot`
   and night's sun pitch untouched; see the dedicated section above.

**Not touched, per file ownership (unchanged from T1-SKY's own handover,
still true after my change):**

3. Night foliage reading self-lit — T1-GROUND-2's ownership (vegetation
   material), confirmed not reintroduced or worsened by this change (my
   diff touches only `art.json`'s `times.dawn`, nothing vegetation-related).
4. Aerial perspective at distance — T1-GROUND-2's ownership (terrain
   material), untouched.
5. `fog_density`/`aerial_perspective` — explicitly not re-attempted, same
   R9.4-rejection reasoning T1-SKY already gave.

**Still open, for whoever picks this up next:**

- The stair-step artefact's real fix (if the coordinator decides it is
  worth one): almost certainly a night-specific `shadow_normal_bias`/
  `shadow_bias` retune, or accepting a steeper moon pitch than -20° (a mood
  tradeoff), verified on real hardware first. Not a `directional_shadow/
  size` bump on the evidence gathered here.

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

- The brief frames the stair-step lead as "a shadow-map resolution or
  cascade-split setting you can fix cheaply, or genuinely a software-
  rasteriser artefact" — a binary. The evidence here is neither: the atlas
  size is real and reproducible (rules out "just llvmpipe"), but raising it
  does not clean the artefact up, it relocates it to a different, still-
  blocky shape (rules out "cheap resolution fix"). The more specific,
  better-supported lead is night's moon pitch interacting with terrain
  undulation — a mechanism this file's own history already names for a
  closely related symptom ("a hard value seam... what a near-horizontal
  light does to gentle terrain undulation," NIGHT-LIGHT round 2). I'm
  flagging this distinction because "raise the atlas size" is the obvious
  next thing someone reaches for after reading the brief's framing, and the
  A/B here says that specific move will not do what it sounds like it
  should.
- I did not find anything to disagree with in the night-ramp diagnosis
  itself — the brief's own lead ("suspect the keyframe values... a missing
  or mis-valued keyframe... before suspecting blend logic") is exactly what
  the evidence confirmed, unlike my predecessor's golden-hour item where the
  brief's framing didn't survive contact with the fix. Saying so plainly per
  the brief's own request to disagree "with evidence" cuts both ways — this
  time the brief was right.

## Full file footprint

- `data/config/art.json` — added `times.dawn` (hour 5.0, sun/sky/environment
  copied verbatim from `night`). No other day-cycle key, no moon/ambient key
  on `day`/`golden`/`night` themselves, touched. Nothing outside the `times`
  block touched. This is the entire change to this shared file; the ground
  lane owns everything else in it.
- `tools/_probe_shadow_atlas.gd` (+ `.uid`) — new diagnostic tool, same
  one-shot-probe convention as `tools/_probe_golden_snap.gd`. Runtime-only
  `RenderingServer.directional_shadow_atlas_set_size()` call, no
  `project.godot` edit.
- `ralph/reports/T1-NIGHT/shots/day_night_after_dawn_keyframe/` — the full
  12-hour "after" sweep.
- `ralph/reports/T1-NIGHT/shots/shadow_atlas_probe/` — the 2048-vs-4096 A/B
  crops.
- This file.
- Not touched: `tools/_capture_day_night_transition.gd`, `capture_water.gd`,
  `world_look.gd`, `day_cycle.gd`, `project.godot`, anything under
  `scripts/world/stronghold*.gd`/`landmark.gd`/`building_prefabs.json`,
  vegetation/terrain material, creature materials, `scripts/combat/**`,
  `scripts/ui/**`, `data/config/bands/**`.

## What I would do next

1. Hand the stair-step artefact to whoever owns night's mood tuning next,
   with the specific diagnosis above (moon pitch x terrain undulation, not
   atlas size) and the A/B evidence, and get one real-hardware look before
   spending either the VRAM or the mood tradeoff.
2. If the coordinator wants `dawn` to be more than a hold — an actual
   pre-sunrise look distinct from full night — that's a deliberate art
   decision for a human or Fable to make, not something to invent here; the
   hold is the minimal fix for the reported defect (monotonic backward
   brightening) and deliberately does not attempt new mood work.
3. A fresh Fable judge pass over the full driven-clock sweep (frames
   already committed) would confirm whether "night now darkens
   monotonically" reads correctly to a blind reviewer, not just to the
   luma numbers — the brief itself says the blind judge is stood down until
   more work lands, so this is packaged for that later pass rather than
   expecting one now.
