# HANDOFF — read this first

Owner's standing directive, most recent first: fix the three visible bugs, then build
the first fifteen minutes of gameplay so it looks and feels like the vision in
GAME_DESIGN.md/ASSETS.md — a Palworld/Pokemon-Switch-grade opening, not a tech demo.
Full context on that directive lives in `docs/decisions/` and the plan file this
session worked from (`/root/.claude/plans/start-m5-from-the-rippling-squirrel.md`
if it's still on disk — copy its "OWNER DIRECTIVE" section into this repo if it
ever needs to survive past that path).

The owner has twice rejected a claim of "verified working" that turned out to be
wrong on closer inspection. **Do not report a bug fixed from a screenshot glance.**
Get material properties, mesh counts, or a pixel-level check before saying so.

## Live, unresolved bug: buildings are missing a wall ("half walls")

This is the most recent open item and where this session stopped. The owner said,
verbatim: *"they're obviously half walls or something weird. it doesn't look
right."* — a direct rebuttal of an earlier claim that buildings render "fully
solid, no see-through walls."

**Confirmed by direct inspection this session** (village houses in Hollowbrook,
not the debug grid): every house variant (`house_a/b/c.glb`) and the Hall shell
render with **one entire side of the building completely absent** — not
transparent, not culled, just not there. You can see clean into a hollow gray
interior volume through the gap. Screenshots taken with a free camera (see
recipe below) confirmed this from multiple angles; it is real geometry, not a
lighting or camera artifact.

Ruled out, with evidence, so the next agent doesn't re-check these:
- **Not a material/transparency bug.** Dumped `backFaceCulling` (true),
  `alpha` (1), `transparencyMode` (null) on every placed `house_model` mesh —
  all normal, opaque, single-sided.
- **Not the D47 mirroring bug returning.** World-matrix determinant on every
  placed house mesh is `+1.0` (not negative) — winding is correct, the
  bake-transform-into-vertices fix from D47 still holds.
- **Not a data/layout bug in the wall list.** Read `scripts/asset-jobs.mjs`'s
  `houseA` piece array by hand: 8 wall pieces, tile-mapped by `pos`+`rotY`
  against the doc comment's edge convention (0=+x edge, R90=-z, R180=-x,
  R270=+z). Worked through the math — all 4 sides of the 2x2 footprint are
  fully covered on paper (2 wall segments per side, no gaps). The missing wall
  is consistent (same side, every instance of the same variant), which means
  the bug is baked into the model once and then placed identically everywhere
  — it is NOT random per-instance placement noise.

**Where I was about to look next** (interrupted before finishing): the merge
step that turns those `{file, pos, rotY}` piece lists into one glTF, in
`scripts/optimize-assets.mjs`'s `readComposite()` (around line 65-90). It
creates one `holder` node per piece with `setTranslation(pos)` and
`setRotation(fromEuler(rotY in degrees))`, reparents the piece's children onto
the holder, and adds the holder to a shared scene. I had not yet checked:
1. Whether `mergeDocuments` (from `@gltf-transform/functions`) silently drops
   or fails to import specific meshes when two source files happen to share
   node/mesh names (the fantasy-town-kit's `wall.glb` is reused many times
   across the piece list — if `mergeDocuments` dedupes by name rather than by
   file, later merges of the same source file could overwrite earlier ones
   instead of adding a new instance).
2. Whether the *particular* Kenney source files used for the front wall
   (`wall-door.glb`, `wall-window-shutters.glb` for houseA) actually contain a
   full wall panel, or whether they are open-fronted "dollhouse cutaway" kit
   pieces not meant to stand alone (Kenney kits sometimes ship a piece
   variant specifically for diorama/cutaway views). Check by loading the raw
   source GLB from `assets_raw/fantasy-town-kit/Models/GLB format/wall-door.glb`
   directly (bare-scene test, no game code) and inspecting its own bounding
   box / vertex count against a known-good `wall.glb`.
3. Whether the bug is actually specific to whichever side happens to use
   `wall-door`/`wall-window-shutters` at all — test by swapping houseA's front
   pieces for plain `wall` pieces, rebuilding, and seeing if the gap moves or
   disappears. That would immediately localize it to those two piece files
   rather than the merge machinery.

**Regression tool built and left in the tree, but not yet run to completion
on this bug**: none. No permanent tool exists yet for "does every building
have all its walls." Once the root cause is found, write one — e.g. a probe
that loads each `models/buildings/*.glb`, checks the merged mesh's bounding
box against the expected full footprint, or counts submeshes/vertex clusters
per compass side. Follow the pattern of `tools/rigcheck-bounds.mjs` (load
exactly like the game does, assert a geometric invariant, fail loudly).

### Recipe: free camera in the Playwright tools (useful, wasn't obvious)

The game's main loop (`src/core/Loop.ts`, exposed as `g.loop` on
`window.__tetherbound`) runs its own `requestAnimationFrame` that repositions
the camera every frame via the player's follow-cam. Setting
`camera.position`/`camera.setTarget()` from a Playwright `page.evaluate()` and
then screenshotting gets silently overwritten by the next real frame before
the shutter fires — every "free camera" shot comes back identical to the
follow-cam view. Fix: call `g.loop.stop()` once before posing the camera, then
`scene.render()` after each manual pose, then screenshot. Nothing in
`tools/lib/game.mjs` does this today (its `place()` helper only works because
it poses the camera to *approximate* where the follow-cam already is). If this
recipe proves generally useful, promote it into `tools/lib/game.mjs` as an
`orbit()` export.

