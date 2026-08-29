# T1-CAMP session report — 2026-08-29

Track 1 (Aesthetics) lane, scoped to §17 (campsite assets) of
`docs/owner-direction/TETHERBOUND_VISUAL_STUNNING_PASS.md`. Branch
`ralph/T1-CAMP`, pushed, no PR opened per instructions.

## What was actually wrong

Rendered the PLAYER-BUILT `camp` buildable (`scripts/build/camp.gd`) exactly
as `build_placer.gd` builds it, standalone, at gameplay third-person distance
with the real 1.80m trainer beside it (see "Method" below). The result
(`shots/t1_camp_before/`, not committed — `.gitignore` excludes `shots/`)
showed the real defect, and it was not primarily a materials/family problem:

**The tent was sunk roughly half its own height into the ground.**
`camp_tent.glb`'s local origin sits 0.611m above its own geometric base — a
glTF-export quirk `docs/ASSET_LEDGER.md` already documents and already
compensates for on this exact mesh's AUTHORED placement
(`band1_lower_meadows/props.json`'s `sink_m: -0.64`, via `props.gd`'s scatter
path). `camp.gd` positions the tent node directly with no such compensation,
so the player-built tent's origin sat AT ground level, burying its true base
0.611m below the ground plane and leaving only ~0.6m of a 1.2m-tall tent
visible — a squashed, knee-high "toy" next to the trainer, in an otherwise
human-scale camp. Measured, not guessed: `tools/_probe_t1_camp.gd`.

**The Creature Bed had the identical bug.** `camp_bed.glb`'s origin sits
0.215m above its own base (ledger: `sink_m: -0.21` on the authored
placement); `scripts/build/creature_bed.gd` had the same missing
compensation, sinking a fifth of a metre of the player-placed bed into the
ground.

