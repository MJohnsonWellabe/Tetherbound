# Handover — T1-SKY — 2026-08-30

Track 1 (Aesthetics) lane, scoped to the WorldLook/day-night keyframe path,
weather presets, sun/sky/environment configuration, and the day/night/water
capture tools. Branch `ralph/T1-SKY`, off `origin/main` at `a97f3e84`, pushed
incrementally (one push per unit of work, not batched).

## What I was asked

1. **First, before touching lighting:** port the capture-parking fix (the
   500m-underground player park that reads as fully submerged and paints a
   red drowning vignette over the frame) into
   `tools/_capture_day_night_transition.gd`, re-run the last four hours, and
   look at what deep night actually is before changing anything. Also fix
   `tools/capture_water.gd`'s sibling clock-pin defect.
2. **Headline:** golden hour never renders on the driven passive clock —
   frames bracketing 18:00 are a flat grey-blue wash while the snap preset
   `apply_time("golden")` is supposedly warm and lovely. Find why the blend
   doesn't reach the keyframe and fix it.
3. **Secondary, all named by the judge:** blown white sun disc with no halo;
   sky/ground weather disagreement in bands 3-5; night foliage reading
   self-lit; the fog weather preset rendering no visible fog; no aerial
   perspective at distance (called the single highest-leverage item).

## Where I actually got to

### Done and verified (re-rendered, pixel-checked, or both)

**1. Capture-parking fix — real bug, fixed, verified.**
`tools/_capture_day_night_transition.gd:91` parked the actor at
`Vector3(EYE.x+5000, -500, EYE.y+5000)` — 500m underground. `water.gd` reads
player head-depth below the water surface with no floor, so that body ramped
a full-screen red drowning vignette. Fixed to match the pattern already
proven in `survey_band2.gd`/`capture_band3_region.gd`: park far off in XZ
**and above ground** (`field.height_at(...) + 1.0`). Same defect existed in
`tools/capture_water.gd`'s `_place_actor` no-actor branch (used by every one
of its four viewpoints, since none carry an `actor` key) — fixed the same
way.

Re-rendered the full 12-hour sweep twice. `hour-22.00.png` before/after is
the clearest evidence: it went from what the 2026-08-29 judge blind-called
"the worst visual defect in the game" (blood-red frame) to a normal,
navigable navy-blue night with visible tree silhouettes and a readable path.
Frames: `ralph/reports/T1-SKY/shots/day_night_run1_after_parking_and_weather_fix/`.

