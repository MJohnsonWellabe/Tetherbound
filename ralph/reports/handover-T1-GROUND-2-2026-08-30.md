# Handover — T1-GROUND-2, 2026-08-30

Stand-down handover, end of this lane's session. Branch `ralph/T1-GROUND-2`,
**branched from** `origin/ralph/T1-GROUND` at `0aa3db2b` (not merged — branching
was the cleaner option since T1-GROUND-2 did not exist yet and T1-GROUND had
no divergent history to reconcile). `origin/ralph/T1-GROUND` itself sits off
`origin/main` at `a97f3e84`. Pushed incrementally, one push per unit of work.
Working tree clean at handover time.

**I did not merge `origin/ralph/T1-SKY`.** The brief named it for reading
context only (its own handover, for diagnosis). T1-SKY's fixes (day/night
capture-parking, golden-hour weather leak, sun disc, art.json day/golden/night
tuning) are **not** present on this branch. This matters for one thing: my
Job 1 renders used `_capture_ground_and_sky.gd`'s `night`/`day` **snap
presets**, not the driven day/night transition tool T1-SKY was fixing, so
none of my evidence depends on T1-SKY's unlanded work. The integration lane
should still land both branches together and re-verify.

---

## What I was asked

Two freshly-diagnosed priority jobs, then T1-GROUND's own unfinished list in
order: (1) night foliage reads self-lit, (2) no aerial perspective at
distance (called the single highest-leverage macro item), then (3.1) verify
the path-pebble fix with a render, (3.2) dashed seam lines, (3.4) wire stream
reeds, (3.5) river-as-canal bank angle, (3.6) a second true grass species.

## What I did, in priority order

### Job 1 — night foliage "reads self-lit": investigated, DOES NOT REPRODUCE, not touched

**The brief's diagnosis chain has a stale premise.** It (and T1-SKY's own
handover) cites `art.json`'s "R9.4 comment records the ground grass RENDERING
at value 0.199" as the reason canopy reads bright by comparison. That literal
comment **does not exist in current `terrain_playground.json`** — I grepped
for it directly. It is quoted *about* that file, secondhand, in `art.json`
and `vegetation.json`'s own comments, and none of those citations were
re-verified against the file they describe. The real current spec
(`tools/art_pipeline/stylised_ground_spec.py`, the GROUND-REBUILD pass) reads:

```python
"meadow_grass": dict(
    hue=66.0, sat=0.47, val=0.43,
    renders_at=(66.0, 0.50, 0.48),
    ...
```

Albedo value **0.43**, on-screen renders at **0.48** — more than double the
cited 0.199. GROUND-REBUILD replaced the ground's photographic textures with
generated ones targeting an exact colour, and evidently raised the ground's
own baseline far enough, as a side effect, to close whatever gap used to
exist between it and canopy albedo.

**Computed canopy albedo for comparison:** `vegetation.json`'s own R9.4
comment measures `Leaves_NormalTree_C.png` at RGB(88,123,0) pre-tint. The
`trees`/`grove` layers both retint it to `#78c86e` (or `#325f3c`/`#c4d696`
per variant). Since `albedo_color` multiplies the texture channel-by-channel:
`(88×120/255, 123×200/255, 0×110/255) ≈ (41, 96, 0)`, HSV value **≈0.378** —
comparable to or darker than the ground's 0.43/0.48, not brighter.

**Rendered and verified directly, not just computed.** Two real night
renders, two different locations:

- `ground-01-band1-opening-night.png`/`-high.png` — CommonTree canopy
  (the `trees` layer). Canopies read as properly dark, near-black
  silhouettes against the grass.
- `ground-02-band2-stone-root-night.png` — the grove/forest corridor, the
  context closest to T1-SKY's own "ranger-camp" viewpoint. Canopy is
  extremely dark, arguably darker than ideal for navigability but
  absolutely not self-lit.

**Not touched, per CLAUDE.md's "evidence-backed already fixed is valid."**
Darkening `vegetation.json`'s canopy retint further without a reproduced
defect risks re-opening the R9.4/NIGHT-LIGHT history's own documented
over-correction pattern (this file has oscillated between "too flat" and
"too gloomy" multiple times already — see `art.json`'s own R9.4/NIGHT-LIGHT
comments). If a future pass reproduces this at a specific viewpoint I did
not check, the fix is still almost certainly a canopy retint value pass, not
an environment change — but I could not find the defect to fix.

Evidence: `ralph/reports/T1-GROUND-2/shots/ground-01-band1-opening-{day,night}{,-high}.png`,
`ground-02-band2-stone-root-{day,night}.png`.

