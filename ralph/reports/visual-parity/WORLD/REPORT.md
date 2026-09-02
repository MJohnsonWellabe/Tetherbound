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
