# The Long Water visual identity — 2026-09-11

## Result

**POLISH, not PASS.** The named reach now has an authored, open view and a deliberate
two-bank rhythm, but the inherited river carve still presents a long pale, uniformly
textured opposite wall. Correcting that wall completely requires a terrain/bake pass;
this bounded location pass does not weaken the impassable chapter gate or claim that
the remaining canal read is gone.

## Player-visible change

- Added a 23 m sightline clearing at the published `the_long_water` region centre.
  Grass and flowers remain; repeated full tree trunks no longer erase the water in the
  bank composition.
- Added one asymmetric three-stone overlook crown on the south rim, two separated
  near-bank shelves, and three irregular far-rim shelf beats.
- Added tall/low clumps from the installed nature family along both rim tops. The
  middle of the channel remains clear and the work does not touch Old Mill Crossing.
- Rejected the first shelf scale as too subtle. The retained third-round candidate
  deep-seats the shelf rocks into the bank so they read as outcrops and keeps the reed
  clumps on the rim tops. It is an improvement, not a complete terrain replacement.

No creature mesh, Meshy generation, water shader, river depth, river width, crossing,
or traversal rule changed.

## Evidence

- Production location frames:
  `shots/locations/19-long-water-approach-day.png`
  `shots/locations/19-long-water-bank-day.png`
  `shots/locations/19-long-water-approach-night.png`
  `shots/locations/19-long-water-bank-night.png`
- Capture command: Godot 4.7 Compatibility renderer, 1280x800,
  `tools/_capture_locations.gd -- --only=19-long-water --fast`.
- Capture result: 4 frames written, 0 failed; 19/18 nearby creatures reported at the
  approach/bank; process exited normally with code 0.
- Focused structural test on the retained candidate:
  `test_long_water_visual_identity.gd`: 2 tests, 82 assertions, 0 failed.

## Honest remaining gaps

- The opposite bank's base terrain remains a straight pale cut with repeated texture.
  Props can interrupt its silhouette; they cannot replace the heightfield surface.
- Night exposure is still too dark to make the overlook a reliable night landmark.
- The accepted production grade remains POLISH. The frame now has visible stone/reed
  rhythm, but the crown is not yet a strong hero silhouette and the pale far wall still
  dominates the composition.
