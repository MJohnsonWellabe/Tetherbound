# WORLD area — VP1 / VP2 / VP3 — round 1

Branch `claude/vp-world`, at `da0ab40a`. Area coordinator: Opus. All code edits and
renders delegated to Sonnet subagents; verification numbers below were re-measured by
the coordinator, not taken from a subagent's summary.

## Perf table

**Not measured this round.** Fix D (the `cull_tile_m = 0` vs shipped `16` A/B at
`band1_open` / `village_high` / `hall_approach`) did not run. This is the round's
biggest gap and the first thing to do next.

| view | metric | budget | tile=0 | tile=16 (shipped) |
|---|---|---|---|---|
| band1_open | primitives | ≤ 12.0 M | not measured | not measured |
| hall_approach | draw calls | ≤ 4000 | not measured | not measured |
| village_high | — | — | not measured | not measured |

Carried forward from the GROUND lane for context, not re-measured here: `24769eff`
recorded **31.67 M primitives at `band1_open`** with `cull_tile_m = 0`, against a
carpet-off baseline of 9.25 M. 31.7 M is the configuration that produced the owner's
~10 FPS report.

Why it did not run: the round was consumed by four defects that had to be fixed before
any perf number would describe the shipping configuration, two of which arrived as
mid-round regressions. Renders here are strictly serial and a single world build costs
tens of minutes (see *Render economics*), so the perf A/B — two full runs across three
stands — did not fit the remaining budget.

## What changed

| file | key | old → new | why |
|---|---|---|---|
| `data/config/art.json` | `sky.cloud_coverage` | 0.5 → 0.4 | clouds read as mackerel/overcast |
| | `sky.cloud_scale` | 1.5 → 0.9 | fewer, larger cumulus. A LARGER number means SMALLER clouds: `scale` multiplies the noise-sampling plane, so lowering it stretches the same cells over more sky |
| | `sky.cloud_high_opacity` | 0.35 → 0.18 base; golden 0.45 → 0.22; dawn 0.5 → 0.2 | thin cirrus was most of the mackerel read |
| | `sky.horizon_haze_strength` | 0.55 → 0.35 | haze washed the horizon to near-white |
| | `sky.horizon_haze_height` | 0.14 → 0.10 | as above |
| | `sky.horizon_haze_colour` | *(new, per time)* | haze biased bluer than each preset's horizon |
| | `sky.horizon_colour` + `environment.fog_colour` | `#d3cebd` → `#b4c8cc` | the ground fades to a cool `#aebcc4` at distance; a warm tan sky band put ~160° of hue against it at the seam. The two keys stay identical, per the invariant documented in the file |
| | `times.golden.environment.exposure` | 1.0 → 0.65 | coordinator: golden badly overexposed |
| | `times.golden.sun.energy` | 1.6 → 1.3 | as above |
| | `times.golden.sky.sun_size` | 0.014 → 0.012 | as above |
| | `sky.sun_glow_falloff` | *(new)* base 200.0, golden 120.0 | see *The sun blob* |
| `shaders/sky_clouds.gdshader` | `haze_colour` uniform | *(new)* | defaults to the old horizon colour, so unset presets are unchanged |
| | `sun_glow_falloff` uniform | *(new, default 24.0)* | replaces a hardcoded exponent |
| `scripts/world/world_look.gd` | `set_clock_frozen()` | *(new)* | see *The clock drift bug* |
| | haze/falloff wiring | *(new)* | follows the existing `_apply_cloud_sky` pair-list pattern |
| `scripts/world/vegetation.gd` | `take_over_path()` in `_adjusted_texture` | *(new)* | see *The white canopy regression* |
| `tools/survey.gd`, `tools/_capture_locations.gd` | freeze the clock during capture | | as above |

`data/config/terrain_playground.json` — **no edit needed**. The round-1 fix list asked
for aerial range 380 → 650, strength 0.42 → 0.30, colour `#c6ccbd` → `#aebcc4`; the
branch already carried exactly those values from `6454c6ce`. The fix list's "current"
figures described a tree older than the branch. Verified on disk and against
`shaders/terrain_ground.gdshader:667`, which confirms `aerial_fade_range_m` is in
world-space metres, so 650 is directly usable. `aerial_desaturate` at 0.55 only
desaturates 55% toward luma at full fade, so distance keeps chroma — left alone.

## Four defects fixed

### The clock drift bug (found while chasing VP1-G0)

`data/config/art.json` sets `day_length_seconds: 600`, so **one in-game hour elapses
every 25 real seconds**. This box has no GPU, so a software-rendered frame costs about
a real second, making `delta` enormous. `world_look.gd::_process` advances
`_elapsed_seconds` every frame and re-derives sun/sky/environment from the drifted hour
via `_apply_blended()`, overwriting whatever `apply_time()` pinned.

So `survey.gd`'s 20 physics + 4 process settle frames after `apply_time("golden")` were
~24 real seconds — about an in-game hour of drift — and the shutter fired on a scene the
clock had already walked away from. **Any capture tool that pins a time and then waits
loses that time.** This silently affects every timed frame this program captures, not
just golden.

An earlier attempt to fix the black golden frame by *adding* 120 settle frames made it
worse: it produced a lit frame that measured R−G of −0.1 and was flat midday, roughly
five in-game hours off the pinned 18:00. That frame is kept at
`round1/clock-freeze/00-INVALID-settle-attempt-golden.png` so the approach is not
repeated. `set_clock_frozen(true)` is off by default and never called from a gameplay
path, so a player's day/night cycle is untouched.

`tools/_capture_locations.gd` had the same bug in `_pin()` and is fixed the same way.
`tools/_capture_ground_and_sky.gd` was checked and is already correct (it freezes once
at boot). `tools/perf_render_stats.gd` never touches time-of-day.

### The sun blob

The giant white sun was never the disc, and the prescribed fix could not have worked.
`shaders/sky_clouds.gdshader:269` computed `glow = pow(clamp(sun_dot,0,1), 24.0) *
sun_glow` with the exponent **hardcoded**. Half-max falls at cos θ = 2^(−1/24), i.e.
θ = 13.7°: a **27.4°-diameter halo**, roughly 54× the sun's real angular size, added
straight into `colour` before the ACES tonemap so it saturates to white across a huge
solid angle. `sun_size` and `disc_edge` shape only `disc`; `sun_glow` scales the halo's
brightness but never its extent. That is why round 1's earlier `sun_size` retune did
not shrink the blob, and why the coordinator's `sun_size ~0.012` prescription would not
have either.

Now tunable as `sun_glow_falloff`, default 24.0 so unset presets are unchanged.
Base 200.0 ≈ 9.5°; golden 120.0 ≈ 12.3°.

**Open risk:** base applies to *every* preset, so day, dawn and night — the moon
included — now get a ~3× narrower glow than before. That is wider than the named defect.
The night frames in the running render are the check; see *Unresolved*.

### The white canopy regression

Every tree canopy rendered as a pale mint-white blob. Reproduced numerically here:
pale-mint pixels went from 0.06% / 0.00% of frame pre-VEG to **1.07% / 1.76%** on
`01-spawn-outward` / `02-valley-floor`.

Root cause is **binding, not the desaturation maths**. `ImageTexture.create_from_image()`
produces a resource with an empty `resource_path`, unlike the imported
`CompressedTexture2D` it replaces. Each retinted mesh is packed into a throwaway
`PackedScene` (`vegetation.gd::_make_mesh_asset`) and handed to
`Terrain3DMeshAsset.scene_file`, and that round-trip drops a path-less runtime resource
while a path-bearing one survives — leaving a null albedo, which draws white. The
coordinator's pixel measurement is what makes this conclusive: the shipped canopy colour
was *exactly* the flat `retint` tint (`#a9d18c`) over a **white** albedo.

Fixed with `take_over_path()` giving the derived texture a stable synthetic identity.
`data/config/vegetation.json` untouched, so the scatter bake stays valid.

**Evidence honesty:** the subagent did *not* independently reproduce the drop inside
Terrain3D's registration — it is a compiled GDExtension with no GDScript to step
through — and took the coordinator's measurement on trust. The mechanism is inferred
from strong circumstantial evidence, not proven.

### VP1-G0, the black golden frame

Does not reproduce on the coordinator's merged tip. On this branch it was black in
`VP-PRE` too, i.e. it **predates** every VP1/VP2/VP3 change. After the clock freeze the
frame renders correctly, so it is resolved here, but the original mechanism was never
isolated — the leading theory is a shader-variant compile stall on the software
rasteriser, unconfirmed.

## Frames

All under `ralph/reports/visual-parity/WORLD/round1/`:

- `before/` — the first-cut state this round started from (5 frames, 1280×720).
- `clock-freeze/` — clock-freeze verification, including the rejected settle attempt.
- `stands/` — 2 stands × 4 times, 1280×720, from the combined verification render.
- `_sheet_before.png`, `_sheet_clock-freeze.png` — contact sheets (built with PIL, not
  `tools/contact_sheet.gd`, because a render held the single Godot slot).

