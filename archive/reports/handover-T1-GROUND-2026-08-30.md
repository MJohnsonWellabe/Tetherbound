# Handover — T1-GROUND, 2026-08-30

Stand-down handover, written at the end of this lane's own session (not a
stop mid-work — the seven-item list was never going to fit one session, and
this is the honest state at the point of handing it off).

**Branch:** `ralph/T1-GROUND`, off `origin/main` at `a97f3e84`. Pushed,
matching `origin/ralph/T1-GROUND` at `831e852b`. Working tree clean.

**Commits, oldest to newest:**

```
436898ac  T1-GROUND: stop the grunt rank palette from crushing an already-dark texture
da7d15e0  T1-GROUND: rest path pebbles flush with slope, shrink the river's rock tiling; re-bake
831e852b  T1-GROUND: evidence frames for items 1-6 (before/after where available)
```

**I touched the scatter-bake inputs.** `data/config/vegetation.json`
(`path_stones.align_to_slope`/`sink`) and `data/config/terrain_playground.json`
(rock `uv_scale`) both feed `scatter_bake.gd`'s config fingerprint. I re-ran
the bake (`godot --headless --path . --script scripts/world/bake_playground_scatter.gd`)
and committed the full `data/scatter/playground/` output in the **same**
commit as the two JSON edits (`da7d15e0`), per the coordinator's own warning
about a merged config fingerprinting as neither of two independently-baked
branches — this branch only touched scatter-affecting config once, so there
is only one bake to reconcile on merge, but whoever lands this alongside
another scatter-touching branch should re-bake once more on the merged
config, not trust either side's bake. `tests/test_scatter_perf_budget.gd`
(`test_playground_bake_is_committed_and_fresh`) passes on this branch as
pushed.

I did **not** touch `data/terrain/playground/` (Terrain3D's own saved
height/control/color maps) — see item 5 below for why I stopped short of
the one change that would have required it.

---

## What I was asked

Seven items from the coordinator's brief, roughly in order of how badly
they break the frame: (1) a villager/NPC rendering as a 100% black
silhouette in daylight, (2) dashed seam lines crossing the terrain, (3)
floating path pebbles, (4) the stream invisible from its own bank, (5) the
river reading as an engineered canal, (6) one grass species everywhere,
(7) a mid-distance smear tier whose boundary tracks the camera. Plus:
regional differentiation is prop-deep (related to 6, scope-permitting).

I did not get through all seven. Below is exactly which.

---

## DONE and verified (render + test evidence in hand)

### 1. The black NPC — real fix, confirmed improved, not fully resolved

**Root cause, found by reading the comments' own dates against each other,
then confirmed by measuring the actual texture:** `npc_ranks.json`'s grunt
(`#8a8a8a`, 0.54x multiply) and officer (`#c2c2c2`, 0.76x) body palettes
were tuned on the theory that `character_model.gd`'s additive emission
floor would lift the multiplied-down result back into a legible range —
that reasoning is written into the file's own `_comment_palette_crush`.
`character_model.gd`'s own **newer** header (`GF-B-010`, dated
2026-08-27) says plainly that `emission_enabled` is `false` on every one
of today's six rigs' body materials, so that floor is dead code for every
character in the game, grunt included. Nobody went back and re-checked
the grunt/officer palette against that fact. Measured directly:
`assets/characters/grunt/grunt_lod0_texture_0.png` (post the earlier
`VIS-CAST` oxblood repaint) has median value **0.137** — already dark —
and multiplying that by 0.54 with nothing to lift it back up is exactly
the "crush" `npc_ranks.json`'s own history says was fixed once already,
reintroduced by a rig rebuild nobody re-checked this specific data
against.