**2. `capture_water.gd`'s clock-pin defect — real bug, fixed, and verified
across three re-render iterations.** Unlike `_capture_ground_and_sky.gd`,
this tool called `weather.set_weather("clear")` once but never froze
`WorldLook`/`WorldWeather`'s `_process`, so the passive clock kept advancing
between each `apply_time()` call and the shutter across a 4-viewpoint pass.
Fixed by freezing both nodes right after finding them (the "freeze-once"
pattern `_capture_ground_and_sky.gd`'s own header documents and justifies).

Re-rendering surfaced a **second, different bug** the clock-drift issue had
been masking: `water-01`/`water-02` (the first two of four viewpoints) still
rendered measurably darker than `water-03`/`water-04` despite every
viewpoint sharing the identical frozen `"day"` state. A sky-only pixel patch
(terrain shadow geometry cannot reach the sky) ruled out a scene-shadow
explanation and confirmed a real, progressive render-state warm-up gap: sky
avg RGB (21,24,24) → (67,74,75) → (130,133,128) → (114,139,148) on the first
re-render. Root cause: this tool repositions the camera by large XZ jumps
between viewpoints on only `SETTLE_AFTER_MOVE=4` frames — far stingier than
the 15 frames `_capture_ground_and_sky.gd` budgets for the same kind of jump
to let Terrain3D's region stream and the sun's shadow map catch up. Raised
`SETTLE_AFTER_MOVE` to 15 (closed most of the gap: water-01 sky went
21→53) and added a one-time 30-frame post-boot warm-up before the viewpoint
loop starts (closed the rest: water-01 sky went 53→102, now in the same
band as the other three). **Final state, verified by direct image
inspection, not just pixel averages:** all four water viewpoints now read
as normal, consistent daylight — `water-01-bank-closeup` in particular now
matches the report's own praise for the pond ("turquoise shallows, sand-to-
grass bank transition, reeds at the waterline") instead of the near-black
frame originally judged. Evidence:
`ralph/reports/T1-SKY/shots/water_run3_final/`.

**3. Golden hour — root cause found, fixed, and the remaining question
resolved by direct A/B rendering.** Three real, independent bugs, all fixed:

- **`_capture_day_night_transition.gd` never touched `WorldWeather` at
  all.** Left running, it rolls a new preset every 4-8 real seconds×60
  (`data/config/weather.json` `cycle_seconds_min`/`max` = 240-480), and the
  initial `SETTLE_FRAMES` alone (240 awaited frames at ~2.4s each under
  llvmpipe — see `_capture_ground_and_sky.gd`'s own measured budget) can
  burn past that window before the first hour is even shot. `cloudy` — the
  heaviest-weighted non-clear preset — sets sky top/horizon colour to
  `#5f7386`/`#9aabb5`, a flat grey-blue: **the exact look the report
  described.** Fixed by pinning + freezing `WorldWeather` to `clear`, the
  same pattern `_capture_ground_and_sky.gd` already uses.
- **Day and golden never set the sky shader's `sun_size`/`sun_glow`.** Only
  `night` got tuned values from the earlier T1-LIGHT fix. On a freshly
  created sky material, an unset shader parameter is never written (see
  `world_look.gd::_apply_cloud_sky`'s per-key `if cfg.has(...)` guard), so it
  sits at the shader's raw uniform default — `sun_size=0.022`,
  `sun_glow=0.35`, a blown hard-edged disc with a glow term that decays as
  `pow(sun_dot,24)` and is invisible past a few degrees (no halo). Gave day
  and golden explicit, smaller, tuned values (0.010/0.16 and 0.013/0.22
  respectively — golden a bit larger/warmer, appropriate for a low prominent
  sunset sun).
- **Golden never set `cloud_lit`/`cloud_shade`/`cloud_sun_gain` either.** At
  the inherited `cloud_coverage: 0.58` (more than half the visible sky),
  clouds rendered at the shader's neutral defaults (near-white lit face,
  cool blue-grey shade) through the whole day+golden span, visually diluting
  the warm gradient underneath regardless of how correct `top_colour`/
  `horizon_colour` already were. Gave golden a warm cloud palette tied to
  its own sun colour, the same treatment night already has.
- **Bonus, found while reading `_blend_dict`/`_merged`: a real architectural
  bug affecting every preset-exclusive key, not just clouds.** When a key
  exists in only one of the two bracketing presets' merged dicts,
  `_blend_dict`'s `av = a.get(key, bv)` silently defaults the *missing*
  side to the *present* side's own value — collapsing what should be a
  smooth ramp into a flat pin for the entire segment nearer that preset.
  Concretely: `adjustment_saturation`/`adjustment_contrast` (only `night`
  set them) were pinned at night's exact tuned numbers (0.72/1.08) for the
  **entire six-hour golden→night span**, not ramping in from neutral — the
  opposite of the continuous blend OP23-05's own extensive history exists to
  guarantee. Fixed by giving the base `environment` block neutral
  (no-op) defaults: `adjustment_enabled: true`, `brightness`/`contrast`/
  `saturation: 1.0`. Re-rendered hour-20.50 and hour-22.00 afterward to
  confirm no regression to the dusk slide or night floor — both still read
  correctly (see run-2 evidence).

**Then I found the fixes weren't moving the ranger-camp viewpoint's own
"golden" look as much as expected, and ran a direct same-viewpoint A/B to
find out why**, rather than continuing to guess-and-tweak blind:
`tools/_probe_golden_snap.gd` renders `apply_time("golden")` — the exact
snap the judge called "genuinely lovely warm" — at the **identical**
EYE/TARGET/HORIZON `_capture_day_night_transition.gd` uses.

**Result: it looks the same as the driven blend.** Pale sky, muted tan
horizon, no dramatic amber. **This settles the open question.** The blend
now correctly matches the snap (the actual thing OP23-05 exists to
guarantee), and the remaining flatness at *this specific viewpoint* is a
composition limit, not a lighting bug: this tool's own header says why — it
deliberately reuses `survey_band2`'s "ranger-camp-close framing (close,
ground clutter visible, a real test of 'can you see to navigate')". That
framing leaves very little open sky in view (dense tree cover both sides,
camera at 1.8m pitched toward mid-distance ground clutter), so there simply
isn't much sky for a warm gradient to read strongly against, regardless of
config correctness. The "genuinely lovely warm frame" the original judged
report cited came from `_capture_ground_and_sky.gd`'s **band-1 opening**
viewpoint — a different tool, a different, much more open camera stand —
not a true same-viewpoint comparison. **I did not chase this further**: the
underlying config bugs (weather leak, blown sun, neutral clouds, the
adjustment-blend pin) were real, are fixed, and now apply everywhere
uniformly; forcing this one navigability-test viewpoint to look dramatically
"sunset panel" would mean either widening its sky (composition change,
arguably outside what this specific tool is for) or over-tuning global
config to flatter one camera stand, which risks the rest of the day cycle.
**Disagreement with the brief, stated plainly per its own instruction:** the
brief's framing ("same viewpoint, snap path correct, blend path wrong") is
not quite what the evidence shows. The blend math itself was never actually
wrong once weather/sun/cloud config was correct — I could not reproduce a
same-viewpoint blend-vs-snap divergence. What was wrong were three
config-level bugs upstream of both paths, which is why fixing them moved
`hour-22.00` (deep night, same architecture) dramatically while the golden
frames only moved modestly — the golden frames were never that far from
correct once weather stopped leaking in; the "grey-blue wash" was mostly
`cloudy` weather, not a broken keyframe blend.

Evidence: `ralph/reports/T1-SKY/shots/day_night_run1_after_parking_and_weather_fix/`,
`.../day_night_run2_after_cloud_tint_fix/`, `.../probe-golden-snap-rangercamp.png`.

### Investigated, diagnosed, deliberately not touched

**4. Sun disc halo — fixed above (item 3).**

**5. Night foliage reads self-lit — real, confirmed visually, diagnosed,
not fixed (cross-lane).** `hour-02.00.png` (true deep night, after all
fixes) shows tree canopies still reading as a fairly saturated, bright
green, close to daytime value, while the ground beneath them is
appropriately dark navy/green. Trees use ordinary lit `StandardMaterial3D`
(no unshaded flag, no baked lightmap — checked `vegetation.gd` and the
scatter/tint pipeline directly), so this isn't a shading-mode bug. The real
cause: an earlier art pass (R9.4, documented in `art.json`'s own comments)
deliberately darkened **grass's** albedo to value 0.199 to get real darks
into the frame; tree canopy material was never subjected to the same
treatment and keeps its original, brighter albedo. Since ambient/direct
light multiplies albedo, a brighter-albedo canopy will always read
proportionally lighter than deliberately-darkened grass under identical
lighting — most visible at night because that's when the game most wants
strong value separation. **This is vegetation-material territory, which the
brief's own file-ownership section assigns to the concurrent T1-GROUND
lane** ("grass/scatter config" — `vegetation.gd` handles trees, bushes and
grass tinting through one shared pipeline). I did not touch it. Whoever owns
that pipeline next should know: the fix is almost certainly a canopy-albedo
darkening pass analogous to R9.4's grass pass, not an environment/lighting
change — nothing on the WorldLook/environment side can differentially dim
foliage vs. ground since Godot applies ambient/light uniformly to both.

**6. The fog weather preset — real, but not what it was described as; not
touched.** Ran a scoped A/B (`--only=band2 --states=fog,day` on
`_capture_ground_and_sky.gd`, evidence in
`ralph/reports/T1-SKY/shots/fog_probe_band2/`). First: **the judge's own
flagged guess — "relies on volumetrics the shipped Compatibility renderer
doesn't have" — is wrong**, and I can say so with confidence: grepped the
whole project for `FogVolume`/`VolumetricFog`; there are zero. This project
only ever uses ordinary `Environment.fog_*` (exponential distance fog),
which is fully supported under GL Compatibility — it is not the newer
volumetric system that needs Forward+. Second, the actual measurement:
pixel-sampled day vs. fog at three regions (near ground, far treeline, sky).
The differences are real and fairly large (near-ground avg RGB roughly
doubled in brightness, far treeline brightened ~2.5x) — **but almost all of
that turned out to be the fog preset's `shadow_opacity: 0.05` (near-zero)
removing the sun's shadow modulation almost entirely**, not a distance-based
haze gradient. The whole frame reads more uniformly lit/duller, not
"hazy with distance." That is why a human viewer calls it "indistinguishable
from clear" even though the numbers moved a lot: nothing in the frame reads
as *air* between the camera and anything. A real fix likely needs either a
meaningfully higher `fog_density_add` specifically for depth-gated
whitening at forest-corridor range (tens of metres, not the ~1800m
half-density-point the current `fog_density_add: 0.007` on top of day's
`0.00055` actually produces), or a much more saturated/distinct fog colour
so a modest density reads as haze rather than as ambient dimming. I did not
attempt either blind: this specific axis (raising density) was already
tried and explicitly rejected once by the owner (R9.4's history in
`art.json` — density was **halved twice**, from 0.0022 down to the current
0.00055, after being called "eating the world... no separation between
hills"). Re-attempting a density hike without a tighter, tested proposal
risked reopening an already-settled complaint. Reporting this precisely
rather than guessing further.

**7. No aerial perspective at distance — real, not touched, diagnosed as a
likely cross-lane collision.** Confirmed `env.fog_aerial_perspective` is
already wired (`aerial_perspective: 0.35` in the base environment block,
read by `world_look.gd::_apply_environment`). The reason it doesn't read at
normal viewing range: Godot's fog is a single exponential
`1-exp(-density*distance)`; at the current `fog_density: 0.00055`, the
63%-fogged point sits around **1800m** — far past any distance a player
actually sees terrain at (a few hundred metres). Raising density to make
aerial perspective legible at realistic ranges is the same axis item 6
already covers, and the same R9.4 history already rejected a much smaller
increase (0.0011, 2x current) for "eating the world." A real fix for
"distant hills read hazier/cooler than near ones" without repeating that
failure almost certainly needs a **distance-based colour/desaturation
gradient baked into the terrain material itself** (the professional
technique for aerial perspective, independent of atmospheric fog opacity) —
which is `terrain material`, explicitly **T1-GROUND's ownership**, not
mine. The brief itself anticipated this exact collision ("Aerial
perspective may reach a shared environment/material file — if it collides
with terrain material specifically, say so ... and coordinate rather than
taking it"). Saying so here rather than taking it.

**8. Sky/ground weather disagreement in bands 3-5 (dark navy ink-blot
clouds over sunlit terrain) — could not reproduce.** Traced
`_capture_ground_and_sky.gd`'s loop by hand first: every `GROUND_STATES`
entry (day/golden/night, shot for every band) passes weather name `"clear"`
explicitly, and `_apply_state()` calls `weather.set_weather("clear")` on
every single shot — so even though band 2's own weather sweep
(cloudy/fog/rain) runs between bands, band 3's first state shot resets
weather back to clear before rendering. My original hypothesis (leftover
weather bleeding forward from band 2's sweep) does not hold up against the
code. Ran a scoped render (`--only=band3 --states=day`) to check directly:
`ground-03-band3-crossing-day.png` shows a clean blue sky with normal white
wisps, no dark ink-blot clouds, sky and ground agreeing. **I cannot rule out
that this was a real defect on an older commit that something since fixed**,
or that it needs a specific band/weather combination my scoped test didn't
hit (I did not test bands 4-5, or band 3 under an actual non-clear weather
carried over from elsewhere) — but on the evidence I have, it does not
reproduce. Recommend the next full `_capture_ground_and_sky.gd` pass (a
regular Track 1 evidence run will do this anyway) confirm one way or the
other rather than anyone spending more time on a targeted repro.

## Exact commands and reproducible camera stands

```
# One-time setup (already committed to this session's container, not the repo)
curl -fL -o g.zip https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip \
  && unzip -o g.zip && chmod +x Godot_v4.7-stable_linux.x86_64 \
  && mv Godot_v4.7-stable_linux.x86_64 /usr/local/bin/godot
godot --headless --path . --import   # twice if the first exits non-zero

# Day/night sweep (headline evidence)
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x800 \
  --script tools/_capture_day_night_transition.gd
# -> res://shots/day_night/hour-*.png, ranger-camp viewpoint
#    EYE=(-250,2266) h=1.8, TARGET=(-258,2258) h=0.9, HORIZON=0.32

# Golden-snap same-viewpoint probe (this session's diagnostic, now committed)
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x800 \
  --script tools/_probe_golden_snap.gd
# -> res://shots/day_night/probe-golden-snap-rangercamp.png

# Scoped ground/sky/weather checks (fast — single band/state instead of the full ~35min pass)
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x800 \
  --script tools/_capture_ground_and_sky.gd -- --only=band2 --states=fog,day
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x800 \
  --script tools/_capture_ground_and_sky.gd -- --only=band3 --states=day

# Water viewpoints (pond/river/stream)
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x720 \
  --script tools/capture_water.gd
# -> res://shots/gate_a/water/water-0{1..4}-*.png
```

## What I learned that is NOT visible in the diff

- **The "freeze-once" weather/clock-pin pattern needs to be the default for
  every new capture tool, not something ported reactively after a judge
  catches the symptom.** This is the third tool in this repo's history found
  missing it (`_capture_ground_and_sky.gd` had it from the start;
  `survey_band2.gd`/`capture_band3_region.gd` and now
  `_capture_day_night_transition.gd`/`capture_water.gd` needed it ported
  in). A short check in `ralph/conventions.md` for "does this capture tool
  freeze WorldLook AND WorldWeather before its first shot" would have caught
  three of these before a judge had to.
- **`_merged()`/`_blend_dict()`'s missing-key-defaults-to-sibling-value
  behaviour is a real, general footgun**, not specific to
  `adjustment_saturation`. Any future preset-exclusive key (set by only one
  named time-of-day, nothing in the base block) will silently pin rather
  than ramp across whichever segment approaches it. Worth either a base
  default for every key a preset might exclusively set, or a `_blend_dict`
  fix that treats a missing key as "hold the LAST fully-resolved value from
  further back in the cycle" rather than "equal the present side."
- **Averaging pixel brightness across a region is a poor proxy for "does
  this read as fog/haze to a human"** — the fog preset moved brightness
  substantially without reading as fog at all, because the change wasn't
  distance-gated (it was shadow removal, which affects near and far
  equally). Depth-cueing effects need to be evaluated by comparing
  near-vs-far *within the same frame*, not frame-vs-frame averages.
- **A capture tool's own camera stand encodes what it's FOR**, and citing
  its frames as evidence for something else is a category error worth
  catching early. `_capture_day_night_transition.gd`'s ranger-camp viewpoint
  was authored for OP23's navigability question ("can you see to navigate"),
  not for judging sky beauty — it was never going to show off a dramatic
  golden sunset even fully fixed, because it barely shows sky.

## Disagreements

- The brief's characterization of the golden-hour defect ("same viewpoint,
  snap path correct, blend path wrong... a specific, testable lead") does
  not hold up once weather/sun/cloud config bugs are fixed — see the
  detailed writeup in item 3 above. The blend math was never actually
  broken; three upstream config bugs (weather leak, blown sun, neutral
  clouds) were.
- I did not attempt the `fog_density` or `aerial_perspective` increases
  that would make items 6/7 visually obvious, because the project's own
  `art.json` comments record that axis being tried and explicitly rejected
  once already (R9.4). Re-litigating a settled owner complaint without a
  materially different approach felt like the wrong use of this session's
  budget; I'd rather hand over a precise diagnosis than a change likely to
  be reverted.

## Full file footprint

- `tools/_capture_day_night_transition.gd` — parking fix, weather pin/freeze.
- `tools/capture_water.gd` — parking fix, WorldLook/WorldWeather freeze,
  `SETTLE_AFTER_MOVE` 4→15, one-time post-boot warm-up. All re-rendered and
  verified (three iterations).
- `tools/_probe_golden_snap.gd` (+ `.uid`) — new, committed diagnostic tool
  (same convention as `_diag_golden_hour.gd`, `_judge_capture_arch_0829.gd`,
  etc.): snaps `apply_time("golden")` at the day/night tool's exact
  viewpoint for direct comparison.
- `data/config/art.json` — day/golden `sun_size`/`sun_glow`; golden
  `cloud_lit`/`cloud_shade`/`cloud_sun_gain`/`sun_colour`; base environment
  `adjustment_enabled`/`brightness`/`contrast`/`saturation` neutral
  defaults. No terrain material, grass/scatter, NPC/creature material,
  `burrow_warrens.gd`, `stronghold*.gd`/`landmark.gd`/
  `building_prefabs.json`, `scripts/combat/**`, `data/creatures/**`, or
  `data/config/bands/**` touched — all outside this lane's ownership, per
  the brief.
- `ralph/reports/T1-SKY/shots/**` — all evidence frames referenced above.
- This file.

## What I would do next

1. Hand item 5 (foliage albedo) to whoever owns `vegetation.gd` next, with
   the specific diagnosis above — it needs a canopy-albedo darkening pass
   analogous to R9.4's grass pass, not anything on the lighting side.
2. Hand item 7 (aerial perspective) to T1-GROUND with the specific
   diagnosis: a terrain-material distance gradient, not a fog-density
   increase (already tried, already rejected).
3. If someone wants a genuinely misty "fog" weather preset, propose a
   concrete density/colour number *with a fresh render* before landing it —
   don't just re-raise the old value.
4. A full, unscoped `_capture_ground_and_sky.gd` pass (~35 min) would be the
   right next full evidence set for a fresh Fable judge pass over all of
   Track 1's current state, now that the day/night/sun/cloud fixes are in.