Measured, day frames, first cut vs pre-cut baseline — the first cut darkened the scene
systematically, which is worth a judge's eye:

| frame | VP-PRE mean | after first cut |
|---|---|---|
| 01-spawn-outward | 112.4 121.0 73.7 | 87.1 102.4 59.7 |
| 02-valley-floor | 123.1 131.8 71.9 | 96.9 111.1 58.4 |
| 03-rise-overlook | 131.8 151.7 137.2 | 115.0 135.7 120.9 |
| 04-three-quarter | 92.8 129.2 111.2 | 71.1 110.3 95.0 |

Clock-freeze verification (960×540 diagnostic), with `DIAG` proving the pin held:

| frame | mean RGB | R−G | verdict |
|---|---|---|---|
| 01-spawn-outward (day, `hour=8.0000`) | 80.3 100.1 59.1 | −19.8 | green-dominant, correct |
| 05-spawn-low-sun (golden, `hour=18.0000`) | 117.2 112.5 68.5 | **+4.7** | genuinely warm |

For contrast the rejected settle attempt measured R−G of −0.1 — neutral daylight.

## Tests

**Not run.** `run_tests.gd --only=test_grass_field.gd,test_scatter_rules.gd,test_scatter_perf_budget.gd`
and the smokes (`smoke_playground.gd`, `smoke_traversal.gd`, `smoke_unstick.gd`,
`smoke_art.gd`) did not execute. Each needs the Godot slot, which was held by renders
for the whole round. This is a real gap: `scripts/world/world_look.gd` and
`scripts/world/vegetation.gd` both changed, and `smoke_art.gd` in particular asserts on
material textures.

## Playability guard

**Not run**, same reason.

## Render economics (the round's main constraint)

- **No GPU exists in this container.** `/dev/dri` is absent; every Vulkan ICD except
  `lvp` (lavapipe) needs a device node. Everything is software-rasterised through
  llvmpipe. `forward_plus` on lavapipe would be slower than `gl_compatibility`, so the
  current path is already the cheaper one.
- **World construction, not pixels, dominates.** A capture process spends tens of
  minutes building the world — relay station, river course, warrens, stronghold massing,
  131 harvest nodes, 507 trees cleared — before drawing anything. That cost is
  essentially resolution-independent, so `VP_FAST` and lower resolution help far less
  than expected. **The real lever is fewer Godot launches, not cheaper frames.** This
  round's verification was therefore batched into one build covering four fixes.
- Peak memory is ~8.5 GB of 16 GB, so two concurrent Godots would OOM. Renders must stay
  serial.
- The scatter bake was regenerated at the start (819,426 placements, 11 layers, 256
  regions) and left uncommitted per the lane rules.

## Unresolved

1. **Perf table not measured** — fix D. Highest priority next round.
2. **Tests and smokes not run** — including `smoke_art.gd`, which touches material
   textures and is the natural guard for the canopy fix.
3. **Moon glow may be a self-inflicted regression.** `sun_glow_falloff` base 200.0
   narrows night's glow ~3× from the old hardcoded 24.0. The night frames from the
   combined render are the check; if the moon reads too tight, give `times.night` its
   own wider override rather than reverting the base.
4. **`take_over_path()` and PCK export.** The synthetic path
   `res://._generated/vegetation_leaf_adjust/<md5>.tex` does not exist on disk. Nothing
   *in this repo* loads it by path (`registered_mesh()` consumes `scene_file` as an
   in-memory object, and no tool audits materials against disk). But whether Godot's
   export step treats a `take_over_path()`'d resource as an external reference-by-path
   is **not verified**, and if it does, an exported build could ship a broken texture
   reference while these headless captures look perfect. Given Windows/ROG Ally is the
   primary target, this needs checking against a real export before the fix is trusted.
5. **The first cut darkened every day frame** by ~20–25 per channel (table above).
   Systemic, not per-view. Not diagnosed.
6. **VP1-G0's original mechanism** never isolated.
7. **Golden's overexposure vs the canopy bug were being read as one defect.** Measured
   `blownwhite` was 0.00% in both clock-freeze frames while pale-mint was 4.13%
   (golden) and 0.91% (day), which suggests "trees blown to white" was mostly the canopy
   *binding* bug. The exposure values were still applied, but their necessity is
   unproven.

## Coordination notes

- The round-1 fix list's aerial values described a tree older than the branch, so fix C
  was already satisfied. Worth checking the branch tip before writing the next list.
- The `sun_size` prescription for the sun blob targeted the wrong shader term and could
  not have worked; the fix required making the glow exponent tunable.
- A subagent refused mid-round steering because relayed coordinator notes arrived
  wrapped in tags resembling system reminders, and it correctly treated them as
  untrusted. It left its primary deliverable unwritten as a result. Later tasks carry an
  explicit trust preamble. Worth knowing for any lane that relays notes to subagents.
- `night`'s `sky.horizon_colour` (`#3d5285`) and `environment.fog_colour` (`#31446f`)
  do **not** match each other, violating the invariant the file documents, and the
  adjacent `_comment_fog_colour_ev8` cites `#1c2740`, which matches neither.
  Pre-existing, out of scope, untouched.

## Recommended next step

Run fix D's perf A/B and the test/smoke set, in that order, in as few Godot launches as
possible — they are the two hard gaps and neither needs a fix first. Judge the night
frames for the moon-glow question before anything else is tuned.

---

## Round-1 verification render — results

8 frames, 2 stands x 4 times, 1280x720, one world build.
`round1/stands/` + `_sheet_stands.png`.

| frame | mean RGB | R-G | palemint% | nearwhite% |
|---|---|---|---|---|
| 01-spawn-outward-day | 80.7 100.2 59.4 | -19.5 | 0.93 | 0.00 |
| 01-spawn-outward-golden | 77.3 72.9 40.7 | +4.4 | 2.11 | 0.00 |
| 01-spawn-outward-night | 8.6 18.6 23.2 | -10.0 | 0.01 | 0.00 |
| 01-spawn-outward-dawn | 58.6 60.0 43.6 | -1.4 | 0.01 | 0.00 |
| 03-rise-overlook-day | 103.9 130.1 119.2 | -26.2 | 0.00 | 0.00 |
| 03-rise-overlook-golden | 82.0 100.7 102.2 | -18.7 | 0.00 | 0.00 |
| 03-rise-overlook-night | 18.8 68.3 104.0 | -49.5 | 0.00 | 0.00 |
| 03-rise-overlook-dawn | 160.7 63.9 54.8 | **+96.8** | 0.00 | 0.00 |

### Verdicts

**Clock freeze — PASS.** All 8 DIAG lines pinned exactly: day `hour=8.0000`,
golden `hour=18.0000`, night `hour=0.0000`, dawn `hour=5.0000`. No drift across
settle and pose frames, at either stand.

**Canopy binding (`take_over_path()`) — FAIL.** Pale-mint on `01-spawn-outward`
day is 0.93%, against 1.07% for the broken first cut and **0.06% for the
pre-regression VP-PRE baseline**. Still ~15x baseline. The comparison is
conservative: the current frame is *darker* than VP-PRE (80.7/100.2/59.4 vs
112.4/121.0/73.7), which should push pale-mint down, yet it went up. The fix did
not restore the binding. Consistent with the subagent never having independently
confirmed the drop inside Terrain3D's registration. Next attempt should use the
diagnostic that was skipped: read back `albedo_texture` on the registered asset
and see whether it is null, before trying another fix. The `user://` round-trip
is the untried alternative.

Caveat on the metric: pale-mint only fires on bright pixels (190-245), so dark
frames (night, dawn, and both `03-rise-overlook` views) cannot register white
canopies at all. Only the day frames test this.

**Sun glow / golden exposure — INCONCLUSIVE, needs an eye.** `nearwhite` is
0.00% in all 8 frames, so nothing is blowing out any more. But `nearwhite` was
also 0.00% *before* the glow fix, so it never was the right measure of the blob
— the halo saturated to white over a wide solid angle without necessarily
clipping. Disc diameter in pixels was not measured. Judge from
`_sheet_stands.png`.

**Golden may now be too dark.** `01-spawn-outward-golden` mean fell from 117.2
(pre-exposure-change, clock-frozen) to 77.3. The exposure 1.0 -> 0.65 was applied
on the strength of "trees blown to white", which the numbers now attribute mostly
to the canopy binding bug, not to exposure. If the canopy fix lands properly,
revisit whether 0.65 was needed at all.

### New defect found by this render: aerial perspective is time-invariant

`terrain_playground.json` `shader.aerial_fade_colour` is a fixed `#aebcc4` and
does not vary with time of day, while the sky's fog and horizon do. Two
independent symptoms in these frames:

- `03-rise-overlook-night` means 18.8 68.3 **104.0** — the distance is *brighter
  and bluer than the foreground at midnight* (compare `01-spawn-outward-night` at
  8.6 18.6 23.2). Night's fog (`#31446f`) and horizon (`#3d5285`) go properly
  dark, but the terrain's own aerial term keeps pulling far hills toward a bright
  cool grey, so the horizon glows.
- `03-rise-overlook-golden` is R-G **-18.7** with blue above green, i.e. cool,
  at 18:00. Golden only reads warm at the sun-facing stand (`01` at +4.4).

Fix direction: drive the aerial fade colour/strength per time-of-day the way the
sky keys already are, instead of a constant. This likely also contributes to the
systematic darkening noted above, since the aerial term fights the lighting at
every hour except midday. **Strongest candidate for round 2.**

### Also worth an eye

`03-rise-overlook-dawn` is R-G **+96.8** (160.7 63.9 54.8) — an almost
monochrome red frame, against a neutral -1.4 for the same time at stand 01.
Plausibly a sunrise viewed head-on, but the magnitude is extreme and it was not
diagnosed.

---

## Post-round addendum — independent re-analysis of the same 8 frames

An independent pass over the committed frames corroborated every number above and
added three findings the first pass missed.

### 1. CONFIRMED BUG: `adjust_bsc` is not a Godot method — the leaf desaturation has never run

`scripts/world/vegetation.gd:615` calls `image.adjust_bsc(brightness, contrast,
saturation)`. Godot's actual method is **`adjust_bcs`**. The verification render's log
contains, 8 times — once per call:

```
SCRIPT ERROR: Invalid call. Nonexistent function 'adjust_bsc' in base 'Image'.
```

GDScript logs the error and continues, so the whole VEG leaf-desaturation feature has
been a silent no-op since it was written. The doc comment at `vegetation.gd:582`
repeats the same transposition, which is presumably how it survived review.

This explains the canopy FAIL above and reframes it: `take_over_path()` addressed the
*binding*, but the *colour* half of the fix could never have worked. Measured canopy
pixels in `01-spawn-outward-day` average RGB **(72.6, 101.3, 31.0)** — blue at 31
against the target family's 60–74. An olive-yellow green, not the intended deeper cooler
green.

**Deliberately NOT applied.** The round was stopped by the program coordinator with "do
not start any new render or fix", and while the edit is one transposed character, it
converts a line that currently throws into a line that actually changes every leaf
texture in the world. That is a visual change requiring a render to verify, and shipping
it unverified against an explicit stop is exactly the failure mode this round already
hit once with the 120-settle-frame "fix". **It is the single highest-value first action
for round 2**: one character, then re-render the day stands and compare canopy RGB
against the `#5f9a4a` / `#2f5f3c` target.

### 2. The moon question cannot be answered from these stands

The moon's yaw (25°) is outside both cameras' FOV, so **no moon is visible in either
night frame**. The brightest region in `01-spawn-outward-night` is a diffuse RGB
(240,240,240) cloud patch, not the tinted `#d8e2ff` disc. So the open risk recorded
above — that `sun_glow_falloff` 200.0 narrowed the moon's glow ~3× — remains genuinely
**unanswered**, not cleared. Round 2 needs a night stand aimed at the moon's azimuth.

### 3. The pale-mint metric is blind at distance

Distant tree clumps in `03-rise-overlook-day` and `-golden` read as visibly pale
whitish-mint puffballs, while the numeric mask reports **0.00%** for those frames. The
mask's RGB relationship does not survive aerial-perspective fog at range, so the metric
misses the failure mode that is most obvious in the wide establishing shot — the shot a
judge looks at first. Do not treat a 0.00% pale-mint reading on a distant view as
evidence of anything.

### 4. Sun glow: day passes, golden does not

Measured disc/halo bounding boxes: **day 31×25 px** — a small clean disc, working as
intended. **Golden 224×113 px** at stand 01 and 227×92 px at stand 03, both touching the
frame's top edge, with no visible crisp disc edge inside the mass — roughly 18° against
the ~12.3° the `sun_glow_falloff=120` config comment predicts. Better than the old fixed
27° halo, but golden still reads as a soft light mass rather than a disc with a glow.
Golden wants a tighter falloff than 120.0.

---

# Round 2

Branch `claude/vp-world`. Perf table is the program coordinator's this round, by
their instruction — not attempted here.

## Values changed

| file | key | old → new | why |
|---|---|---|---|
| `data/config/vegetation.json` | `trees`/`grove`/`saplings`/`bushes` `retexture_adjust` | **removed** | the runtime adjust path never worked, twice over (below) |
| | those layers' `retexture` swap targets | → `derived/Leaves_NormalTree_C_desat55.png` (bushes: `_b100`) | baked offline instead |
| | `variant_retint` | unchanged | still supplies the three tints |
| new assets | `assets/environment/stylized_nature/derived/*.png` | *(new)* | brightness 1.05/1.00, saturation 0.55 |
| `data/config/art.json` | `sky.sun_glow_falloff` | 200.0 → 600.0 | halo 9.5° → 5.5° |
| | `sky.sun_glow` | 0.12 → **held at 0.12** | see *the stale-value correction* |
| | `sky.cloud_edge_softness` | 0.06 → 0.10 | edges read blotchy at larger cloud size |
| | `times.golden.sky.sun_glow_falloff` | 120.0 → 350.0 | halo 12.3° → 7.2° |
| | `times.golden.sky.sun_disc_edge` | *(inherited 0.75)* → 0.7 | crisp modest disc |
| | `times.night.sky.sun_glow_falloff` | *(none)* → 80.0 | moon needs a WIDE ~15° halo |
| | `times.night.sky.sun_glow` | 0.05 → 0.12 | moon had no glow at all |
| | `times.dawn.environment.exposure` | 0.8 → 0.55 | dominant cause of the red wash |
| | `times.dawn.environment.fog_density` | 0.0009 → 0.0006 | secondary contributor |
| `tools/_capture_locations.gd` | `02-mill-pond-approach` `back`/`up` | 7.0/3.2 → 13.0/9.2 | stand was inside a canopy |

## The canopy fix — VERIFIED

The runtime adjustment path failed for **two independent, separately confirmed**
reasons, which is why two prior attempts did not move it:

1. `vegetation.gd:615` called `image.adjust_bsc(...)`. **No such Godot method** —
   the engine's is `adjust_bcs`. The render log carried `SCRIPT ERROR: Invalid
   call. Nonexistent function 'adjust_bsc' in base 'Image'` eight times, once per
   call. The desaturation had never executed, not once, since it was written.
2. The derived `ImageTexture` has an empty `resource_path` and is dropped through
   the `PackedScene` → `Terrain3DMeshAsset` round-trip. `take_over_path()` did not
   fix it (pale-mint stayed at 0.93% against a 0.06% baseline).

Baking offline sidesteps both: the derived sheets are ordinary imported textures
with real paths, bound through the existing `retexture` swap
(`vegetation.gd:688`, `albedo_texture = load(swap)`).

All four adjusting layers resolve to **one** source texture,
`Leaves_NormalTree_C.png` — confirmed by reading each model's
`pbrMetallicRoughness.baseColorTexture` out of the `.gltf`, not guessed from
filenames. TwistedTree and CherryBlossom already swap to it before any adjust ran.

The bake matches the engine exactly: `Image::adjust_bcs` centres saturation on the
plain arithmetic mean `(r+g+b)/3`, **not** luma weights (verified against
`core/io/image.cpp` — my own instruction to the subagent said luma weights and was
wrong; it checked and overrode me).

- mean RGB 86.3/121.8/**0.0** → 82.6/103.1/**32.8**; blue max 0.0 → 80.3
- mean HSV saturation 0.984 → 0.671; alpha byte-for-byte identical

The zero blue channel was the whole problem: no multiply tint can desaturate a
texel whose blue is 0, which is why two rounds of `variant_retint` still rendered
fluorescent lime.

**Verified in frame.** `02-mill-pond-approach-day` — the stand the judge could not
read — now shows genuine deep and mid greens with visible per-tree tint variation,
45.0% green pixels against 0.60% pale-mint, with the mill and pond legible behind.

## The stale-value correction (worth propagating)

The round-2 fix list said `sky.sun_glow` 0.35 → 0.25, intending to **dim** the
glow. The file's actual base was already **0.12**, so applying the literal target
would have **more than doubled** the glow's brightness — on the exact defect the
round was fixing. Held at 0.12. If the sun now reads too dim rather than too
broad, the faithful reading of the intended ratio is 0.12 × (0.25/0.35) ≈ 0.086,
i.e. dimmer still.

This is the second round where a prescribed value described a state the branch was
not in (round 1's aerial values were already satisfied). Checking the tip before
writing the list would save a round-trip.

## Dawn red wash — diagnosis

Dominant cause is `environment.exposure` at **0.8**, the highest of the three
sunlit presets (day 0.6, golden 0.65) despite dawn having the **lowest**
`sun.energy` (0.9) and the most saturated `sun.colour` (`#ffc3a0`). Exposure
multiplies every HDR pixel uniformly regardless of depth or view direction — the
only lever that can reach sky, far terrain **and** near ground alike, which is what
"uniform red-orange including the near field" requires. Under this project's ACES
tonemap an overexposed warm scene plateaus toward a saturated warm colour rather
than clipping to white, matching the measurement exactly.

