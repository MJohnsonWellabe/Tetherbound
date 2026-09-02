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