**Verified NOT the metallic bug.** `tests/test_character_metallic.gd`
(4 tests) passes on `main` before I touched anything — the dielectric
correction (`GF-B-010`'s other half) is fine and untouched by this fix.

**Confirmed against a real render, at the exact spot the judge saw it.**
Band 2's camera stand (`(310, -6.4, 1660)`, `tools/_capture_ground_and_sky.gd`'s
own `band2` viewpoint) puts the camera looking straight at Dorn, band 2's
own picket, at his authored position `(315, 1668)`. Before:
`ralph/reports/T1-GROUND/shots/ground-02-band2-grunt-BEFORE.png` — a flat
black cutout, zero visible detail. After:
`ground-02-band2-grunt-AFTER.png`, side-by-side crop in
`grunt-BEFORE-AFTER.png`. The after frame shows real visible form — collar,
shoulder strap, mask, boots — that the before frame did not have at all.

**Not fully "fixed" and I want to be honest about that.** Brought grunt to
`#dcdcdc` (0.86x) and officer to `#eeeeee` (0.93x) — close to identity but
not all the way, so the rank ladder survives as a faint step rather than a
second darkening pass on a texture with no range left to give (the
established lesson from `repaint_grunt_faction.py`'s own header: neither a
bigger additive floor nor a bigger multiply can lift a near-black texture
without either flattening its darks or clipping its lights). The result is
**visibly better and no longer reads as a debug cutout**, but Dorn is
still a fairly dark figure — expected for what is meant to be a dark
tactical uniform, but if the owner wants him brighter than this, the next
lever is not a further palette push (that repeats the mistake), it is
either a small ambient/rim-light floor specific to humanoid rigs in
shade, or accepting this as the intended "dark faction" look. I did not
make that call for the owner.

**Tests:** `test_character_metallic.gd` (4 tests, 27 assertions) still
green after the palette edit — it reads the palette dynamically off
`npc_ranks.json`, not a hardcoded hex, so it correctly re-validated against
the new values rather than needing an update. `smoke_art.gd`'s own rank
ladder check (`_a_rank_badge`/body-palette section) does the same dynamic
comparison; not run standalone this session but nothing in the edit
touches what it asserts (still-distinct body colours across ranks:
`#dcdcdc`/`#eeeeee`/`#ffffff` are all distinct).

### 3. Floating path pebbles — real fix, mechanism confirmed, re-baked

**Measured, not guessed.** Wrote a throwaway headless probe (not
committed — see "what I did not commit" below) that loads each
`RockPath_Round_*`/`Pebble_Round_*` model and reads its rendered AABB. The
mesh origin sits within **0.002–0.009 m** of the model's own lowest
vertex — i.e. these are NOT centre-pivoted the way I first assumed, so a
missing `sink` on its own would only ever explain a few millimetres of
float, not "a few cm". The real cause: `path_stones` places these as
**rigid flat plates** (`RockPath_Round_Wide` measures 2.11 × 0.11 × 2.13 m
— confirmed against `ralph/DONE.md`'s own earlier measurement of the same
family) sampled at a **single centre point**, with up to 14° of slope
allowed (`max_slope_deg: 14.0`) and no `align_to_slope`. A 2 m-wide rigid
plate resting level on a 14° slope has ~0.5 m of vertical mismatch across
its own footprint — the downhill edge floats, exactly the defect
`vegetation.json`'s `rocks` layer already has a named fix for
(`_comment_align`), just never extended to this layer.