The two-stand discrepancy (03 at R−G +96.8, 01 at −1.4) is framing, not config:
`03-rise-overlook` is an elevated 15 m, ~275 m open vista with far more sunlit
content to push into the plateau.

Ruled out on evidence, not merely discounted:
- `aerial_perspective` (0.8) — `ralph/DONE.md`'s EV8 entry records it as having no
  measurable effect under `gl_compatibility`, which `project.godot` still uses.
- a tonemap/adjustment leak from `night` — `_merged()` layers only base plus the one
  named preset and never chains.

## Golden's cool cast — NOT an inheritance bug

Golden explicitly overrides both `sky.horizon_colour` and `environment.fog_colour`
to a matching warm `#e8b784`; it is not silently taking the cool base `#b4c8cc`.
Remaining contributors, all deliberate or out of scope: golden's cool
`ambient_colour` `#8f9ec4`, its cool `cloud_shade`/`cloud_base`, and — the biggest
suspect for a vista shot — the terrain's constant `aerial_fade_colour` `#aebcc4`.

**That last one remains this area's top structural defect** (raised at the end of
round 1, unaddressed): the terrain's aerial perspective colour never varies with
time of day, while the sky's fog and horizon do. It makes the horizon glow at
midnight and stay cold at golden hour.

## Frames

`ralph/reports/visual-parity/WORLD/round2/`:
- `locations/` — 15 frames, village + mill-pond, day and night, 960×540.
- `_sheet_locations.png` — contact sheet.

Pale-mint on `01-village-standing` (1.83%) and `02-mill-pond-standing` (1.96%) is
**bright sky and cloud**, not canopy — those stands frame open sky and pale walls,
and the metric's 190–245 band catches both. Confirmed by eye on the approach frame,
where the same metric reads 0.60% with visibly green trees.

## Verified vs not

| item | status |
|---|---|
| canopy leaf bake + swap | **VERIFIED in frame** (green canopies, tint variation) |
| mill-pond camera lift | **VERIFIED** (mill and pond legible) |
| cloud edge softness | visible in frame, soft edges, no blotching |
| sun halo 600/350 | **NOT verified** — needs a frame with the sun in view |
| moon glow (night falloff 80) | **NOT verified** — needs a night stand aimed at the moon |
| dawn exposure 0.55 | **NOT verified** — needs a dawn stand |
| tests / smokes | **NOT run** |

## Render economics, again

`tools/vp_capture.sh` launches a **separate Godot per tool**, and each pays the full
world build — locations alone took 2137 s. Combined with the mandatory ~7 min
scatter re-bake after any `vegetation.json` edit, a full capture set does not fit a
75-minute budget on this GPU-less box. Batching everything a round needs into ONE
world build, as round 1's stands render did, is the only approach that fits.

## Round-2 survey frames — and a REGRESSION

`round2/survey/` + `_sheet_survey.png`, 960x540.

| frame | mean RGB | R-G | palemint% |
|---|---|---|---|
| 01-spawn-outward | 78.0 98.1 56.9 | -20.1 | 0.20 |
| 02-valley-floor | 90.3 109.0 56.2 | -18.7 | 0.42 |
| 03-rise-overlook | 101.4 127.7 116.3 | -26.3 | 0.00 |
| 04-three-quarter | 66.3 108.0 93.8 | -41.7 | 0.00 |
| **05-spawn-low-sun** | **0.0 0.0 0.0** | — | 0.00 |

Canopy corroboration: pale-mint on the day survey stands fell to 0.20% / 0.42%,
against 1.07% / 1.76% for the broken first cut and a 0.06% pre-regression
baseline. Combined with the visibly green mill-pond frame, the leaf bake holds
across both capture tools.

**REGRESSION: `05-spawn-low-sun` is pure black again** (mean 0,0,0), the same
failure as round 1's VP1-G0.

What this is NOT:
- Not a missing clock freeze. `set_clock_frozen` is committed (`6afd51a1`) and
  present in `world_look.gd:139`, called from `tools/survey.gd:204`. The
  implementation is a clean early return in `_process`.
- Not a general breakage: the four day stands in the SAME run render correctly,
  and all 15 location frames — day AND night, through the same freeze in
  `_capture_locations.gd` — render correctly.

What contradicts it: round 1's stands render produced a genuinely lit, warm
golden frame at a verified `hour=18.0000`, using an adapted copy of this same
tool. So golden renders under one tool and not the other, with the same config.

Mechanism UNKNOWN. Not diagnosed — the round-2 budget was spent. Untested
hypothesis worth trying first: `apply_time()` may not push the sky material the
way `_apply_blended()` does, so freezing the clock before any blend has run could
leave a preset that differs from the boot state uninitialised. That would explain
why `day` (the boot state) survives and `golden` does not, and why round 1's
adapted tool — which froze at a different point in its sequence — did not hit it.

**This is the top item for round 3**, ahead of further tuning: the golden-hour
frame is unjudgeable, so the sun-halo (600/350) and golden-exposure changes
remain unverifiable through this tool.

## Ground/sky frames — golden is FINE; the black frame is a TOOL bug

`round2/ground/` + `_sheet_ground.png`, 960x540, four stands across day / golden /
night (plus cloudy / fog / rain at band2).

| frame | mean RGB | R-G | nearwhite% |
|---|---|---|---|
| 00-village-golden | 64.8 60.9 37.6 | **+3.9** | 0.00 |
| 01-band1-opening-golden | 71.2 58.3 35.3 | **+12.9** | 0.00 |
| 02-band2-stone-root-golden | 24.7 20.9 8.6 | **+3.8** | 0.00 |
| 03-band3-crossing-golden | 59.3 52.0 33.5 | **+7.3** | 0.00 |
| 00-village-day | 98.6 113.9 60.5 | -15.3 | 0.00 |
| 00-village-night | 6.1 15.0 20.0 | -8.9 | 0.00 |

**All four golden stands render, and all four are warm** (R-G positive, against
negative for every day stand), with `nearwhite` 0.00% everywhere — no blown-out
sun blob at any time of day.

This settles the regression above: **golden's configuration is correct, and
`05-spawn-low-sun`'s black frame is a defect in `tools/survey.gd`, not in
`data/config/art.json`.** Golden renders correctly through
`_capture_ground_and_sky.gd` on the identical config, in the same pipeline run,
minutes apart.

A concrete difference to start from in round 3: the two tools freeze the clock by
DIFFERENT mechanisms. `_capture_ground_and_sky.gd` calls `set_process(false)` on
`_look`/`_weather` once at boot; `tools/survey.gd` uses the newer
`set_clock_frozen(true)`. The working tool uses the older mechanism. That is where
to look first — and it means round 1's `set_clock_frozen` may itself be implicated,
despite the four day stands surviving it.

**Round-3 recommendation changes accordingly: fix the tool, do NOT retune golden.**
Retuning golden against a black frame would be tuning against an artefact.

### What this verifies

- **Sun halo (falloff 600 base / 350 golden)** — `nearwhite` 0.00% at every stand
  and every time of day, including the golden stands where the sun is in view.
  No blown white mass. Consistent with the intended 5.5 deg / 7.2 deg halo, though
  disc diameter in pixels was not measured this round.
- **Golden exposure 0.65** — warm without blowing out, at four independent stands.
- **Dawn** — still NOT verified; this tool captures day/golden/night, not dawn.
- **Moon glow (night falloff 80)** — still NOT verified. The night stands are very
  dark (mean 6.1 / 3.8 / 5.5) with no blown pixels, but nothing here confirms the
  moon is in frame, and round 1 established it sits outside these headings.

---

# Round 3

Merged `origin/claude/coordination-subagents-3fhz1x` first, as instructed; it carries the
measured VP2 cost config (`cull_tile_m` 24, `scatter_lod_ranges` false), untouched here, and
brings VP_FAST, used for all round-3 captures. Re-baked after the config edits: 826,135
placements. Perf table is the coordinator's this round.

## Headline: VP1-G0 is FIXED, and the cause explains three rounds of contradictions

`05-spawn-low-sun` renders **lit and warm, mean 84.5/73.0/47.7, R−G +11.5**, where it was
pure 0,0,0 in VP-PRE, in the first cut, and again in round 2.

