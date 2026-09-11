# Abandoned Ranger Camp arrival pass — 2026-09-11

## Status

**Final honest grade: POLISH (improved, not closed).** The production capture
is complete at **6/6 frames with 0 failures**. The new lens makes the actual
spur and camp activity legible from the ordinary arrival, and the fire gives
the night approach a clean destination. The daytime arrival still reads as a
small low camp rather than a commanding abandoned shelter before the label,
so this evidence does not support PASS.

## Authored correction

- Added one overlapping r9 approach lens centered at `(-249.5,2251.5)`; it
  contains the real resolved camera at roughly `(-242,2247)` and overlaps the
  established camp r15 clearing rather than forming a second broad opening.
- Added one installed patched-canvas tent, pitched 68 degrees with slight roll,
  as a collapsed shelter on the approach side. It is 8m+ from the functional
  rest/craft points and ranger-spur centerline.
- Preserved every existing prop, the fire, rest/crafting offer, creature bed,
  and walked spur.

## Validation before capture

- `test_ranger_camp_approach_identity.gd`: **2 tests, 12 assertions, 0 failed**.
- `test_band_content.gd`: **6 tests, 1,431 assertions, 0 failed**.
- Combined: **8 tests, 1,443 assertions, 0 failed**.

Dedicated evidence script:
`tools/capture_ranger_camp_arrival_identity.gd`, using the production Meadows
scene for ordinary arrival, camp standing, and collapsed-shelter day/night pairs.

## Production evidence review

- `01-spur-arrival-day.png`: **POLISH**. The walked spur is open and the camp
  furniture is visible at the end, but the low shelter silhouette does not yet
  separate strongly from the ground cover at this distance.
- `02-spur-arrival-night.png`: **PASS for destination readability**. The fire
  creates a clear warm endpoint and the open lens holds a navigable approach;
  the wider frame remains very dark outside that focal pool.
- `03-camp-standing-day.png`: **PASS**. Fire, workbench/anvil, log seating and
  collapsed canvas resolve as one coherent abandoned work camp while the road
  and interaction area remain unobstructed.
- `04-camp-standing-night.png`: **POLISH**. The fire and functional center read
  cleanly, but the collapsed canvas is nearly black and loses its patched-kit
  material identity.
- `05-collapsed-shelter-day.png`: **FAIL as shelter proof / valid incidental
  defect evidence**. Two foreground trunks dominate the composition and the
  low canvas does not resolve as the named subject. This is a capture/composition
  weakness, not evidence that traversal is blocked.
- `06-collapsed-shelter-night.png`: **FAIL as shelter proof** for the same trunk
  occlusion, compounded by low exposure. The camp fire still provides a useful
  directional landmark in the distance.

Exact evidence directory:
`ralph/reports/BROAD-VISUAL-0910/RANGER-CAMP-ARRIVAL-IDENTITY/`.

## Ranked remaining fixes

1. Give the abandoned shelter one taller broken support/crossbar or lifted
   canvas corner visible from the ordinary spur; retain the current footprint
   and keep it outside the rest/craft circulation ring.
2. Add a restrained warm fill or material lift to the collapsed canvas so its
   shape survives night exposure without flattening the forest mood.
3. Reframe any future dedicated shelter proof away from the two foreground
   trunks. They document a real obstruction in that viewing pocket, but do not
   represent the clearest walked-road arrival.

No creature, rest, crafting, encounter, road, or interior behavior was changed.
