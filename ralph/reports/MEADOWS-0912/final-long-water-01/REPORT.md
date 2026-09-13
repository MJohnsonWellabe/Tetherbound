# The Long Water final-01 independent review (2026-09-12)

## Verdict

**POLISH — retain the asymmetric-bank production state, but do not count a
location PASS.** The set now proves a long, navigationally memorable water
corridor at ordinary player scale, with a bend, wooded bank rhythm, route
adjacency, and a distant tower giving the eastward axis real depth. The opposite
bank remains a long, uniformly textured sheer cut, however, and the oversized
pale near-bank rock group competes with the water in three of the four bearings.
Those visible prototype traits keep The Long Water below the finished-location
bar.

## Evidence and production integrity

- `manifest.json` reports `complete: true`, no failures, and eight records. All
  eight native 1280x720 PNGs are present as four coherent day/night pairs.
- Recorded player stands, live ground samples, and `player_y` values agree: the
  player is held exactly 0.35 m above the sampled production terrain in every
  frame. Hero-distance and camera-distance values are present for every record.
- The disclosure is materially accurate. The reviewed harness instantiates
  `res://scenes/world/meadows_playground.tscn`, waits for the production shell,
  retains the ordinary player, Terrain3D, scatter, props, and encounters, applies
  authored day/night states, freezes clear weather and locomotion, and hides only
  HUD/submersion overlays. It adds an evidence camera and does not fabricate
  progression or encounters.
- The output helper requires a fresh destination before capture. The harness
  checks that the player remains on the sampled terrain but does not use a
  collision/occlusion `CaptureCheck` for the evidence camera. Native inspection
  finds no camera inside terrain or a solid. A few leaf tips enter the extreme
  upper-left of the arrival pair, but they do not obstruct the water/road read.

## Native-frame judgment

- `01-axis-arrival-day` / `02-axis-arrival-night`: valid ordinary approach
  proof. The road carries the right side while water runs beside it on the left,
  so this pair establishes route adjacency better than the older underframed
  location capture. The water is still secondary to the road and meadow, and
  the exposed opposite wall reads as one continuous engineered cut.
- `03-overlook-west-day` / `04-overlook-west-night`: open water and the wooded
  two-bank corridor remain readable with no trunk blocking the view. The three
  very pale, smooth near-bank rocks occupy the central player silhouette and
  become the strongest object group; their scale/material feel placed rather
  than integrated. The far wall's repeated face treatment is especially obvious
  in daylight.
- `05-overlook-east-day` / `06-overlook-east-night`: **PASS for this individual
  composition.** This is the set's strongest named-location proof. Water owns
  the frame, recedes through an asymmetric wooded bend, and terminates on a
  distinct tower silhouette. Road, roaming creatures, vegetation, and open
  country provide useful scale without displacing the water. Night retains the
  whole corridor and reflection cleanly.
- `07-bank-wander-day` / `08-bank-wander-night`: directly proves that water
  remains on the carved bed and that the bank edge now wanders modestly. It also
  exposes the remaining blocker most clearly: much of the far bank is a tall,
  near-constant-height strip with uniform pale face texture, while the bright
  rock group repeats on the right bank.

## Acceptance boundary

Final-01 is a genuine improvement over the earlier POLISH evidence: the long
axis is dependable, the eastward bend/tower sequence is strong, night is usable,
and no submitted view is invalid. It does not erase the earlier ledger concern
that the water reads partly as an engineered canal. A location PASS requires the
far-bank face to break into believable material and height intervals and the
near-bank stones to integrate into that geology rather than present as a pale
prop row. Until then, **POLISH** is the strict defensible grade.

## Review-only scope

This review adds only `REPORT.md`. It does not modify the manifest, PNG evidence,
production/config/source/test/capture files, Terrain3D data, generated scatter,
or staging state.
