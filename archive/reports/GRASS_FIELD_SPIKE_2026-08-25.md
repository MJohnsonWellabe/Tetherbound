# GRASS-FIELD — the spike, and what it proved

`branch: ralph/GRASS-FIELD` · `cut from origin/main at 636673ce` · `2026-08-25`
· follows `ralph/reports/WORLD_GRASS_2026-08-25.md`

The owner asked whether the reference's ground could be generated rather than
placed. It can, on the renderer this project actually ships, and this is the
spike that establishes it.

**It ships OFF.** `data/config/grass_field.json`'s `enabled` is `false`, the
scatter path is untouched behind it, and `tests/test_grass_field.gd` fails if
anyone flips it. Turning it on is an owner decision made against an ROG Ally,
not a lane's made against a container.

## The question, and why the first answer was wrong

`WORLD_GRASS_2026-08-25.md` measured the ceiling: every ground-cover instance is
a stored transform, a tuft covers ~0.33 m2, so the reference's continuous carpet
needs ~1.5 tufts/m2 across a 16.8 km2 corridor — **25 million placements against
a 900,000 chapter ceiling, roughly 40x out however it is spent.** Three blind
rounds ranked *"the player stands on a painting of grass with props stabbed into
it"* first, every time, and no density number ever moved it.

That report then named `Terrain3DMeshAsset.density` as the instrument that could
reach it. **That was wrong**, and it was checked before anything was built:

- `tools/_probe_terrain3d_api.gd` reads the API off ClassDB — the addon ships
  here as a GDExtension binary with no C++ sources vendored, so the usual
  "verify against the real Terrain3D source" is not available offline.
- `density` exists, but every entry point on `Terrain3DInstancer`
  (`add_instances`, `add_transforms`, `add_multimesh`, `append_location`,
  `append_region`) either takes explicit transforms or generates them once and
  stores them. Upstream is explicit that `add_instances` is *"designed for hand
  editing via Terrain3DEditor"* and that *"data is currently stored in
  `Terrain3DRegion.instances`"*.

It is a paint-brush parameter. It costs exactly what we already pay. The
correction is committed on `ralph/WORLD-GRASS` so the claim does not outlive it.

## What was built

A camera-relative carpet that stores nothing. A fixed ring of tufts follows the
camera, and the **vertex shader** puts each one on the terrain surface by
sampling Terrain3D's own height data. Cost is a function of the ring, not of the
world: the same geometry renders in the village and eight kilometres down the
corridor.

| file | what it is |
|---|---|
| `shaders/grass_field.gdshader` | the carpet: height lookup, control mask, gradient, ground blend, wind |
| `scripts/world/grass_field.gd` | builds the tuft mesh and the ring, follows the camera, mirrors Terrain3D's uniforms |
| `data/config/grass_field.json` | every number, and the `enabled` flag |
| `tests/test_grass_field.gd` | the flag contract |
| `tools/_probe_terrain3d_api.gd` | what Terrain3D actually exposes |
| `tools/_probe_terrain3d_shader.gd` | Terrain3D's own generated shader, off the live material |
| `tools/_probe_grass_field.gd` | the capture |

**The region lookup is copied, not invented.** `tools/_probe_terrain3d_shader.gd`
pulls Terrain3D's generated shader source off the running material via
`RenderingServer.shader_get_code()` and writes it out;
`get_index_coord()` and the height `texelFetch` in our shader are lifted from
it verbatim. This matters because a region lookup that is subtly wrong **does
not error** — it puts the grass a few metres under the ground and reads as "the
shader does not work".

The hooks that make it possible, all present in Terrain3D 1.0.2:
`Terrain3DData.get_height_maps_rid()` / `get_control_maps_rid()` /
`get_color_maps_rid()`, and `region_size` / `vertex_spacing` / `get_region_map()`
for the arithmetic.

## The go/no-go, and its result

Three criteria were set before any code was written. All three met, on real
frames of the real Meadows (`shots/field_r0` … `field_r5`):

1. **It compiles and runs under GL Compatibility**, which `D01` locks this
   project to after the Ally freeze root-caused to a Forward+ stall. Godot lists
   compute shaders, subsurface scattering and `RenderingDevice` as unsupported
   there; this uses none of them — vertex maths, one `texelFetch`, an alpha
   scissor.
2. **The blades sit on the terrain**, following its contours across four bands,
   not on a plane at y=0 and not buried.
3. **The control mask keeps them off the painted routes** — and it reads the
   *same* control map the terrain paints its dirt from, so the verge lines up
   with the road for free instead of being a second exclusion rule to keep in
   sync.

