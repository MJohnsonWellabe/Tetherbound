# Blind critique — the five download-page frames (2026-08-09)

A blind sub-agent judged `shots/site/` (hero-meadow, village-square,
opening-bedroom, starters-by-the-door, camp-dusk) against the key art and the
five Palworld references, per `.claude/skills/visual-judge`. It was told
nothing about what had just changed. Both bar questions came back **no**.
This file is the record; the actionable half either got fixed the same day or
lives in `ralph/BACKLOG.md`.

## The verdict, condensed

Top three separators from the references, ranked:

1. **The mid-ground is empty and the world ends ~40m out.** Every reference
   fills every distance band; these frames have detailed ground in front,
   bald pale hills behind, nothing on any horizon. "This, more than any
   asset, is why the frames read as a test level."
2. **The creatures are not one style and are not staged as the point of the
   game.** The three starters read as three different store packs (the tank
   photo-real, the axolotl toy-gloss, the bird a third finish), and the only
   creature frame shot them from behind against a blockout wall. No frame
   had a trainer and a creature together. "The trainer is the best asset in
   the build — and his style matching the key art proves the creatures miss
   it."
3. **The palette contradicts the art direction.** Crimson canopy dominated
   the hero frame where the key art is green-oak country with red held back
   as an accent (and red is supposed to be reserved for Team Tether);
   the two ground greens (dark olive detail vs pale lime hills) split at a
   hard visible seam; saturated lime strips outshone every intended subject.

Bar A (belongs to the key art's world): **no** — windmill, hill language and
the trainer carry it partway; groves, streams, warm settlements, horizon
landmarks and day/dusk/night moods are absent, and the red canopy contradicts
the palette. Bar B (same kind of game as Palworld, shown side by side):
**no** — "one is a shipped creature-collector and the other is an engine test
with some creature assets dropped in."

## Fixed the same day (scene-level)

- Camp frame now actually shot at dusk (low warm sun) instead of the same
  noon sky as every other frame.
- Starters restaged: shot from the door side so all three face the camera
  with meadow and sky behind their silhouettes, trainer standing with them —
  and the wall-corner texture artefact left the frame with the old angle.
- Red-canopy twisted trees thinned from 38 to ~16 and unclumped from the
  spawn (`vegetation.json` grove layer): red back to being the accent.
- (Earlier, same session, own-eye pass: debug HUD out of the frames, the
  79-degree "crater wall" pad skirts flattened to embankments.)

## Standing work it maps to (already queued)

- Full per-asset blind review including creature style cohesion → **R0.8.5**
  (this critique is input to it, not a substitute for it).
- Humanoid GLB regeneration → R3.0. Tuskroot's real model → R4.5.
- Day/night moods → R5.1. Wayfinding/landmark polish → R7.1. Villagers and
  interior dressing → R7.2.

## Newly queued from this critique

- Continuous ground cover instead of isolated tufts, and scatter clustering
  with real clearings (the "confetti" note) → R7.1 note added.
- The olive-detail vs lime-hill material seam (texture fade distance) →
  R7.1 note added.
- Creature style unification decision (rework vs replace mismatched
  starters) → flagged inside R0.8.5's remit; a fundamental art decision the
  owner has to make on R0.8.5's evidence, not silently.

## Notes on two of its claims

- "The bed is a child's bed": measured, the bed is 2.13m long at its applied
  scale — the critic's read was perspective (trainer nearer the camera).
  Kept as-is.
- "Raw pink/tan cubes lying in the grass": those are the harvest-node and
  camp placeholder meshes — real game objects that read as debug primitives
  in a still. They are placeholder by design today; they will stop being
  placeholders when gathering gets its art pass (R2.x).