### Job 2 — no aerial perspective: FIXED, verified, real mechanism discovery

**Not a fog_density change.** That axis is `art.json`'s own R9.4 history,
explicitly rejected by the owner twice already (density halved
0.0022→0.0011→0.00055 after "fog is eating the world... no separation
between hills"), and at the current density the 63%-fogged point sits
~1800m out — far past real viewing range. T1-SKY's handover reached the same
conclusion and correctly declined to touch it.

**Real discovery: Terrain3D 1.0.2 supports a shader-override API** —
`enable_shader_override(bool)`, `set_shader_override(Shader)`,
`get_shader_override()`, `is_shader_override_enabled()` — confirmed first via
`strings` on `addons/terrain_3d/bin/libterrain.linux.release.x86_64.so`, then
by exercising it at runtime. This was apparently unknown/undocumented in this
repo before now; every existing terrain-shader config path
(`_apply_ground_shader`) only ever reached Terrain3D's own auto-generated
shader through `set_shader_param`.

**Mechanism:** `tools/_dump_terrain_shader.gd` (new, committed) calls
`enable_shader_override(true)` then `get_shader_override()` to capture
Terrain3D's real generated shader source — not guessed from binary strings.
Copied to `shaders/terrain_ground.gdshader`, with one addition: a
distance-based desaturate-then-mix-toward-haze block at the end of
`fragment()`, gated on `v_vertex_xz_dist` (Terrain3D's own camera-relative XZ
distance varying, already computed for its mipmap bias — reused, not
duplicated). Five new TUNABLE uniforms, wired through
`terrain_playground.json`'s existing `shader` config block exactly like
every other terrain shader setting:

```
aerial_fade_start_m: 45.0    # past normal ground-camera range on purpose
aerial_fade_range_m: 160.0
aerial_fade_strength: 0.32
aerial_desaturate: 0.55
aerial_fade_colour: "#bec9ce"
```

`playground_world.gd::_apply_ground_shader` loads and installs this shader
**before** its existing config-uniform loop, so the new keys are recognised
by that loop's own `_get_shader_parameters()` check rather than landing in
its `ignored` warning.

**A real footgun found and fixed along the way, worth any future lane
knowing:** `enable_shader_override(true)` is **not idempotent**. Calling it
a *second* time — even when override is already enabled with a real custom
shader in place — regenerates the shader from current auto-shader state and
**silently discards** whatever was in `shader_override`. My own diagnostic
tool (`_dump_terrain_shader.gd`) called it twice (once implicitly via my
fix's own install, once again in the tool's read path) and reported the
install as "broken" — it wasn't; the tool's own second call was clobbering
it. Fixed by checking `is_shader_override_enabled()` first. Documented in
both the tool and the shader's own header comment. **This is the single
most important non-diff finding in this handover** — anyone touching
Terrain3D's shader override in the future will hit this exact trap.

A second, unrelated timing trap in the same tool: `playground_world.gd`'s
`_ready()` is a coroutine (awaits `process_frame` multiple times before
`_apply_ground_shader` even runs). The dump tool's original 2-frame wait read
the terrain material **before the install had run at all**, which looks
identical to "the fix does nothing." Fixed by matching
`_capture_ground_and_sky.gd`'s own `BOOT_FRAMES=90`.

**Verified, end to end, after both fixes:**
- Full-boot dump: 27348 chars (vs. the stock 23321), contains the aerial
  block, `is_shader_override_enabled()` true, **no shader compile errors**,
  **no "ignored" uniform warnings** anywhere in the boot log.
- Rendered `ground-01-band1-opening-day-high.png` (elevated 30m, band 1):
  distant hills past the treeline read progressively hazier/cooler than the
  near field — the exact defect (subject 8, "no aerial perspective... reads
  like a backdrop a few hundred metres away") is visibly gone.
- Rendered the normal ground-height day frame too: near field (player,
  grass, first ~40m) is visually **unaffected** — confirms
  `aerial_fade_start_m=45.0` keeps this off VISUAL_STUNNING_PASS.md §15's
  creature/player readability.

**Scatter re-bake required and done.** `terrain_playground.json`'s shader
block is inside the file `scatter_bake.gd::config_fingerprint()` hashes in
full, so adding the `aerial_fade_*` keys changed the fingerprint even though
nothing placement-affecting moved. Re-ran `bake_playground_scatter.gd`:
762033 placements across 11 layers, **byte-identical** region output — only
`manifest.json`'s fingerprint stamp changed, confirmed by `git status`
showing exactly one file. `tests/test_scatter_perf_budget.gd`'s three tests
(freshness, load budget, batch count) pass.

**Performance:** did not run the full `tools/perf_render_stats.gd` pass
(SETTLE_FRAMES=240 + per-view sampling, another 10-20 min this session's
budget did not have room for after the debugging above). Structural
reasoning instead: the change adds zero draw calls, zero new textures, zero
new geometry — it is pure fragment-shader ALU inside the SAME terrain
material pass that already runs every frame, gated behind a cheap `if
(aerial_t > 0.0)` that is a true no-op (branch not taken, zero extra cost)
for every pixel nearer than 45m. `perf_render_stats.gd`'s own header says it
measures draw-call/primitive counts for scatter LOD, which this change
cannot move. **Flagging rather than asserting**: if a future pass wants a
real ALU-cost number under GL Compatibility, that needs a different
measurement than this tool provides.

Evidence: `ralph/reports/T1-GROUND-2/shots/ground-01-band1-opening-day{,-high}.png`.

### Item 3.1 — path pebbles: VERIFIED

Re-rendered `ground-01-band1-opening-day.png`, cropped the path-pebble row
(`ralph/reports/T1-GROUND-2/shots/path-pebbles-crop-AFTER.png`). Pebbles sit
flush on the dirt with real contact shadows, no floating gap — T1-GROUND's
`align_to_slope`+`sink` fix confirmed working. This was T1-GROUND's own
"done-but-under-verified" item; now verified.

**Bonus finding in the same crop:** the dashed seam line (item 3.2) is
clearly visible crossing the path diagonally in this exact frame — real,
reproduced again, still not root-caused (see below).

### Item 3.4 — stream reeds: mechanism FIXED and verified; visibility problem (a DIFFERENT, larger fix) remains

`water.gd::_build_plant_band` gates every placement candidate on the member
`_level` — the pond's flat surface. The river works around this with one
`_level` swap for the whole body (its `water_level` is a single number); the
stream's bed keeps falling along its own ~90m authored course, so a single
swap does not work and it had **zero** `reeds`/`bank_scrub` config at all —
confirmed by T1-GROUND's own probe of `height_at`/`stream_factor` along the
bank.

**Fix:** `_build_stream_reeds()` (new, `water.gd`) reuses `_build_stream`'s
own trimmed centreline (stored in a new `_stream_samples` member) and swaps
`_level` to the **local** bed height at a series of ~8m stations along it,
calling the existing, untouched `_build_plant_band` once per station with a
one-point "shore". New `reeds`/`bank_scrub` sub-blocks added to
`water.json`'s existing `stream` block, deliberately small
(`clumps: 2`) since each of ~6-7 stations calls the placer once.

**Verified mechanically:** `tests/smoke_pond_water.gd` — 82 stream reeds, 20
bank scrub placed, zero regression to pond (152 reeds) or river (159
reeds/57 scrub) counts.

**Verified visually, and here is the honest part:** rendered
`water-03-stream-eye.png` at T1-GROUND's own camera stand. **Still no
visible water or reeds from this exact viewpoint** — this is not a
regression, it is exactly T1-GROUND's own root-cause finding holding up: the
camera stands over a metre below the channel's own far rim, on a hillside
whose *general* grade (unrelated to the stream) swallows the local carve
from this specific vantage. My fix closes the gap T1-GROUND separately
identified — "even if the relief read, there is nothing marking the water" —
but **cannot** fix the siting/relief problem on its own. T1-GROUND's own
plan named two options and called (b) (what I did) lower-risk; that
assessment was correct, but (b) alone does not resolve "the stream is
invisible from its own bank" for this specific complaint. **(a) — raise
`carve_depth` for this stretch of `terrain_playground.json`'s
`water.stream.points`, which needs a `data/terrain/playground/` regen and a
`smoke_traversal.gd` check — is still open and is the one that actually
closes this complaint.**

Evidence: `ralph/reports/T1-GROUND-2/shots/water-03-stream-eye-AFTER-reeds.png`,
`water-03-stream-grazing.png`.

## Investigated in a prior pass, NOT reattempted this session (time)

- **Item 3.2, dashed seam lines** — reproduced again (visible in this
  session's own `path-pebbles-crop-AFTER.png`), root cause still not
  isolated. T1-GROUND's own hypotheses (sin-hash aliasing vs. macro
  dry-patch boundary dithering) are exactly where this was left; a
  debug-overlay render or a bisect (disable `macro_cfg`, re-render) is still
  the right next step. Did not attempt.
- **Item 3.5, river bank angle** — not touched. T1-GROUND's own measurement
  (59-77° bank cut at every one of 19 authored points) stands; the fix
  (`river.course[i].rim` widening) needs a terrain regen + `smoke_traversal.gd`
  before it ships, which this session did not have budget for after Jobs 1/2.
- **Item 3.6, a genuine second grass species** — not attempted. Still, per
  T1-GROUND's own assessment which I have no reason to revise, "the single
  biggest lever" on the ground subject and the deepest fix for "regional
  differentiation is prop-deep." This is real shader work in
  `grass_field.gdshader` (the most heavily-tuned file in this pass) and
  needs its own multi-round visual-judge pass per `ralph/conventions.md` —
  correctly scoped as its own task, not squeezed into this session.

---

## Exact commands and reproducible camera stands

```
# One-time setup (this session's container)
curl -fL -o g.zip https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip \
  && unzip -o g.zip && chmod +x Godot_v4.7-stable_linux.x86_64 \
  && mv Godot_v4.7-stable_linux.x86_64 /usr/local/bin/godot
godot --headless --path . --import   # ran twice, both clean this session

# Shader override dump/verify (headless, no renderer needed)
godot --headless --path . --script tools/_dump_terrain_shader.gd
# -> res://shots/terrain_shader_dump.gdshader

# Stream reeds mechanism check (headless, fast, no world boot)
godot --headless --path . --script tests/smoke_pond_water.gd

# Scatter freshness/perf (headless)
godot --headless --path . --script tests/run_tests.gd -- --only=test_scatter_perf_budget.gd
godot --headless --path . --script tests/run_tests.gd -- --only=test_scatter_rules.gd
godot --headless --path . --script scripts/world/bake_playground_scatter.gd

# Job 1/2/3.1 evidence (real renderer)
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x800 \
  --script tools/_capture_ground_and_sky.gd -- --only=band1 --states=day,night --elevated=30
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x800 \
  --script tools/_capture_ground_and_sky.gd -- --only=band2 --states=day,night

# Item 3.4 evidence
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x800 \
  --script tools/_capture_ground_and_sky.gd -- --only=stream --states=day
```

Camera stands used (all pre-existing in `_capture_ground_and_sky.gd`, not
invented this session): `ground-01-band1-opening` `Vector2(8,90)→Vector2(-40,180)`;
`ground-02-band2-stone-root` `Vector2(310,1660)→Vector2(400,1800)`;
`water-03-stream-eye`/`-grazing`, T1-GROUND's own stream stand.

---

## What I learned that is NOT visible in the diff

1. **`Terrain3DMaterial.enable_shader_override(true)` is not idempotent** —
   a second call regenerates and silently discards a previously-installed
   custom `shader_override`, even when override was already enabled. Cost
   real debugging time (two full-boot render cycles) before I isolated it
   with a targeted debug print. Documented in the shader's own header and in
   `_dump_terrain_shader.gd`'s comment so the next lane does not repeat it.
2. **A capture/diagnostic tool that waits fewer frames than world boot
   actually needs produces a false negative that looks exactly like "the fix
   does nothing."** `playground_world.gd::_ready()` is a coroutine; my first
   version of `_dump_terrain_shader.gd` read the terrain material 2 frames
   after `add_child`, long before `_apply_ground_shader` had even run.
   `_capture_ground_and_sky.gd`'s own `BOOT_FRAMES=90` is the value that
   actually works — reused it rather than re-deriving a smaller one.
3. **Secondhand citations of another file's own numbers, inside a third
   file's comment, go stale silently.** `art.json` and `vegetation.json`
   both quote "terrain_playground.json's own R9.4 comment" citing ground
   grass rendering at value 0.199 — a comment that no longer exists in that
   file (GROUND-REBUILD superseded it). Both citing comments were written
   accurately at the time, and neither has been wrong enough to break a
   test, so nobody re-checked them. This is exactly the kind of "R9.4
   history" the CLAUDE.md/ralph process treats as authoritative — worth a
   process note: a comment that quotes ANOTHER file's content by
   description, not by reading it fresh, is a staleness trap the moment
   that other file changes.
4. **Running the scatter bake concurrently with a capture render, and
   running two captures back to back, both work on this 4-core container**
   but slow each other proportionally — not free parallelism, just don't-
   have-to-wait-idle parallelism. Sequenced captures were more predictable
   for timing budget purposes than trying to overlap them.

## Disagreements

- **Job 1 does not reproduce.** I disagree with the brief's confidence that
  this is "freshly diagnosed" and ready to fix — the diagnosis chain rests
  on a number that is stale by more than 2x relative to the file it is
  quoted from. Recommend closing this item on the evidence in this handover
  rather than re-opening it without a fresh reproduction, per CLAUDE.md's
  own "evidence-backed already fixed is valid, a newer reproduction reopens
  it" rule — I could not produce a newer reproduction despite trying at two
  different locations.
- **Item 3.4 (stream reeds) should not be read as "the stream is fixed."**
  T1-GROUND's own handover was careful about this distinction and I want to
  preserve it: the reeds mechanism is real, tested, and done. The
  *complaint* ("invisible from its own bank") is not resolved, because it
  was never primarily about missing reeds — it is a terrain-relief/siting
  problem this fix does not touch. Whoever picks up item 4a should not
  assume this session's work makes that easier or harder; it is orthogonal.

## Full file footprint

**Config (bake-affecting, re-baked):**
- `data/config/terrain_playground.json` — added `shader.aerial_fade_start_m`/
  `aerial_fade_range_m`/`aerial_fade_strength`/`aerial_desaturate`/
  `aerial_fade_colour`. **No placement-affecting key touched** (no scatter
  rule, no vegetation layer, no terrain macro geometry) — the fingerprint
  changed only because the hash covers the whole file.
- `data/scatter/playground/manifest.json` — re-baked; **only the fingerprint
  stamp changed**, all 256 region files byte-identical (confirmed via `git
  status`, which showed exactly one changed file after the bake).

**Config (not bake-affecting):**
- `data/config/water.json` — added `stream.reeds`/`stream.bank_scrub`
  sub-blocks.

**Scripts:**
- `scripts/world/water.gd` — new `_stream_samples` member,
  `_build_stream_reeds()`, wired into `build()`; `_build_stream` now stores
  its trimmed centreline. `_stats` gained `stream_reeds`/`stream_scrub`
  keys.
- `scripts/world/playground_world.gd` — `_apply_ground_shader` now installs
  `shaders/terrain_ground.gdshader` via `set_shader_override`+
  `enable_shader_override` before its existing config-uniform loop; added
  `aerial_fade_colour` to that loop's `COLOURS` list.

**New files:**
- `shaders/terrain_ground.gdshader` — Terrain3D's own auto-generated shader
  (captured, not hand-written) plus the aerial-perspective block, both
  T1-GROUND-2 banners self-documenting provenance and regeneration steps.
- `tools/_dump_terrain_shader.gd` — committed (not throwaway): referenced by
  the shader's own header as the regeneration tool for future lanes.

**Nothing else was touched.** No `vegetation.json`, `grass_field.json`,
`npc_ranks.json`, band configs, `burrow_warrens.gd`, `stronghold*.gd`,
`landmark.gd`, `building_prefabs.json`, or `scripts/combat/**` — all outside
this lane's ownership or this session's investigated scope.

**Evidence, committed:**
- `ralph/reports/T1-GROUND-2/shots/*.png` — 9 files, see individual commit
  messages for captions.
- This file.

## What I would do next, in priority order

1. **Terrain regen for the stream's `carve_depth`** (item 4a) — the one
   change that actually resolves "invisible from its own bank." Needs
   `data/terrain/playground/` regeneration and a `smoke_traversal.gd` run
   before it ships.
2. **Debug-overlay or bisect the dashed seam lines** (item 3.2) — T1-GROUND's
   two hypotheses (sin-hash alias vs. macro dry-patch dither) are still
   both open; this needs a colour-coded ownership overlay or a
   `macro_cfg`-disabled A/B render to distinguish them.
3. **River bank angle** (item 3.5) — `river.course[i].rim` widening, terrain
   regen, `smoke_traversal.gd` full run before rendering (a wider channel
   can strand the corridor).
4. **A genuine second grass-blade species** (item 3.6) — scope as its own
   multi-round visual-judge pass, not squeezed into a session already
   carrying two other jobs.
5. **A full unscoped `_capture_ground_and_sky.gd` pass** (~35 min) for the
   next Fable judge round now that aerial perspective and stream reeds are
   landed — this session only rendered scoped subsets to fit its budget.
6. **Tell T1-SKY's lane (or whoever integrates both branches) that Job 1
   does not need the canopy-albedo pass they deferred to this lane** — flag
   this explicitly since their handover named it as "GROUND's job," and
   without this note a future lane could re-open it on the same stale
   citation.