The freeze *ordering* was never the defect. `survey.gd` never froze **WorldWeather**, and
`world_look.gd::set_weather()` is **not gated by `_clock_frozen`** — it unconditionally
calls `_apply_blended()`. That is the one deliberate exception to the freeze contract (so a
capture tool can set weather while frozen), but it also means WorldWeather's own
unsupervised roll reaches WorldLook through a door the freeze never covers. WorldWeather
rolls on a **240–480s real-time** timer, so it only reaches runs long enough to cross that
window — on whichever viewpoint is last:

- round 1's 2-viewpoint stands render → good golden frame (too short to reach the roll)
- the 5-viewpoint survey → golden fails, and golden is its final viewpoint
- `_capture_ground_and_sky.gd` and `_capture_locations.gd` → never failed, because both
  force weather to "clear" and freeze the node

**This is a general trap, not a survey bug.** Any capture tool that freezes the clock but
not the weather node will silently drift, and only on long runs — which is exactly why it
survived three rounds and made short tests look like passes. Worth every lane knowing.

## Values changed

| file | key | old → new |
|---|---|---|
| `art.json` | `sky.sun_colour` | #fff1d8 → #fff0c8 |
| | `sky.sun_disc_edge` | 0.75 → 0.5 |
| | `sky.sun_glow_falloff` | 600 → 2050 (5.5° → 3.0°) |
| | `times.golden.sky.sun_glow_falloff` | 350 → 1150 (7.2° → 4.0°) |
| | `times.golden.environment.ambient_colour` | #8f9ec4 → #a59fb5 |
| | `times.golden.sky.cloud_shade` / `cloud_base` | #6a5d78/#4f4459 → #8a7d78/#6b5c56 |
| | `times.night.sky.sun_glow_falloff` / `sun_glow` | 80 → 55 / 0.12 → 0.15 |
| | `times.night.sky.horizon_colour` + `environment.fog_colour` | #3d5285/#31446f → #4d6a9e (both) |
| | `times.night.environment.ambient_colour` | #2a3b6e → #34448a |
| | `times.dawn.environment.exposure` / `fog_density` | 0.8 → 0.55 / 0.0009 → 0.0006 |
| `terrain_playground.json` | `shader.grain_fade_end_m` | 48.0 → 60.0 |
| | `shader.aerial_fade_strength` | 0.30 → 0.24 |
| | `shader.aerial_fade_colour` | #aebcc4 → #7f8c9e |
| `vegetation.json` | `layers.trees.ridge_bias` | 0.75 → 0.4 |
| `tools/survey.gd` | freeze WorldWeather + DIAG prints | *(new)* |

Also fixes a long-standing invariant violation: night's `horizon_colour` and `fog_colour`
disagreed. The invariant now holds in **every** preset.

## Verified

- **Golden hour renders** (above).
- **The moon, photographed for the first time.** A crisp disc with a soft halo, placed where
  the arithmetic predicted (yaw 25°, horizon 0.65 → ~8° above frame centre). It had evaded
  three rounds purely because no capture faced yaw 25°.
- **Night value range (item 5).** Every night frame brighter with more channel separation and
  exposure untouched: `01-village-approach-night` 6.4/16.6/31.7 → 11.3/22.4/39.3.
- **Golden at the sun-facing stand:** R−G +4.4 → **+12.3**.
- **Canopies still green** after the re-bake (`02-mill-pond-approach` pale-mint 0.70%).

## NOT verified / failed

**1. Golden is still cool at the away-facing stand.** −18.7 → **−16.2**. Warming ambient and
clouds moved it 2.5 points, so the diagnosis that ambient dominated was wrong. Worse, the
round's own fixes fight each other there: item 1 warmed ambient while item 8 made
`aerial_fade_colour` bluer and darker, and at a stand facing away from the sun most of the
frame is distant terrain, so the aerial term wins.

**2. The dawn exposure fix is FALSIFIED.** `03-rise-overlook-dawn` R−G +96.8 → **+96.3**. A
31% exposure cut moved the cast by half a point. In hindsight the reasoning was
self-defeating: **exposure scales R, G and B proportionally, so it can darken a frame but can
never remove a hue cast.** The frame did get darker (mean 160.7 → 145.8) — exposure working
as exposure. Prime suspect now is dawn's `fog_colour` **#e6bca4**, a strongly warm orange
dominating a vista where fog covers most of the frame. Never questioned; `fog_density` was
cut instead.

**3. NEW DEFECT — a full-frame maroon wash whenever the light source is in view.** The moon
stand exposed it: R−G **+78.3** at night with the moon in frame, and **+96.3** at the dawn
vista, against **+3.7** and **−50.8** for the same times at stands without the light in
frame. Night's own palette is cool (`sun_colour` #d8e2ff, fog #4d6a9e), so this is not the
preset's colours. No previous capture had ever faced a light source — adding one camera
found it.

**4. Night horizon glow got WORSE.** `03-rise-overlook-night` 18.8/68.3/104.0 →
**25.8/76.6/113.8**. Item 5's brightening propagates into the distance because
`aerial_fade_colour` is time-invariant. The vista sits at mean 72 against the same time's
foreground at 21.

**5. Tests and smokes NOT run** — the Godot slot was held by renders for the whole round.

## Structural findings for round 4

**`aerial_fade_colour` cannot be fixed with a value — it needs script wiring.**
`playground_world.gd::_apply_ground_shader` reads the shader block **once** at scene setup
and never again, and `world_look.gd` re-derives sky/fog/ambient every blend tick but has **no
connection to the terrain material at all**. This is now the third round this constant has
been the root cause (golden cool at range, night horizon glow, distance not separating), and
it will keep resurfacing until something pushes a per-time colour into that uniform.

**Nothing connects the aerial term to vegetation** — only `terrain_ground.gdshader` reads it.
So "distant trees read as thin pins" cannot be fixed from `terrain_playground.json`.

**Two texture tints violate the file's own rule.** `textures[grass].tint` #e9dfc0 and
`textures[soil].tint` #e2d8b4 are warm creams with no override comment, against the file's
stated "tint is WHITE, deliberately, on every surface" (rock/damp/forest_floor are #ffffff;
path has a documented override). A warm cream multiplied onto a green albedo skews
yellow-green — a plausible source of the "fluorescent lime" this program keeps chasing. Left
unchanged deliberately: round 2's day frames passed the judge's bar, so lime is not a
demonstrated live defect, and changing ground colour in the same render that tests whether
grain shows would muddy both answers.

**`rock.uv_scale` is 0.16** next to a T1-GROUND comment saying it was corrected to 0.22 for
exactly the tiling reason it now exhibits. Either a stale comment or a regression; not
touched.

## Judged from frames, not retuned blind (item 4)

- groves with open ground between: **visible** in the wides; reads as a continuous wall at
  ground stands on a trail, which is `trail_bias` 0.85 working as designed.
- tree scale variance: **visible**. No unmistakable hero tree in these stands, expected at
  ~70 heroes over ~12 km (about 1 per 170 m).
- bushes/saplings as a canopy-to-ground transition: **faint**, and asset-limited — saplings
  are miniature CommonTree meshes, so they read as small trees, not a bushy band.
- reeds/scrub at the pond bank: **not judgeable** — no frame in the set shows an eye-level
  bank; the pond is walled in by canopy from every angle captured. Left unchanged rather than
  tuned blind.

## Frames

`ralph/reports/visual-parity/WORLD/round3/`: `stands/` (9, incl. `06-moon-stand-night`),
`locations/` (15), `survey/` (5), plus `_sheet_stands.png`, `_sheet_survey.png`.

## Red wash — my diagnosis was WRONG; here is what is actually established

I claimed the red wash was the same `WorldWeather` bug as VP1-G0, reaching late
frames of a long run. **Falsified.** I added the weather freeze to the stands tool
and re-rendered all nine frames:

| frame | before | after weather freeze |
|---|---|---|
| 03-rise-overlook-dawn | 145.8/49.5/42.3 (+96.3) | **145.8/49.5/42.3 (+96.3)** |
| 06-moon-stand-night | 117.1/38.8/55.9 (+78.3) | **117.1/38.8/55.9 (+78.3)** |

**Bit-identical.** Freezing weather changed nothing, and identical output across
two runs also proves the render is deterministic — so elapsed real time was never
the variable, and my "same preset early vs late" reading was a coincidence of
frame ordering.

### Ruled out, with evidence

1. **Weather roll / elapsed time** — the freeze produced bit-identical frames.
2. **The camera** — the bisect tool uses the *identical* camera for this stand
   (eye 172,−88 → target −60,60, horizon 0.24) and measured a clean **−12.8**,
   against the stands tool's **+96.3**.
3. **Light source in frame** (my earlier claim) — golden points **8.5°** off its
   sun and renders fine; dawn points **119.5°** away and is red.
4. **Config mutation across `apply_time()` calls** — `_merged()` deep-copies
   (`.duplicate(true)`), and `_layer_weather()` mutates only those copies.

