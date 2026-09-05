# Cloudreach environment correction — 2026-09-04

## Round 2 — 2026-09-05

The new candidate evidence is in `round2/`, preserving the first-round survey and
its blind verdict. This is **not a visual acceptance claim**. The current broad
geological silhouettes still need art-direction review, especially the ravine and
counterweight-exit views; see `round2/IMPLEMENTATION.md` for exact changes,
verification, performance, and the residual work.

## Round 1

This checkpoint repairs the generated world's surface construction and records a
new ten-frame environment survey. It does not claim final visual acceptance,
completed Fly evidence, a playable final confrontation, or an end-to-end chapter.

The decisive defect was clockwise winding. The original generated crowns and
trail ribbons produced downward normals in Godot and disappeared from above.
Ground cover remained visible, while inner cliff faces showed through the missing
ground. `test_cloudreach_environment.gd` reproduced the downward normal before the
fix and now protects both upward crowns and outward cliff walls.

The pass also adds rooted cliff bases, upper shelves and asymmetric buttresses,
broken distant crowns, a Cloudreach atmospheric delta on the production day
cycle, supported settlement terraces, complete cottage floors, footprint and
route exclusions for outdoor foliage, curved grass tufts, clustered flower/grass
masses, conservative tree placement, and slope-correct tree roots. The Galefoot
watchtower moves behind its cottage group and the courtyard gains supplies using
installed crate/barrel/paving props. Landmark visibility now ends before its
supporting geology, avoiding distant architecture floating above culled land.

Realm Gate Crag and the summit use installed Quaternius castle masonry meshes;
the summit also reuses the production Team Tether pylon. No new meshes, images,
external assets or creature assets were generated. The installed sources are:

- `assets/buildings/quaternius_castle/WallEntranceBricks.obj`
- `assets/buildings/quaternius_castle/SmallSquareTowerBricks.obj`
- `assets/buildings/quaternius_castle/TallWallBricks.obj`
- `assets/environment/team_tether/tether_pylon.glb`

All ten non-creature resource placements now instantiate the production daily
resource wrapper. Placements use the intended height or the nearest real path;
their original content coordinates remain node metadata. Sunleaf has an explicit
High Roost placement override so the nearest-path fallback cannot move a Fly-only
resource to the grounded summit. The two encounter-cycle Skyplume sources remain
excluded with creatures.

## Verification

- `tests/run_tests.gd -- --only=cloudreach_environment,cloudreach_world_data`:
  15 tests, 400 assertions, zero failures.
- `tests/smoke_cloudreach_foundation.gd`: PASS, six regions, twelve landmarks,
  five bridges, supported entry, procedural cover and all authored prop pockets.
- `tests/smoke_cloudreach_arrival_walk.gd`: PASS, continuous ordinary movement
  from the arrival through the western bend and level camp approach to Aila.
- `tests/smoke_cloudreach_environment.gd`: PASS, ten actual resource floor rays,
  Sunleaf retained in High Roost, clear candy courtyard and ten distant ranges.
- `git diff --check` on this pass's source/config files: clean.

## Evidence and limits

`tools/capture_cloudreach_environment_correction.gd` uses the production world,
player, spring arm and camera, with the environment-only HUD hidden. It positions
the player on the real authored surfaces and records rendering counters and
measured Windows frame time in `performance.json`. The machine is a GTX 1060 3GB;
these measurements do not establish ROG Ally performance. Contact-sheet images
are actual renderer captures, not generated concept art.

The final capture measured 338–2,460 draw calls and 3.51–9.22 ms per frame at
1280×720 on that GTX 1060, over 24 sampled frames per view. Primitive submission
ranged from 543,859 to 7,450,819. These short samples are a development checkpoint,
not a sustained traversal or target-device performance acceptance run.

The ten current frames cover arrival, Galefoot/lower cliffs, causeways, ravine,
High Roost from below, the shrine destination, upper settlement, final approach,
and the current final-arena space. The required Fly silhouette has no evidence in
this environment harness; its runtime owner must capture that interaction. The
final-arena frame shows current world construction only, not a working boss.
Interaction/HUD/dialogue evidence belongs to the companion Act I survey.

The counterweight exit stands 50 m below Cliffhold. Its direct preview still shows
the terrace's face rather than an identifiable settlement, even when the player
looks up. That failed sightline is retained in `05-upper-cloudreach-cliffhold`;
`08-upper-cliffhold-east-arrival` separately records the actual plateau-circuit
approach from the observatory side. The preview needs further composition work.

Broad flat plateau silhouettes, the simplicity of remaining landmark shapes and
the limited authored habitation outside the first settlements are still visible
risks. This report is implementation/test evidence, not the code-blind verdict.
The next visual decision must come from a fresh blind review of the contact sheet
against both references and the Cloudreach board, with creatures excluded.
