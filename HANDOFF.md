# HANDOFF — read this first

Owner's standing directive: build the first fifteen minutes of gameplay so it
looks and feels like GAME_DESIGN.md and ASSETS.md describe, a Palworld or
Pokemon-on-Switch grade opening rather than a tech demo. Everything else is
subordinate to that.

The owner has three times rejected a claim of "verified working" that turned
out to be wrong. **Do not report anything fixed from a screenshot glance, and
do not report it fixed because the tests are green.** This session proved why:
a toon shading commit passed typecheck and the whole test suite while turning
every creature in the game into an untextured capsule, because nothing tests
that a rig actually mounts. Get a material property, a mesh count, a pixel, or
a state read out of a running browser before you say a thing works.

## What this session fixed, with evidence

- **Buildings rendered inside out (D58).** The "half walls" report was real and
  the assets were never at fault. `bakedPrototype` bakes a negative-determinant
  matrix into the vertices, which flips the indices to counter-clockwise, but
  the mesh kept a clockwise-front `overrideMaterialSideOrientation` stamp that
  `clone()` copied. Fixed with one line. Verified from both compass sides and
  from inside.
- **All fifteen pals are rigged creatures again (D59, supersedes D56).** The
  six "irreparable" species were not irreparable. Quaternius rigs carry a 100x
  armature scale, and Babylon double-applies it when a skeleton has more than
  one root joint. The six broken ones park IK bones under the armature as extra
  roots; the nine working ones have a single root. Exact split, no exceptions.
  `normalizeArmatureScale` in `scripts/lib/glbtool.mjs` bakes the scale out by
  conjugation. `tools/rigcheck-bounds.mjs`: 20 of 20 pass, was 6 broken.
- **Camera boom collides with buildings.** `src/entities/CameraBoom.ts`, pure
  and tested. Measured pulling 5.2m down to 1.54m at a wall.
- **Houses are solid and enterable.** Wall-ring colliders from the real model
  footprint (the old single circle was sized from the primitive fallback and
  sat 1-2m inside the walls), a real `wall-doorway-square` aperture instead of
  the solid `wall-door` panel, and a hinge leaf on the shared `DoorRegistry`.
- **Pause menu with Start Over.** Verified in a browser: first press arms,
  second wipes both localStorage keys and reloads.
- **The guided opening.** Verified in a browser from a wiped save: fresh game
  starts with an empty party and an empty satchel, Orin's conversation hands
  over axe, pick, knife, hammer, 40 wood and 3 worn orbs, grants exactly one
  starter, sets `met_orin` and `took_starter`, and the objective advances to
  "Catch a tuftmoth in the meadow past the fence".
- **Story bugs.** Orin replayed his whole introduction (starter choice
  included) on every talk; the starter was farmable by releasing your only pal;
  the Loamking offer granted the pal before asking, so "Leave it" gave it to
  you anyway; `victory:` and `recruit:` effects were dropped while a test
  asserted they were valid.

## Known gaps, honestly stated

- **The guaranteed first catch is agent-verified, not orchestrator-verified.**
  A subagent drove it end to end with screenshots (docile tuftmoth at (65,0),
  one orb, party reaches 2, `first_catch` set). My own probe of the spawner
  pool returned zero pals of any kind, which means my accessor was wrong rather
  than the spawn, but I did not close that loop. Verify it before trusting it.
- **Toon shading is committed but not judged.** It is real, correctly scoped to
  pals/NPCs/player via `mountRig`, and config-gated in `lighting.json` with a
  `?toon=0` override. Both the implementing agent and I read it as a marginal
  improvement, not the Palworld transformation the owner asked for: these
  models already shade nearly flat per face, so band quantization has little
  gradient to bite on. Next levers are `rimStrength`/`rimPower` or dropping to
  2 bands. Run the `visual-judge` skill against a real contact sheet before
  deciding it earns its place.
- **The furnished home house has no real light.** `PointLight` is not exported
  from `src/core/babylon.ts`, so it ships an emissive lamp mesh that reads warm
  but casts nothing. Add the export and a real light.
- **Combat polish never happened.** All of these are diagnosed and unfixed:
  no leash (walk away and the fight HUD stays up forever), encounters can start
  mid-dialogue, the power attack is a dead silent button below level 8 (the
  charge bar needs 9 quick hits and early enemies die in 5, and `MoveResolver`
  returns 0 damage with no feedback), the telegraph and dodge never fire against
  sub-level-8 enemies which is every early Meadows spawn, and there is no ALERT
  pose during the 2.5s opening grace.
- **Pages deploy is blocked.** Pushing `claude/tetherbound-game-plan-w40lbs`
  was denied by the permission classifier. It is a clean fast-forward from
  main. The owner has to approve it or deploy another way.

## Harness trap that will cost you an hour

Headless Chromium throttles requestAnimationFrame hard, so the fixed-step loop
barely ticks. A `page.keyboard.press('KeyE')` is never sampled and the game
looks completely broken when it is fine. Hold keys for 2.5 seconds or more, or
drive the DOM directly. Dialogue choices are `.dlg__choice` elements, not
`<button>`. The panel advances on `pointerdown`, which is not throttled.

For screenshots, the render loop re-poses the camera every frame: call
`window.__tetherbound.loop.stop()` first, then pose, then `scene.render()`,
then shoot.

## Standing project rules

See CLAUDE.md, which wins over this file. Party cap 5 enforced only in
`Party.add()`. The player never wields a weapon. The throw is always available.
No storage box. Every tunable in `src/data/*.json`. Seeded RNG only in world
generation. TypeScript strict. Files split past 300 lines. Fixed 60Hz via the
`Loop.ts` accumulator. Dispose everything you create. Write the test before the
formula in `combat/` and `party/`. CC0-only is waived (D42);
`ASSET_MANIFEST.md` is provenance, not a licence gate.

Run `npm run decisions` for the next free number before writing a decision
record. Do not guess it.
