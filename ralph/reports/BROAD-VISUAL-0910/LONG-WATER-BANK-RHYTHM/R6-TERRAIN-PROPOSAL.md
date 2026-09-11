# The Long Water — R6 terrain repair proposal

Status: **ACCEPTED SHIPPABLE POLISH IMPROVEMENT / NOT PASS**. R5 dressing was
rejected and fully reverted to accepted commit `b7c058a47` before this work.

## Root cause

`playground_heightfield.gd::_river_carve()` subtracts one cross-section from
the terrain for each polyline segment. At The Long Water, `half_width` and
`rim` interpolate smoothly for roughly 250m. The existing smoothstep keeps the
wall safely too steep to climb, but its inner and outer thresholds remain
parallel to the course. Terrain3D then bakes this same height function into the
visible mesh and collision; `river_factor()` separately paints/excludes scatter
against the same nominal thresholds. This is why prop passes cannot break the
uninterrupted pale value line: it is the terrain silhouette itself.

## Smallest safe R6

Add optional per-course-point `bank_wobble_m`. Only Long Water indices 4, 5 and
6 receive amplitudes (2.4m, 3.5m, 0.5m); Old Mill indices 7–10 remain zero.
The heightfield converts the map's existing smooth 14m edge-noise field to a
positive-only metre offset and translates the complete bank smoothstep outward.
This changes the toe/top plan silhouette without changing `rim`, depth, or wall
slope. Positive-only displacement is important: the fixed water mesh can reveal
small carved toe shelves, but can never extend over uncarved ground.

The same edge displacement is applied in `river_factor()`, keeping terrain
paint and scatter exclusion aligned. `river.gd` adds the maximum endpoint
amplitude to recovery-volume width, ensuring widened pockets remain covered by
the existing village-side failsafe.

Owned static candidate:

- `data/config/terrain_playground.json` — localized amplitudes and binding rationale.
- `scripts/world/playground_heightfield.gd` — carve/cache/factor edge displacement.
- `scripts/world/river.gd` — recovery-volume coverage.
- `tests/test_long_water_visual_identity.gd` — behavioral guard.

## Gameplay, collision, navigation

- Terrain mesh and Terrain3D collision are generated from the same heightfield,
  so there is no separate decorative collision surface to drift.
- Bank slope is preserved rather than gentled. The new test samples five hero
  stations and requires every wall to remain at least 48 degrees, above the
  player's 45-degree floor limit.
- Old Mill's bridge/narrows geometry is untouched and explicitly asserted zero.
- Water width is unchanged; only the bank moves outward. This cannot create a
  dry ford across the channel.
- Recovery boxes grow with the maximum possible wobble, and still return the
  player to the village side. No navigation mesh is authored for this terrain;
  ordinary player movement continues to use Terrain3D collision/ground queries.

## Validation route

Static checks: JSON parse and `git diff --check` are clean. Once the renderer is
released, run:

1. `test_long_water_visual_identity.gd` (edge variation, Old Mill isolation,
   slope gate, existing identity contract).
2. `test_band_content.gd` (split-config integrity).
3. `test_river_crossings_stay_open.gd` and `tools/_probe_river.gd` (crossing and
   whole-course traversal/failsafe regression receipts).
4. Existing eight-frame Long Water day/night production capture, preserving the
   accepted R3 axis cameras and using the direct pair to inspect the real bank.

Acceptance bar: the far bank must visibly wander in 01/03/05/07, no water may
sit on uncarved ground, Old Mill must remain aligned, no new ford may appear,
and no foreground trunk may obstruct the proof. If the terrain still reads as
an engineered canal, revert R6 and retain R3 rather than shipping complexity.

Current static/runtime receipts before production capture:

- Long Water identity: **3 tests, 116 assertions, 0 failed**.
- River recovery/crossing contract: **5 tests, 42 assertions, 0 failed**;
  Old Mill retains 4.94m minimum deck clearance.
- General Meadows heightfield: **15 tests, 90 assertions, 0 failed**.
- Heightfield cost/cache: **3 tests, 8 assertions, 0 failed**.
- Repaired `tools/_probe_river.gd`: weakest full-course wall **68.6 degrees**,
  Long Water authored station **75.3 degrees**, Old Mill narrows **81.1–82.8
  degrees**. The probe had still filtered against the obsolete +-240m test
  square and therefore returned `inf`; it now uses authoritative
  `world_bounds` and excludes only the configured end-fade reaches.

## Production result

The authoritative 64-region bake exited 0. Because the change is localized,
only `manifest.json`, `terrain3d-01_08.res`, and `terrain3d-02_08.res` differ
from HEAD. The freshness guard passes after the bake.

Windows OpenGL production capture exited 0 with **8/8 frames and 0 failures**
at 2026-09-11 06:13:50–06:14:03:

- `01-axis-arrival-day.png` / `02-axis-arrival-night.png`
- `03-overlook-west-day.png` / `04-overlook-west-night.png`
- `05-overlook-east-day.png` / `06-overlook-east-night.png`
- `07-bank-wander-day.png` / `08-bank-wander-night.png`

Honest grade: **POLISH, improved, not PASS**. Frame 05 now shows the far bank
bulging and receding asymmetrically along the water's long axis; 07 directly
shows the toe/top silhouette wandering without water on uncarved ground. The
extended corridor identity from R3 survives. The pale bank material/value is
still uniform and the wall remains necessarily sheer, especially in 01, 03
and 07. The near-bank bright rock cluster also competes in 03/05/07. These are
remaining commercial gaps, not reasons to discard the genuine landform gain.

Owner review independently inspected all eight frames and accepted the R6
geometry as a real POLISH improvement. It specifically retains 05/06 and 07/08
as proof of asymmetric curve/recession with no water-on-ground, crossing, or
traversal regression. The next blocker is the uniform pale steep-face palette.