## What's confirmed solid — do not re-investigate these

- **Vegetation/instancing (bug 1c of the owner's brief).** D53 fixed the
  mirrored-prop bug (`PropModels.ts` — `proto.parent = null` after baking).
  `tools/walktest.mjs` (committed, permanent) walks 500m+ and asserts nonzero
  resident prop instances at 9 spots; last run was clean, 2700-3200 instances
  per spot throughout.
- **Rigged pals/characters exploding into shards (D56).** Root-caused (shared
  skeletons under `instantiateModelsToScene`, plus a geometry-optimizer pass
  that corrupted some skins' inverse-bind matrices) and fixed
  (`loadContainerOwned` in `src/core/AssetLoader.ts`, `mountRig()` in
  `src/anim/Rigs.ts`, skinned models skip all geometry passes in
  `scripts/lib/glbtool.mjs`'s `slim()`). Six irreparable species were recast
  onto Kenney Cube Pets. `tools/rigcheck-bounds.mjs` (committed, permanent)
  checks all 20 rigged models' bounding-box-through-skeleton stays under 20m;
  currently 0 broken.
- **Combat pacing (D55).** Opening grace, cadence floor, telegraph, doubled
  HP, flee tuning, aim-hold-during-throw. Tested via
  `tests/combatClock.test.ts` as a pacing contract, not fragile fixed numbers.
- **Doors (D57).** `wood_door` is a real interactive piece, distinct from the
  frame-only `wood_doorway`; hinge swing, save-compatible, tested in
  `tests/door.test.ts` and `src/building/Door.ts`.

## What's NOT started yet (the owner's brief, parts 2-4)

These were never begun this session — do not assume partial progress exists
beyond what's listed above.

1. **Combat clock remainder**: visible ALERT pose during the opening grace,
   0.4x slow-motion during the catch-ring window (planned as a sim-rate
   factor in `Loop.ts`'s accumulator, driven by `CombatMode`'s aiming state,
   tunable in `moves.json`), first-combat-only contextual hints in
   `CombatScreen.ts`.
2. **The first fifteen minutes vertical slice** — the actual point of this
   whole effort and the thing the owner most wants to see. Nothing built:
   no wake-up scene, no Grandpa dialogue, no starter choice refit, no
   Mom/backpack scene, no guided objective chain, no guaranteed docile
   Tuftmoth encounter. See the plan file's "Part 2" section for the full
   spec (scene-by-scene, reuses `DialoguePanel`, `Story.ts`, `HUD`, existing
   events, `SaveV1.progress.flags`).
3. **Art pass toward Palworld's read** — partially covered by an
   already-merged lighting commit (warm sun, sky-tinted fog, sky-blue
   ambient), but NOT independently re-verified against the owner's specific
   asks: terrain macro variation (golden dry-grass patches), interior warm
   lamp light for the wake-up/Grandpa scenes, toon 3-step shading on
   characters/pals. None of these three has been touched.
4. **Gamepad completion.** `src/core/input/GamepadLayer.ts` exists (was ~224
   lines last checked) and handles axes plus a partial RT/LT read, but is
   missing most of the XInput mapping the owner specified: full stick
   deadzone/curve tuning, A/X/Y/B verbs, dpad screen navigation, Start/Back,
   connected-toast, glyph hints, a saved look-sensitivity setting, and
   gamepad focus-ring navigation for menus. Not started.
5. **Final acceptance** (scripted Playwright playthrough of the whole 15
   minutes with a screenshot per beat, `?debug=build` clean, no vegetation
   gaps, no exploded rigs, full suite green, push to `main` and
   fast-forward `claude/tetherbound-game-plan-w40lbs`, report the live URL)
   — blocked on everything above.

## Standing project rules (from CLAUDE.md — do not violate)

Party cap 5 (enforced only in `Party.add()`). Player never wields a weapon.
Throw always available in combat. No storage box — releasing a pal is
permanent. Every tunable number lives in `src/data/*.json`, never hardcoded in
a system file. No `Math.random()` in world generation — seeded RNG only.
TypeScript strict. One responsibility per file, split past 300 lines. Fixed
60Hz sim via `Loop.ts`'s accumulator. Dispose every geometry/material/texture
you create. Write the test before the formula for anything in `combat/` or
`party/` (this session extended that convention to `Door.ts`'s hinge math
too — worth keeping up for any new pure-math module).

CC0-only is **waived** by the owner (non-commercial project, quality over
license purity) — see D42. `ASSET_MANIFEST.md` stays as a provenance log, not
a license gate.

Deploy mechanics: push to `main`, then fast-forward
`claude/tetherbound-game-plan-w40lbs` (the only branch GitHub Pages'
environment protection currently allows — the owner hasn't changed that
setting yet).

## Decision records made this run of work

D42 (CC0 waiver) through D57 (doors) are recorded in `docs/decisions/`. Run
`npm run decisions` for the next free number before writing a new one — do not
guess the number by hand, a background agent collided with D42 once already
this project and had to be renamed after the fact.

## Immediate next step for whoever picks this up

Finish diagnosing the missing-wall bug (see the three numbered checks above),
fix it, verify with fresh screenshots taken via the `loop.stop()` free-camera
recipe from both outside AND inside a building (the owner explicitly asked for
both), write a permanent regression tool, then move directly into the
vertical slice — that is the actual deliverable the owner is waiting on.