## Two defects the shader answers that an asset purchase was going to be asked for

Round 3 of WORLD-GRASS's blind pass filed these under *needs art that is not in
the build*: the grass mesh is "flat two-tone polygon with no base-to-tip
gradient, no translucency, no ground blend". Both are shader outputs:

- the generated blade carries `UV.y` as height along the blade, so the gradient
  is a `mix()`;
- the blade's base is **multiplied** by the terrain's own colour map, so growth
  comes out of the ground instead of meeting it at a razor line.

**One bug worth recording.** Terrain3D's colour map is a near-white MULTIPLIER
(`terrain_playground.json`: `#f7f8f2`, `#fbfbf6`), not a colour. Mixing *toward*
it — the obvious reading — washed every blade base out to near-white and made
the whole field read pale and plasticky. Multiplying by it, which is what the
terrain's own shader does, is correct.

## The blind pass on the spike, and what it changed

A critic told nothing about the change judged `shots/field_r4` against the same
references. Its in-lane findings were specific and all actionable; the ones
acted on immediately:

| finding | cause | fix |
|---|---|---|
| *"one blade repeated — same height, same lean, same direction... reads as a comb, or a field of leeks"* | every blade in a tuft hashed on the same instance origin | `UV2.x` now carries which blade of the tuft a vertex belongs to; height, lean and lean direction hash per BLADE. Coverage and shade stay per-tuft on purpose, or drifts dissolve into static |
| *"blades are 4-6cm wide where real meadow grass is 3-6mm"* | 19 mm blades | 6 mm |
| *"distinct horizontal stripes... the loudest procedural signature in the set"* | axis-aligned value-noise lattice | noise domain rotated 31° off the world axes |
| *"~40-50% of the near-field ground is bare terrain between blades"* | too few, too sparse | 170k → 210k tufts, 5 → 7 blades, fade pushed 36 → 42 m |

Its remaining findings are recorded rather than acted on, and split cleanly:

- **Not this system's** — the floating house in `03-band3-crossing-off`, a
  duplicate trainer hovering 3.5 m above the signpost in `04-band4-*`, shadow
  cascade staircase, terrain quad seams, no clouds, no aerial perspective, no
  ambient floor in shade (measured: 28.1% of `04-off` below 5% luminance against
  1.3% in every reference), terracotta trunks spending the world's strongest warm
  chroma on its commonest friendly prop.
- **Genuinely still missing** — the mid-layer. The critic counted two mid-height
  plants across twelve frames. `ralph/WORLD-GRASS` adds a `groundmat` layer that
  is exactly this; it is not on this branch, and the suppression list carries a
  note that whoever consolidates the two must add `"groundmat"` to it.

## Budget

The four non-colliding carpet layers are **625,227 of WORLD-GRASS's 725,949
placements — 86% of the bake**, and ~20 MB of `data/scatter/*.bin`. With the
field on, `vegetation.gd` drops them after the bake is read and before anything
is grouped, marked harvestable or given a mesh asset, so a suppressed layer
costs nothing beyond bytes already on disk. The bake itself is untouched, which
is what keeps the A/B honest.

Everything the field does not replace stays scatter, and must: trees, rocks and
bushes carry collision and harvest points and are the landmarks the eye
navigates by. `tests/test_grass_field.gd` reads `collides`/`harvest_item`
straight off `vegetation.json` and fails if any such layer is ever suppressed —
the field is the right instrument for what you walk *through* and the wrong one
for what you walk *into*.

## GPU: still unmeasurable, still stated as risk

`PERF-ROG-GPU` is unchanged by any of this. The Compatibility renderer counts
MultiMesh batches rather than instances and this box rasterises in software, so
**no frame rate is claimed and none can be.** What can be said about the shape
of the cost:

- it is **bounded and constant** — 210,000 tufts is the whole world's ground
  cover at every point in the chapter, against a placement count that grew with
  the corridor;
- it is **one draw**, not 43 batches;
- overdraw is the real handheld risk, which is why the shader uses an alpha
  scissor with `depth_prepass_alpha` rather than `blend_mix`;
- `tuft_count`, `field_radius` and `blades_per_tuft` are each a single number
  that trades quality for cost, and none of them needs a re-bake.

## What the owner has to decide

Whether this is affordable on the device. Nothing else about it is a judgement
call this container can make. The A/B is one boolean in
`data/config/grass_field.json`, both systems are intact, and the scatter path is
exactly as it was.
