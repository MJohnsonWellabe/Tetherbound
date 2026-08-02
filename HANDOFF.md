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
- **Vegetation renders where you stand.** Every prop cell of a family shared one
  Geometry, and `thinInstanceSetBuffer` writes matrices into the geometry, so
  all nine resident cells overwrote each other and the nearest-first build queue
  meant the FARTHEST cell won. Trees on the horizon, bare ground underfoot,
  while the per-cell harvest colliders stayed correct, which is why an invisible
  bush still asked for a knife. `makeGeometryUnique()` per cell.
- **Gamepad picks the standard-mapping pad.** Nothing was unmapped; the picker
  took the first `getGamepads()` entry without checking `mapping`, and an Ally
  enumerates several HID devices. See the unverified caveat below (D61).
- **One dialogue tap advances one screen.** The panel advanced on pointerdown
  and the same touch bubbled to TouchLayer and advanced again. Proven by
  disabling and restoring the guard.
- **The wake-up room is legible.** Boom resolved to 1.73m indoors with a 1.67m
  visible extent against a 1.8m character, so the screen was the player's back.
  Now 2.4m and 2.32m. Plus all three door bugs, and the Hall entrance which was
  fully impassable.
- **Combat is readable (D63 pending).** Four actions on the face buttons in a
  diamond around a centre-framed target, lit by `suggestActions()`. Verified in
  a real fight against a real tuftmoth.
- **Hollowbrook is prebuilt Quaternius buildings (D62).** The pack bakes shading
  into its albedo (0.10-0.16 mean per channel against 0.48-0.67 for Kenney), so
  every job from it bakes through a gamma of 0.4 or it renders as silhouettes.
- **Story bugs.** Orin replayed his whole introduction (starter choice
  included) on every talk; the starter was farmable by releasing your only pal;
  the Loamking offer granted the pal before asking, so "Leave it" gave it to
  you anyway; `victory:` and `recruit:` effects were dropped while a test
  asserted they were valid.

## Known gaps, honestly stated

**Performance is over budget near the new village buildings.** Measured at
1280x720: 11.9 to 13.7ms frame time within about 7m of the four Quaternius
buildings, against an 8ms budget, and 154 to 171 draw calls against a ceiling
of 150. Open meadow is fine (3.0 to 3.4ms, 132 draws). The buildings are 5,700
to 7,800 raw triangles against 760 to 2,840 for the Kenney composites they
replaced. Already tried and did NOT close it: simplify at ratio 0.4, and
dropping shadow casting on village houses. The models ship flat shaded with a
unique vertex per face, so the simplifier has no shared topology to collapse
and an error sweep from 0 to 5.0 plateaus. Best current theory, reached by
elimination rather than proof: main pass fragment overdraw from these
buildings' own open architecture (stilts, overhangs, see-through archways).
Suggested next steps: normal-smoothed LOD proxies, or pick less open models
for the slots nearest the player. Recorded in D62.

**The starter trio is spread along the wrong axis.** The picker works and the
creatures are visible, but they line up in depth rather than left to right, so
the third card's creature sits partly behind the card row. `starterPicker.json`
is tuned as far as data alone goes; fixing it properly means changing the
placement code in `src/ui/starterPlacement.ts`.

**The gamepad fix has never been tested on real hardware.** There is no
physical pad in this environment. It is proven only by unit tests over the
selection function and a mocked dual-pad enumeration. The `?stats=1` overlay
now prints the chosen pad id and flags a non-standard mapping, which is the
first thing to read if the owner reports it still broken.

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