### What that leaves

Same camera, same preset, same config — clean in a single-frame tool, red as
frame 8 of a nine-frame run. So it IS sequence state, but not weather and not
config pollution. The remaining candidate is **`Environment` state persisting on
the reused camera/environment across frames**, which is exactly the
`environment.adjustment_*` lead the coordinator listed first.

Concretely worth testing: `night` carries `adjustment_saturation`/
`adjustment_contrast`; if dawn does not override them, a dawn frame rendered
*after* a night frame inherits them, while a dawn frame rendered alone does not.
Note this needs to account for `01-spawn-outward-dawn` being clean (+3.7) despite
following `01-spawn-outward-night` — so a single inheritance is not enough, and
the hypothesis to test is **accumulation** (03-dawn follows two night frames;
the moon stand follows those plus a red dawn).

### The test that settles it, in one render

Render dawn at the 03 stand **four times in a row in one boot** with nothing else,
and print R−G each time. If it starts clean and drifts red, it is accumulation and
the fix is to reset the Environment (or explicitly set `adjustment_*` per preset)
between frames. If all four are red, the single-frame bisect result is the anomaly
and the bisect tool differs from the stands tool in some other way.

**Do not spend another round retuning `art.json` colours for this.** Three
explanations have now been falsified by measurement, and the one surviving class
of cause is tool/engine state, not art values.

---

# Round 4

Branch `claude/vp-world`, merged from the program branch at round-4 start.

## Two fix-list premises did not hold — checked before spending renders

**Item 1 ("the red frames predate the exposure change").** They do not.
`times.dawn.environment.exposure` 0.8 → 0.55 was committed at **06:08**; the stands
rendered at **06:30** and were re-rendered at **07:20**. Both post-change, both red,
and the two renders were **bit-identical**. Exposure was already excluded by
measurement, and it could not have been the cause in any case: exposure scales R, G
and B proportionally and cannot remove a hue cast.

**Item 6 ("distant scatter reads sparser than round 2").** Measured on the same view:

| | canopy pixels | far-band canopy |
|---|---|---|
| round 2 `03-rise-overlook` | 45.14% | 67.90% |
| round 3 `03-rise-overlook-day` | 44.10% | **72.12%** |

Distant scatter is not sparser; the far band gained 4.2 points. Lowering the ecology
`contrast` for trees/grove would have reduced real density to chase a defect that is
not a density change, partly undoing the VP3 clustering work. The likely real cause is
**value separation**: round 3 darkened and blued `aerial_fade_colour` to `#7f8c9e`,
bringing far canopy closer in value to the terrain behind it, so trees read as thin
pins without any of them disappearing. That is what the per-time aerial work below
addresses. **No vegetation change made.**

This is the third and fourth time a prescribed value has described a state the branch
was not in. Checking the tip first now routinely saves a render.

## The structural fix: aerial perspective now varies with time of day

Raised in every round since round 1; authorised this round.

`terrain_playground.json`'s `shader.aerial_fade_colour` was a **constant**, and
`playground_world.gd` read that block **once at scene setup**, while the sky's fog and
horizon vary per preset. So distance faded toward the same colour at every hour.

**The night inversion now has an exact mechanism:** night was inheriting day's
`#7f8c9e`, which sits *above* night's own fog `#4d6a9e` in value. Distance was being
faded toward something brighter than the sky it met — which is why a midnight vista
measured 25.7/76.6/113.8 against its own foreground at 13.4/22.3/28.2.

Plumbing: `playground_world.gd` caches the terrain material and exposes
`set_aerial_fade_colour()`; `world_look.gd` pushes from inside the **shared**
`_apply_environment()`, which both `apply_time()` and `_apply_blended()` already call,
so pinned capture frames and the live clock both get it from one call site.
`aerial_fade_colour` joins `_COLOUR_KEYS.environment` so `_blend_dict` lerps it rather
than snapping at the segment midpoint. Uses `set_shader_param` with a `has_method`
guard, matching the existing pattern at `playground_world.gd:837` — this is a Terrain3D
material, not a stock `ShaderMaterial`.

| preset | aerial | that preset's fog | relationship |
|---|---|---|---|
| day | `#7f8c9e` | `#b4c8cc` | cooler, a stop darker |
| golden | `#c9a98a` | `#e8b784` | same warm hue, darker, less saturated |
| dawn | `#c4a9a4` | `#e6bca4` | warm-neutral, darker |
| night | `#2f3f63` | `#4d6a9e` | same cool hue, a full stop darker |

Day uses the value actually on the branch after round 3, **not** the `#aebcc4` the fix
list named (the pre-round-3 constant). Every preset gets an explicit key including day,
because `_blend_dict` only lerps where BOTH segment endpoints define it — an unset day
would have held dawn's dark colour across the entire dawn→day transition. A preset
omitting the key is simply never pushed, so the terrain keeps its setup value.

## Night ground (item 3)

`times.night.environment.ambient_colour` `#34448a` → `#3d50a3`, a pure ×1.18 value
scale with hue and saturation unchanged. Ambient lifts the NEAR field; the new night
aerial darkens the FAR field; together they widen the near/far gap in the correct
direction, reversing the inversion. `ambient_energy` and `exposure` deliberately
untouched — this file's own VIS-WORLD precedent records that raising either
re-introduces the "character pasted on black paper" defect.

## Low sun (item 5) — mitigated, not fixed, and the stated mechanism is wrong

golden and dawn `sun_size` 0.012 → 0.009 and `sun_glow` → 0.12, matching base.

But the fix list's mechanism ("the halo term scales with the disc near the horizon") is
not what the shader does. In `sky_clouds.gdshader` both `disc` and `glow` are pure
functions of `sun_dot = dot(dir, sun_dir)` — **purely angular, with no elevation term
anywhere**. The oval is a projection artifact: `EYEDIR` in a sky pass follows the
camera's perspective, so a circle of constant angular radius renders as a circle only
on the optical axis and as an ellipse off it, more eccentric further from screen
centre — and none of the fixed survey framings aim at the sun. **No `sun_size` /
`sun_glow` / `sun_glow_falloff` value can fully correct this.** Shrinking the disc makes
the same stretch read as a small oval instead of a frame-filling mass. That is a
mitigation. A real fix would need the sky shader to compensate for off-axis projection.

## Still open

- **The red wash.** Five explanations now falsified by measurement (weather roll,
  exposure, camera, light-in-frame, config mutation). The repeat test — the same dawn
  frame rendered four times in one boot — was running when the budget ran out.
- Tests and smokes not run this round.

## Repeat test: ACCUMULATION FALSIFIED — and a possible regression from this round

The same dawn frame, re-applied four times in one boot, nothing else changed:

| pass | mean RGB | R−G |
|---|---|---|
| dawn #1 (right after night) | 145.7/49.5/42.5 | +96.1 |
| dawn #2 | 145.7/49.5/42.5 | +96.2 |
| dawn #3 | 145.7/49.6/42.5 | +96.2 |
| dawn #4 | 145.7/49.6/42.5 | +96.2 |

**Flat.** No drift across four applications, so the red is not accumulation. Combined
with the earlier bit-identical re-render, it is not sequence position either. Six
explanations are now falsified by measurement: weather roll, exposure, camera,
light-in-frame, config mutation, and accumulation.

The single-frame bisect's clean **−12.8** is now the sole outlier against everything
else. It should be treated as suspect — most likely that tool was not rendering the
framing it claimed — rather than as evidence about the defect.

### ⚠ POSSIBLE REGRESSION INTRODUCED THIS ROUND — verify before merging

The same run's sanity frames read:

| preset | this run | round 3, same stand |
|---|---|---|
| day | R−G −27.2 | −25.3 (consistent) |
| golden | R−G −19.6 | −16.3 (consistent) |
| **night** | **R−G +81.1** | **−50.9** |