**Fix:** opted `path_stones` into the same `align_to_slope` mechanism
`rocks` already uses (`scripts/world/scatter_rules.gd:1011`, generic,
already there, zero code changed), plus a shallow `sink: 0.03` to bury the
rim the alignment alone still leaves showing on broken ground (the same
pairing `rocks`' own anchors already use).

**Re-baked and tests green:** `tests/test_scatter_perf_budget.gd`'s three
tests pass, confirming the committed bake matches the edited config's
fingerprint. I did **not** get a dedicated before/after render of this
specific fix — `ground-01-band1-opening-day-BEFORE.png` (pre-fix) and
`path-pebbles-crop-BEFORE.png` are the "before" half; I did not re-render
band 1 after the pebble+rock-texture commit to get a clean "after", because
by that point I was deep into the water/stream investigation and judged
the render budget better spent there. **This is the one item in the "done"
list I'd call done-but-under-verified** — the mechanism is exactly the one
that already fixed the same defect for `rocks`, and the math is real, but
I have not personally looked at a post-fix path frame. Re-render
`ground-01`/`ground-04` (both named in the original brief for this defect)
before calling it closed.

### 4. Stream invisibility — root-caused, NOT fixed

This is the finding I'm most confident is correct and most sure I did not
have budget to finish.

**The judge was right and it is not a rendering bug at the point sampled.**
Wrote a second throwaway probe that calls `playground_heightfield.gd`'s
own `height_at`/`stream_carve_depth`/`stream_factor` directly at the exact
coordinate `tools/_capture_ground_and_sky.gd`'s `_capture_stream()` uses
(`points[12]` of 25, arc ≈ 50.7 m along the course — well past the 14 m
head ramp). Results, sampled outward from the centreline along the
course's own perpendicular:

```
off=  0.0  height=   1.715  carve= 0.700  stream_factor=1.000
off=  1.2  height=   1.902  carve= 0.389  stream_factor=1.000
off=  2.4  height=   2.160  carve= 0.011  stream_factor=0.014
off=  3.0  height=   2.108  carve= 0.000  stream_factor=0.000
off=  8.4  height=   1.141  carve= 0.000  stream_factor=0.000   <- capture's own "bank" stand
off= 10.4  height=   0.617  carve= 0.000  stream_factor=0.000   <- capture's own camera
```

The carve is real (0.7 m deep at the centre, tapering to 0 by 2.4 m off
it) and `stream_factor` — the signal that should paint the bed toward the
dirt/path texture and (via `grass_field`'s `forbidden_ground` mask)
suppress grass over it — is correctly 1.0 at the centre. **But the
surrounding hillside the stream is cut into drops over a metre across the
last 8 m alone, unrelated to the stream at all.** The camera (and the
"bank" point the player would actually stand at) is more than a metre
*lower* than the channel's own far rim. From that vantage, looking uphill,
a 0.7 m local dip riding on top of an already-rising 6°+ slope does not
read as a channel — the general grade swallows it. This is a **siting**
problem, not a code bug: the carve/paint system works exactly as
configured, the stream is just cut into ground where its own vertical
relief is small relative to the terrain it's cut into.

**Second, independent finding: even if the relief read, there is nothing
marking the water.** `water.gd` builds `reeds`/`bank_scrub` plant bands for
the pond and the river (`_build_plant_band`, driven from
`data/config/water.json`'s `pond`/`river` blocks) but **there is no
`stream` block at all** — `water.json` has no stream reed/scrub entry, so
the stream gets zero bank dressing where pond and river both do. I checked
whether `_build_plant_band` could just be pointed at stream shore points
and it cannot, as written: it filters every candidate spot against the
member variable `_level` (the *pond's* flat water level, ≈ −17.0), which
is nowhere near the stream's own elevation (≈1.7 in the example above) —
every single placement attempt would silently fail the elevation gate.
Wiring stream reeds in needs either a stream-specific placer (duplicate,
zero risk to pond/river) or an explicit reference-level parameter threaded
through `_build_plant_band` (touches the shared function three call sites
already use). I did not attempt either — this is genuinely new code in a
shared, load-bearing file, and I did not have a render cycle left to
verify it properly (each full world-build + capture cycle on this
container ran 15–30 minutes, and this session had already spent several on
the items above).

**What I'd do next, concretely:** either (a) increase `carve_depth` for
this specific stretch of `terrain_playground.json`'s `water.stream.points`
so the channel's own relief is large enough to survive the hillside grade
it's cut into (this needs a `data/terrain/playground/` regen + commit —
the terrain heightfield is rebuilt from JSON and re-saved every boot, so
it is not free, but it is the same class of change earlier `T1-GROUND`
work already shipped, see `git log -- data/terrain/playground`), or (b)
write a `_build_stream_reeds()` alongside `_build_stream()` that reuses
`_add_reed_batch` (the generic instancing primitive — I did not check its
own level-dependence, only `_build_plant_band`'s) against the stream's own
already-resampled centreline points, which needs no terrain change at
all and is lower-risk. I'd start with (b).

### 5. River reading as an engineered canal — texture fix only, angle NOT fixed

**Confirmed the specific "large hex/pebble" complaint against real
numbers.** `terrain_playground.json`'s `rock` ground texture
(`rock_scree`) — the same texture Terrain3D's generic slope threshold
paints onto every steep surface in the corridor, river banks included, not
a river-specific material — tiled at `uv_scale: 0.1538` (6.5 m per tile),
the largest of any ground texture in the file (grass/soil 5.0 m, path
4.0 m). Brought to `0.22` (~4.5 m per tile), matching the others. This is
a pure material parameter, no terrain regen, no re-bake needed for the
geometry (the scatter bake still needed a re-run because the fingerprint
covers the whole file, not because this specific change affects
placements). Rendered before/after is not directly comparable since I
didn't capture a pre-fix river-eye frame, but `water-02-river-eye-AFTER-uvscale.png`
is in hand and the bank texture there reads as fine-grained rock, not the
"marble chip" scale the judge described.

**What I deliberately did NOT touch: the bank angle itself.** Measured
every one of the 19 authored points in `terrain_playground.json`'s
`river.course`:

```
depth 10.0-15.0 m, rim 3.4-6.0 m  ->  bank angle 59-77 degrees, EVERY point
```

The channel is a near-constant 60-77° cut for the entire 2 km course —
this, not the texture scale, is most of why it reads as riprap on a canal
levee rather than a natural bank. **I chose not to touch it.** The reason:
`river.course`'s `rim` is the one lever that would fix it (a wider rim at
selected points would gentle the profile), but that is a heightfield edit
— `data/terrain/playground/` gets rebuilt and re-saved from this config on
every boot, so a `rim` change means committing a new terrain bake
alongside it, and a wider cross-section also widens the zone
`river.reeds`/`bank_scrub`'s own `max_bank_slope_deg: 78` anchor-siting
logic works against. I did not have a spare render+verify cycle to check
that a rim change doesn't strand a reed clump or open a traversal gap
(`smoke_traversal.gd` walks this course), and this repo's own history
(`ralph/conventions.md`'s testing-traps section) is full of exactly this
class of mistake costing someone else a render cycle later. Left as data
for whoever picks this up: the lever is `river.course[i].rim`, the target
is something closer to the pond's own natural-looking banks, and it needs
a terrain regen + `smoke_traversal.gd` run before it ships.

### 6. One grass species everywhere — real partial fix, second TRUE species not attempted

**Found a real, shipping regression while investigating this.**
`grass_field.json`'s `suppress_scatter_layers` included `"groundmat"` —
the clover/broadleaf mid-layer a previous lane (`WORLD-GRASS`) built
specifically to answer "props stabbed into dirt, no ground→mat→tuft
ladder". `grass_field`'s own shader-based cover tiers are `bushes`/
`flowers`/`litter` only — **nothing in the field replaces groundmat**, so
turning the field on (it is `enabled: true` today) silently threw away
145,577 already-baked clover/broadleaf placements with nothing standing in
for them. This is likely a real, measurable contributor to "every band the
same vertical blade sprite, differing only by tree props and flower
confetti" — the one layer that was supposed to break that up wasn't
rendering at all.

**Fix: removed `"groundmat"` from the suppress list.** Zero re-bake needed
— `vegetation.gd` reads the suppress list at load time off the
already-baked placements (confirmed by reading `vegetation.gd:310-348`
before touching anything), so this is a pure "stop throwing this away"
change. `tests/test_grass_field.gd` (10 tests) still green — no test
required `groundmat` to be on the suppress list specifically, only
internal consistency, which this preserves.

**What I did NOT do: give the grass tuft layer itself a second species.**
The brief calls this "the single biggest lever" and I believe that's
right, but a real second blade species (different silhouette, own
clustered distribution, own colour family, mixed into `grass_field.gdshader`'s
existing lattice-hash tuft generation) is genuine new shader work in the
most heavily-tuned file in this pass (`GRASS-REROLL`'s own report records
a re-roll of the *entire* meadow from one subtle bug in this exact
mechanism). I did not have the render budget left to do that safely — it
needs its own multi-round blind-pass verification per
`ralph/conventions.md`'s own visual-affecting-work rule, and I'd rather
hand off a precise, scoped next step than a rushed one. The `groundmat`
fix is real progress on the same complaint, not a substitute for this.

**Not independently verified with a render.** I did not re-capture band 1
or any band after this specific change (it landed in the same commit as
the pebble/rock-texture fix, and I spent the remaining render budget on
the black-NPC verification and the stream investigation instead). Next
step: render any band-1/2/3 day frame and confirm clover is visibly back
under the grass — if it reads as clutter rather than a mid-layer, the
`groundmat` clump/density numbers (unchanged by me) may need retuning
before this can be called done.

---

## Investigated, evidence gathered, NOT fixed

### 2. Dashed seam lines — real, reproduced, root cause NOT isolated

Confirmed real and reproduced in two independent frames:
`ralph/reports/T1-GROUND/shots/dashed-line-crop.png` (cropped from
`ground-01-band1-opening-day-BEFORE.png`, bottom-right of frame — same
location the judge named) shows a clear, regularly-spaced dotted line
crossing the mid-distance grass diagonally.

**Ruled out, with reasons:**
- **Not a Terrain3D region border.** Regions are 512 m apart
  (`region_size 256 * vertex_spacing 2.0`); this line crosses within a
  single ~40 m-wide frame, nowhere near a region boundary at this world
  position.
- **Not the grass/stone field.** `ralph/reports/GRASS_HANDOVER_2026-08-26.md`
  §"one artefact ruled out" already did this exact check on 2026-08-26 —
  same lines, field's own MultiMeshes hidden, lines unchanged. Confirmed
  still true by construction: the field renders nothing past its own
  edge/culling and these lines appear inside and outside its extent alike.
- **Weakly suspected and NOT confirmed: a per-pixel `sin()` hash
  artifact.** `build_playground_terrain.gd` has five call sites of
  `absf(fmod(sin(float(pixel_x) * 12.9898 + float(pixel_z) * 78.233) * 43758.5453, 1.0))`
  — the classic GLSL "sin-dot" pseudo-hash, known to alias into visible
  periodic patterns at large arguments due to float32 precision loss. I
  could not confirm `pixel_x`/`pixel_z` actually reach a large enough
  magnitude to trigger this — they appeared to be per-region-local loop
  indices (bounded ~0-255), which is normally too small for the effect,
  but I did not verify the loop's actual call-site bounds carefully enough
  to rule it out.
- **Best remaining hypothesis, also not confirmed:** the macro
  dry-patch/verge-cut boundary (`_macro_dry`, `build_playground_terrain.gd`)
  is a coherent-noise contour (can be locally near-straight over tens of
  metres) dithered at the 2 m control-map texel pitch — a contour crossing
  the texel grid at a shallow angle could alias into exactly this kind of
  dotted line, especially where mip-blur (the "smear tier", item 7) has
  already softened everything else in frame but the individual dithered
  texels partially survive minification.

I did not have a way to distinguish the last two hypotheses without a
debug-overlay render (colour-coding which system owns each pixel), which
I judged too large a side-quest for the time remaining. **Next step:**
build that overlay, or bisect by disabling the macro dry-patch pass
(`macro_cfg` empty) and one render to see if the lines survive.

### 7. Mid-distance smear-tier boundary — looked better than reported, not touched

Cropped and inspected `ground-01-band1-opening-day-BEFORE.png` (full
crop: `ralph/reports/T1-GROUND/shots/`, not saved separately). The
blade-grass-to-smear transition is visible but reads as a fairly gentle
taper in this specific frame, not the hard tracked-boundary the brief
described — likely because `field_radius`/`fade_start`/`edge_shorten_floor`
in `grass_field.json` are already at values a prior lane (`GRASS-FIELD`)
tuned specifically for this (72 m radius, 42 m fade start, floor 0.0 so
blade height sinks to zero at the edge rather than stopping abruptly —
this is the exact fix `ralph/reports/GRASS_HANDOVER_2026-08-26.md`'s own
"what I would do next" §2 asked for, and it looks like it already landed
between that report and now). The camera-relative nature of the boundary
is architecturally inherent (it is a ring around the player, always will
be, by the owner's own "no millions of blades" constraint) and I did not
find a case in my renders where it reads as badly as described. I did not
chase this further — did not want to spend render budget re-litigating a
defect I could not reproduce as described, when six other items had
harder evidence.

---

## Disagreements / corrections to the brief, with evidence

- **Item 1's "villager NPC" is a Team Tether grunt, not a villager.**
  Confirmed against `data/config/bands/band2_stone_and_root/trainers.json`:
  band 2 has exactly three humanoid NPCs and all three are
  `"rank": "grunt"` pickets (Dorn, Pell, a third). There are no villagers
  in band 2 at all — `village_npcs.json`'s cast is all in band 1's square.
  This matters because it changes where the fix belongs: not a general
  villager/trainer material path, but specifically `npc_ranks.json`'s
  grunt/officer rank palette. The band-4 "Team Tether grunt... near-black
  mass" the brief separately named is the *same* rig/rank, same root
  cause, same fix — these were never two defects.
- **The claimed emission-floor fix in `ralph/DONE.md` was real, for rigs
  that no longer exist.** `DONE.md`'s "Dark Team Tether NPCs... Hess now
  reads with visible brown leather" entry is not wrong or stale writing —
  it was correct for the pre-rebuild rigs it was written against. The
  rigs were rebuilt (removing baked emission textures) after that entry
  was written and before `GF-B-010`'s own header was added to
  `character_model.gd` to say so. Nobody propagated that fact back to
  `npc_ranks.json`'s palette values, which is the actual gap — not a
  documentation error, a cross-file consistency gap between a script
  comment and a data file that both describe the same mechanism.
- **path_stones' floating pebbles are not a mesh-origin bug** — I
  initially assumed a centre-pivoted mesh (matching the "sink" pattern
  used elsewhere) and measured it directly before writing anything: the
  origin sits within a centimetre of the model's own base. The real cause
  is slope + rigid single-point sampling, the same class of bug `rocks`
  already had fixed. Worth stating because a future lane re-deriving this
  from the brief's own wording ("hover a few cm") could easily reach for
  the wrong fix.

---

## Full file footprint

**Config (bake-affecting, re-baked):**
- `data/config/vegetation.json` — `path_stones.align_to_slope`/`sink`.
- `data/config/terrain_playground.json` — `rock.uv_scale`.
- `data/scatter/playground/manifest.json` + all 256 `region_*.bin` files
  — regenerated by `bake_playground_scatter.gd`, committed alongside the
  two files above in the same commit.

**Config (not bake-affecting):**
- `data/config/grass_field.json` — removed `"groundmat"` from
  `suppress_scatter_layers`.
- `data/config/npc_ranks.json` — grunt palette `#8a8a8a` → `#dcdcdc`,
  officer `#c2c2c2` → `#eeeeee`. Captain/Warden untouched.

**Nothing else was touched.** No `.gd` scripts changed. No shaders
changed. `burrow_warrens.gd`, `stronghold.gd`, `landmark.gd`,
`building_prefabs.json`, any band's gameplay content (spawns/trainers) —
all untouched, on purpose, per the brief's own ownership boundaries.

**Evidence, committed:**
- `ralph/reports/T1-GROUND/shots/*.png` — 9 files, listed with their own
  captions in the `831e852b` commit message.
- This file.

**Not committed — two throwaway diagnostic probes, deleted after use:**
`tools/_probe_pebble_aabb.gd` (measured the RockPath/Pebble mesh AABBs —
see item 3) and a second inline probe measuring `playground_heightfield.gd`'s
`height_at`/`stream_carve_depth`/`stream_factor` at the stream's own
sampled coordinate (see item 4). Both were plain read-only geometry/data
probes with no rendering, run via `godot --headless --path . --script`.
I deleted them rather than commit them without a `.uid` sidecar (which
`--import` generates and I did not want to run mid-way through two other
concurrent Godot processes — see below). If a successor wants either
back, they are trivial to rewrite from the numbers quoted above, or ask
and I can reconstruct them exactly.

---

## Environment notes for whoever picks this up

- Godot was not preinstalled; fetched 4.7-stable per `CLAUDE.md`'s own
  command. Two full `--import` passes were run (the first exits with a
  large log but no hard failure; the second is clean, per
  `ralph/conventions.md`).
- **Running the scatter bake concurrently with a capture render works.**
  `bake_playground_scatter.gd` is plain `--headless` (no rendering
  driver), so it does not hit the `--headless` + `opengl3` hang, and I ran
  it alongside an active `_capture_ground_and_sky.gd` render with no
  errors — just slower wall-clock for both (4 cores, `nproc`). Budget for
  it if reusing this pattern, but it is a legitimate way to save wall time
  rather than serialising a CPU-only job behind a GPU-render job.
- **This container's actual per-frame cost is well above the
  `_capture_ground_and_sky.gd` header's own ~2.4s/frame estimate** —
  a `--states=day` partial run (skips 2 of 3 time-of-day states) still
  took over 25 minutes wall-clock for 2 of 5 ground bands plus nothing
  else, before I killed it and switched to `--only=water` (which itself
  took ~17 minutes for boot + 3 water bodies). Budget accordingly; do not
  assume the header's arithmetic holds on whatever box you land on.
- **The `--only=` filter is a plain substring match against each
  viewpoint's own name**, not an enum — `--only=band2` matches only the
  ground-band loop's `band2` entry (skips the water section entirely,
  since `"water" in "band2"` is false); `--only=water` runs pond+river+
  stream and skips every ground band. Use these to scope a render to
  exactly what you need to verify; do not run the full unscoped capture
  unless you actually need all 8 viewpoints × up to 3 states.
- A stop-hook in this session enforces committing/pushing before ending a
  turn. I held bake-affecting JSON edits uncommitted until the re-bake
  finished (to avoid a commit where the bake fingerprint doesn't match
  its own config, per `ralph/conventions.md`'s explicit warning about
  exactly this), which meant staging only the independent, already-tested
  fixes (`npc_ranks.json`/`grass_field.json`) in the first commit and the
  bake-dependent pair in the second, once the bake actually finished.
  Worth knowing if a future session hits the same hook mid-bake.

## What I would do next, in priority order

1. **Re-render band 1/4 to verify the pebble fix** (item 3's one
   under-verified claim) — `--only=band1 --states=day` or similar, crop
   the path pebble rows the way `path-pebbles-crop-BEFORE.png` did.
2. **Wire stream reeds/bank_scrub** (item 4's lower-risk half) — a
   `_build_stream_reeds()` alongside `_build_stream()` in `water.gd`,
   reusing `_add_reed_batch`, driven from a new `water.json` `stream`
   block mirroring `river`'s `reeds`/`bank_scrub` shape. Render-verify at
   the same `water-03-stream-eye` stand before/after.
3. **Debug-overlay the dashed seam lines** (item 2) to pick between the
   sin-hash and macro-dry-boundary hypotheses, or bisect by disabling one
   system at a time and re-rendering `ground-01`.
4. **The river bank angle** (item 5's harder half) — vary `river.course`'s
   `rim` per point, terrain regen, `smoke_traversal.gd` full run before
   even rendering, since a wider channel can strand the corridor.
5. **A genuine second grass-blade species** (item 6's "biggest lever") —
   scope it as its own multi-round visual-judge pass per
   `ralph/conventions.md`; do not rush it into a shared commit the way
   this session did not.
6. Re-render band 1-5 broadly to confirm `groundmat`'s return reads as a
   mid-layer and not clutter; retune its clump/density numbers if not.