**The campfire had no stone ring at all.** Every AUTHORED camp in the game
(band1/band3/band4's trail_camp clusters, the stronghold rest point) pairs
`Bonfire_Fire` with the Meshy-generated `campfire_stone_ring` — same asset
family as the tent, from the same owner-directed generation
(`docs/ASSET_LEDGER.md`). The player-built camp never did, so the one
campsite every player actually places read as bare logs on grass while
every scripted camp nearby looked deliberately built.

None of these three needed a new asset, sourcing, or a Meshy generation —
they were composition/placement bugs in code, in already-installed,
already-ledgered assets.

## Fixes shipped

- `scripts/build/camp.gd`: `TENT_POSITION`'s y raised by the measured
  0.611m sink; added `campfire_stone_ring.glb` around the fire at scale 0.8
  (the largest scale that clears the tent's own footprint in this camp's
  tight tutorial layout — see the constant's own comment for the
  clearance arithmetic), wired into both the ghost preview and the real
  build, `tint_ghost()` included.
- `scripts/build/creature_bed.gd`: `_piece.position.y` raised by the
  measured 0.215m sink in both `build_ghost()` and `build_real()`.
  `REST_ANCHOR` (0.42m) did not need touching — it was already calibrated
  against the bed's TRUE (unsunk) top surface (0.194m) plus clearance, so
  before this fix the resting creature was floating ~0.22m above a
  half-buried bed; now it sits just above the real mattress.
- `tools/_probe_t1_camp.gd` (measurement) and `tools/_capture_t1_camp.gd`
  (before/after render) added and committed, following this repo's own
  `tools/_probe_*`/`tools/_capture_*` convention, for reproducibility.

## Investigated and deliberately reverted: the bedroll's palette

`bedroll.obj` (Kenney Survival Kit, CC0) samples a bright red/near-white
column pair from its shared palette atlas — a real "share one material/style
family" gap beside the Meshy tent's muted earth-tone canvas. Tried a runtime
`albedo_color` multiply override (the same mechanism
`build_material_finish.gd` already uses project-wide) at two strengths.
Measured the result by sampling actual output pixels (PIL) rather than
eyeballing: under this scene's ACES tonemap, multiplying the bright
near-white pillow region DOWN made it read as MORE saturated red, not less —
the R channel stays clipped at 255 while G/B fall, the opposite of the
intended dulling effect, at both `Color(0.75,0.55,0.42)` and
`Color(0.92,0.85,0.75)`. Reverted rather than shipped backwards; the
constant and the reasoning are left as a comment in `camp.gd` at the
`BEDROLL` declaration so the next attempt does not repeat it blind. A real
fix needs either a different atlas column (this mesh's own UV data chooses
it; nothing in code can move it) or a tonemap-aware grade — out of this
session's scope.

**Workbench** (`Workbench.gltf`, Quaternius Fantasy) was checked and left
alone: it is the same prop family already used for every other buildable
piece and generic scatter prop across the game (`Bench`, `Crate_Wooden`,
`Barrel`, etc.), its `MI_Trim_Furniture`/`MI_Trim_Metal` materials already
get the correct metallic-factor fix via `build_material_finish.gd`
(confirmed: raw import is `metallic=1.0` with a real metallic-roughness
texture that `apply()` zeroes and replaces per its own established rule),
and it read correctly in every capture. No changes made.

## Method

`tools/_capture_t1_camp.gd` builds exactly what a player builds — `camp.gd`
plus a `Workbench` and a `Creature Bed` a few metres off, the same order of
magnitude as the authored trail_camp's own spacing — on a flat pad with the
real `player.tscn` trainer as a scale ruler, then two shots: a gameplay
third-person establishing frame and a closer composition frame. Reused
`tools/_capture_structures.gd`'s own stage/lighting/shutter formula rather
than inventing a new rig. `godot --headless --path . --import` was run once
before any capture, per this repo's own documented trap.

## Verification

- `tests/run_tests.gd -- --only=camp,creature_bed,build_catalogue,home_progress,gate_a_rest_torch,free_build,gateb_flags`:
  42 tests, 830 assertions, 0 failed.
- `tests/smoke_gate_a_rest_torch.gd` (full production `meadows_playground.tscn`,
  real controller-path placement of `creature_bed` and `camp`, real rest/torch
  interactions): passed clean — `[camp] rested; day 2`, creature bed HP
  regen, torch draw/stow cycles all unaffected by the geometry changes.
- Did not run the full `tests/run_tests.gd` suite unfiltered — it does not
  fit this sandbox's single-invocation time budget (the suite's own header
  documents outgrowing a straightforward CI window); the filtered run above
  covers every test file this change could plausibly affect.

## Performance — honest gap

No ROG Ally was available in this session; every capture ran under the
Compatibility renderer via `xvfb-run` + llvmpipe software rendering, whose
absolute frame times this repo's own tooling already documents as not
trustworthy (`tools/_capture_structures.gd`'s header). Could not measure a
real before/after FPS delta.

What can be said without hardware: the only added geometry is one more
instance of `campfire_stone_ring.glb` per placed `camp` — a mesh already
instanced multiple times per band across `band1_lower_meadows`,
`band3_the_river_lock`, `band4_upper_meadows_ironwood`, and
`stronghold_occupation.json` with no documented performance concern raised
against it there. `camp` is placed by the player a handful of times over a
playthrough (the compact-camp redesign collapsed it to one buildable), not
scattered at world-generation density, so the per-instance cost of one more
already-vendored mesh is bounded and low-risk. The tent/bed sink fixes are
pure `Vector3` offset changes with zero new geometry. This is a reasoned
expectation of no meaningful cost, not a measurement — worth a real-hardware
sanity check per §21.

## Not touched (ownership boundaries respected)

Ground/terrain materials, lighting/`art.json`, regional identity/landmarks,
water, the seven `ralph/LAND-0829A` lanes' files (band spawn data,
`playground_world.gd`'s `TM_AT`, terrain bake), and `tools/gate_f/`.