Night has flipped from cool to red at this stand, and the only change between those
two renders is **this round's per-time `aerial_fade_colour` commit**. Day and golden
are unaffected, which fits: night is the preset whose aerial colour changed most
(inheriting day's `#7f8c9e` before, now its own `#2f3f63`).

Checked and NOT the cause: `world_look.gd::_as_colour` returns a proper `Color` for a
`#rrggbb` string, and `playground_world.set_aerial_fade_colour` is guarded and typed —
no obvious conversion or type fault.

Two readings, and I could not separate them before the budget ran out:
1. The per-time aerial genuinely regressed night, in which case the night value or the
   push needs fixing before this merges.
2. The test tool's "night (sanity)" framing differs from `03-rise-overlook-night`, in
   which case night was already red at that framing and the aerial change is innocent.

**The cheap discriminator:** re-render `03-rise-overlook` at night with the four
`times.*.environment.aerial_fade_colour` keys temporarily removed. If night returns to
≈ −50, this round caused it. That is one render and it should happen before the merge.

Note this also connects the two symptoms: if night at *some* framings is red, then
"dawn is red at 03 and clean at 01" and "night is red at the moon stand and clean at
03" may be one defect selecting on framing, not two.

### CORRECTION: the night flip is probably NOT this round's aerial change

Above I flagged night reading +81.1 as a possible regression from the per-time aerial
commit. Follow-up analysis identifies a simpler cause: **the two runs had different
frame histories.** Round 3's run cycled the full day/golden/night/dawn set at
`01-spawn-outward` BEFORE reaching `03-rise-overlook`; the repeat test went straight to
`03-rise-overlook`. Different number of prior preset transitions, same config.

So the aerial commit is not implicated, and the one-render discriminator I proposed
above is no longer the priority. Keeping the flag recorded rather than deleting it,
because the reasoning is what led here.

### Leading mechanism: Godot's sky radiance re-bake has not converged

`scenes/world/meadows_playground.tscn:33-34` sets the Environment's
`ambient_light_source` and `reflected_light_source` to **SKY**, and `world_look.gd`
pushes new sky `ShaderMaterial` uniforms on every `apply_time()` / `_apply_blended()`.
Godot spreads that radiance convolution over several real frames rather than applying it
synchronously with the parameter push. A camera with a lot of open sky in frame samples
a partially-converged radiance; a camera buried in foliage barely does.

This fits every observation, which is more than any config explanation managed:
- **camera-dependent** — elevated, sky-heavy `03-rise-overlook` and `06-moon-stand` go
  red; low, foliage-heavy `01-spawn-outward` stays clean through the identical
  night→dawn transition (+3.7).
- **sequence-dependent** — the number of prior transitions changes the result.
- **deterministic and bit-identical across runs** — same frame counts, same partial
  convergence.
- **flat across four repeats** — it has plateaued, not drifted.
- **immune to every config toggle** — six falsified explanations, all of them config.

Code was ruled out properly, not assumed: `apply_time()` rebuilds a fully-merged,
deep-duplicated dict each call; `adjustment_*` (`world_look.gd:669-672`) are set
UNCONDITIONALLY via `cfg.get(key, default)`, so the "assigned only when present, never
cleared" shape I hypothesised **does not exist** in this file; and `_apply_cloud_sky`'s
conditional sets always receive the full base-merged dict.

### The fix, and why it is now safe when it was not in round 1

The fix belongs in the **capture tooling**, not gameplay: wait materially longer after
`apply_time()` before the shutter — the current 20 physics + 4 process frames are not
enough for radiance to converge — or sample R−G twice and capture only once two
consecutive samples agree.

Round 1 tried extra settle frames and it was correctly rejected, because back then the
clock advanced during the wait and the frame drifted ~5 in-game hours off the pinned
time. **That objection no longer applies:** `set_clock_frozen()` now pins the clock, so
extra settle frames cost wall-clock and nothing else. The round-1 trap and the round-4
fix are compatible precisely because the freeze landed in between.

**The one render that proves it:** the same night→dawn sequence at `03-rise-overlook`,
varying ONLY the settle length after `apply_time("dawn")` — 24 vs 200 vs 1000 frames. If
R−G converges back toward the clean ≈ −12 as settle grows, this is confirmed and the
tooling fix is right.

## Round-4 tests — 1 failure, reported verbatim

`run_tests.gd --only=test_grass_field.gd,test_scatter_rules.gd`:

```
55 tests, 1116716 assertions, 1 failed

test_scatter_rules.gd :: test_ecology_core_clusters_without_changing_the_count
  — expected true, got false
    (core gating did not cluster: 100m-bin CV 2.483 gated vs 2.334 plain)
```

`smoke_art.gd`: **PASS** — "art: OK — models loaded, sized to their colliders, and the
meadow is dressed." Notably it also confirms the round-2 canopy fix still holds at the
asset level: `vegetation LOD  CommonTree_1 survives retint: [10, 4]`, and 384,640 props
across 35 batches.

On the failure: the test builds its own ecology block inline and asserts
`cv_b > cv_a * 1.15`. It measured a ratio of **1.064** — so core gating DOES cluster,
just not by the required 15% margin. It exercises the `corridor_fill` path.

**Probably not this lane's round-3 `ridge_bias` change** (0.75 → 0.4): `ridge_bias` feeds
`_clump_centre`, which is called only from the origin-square `clumps` path and never from
`_place_corridor_fill`. That was checked when the change was made. But it has NOT been
proven by re-running the test at the old value, so it cannot be fully excluded — that is
one cheap test run, not a render, and it should happen before this is attributed
elsewhere.

## Round-4 stands — the aerial plumbing is a silent no-op

9 stands in `round4/stands/` + `_sheet_stands.png`. Deltas against round 3, where only
the aerial colours changed:

| frame | Δ mean RGB | expected |
|---|---|---|
| `03-rise-overlook-night` | +0.2 / +0.6 / +0.8 | large darkening (`#7f8c9e` → `#2f3f63`) |
| `03-rise-overlook-golden` | ~0 | warming (→ `#c9a98a`) |
| `01-spawn-outward-night` | **+1.6 / +2.8 / +1.4** | ambient lift — **works** |

The ambient change (art.json → `world_look` → `Environment`) lands; the aerial change
(art.json → `world_look` → terrain `ShaderMaterial`) does not. Same file, same commit.
The uniform exists (`terrain_ground.gdshader:135`) and the setup path warns about unknown
keys, so the constant IS applied at scene build — this is specific to the runtime push,
whose setter returns silently when the cached material is null, and the terrain material
is built after `world_look` first applies.

Both red frames persist (+96.5, +78.2), unmoved by any colour edit.

# Round 5 — the sky-radiance hypothesis is falsified, and a unifying suspicion

| test at `03-rise-overlook` dawn | mean RGB | R−G |
|---|---|---|
| baseline (reproduces) | 146.3 / 49.9 / 42.6 | **+96.5** |
| `fog_aerial_perspective = 0.0` only | 146.3 / 49.9 / 42.6 | **+96.5** (bit-identical) |
| Sky `PROCESS_MODE_REALTIME` + `radiance_size` 128 | 146.3 / 49.9 / 42.6 | **+96.5** (bit-identical) |
| settle 24 / 200 frames | 146.3 / 49.9 / 42.6 | +96.5 |
| settle 1000 frames | 9.9 / 7.9 / 6.2 | +2.0 — **test artifact, see below** |

Neither arm cleared it. **Eight explanations are now falsified by measurement.**

**The hypothesis was structurally impossible, and this is the useful part.** It requires
`fog_sky_affect` at its 1.0 default so fog paints sky as well as terrain. This project
sets it to **0.0** — confirmed three ways: `art.json` line 121, `world_look.gd:668`
(`env.fog_sky_affect = float(cfg.get("fog_sky_affect", 0.0))`, commented "Sky affect at
zero, deliberately"), and a runtime print. With sky affect at zero, fog cannot tint the
sky, so a fog-sourced wash over BOTH sky and ground was never possible. Worth checking
before designing the next hypothesis.

The 1000-frame settle result must NOT be read as "it resolves itself": the frame went
near-black overall (same silhouette, everything dark), because the test parks the player
at y=−500 with physics live, so it free-falls for the whole run and something scales its
bounds off the player rather than the camera. A real long-settle test needs the player
pinned or frozen.

## The pattern nobody has named yet

Across this investigation, **unrelated config mutations keep producing bit-identical
frames**: two weather-freeze runs, two exposure states, `fog_aerial_perspective` 0.8 → 0,
a whole sky process-mode change — all identical to the tenth. Meanwhile the round-4
stands showed the per-time `aerial_fade_colour` moving a vista by +0.2/+0.6/+0.8 when a
full stop of darkening was applied.

That is the same signature twice: **changes that should alter the frame are not reaching
the renderer.** Two independent instances (my aerial push, and these mutation arms) point
at one class of cause — the mutation is applied to a different object than the one being
rendered. The scene has a `WorldEnvironment` (`meadows_playground.tscn:33-34`) and
`world_look.gd` also builds/owns Environment and Sky resources; a tool or a code path
that mutates one while the camera renders the other would produce exactly this.

**The test that would settle it, and it is not a render:** inside a running capture,
print the identity of the Environment actually in use by the rendering camera
(`get_viewport().find_world_3d().environment`) alongside the one `world_look` mutates,
and compare. If they differ, that single fact explains both the aerial no-op AND why
eight config explanations all "failed" — several may never have been tested at all,
only assumed applied.

Until that is checked, **no further conclusion should be drawn from a config toggle
producing no change in this scene** — a null result there is currently indistinguishable
from the change not being delivered.

# Round 5b — the red wash is ELAPSED-TIME driven, not preset or camera

## Identity check: everything is the same object

```
viewport.find_world_3d().environment : id=-9223371912535603377  meadows_playground.tscn::Env_1
capture Camera3D                     : environment override=null   attributes override=null
scene CameraRig/Camera3D             : environment override=null   attributes override=null
WorldEnvironment node                : same id
world_look.gd (../WorldEnvironment)  : same id
Sky / sky_material                   : same instances everywhere
```

**My "changes are not reaching the renderer" suspicion is FALSIFIED.** Delivery routing
is correct and neither camera carries an override. Settled for the cost of a print.

## The shutter-time diff is EMPTY — and that is the finding

Comparing `01-spawn-outward-dawn` (clean) against `03-rise-overlook-dawn` (red), same
preset, at shutter: `fog_enabled`, `fog_density`, `fog_light_color`,
`fog_aerial_perspective`, `fog_sky_affect`, all `adjustment_*`, `ambient_light_color`,
`ambient_light_energy`, `tonemap_mode`, `tonemap_exposure`, and the sky uniforms
`sun_glow` / `sun_colour` / `horizon_colour` / `haze_colour` / `sun_glow_falloff` are
**bit-identical**. The Environment and sky state are provably correct *on a washed frame*.

## What it actually tracks

- `03-rise-overlook-dawn` shot EARLY in a short run: **clean**, R−G ≈ +1.3.
- With a longer post-teleport settle, the **`day`** preset — normal values at shutter —
  rendered as a uniform maroon wash over the whole frame: sky, distant terrain AND near
  rocks. Day R161/G77/B63; night R120/G39/B49. Mean and median match, so it is a uniform
  cast, not a hot sun disc.

**So it is neither preset-specific nor camera-specific.** It tracks elapsed render time.
That vindicates the round-3 instinct (early frames clean, late frames red) which was
abandoned when freezing `WorldWeather` did not fix it — the pattern was right, the cause
was not weather.

It also explains why eight explanations all "failed": **none of them touched elapsed
time.** Config toggles produced bit-identical frames because the cause is not in the
config.

## Leading candidate — unbounded `TIME` in the sky shader

`shaders/sky_clouds.gdshader` uses raw, unbounded `TIME` in two places:

```glsl
218: vec2 plane2 = dir.xz * (t * 2.6) * high_scale * vec2(0.35, 1.0) + wind * 1.8 * TIME;
226: vec2 plane  = dir.xz * t * scale + wind * TIME;
```

This is the only term in the system that grows with elapsed render time and is immune to
every config change tested. Under llvmpipe a stands run accumulates tens of minutes of
`TIME`, where a single-frame tool accumulates seconds — matching "clean early, red late,
never reproducible in a short tool".

**Caveat, stated rather than glossed:** a sky-shader term cannot by itself tint NEAR
ROCKS, and the drift magnitude at these elapsed times looks too small to destroy float
precision on its own. So either the sky feeds everything through an ambient/radiance path
(worth testing, given `ambient_sky_contribution` is non-zero on several presets), or the
real cause is a different time-driven term — a post-process/glow reaction, or something
in the software renderer's own accumulation. **Not proven.**

## The test that settles it, and it is cheap

Render the SAME frame twice in one boot — once immediately, once after N idle frames with
nothing else changed — and print `TIME` at each shutter. If the second is red, bisect N.
Then clamp: replace `TIME` with `mod(TIME, P)` for a wind period `P` and re-render.

Anyone continuing this: **do not spend another round on colour values.** Nine explanations
are now falsified and the config is proven correct at shutter on a washed frame.

# Round 5c — elapsed time is NOT the cause; the wrap is not the fix

Matched-TIME A/B in ONE boot at `03-rise-overlook`, preset `day`. `time_wrap` is a
uniform, so both arms were shot at the same elapsed time with every other variable
identical — `1.0e9` (wrap effectively off, old raw-`TIME` behaviour) vs `2500.0` (shipped).

| checkpoint | TIME (s) | R−G wrap OFF | R−G wrap ON |
|---|---|---|---|
| N=0 | ~165 | −6.76 | −8.13 |
| N=200 | ~1226 | −8.26 | −8.25 |
| N=300 | ~1774 | −8.72 | −8.66 |
| N=400 | ~2325 | −8.95 | −8.97 |
| N=500 | ~2883 | **−9.02** | **−8.85** |

**NEITHER ARM EVER WASHED.** Ten frames, out to TIME 2890 s — covering the whole
2000–2900 s window in which every washed run sat.

## What this settles

1. **Elapsed time alone does not cause the red wash.** Falsified. My round-5b reading
   that it "tracks elapsed render time" was too strong: elapsed time was a *correlate*
   of the runs that washed, not the cause.
2. **The `TIME` wrap is NOT the fix.** It stays in as a genuine latent-bug fix (unbounded
   `TIME` into `fract()`/`floor()` is a real hazard, and it costs nothing), but it must not
   be described as fixing the wash. At N=500 the wrap is ACTIVE and the two arms differ by
   0.17 R−G — i.e. bounded and raw `TIME` are visually indistinguishable at these
   magnitudes, so precision loss is not degrading anything here.
3. **A useful side result:** with the wrap active past its period, no seam or jump appeared
   in the measurements. The 2500 s period is safe to ship.
4. **The brightening is a completed convergence, not a ramp to the wash.** Mean rose 0.33
   → ~0.49 by TIME ~1200 s and then *plateaued* (0.4956 → 0.4912 → 0.4896 → 0.4884). It
   settles; it does not run away into a wash.

## Where the cause must be

The discriminator is now sharp. Runs that washed all involved **stand and preset
TRANSITIONS**: round 5b washed at shot 3 of 4 (teleport + `apply_time` changes), and the
round-3 stands run washed at shot 8 of 9. This test did ten shots with **no transitions**
— same stand, same preset, only idling — and never washed at any elapsed time.

So the trigger is in what happens at a transition: teleporting the camera/player between
stands, and/or `apply_time()` switching presets — not in time passing.

**Next test, and it is cheap:** at ONE stand, shoot `day`, then call `apply_time` to cycle
through the other presets and back to `day`, and shoot `day` again — no teleport, no long
idle. If the second `day` is washed, preset switching is the trigger. If it is clean, add a
teleport and repeat. That isolates the two candidates in at most two short runs, and
neither needs to run for an hour.

Evidence: `round5c-wrap-ab/` (10 frames), `round5c-onset/` (2 frames).

# Round 5d — transitions are NOT the trigger either; a camera/player-separation lead

One boot at `03-rise-overlook`, preset `day` throughout, three shots differing only in what
happened between them:

| shot | preceded by | mean RGB | R−G |
|---|---|---|---|
| A | fresh arrival + `apply_time("day")` | 0.3726/0.3992/0.3107 | −6.78 |
| B | preset cycle golden→night→dawn→day, SAME camera, NO teleport | 0.4904/0.5252/0.4088 | −8.89 |
| C | teleport 03→01→03, NO preset change | 0.4908/0.5254/0.4088 | −8.80 |

**All three clean.** So neither `apply_time()` preset switching NOR teleporting between
stands triggers the wash. Both remaining candidates from round 5c are eliminated —
thirteen explanations now falsified by measurement.

Shot A also reproduces the previous run's N=0 almost exactly (−6.78 vs −6.76, mean 0.3726
vs 0.3720), so the harness is stable across boots and these nulls are trustworthy.

## The one structural difference that remains — and there is direct evidence for it

This tool places the actor at each stand and freezes it on the ground. The tools whose runs
DID wash do not: `render_world_r3.gd:389` reads

```gdscript
if not view.has("actor"):
    return
```

and the `03-rise-overlook` stand has **no `actor` key**. So in every washed run the player
was left at spawn while the camera teleported ~200 m away. In every clean run the player sat
at the camera.

The supporting evidence is direct, and it was recorded earlier as a discarded artifact: a
settle test that parked the player at y=−500 with physics live produced a **near-black whole
frame** — same terrain silhouette, everything dark. That is proof that player position alone
can globally change what renders, independent of camera, preset and config. It was set aside
as "a harness artifact" at the time; in light of these nulls it looks like the same
phenomenon at a different magnitude.

So the working hypothesis is **camera/player separation**, not time, not preset, not
teleporting per se.

## The test, and it is short

Re-run the exact sequence that washed (`01-dawn` → `03-dawn` → `03-day` → `03-night` via
`render_world_r3.gd`) TWICE:
1. unchanged — expect the wash at shot 3, reproducing the known result;
2. with an `actor` key added to the `03-rise-overlook` stand so the player is placed at the
   camera — if the wash disappears, camera/player separation is the mechanism.

That is one variable, a known-positive control, and no long idles. If it reproduces, the
in-game consequence matters more than the capture bug: it would mean the look degrades
whenever the rendering viewpoint is far from the player, which is a real gameplay condition
(cutscenes, distant cameras), not just a capture artifact.

Evidence: `round5d-transition/` (3 frames).
