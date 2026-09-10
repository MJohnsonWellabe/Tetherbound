# Settlement grounding 01 — physical completion and visual disposition

Date: 2026-09-09 CDT / 2026-09-10 UTC
Scope: shared village placement, nine Stormwood enterable-building foundations, real interiors and traversal, and the Still Grove doorway obstruction.

## Disposition

Keep the physically verified settlement work: collider-aware placement, nine blended terrain foundations, five completed cottage interiors, shared workshop furniture/light with a clear central aisle, and Fenn's move beside the Still Grove doorway. The current production traversal passes all nine buildings with their real player capsule, baked Terrain3D, doors/arches, floors and wall collision.

Do not claim a visual-bar win. Every blind settlement comparison returned either no meaningful preference or a mixed result with no convincing overall advance. The final TIMBER02 rear-wall lining candidate was valid geometry and passed its unit test, but its judge found no meaningful overall preference, so the three timber modules and their focused assertions were withdrawn. The candidate is preserved as `.artifacts/broad-visual-0910/SETTLEMENT-GROUNDING-01-TIMBER02-WITHDRAWN.patch` and is absent from current source.

## Measured defect

The original placement was not merely a poor camera angle. `village.gd::_place()` seated a building from the lowest of its render-AABB centre and four corners, while walkable floors sat higher inside the render bounds. It also sampled unscaled offsets. The first probe compared the shipped Terrain3D samples inside each actual support footprint against each walk floor:

| Enterable structure | Terrain above walk floor | Terrain relief in footprint |
| --- | ---: | ---: |
| Ashfoot shelter | 0.389 m | 0.339 m |
| Pools shelter | 1.220 m | 1.155 m |
| Rodline workshop | 3.220 m | 2.975 m |
| Rodline home | 0.740 m | 0.643 m |
| Still Grove shelter | 0.983 m | 0.910 m |
| Lantern Hollow inn | 0.925 m | 0.863 m |
| Lantern Hollow home | 0.419 m | 0.379 m |
| Lantern Hollow workshop | 0.956 m | 0.960 m |
| Ember shelter | 1.084 m | 0.975 m |

The measurement receipt is `.artifacts/broad-visual-0910/runs/stormwood-settlement-grounding-first`. Its numeric output remains useful, but the run is **not a passing test**: exit code 0 was accompanied by three wrapper-recorded errors (two empty resource loads and no active Terrain3D camera). Two attempts to correct that standalone Terrain3D fixture crashed with Windows access violation `-1073741819`: `stormwood-settlement-grounding-corrected-fixture` and `stormwood-grounding-native-diagnosis`. The crash was at the probe's Terrain3D initialization order, not production world traversal. `tools/_probe_stormwood_settlement_grounding.gd` therefore remains diagnostic-only and must not be cited as green validation.

## Current implementation

- `scripts/world/village.gd` applies placement scale to ground samples. Enterable buildings derive seating support from their authored ground-touching collider boxes, so roof overhangs and interior slabs do not lower the whole building. Decorative structures retain their render-AABB placement, and explicit `ground: "highest"` structures retain that contract.
- `scripts/world/stormwood_heightfield.gd` applies oriented settlement pads after the macro landform. Each pad has a flat room/doorway rectangle and a smooth 10 m return to the unchanged terrain.
- `data/config/terrain_stormwood.json` authors nine pads around the actual collider footprints plus a 3 m local `+Z` door/open-arch approach. Heights balance local cut and fill; they are not highest-corner floating replacements.
- `data/config/stormwood_settlements.json` marks the five reused ranger/cottage shells with real cottage interiors. The existing inn remains an inn interior; workshops retain their permanently open arches.
- `data/config/building_prefabs.json` gives `cottage_a` its measured room metadata and the shared 6 m by 8 m workshop its actual inner dimensions, 1.6 m clear aisle, floor height, installed Workbench/Anvil_Log/Prop_Crate dressing, measured collision bounds and warm light data.
- `scripts/world/workshop_interior.gd` builds those three installed props and their honest scenery collision. It adds no storage verb. All positions and light values come from the prefab room data.
- `data/config/stormwood_trainers.json` moves Fenn from the doorway to shelter-local `(-0.75, 4.5)`, world `(-178.4592194978723, 2706.5597586667554)`. Encounter id, group, party, dialogue/progression adapter fields and body collision remain unchanged.

The Fenn placement leaves 1.750 m between Fenn's centre and the player route through the real door. The two real capsule radii plus the test margin require 0.960 m (`0.36 + 0.40 + 0.20`). Fenn is 2.305 m from the doorway threshold, inside the 4.2 m challenge range; 2.222 m from the conductor road, inside the 30 m route contract; and 19.590 m from Ondra, beyond their combined 8.0 m prompt ranges. Fenn's whole capsule footprint remains on the flat shelter pad.

## Terrain and scatter outputs

The full terrain bake receipt is `.artifacts/broad-visual-0910/runs/stormwood-settlement-full-bake-first`:

- command: `--headless --script scripts/world/build_stormwood_terrain.gd`
- 108/108 regions completed in 159.95 s, process exit 0
- changed exactly the terrain manifest and six affected regions: `terrain3d-01_00.res`, `terrain3d-01_02.res`, `terrain3d-01_05.res`, `terrain3d-01_07.res`, `terrain3d-01_10.res`, and `terrain3d-02_04.res`
- **not clean**: the receipt records the same three setup errors as the old baker path—empty `res://`, empty resource load, and no active Terrain3D camera. Completion and file scope are recorded, but this is not represented as an error-free bake.

The scatter rebake receipt is `.artifacts/broad-visual-0910/runs/stormwood-pad-scatter-first`:

- command: `--headless --script scripts/world/bake_stormwood_scatter.gd`
- 108 regions, 1,244,185 bytes, 33,773 kept placements
- exit 0, no engine/script errors
- changed the scatter manifest and five affected bins: `region_-1_2.bin`, `region_-1_5.bin`, `region_-1_7.bin`, `region_-1_10.bin`, and `region_-2_4.bin`

`stormwood_scatter.gd::SOURCES` fingerprints settlements, terrain config, world config, heightfield and scatter source. It does not fingerprint `stormwood_trainers.json`, so the later Fenn move required no scatter rebake.

## Test and failure receipts

The test history is retained because two failures found real defects and two others found fixture/assertion defects:

1. `.artifacts/broad-visual-0910/runs/grounding-grass-unit-current`: 25 tests, 89,404 assertions, one failure. Two rotated 2 m lattice vertices had pad weights about `0.99985`. Reconstructing Terrain3D's bilinear surface showed the actual floor displacement was only `0.000001 m`; the implementation-weight assertion was replaced with a 1 mm physical-height tolerance rather than loosened arbitrarily.
2. `.artifacts/broad-visual-0910/runs/grounding-unit-physical-tolerance-first`: 3 tests, 1,819 assertions, zero failed, exit 0, no errors. This proves the real collider footprints, 3 m approaches, 2 m baked lattice and bilinear floor result.
3. `.artifacts/broad-visual-0910/runs/settlement-workshop-unit-first`: 3 tests, 1,843 assertions, one failure. The rotated crate reached the workshop wall. Moving it 0.05 m inward fixed the actual bound.
4. `.artifacts/broad-visual-0910/runs/settlement-workshop-crate-clearance-first`: 3 tests, 1,843 assertions, zero failed. This directory predates the final result wrapper and has console/engine logs but no `result.json`.
5. `.artifacts/broad-visual-0910/runs/settlement-cloud-cover-unit-first`: combined run, 5 tests, 1,854 assertions, zero failed, exit 0, no errors. Its settlement portion matches the current post-TIMBER02-withdrawal furniture/layout source.
6. `.artifacts/broad-visual-0910/runs/fenn-door-corridor-unit-first`: 6 tests, 35 assertions, zero failed, exit 0, no errors. It checks grounding/road reach, Ondra prompt separation, real doorway transform, player/NPC capsule clearance, prompt reach and pad support. The shared clearance loop covers every trainer within 10 m of every authored settlement door; currently Fenn and Pools trainer Ivo qualify.

The first production traversal, `.artifacts/broad-visual-0910/runs/stormwood-settlement-traversal-first`, failed seven door cases because the smoke looked for a literal `Gate/CollisionShape3D`. The production gate shape is an unnamed child and receives an automatic node name. The test expression also conflated a missing node with a disabled shape. The temporary production `village_door.gd` change made during that diagnosis was fully reverted.

The corrected smoke reads the door's production `_gate_shape` reference. `.artifacts/broad-visual-0910/runs/stormwood-traversal-shape-reference-first` proved all seven doors initially had `open=false` and `disabled=false`; eight routes passed. Both workshop arches passed with the first solid rear-wall hit 8.70 m deep, floor relief 0.099 m, inside local z 2.13 and side-wall stops at ±2.37. Still Grove alone stopped before the doorway. Its initial secondary side-wall failure was a consequence of never entering and is now skipped when entry fails.

`.artifacts/broad-visual-0910/runs/still-grove-contact-diagnostic-first` identified the actual blocker:

- collider: `/root/Stormwood/StormwoodTrainers/Fenn/Body`
- Fenn world position: `(-180.0, 35.7, 2705.0)`
- shelter-local position: `(1.155273, 0.049999, 3.415405)`
- doorway centre/threshold: local `(1.0, 3.0)`
- contact normal approximately `(+X)`; Terrain3D contact normal `(0,1,0)` showed sound ground support

After moving Fenn, `.artifacts/broad-visual-0910/runs/still-grove-fenn-beside-door-first` passed the selected shelter: floor relief 0.001 m, inside z 0.93, side-wall stop x 1.37, exit 0, no errors. Its console still contains the old hard-coded `9/9` success text even though one filtered structure ran; that stale receipt is disclosed. The smoke now tracks selected/expected counts.

The authoritative traversal receipt is `.artifacts/broad-visual-0910/runs/stormwood-all-nine-fenn-clear-first`: 69 s, exit 0, no errors, correct `9/9` summary. Every door begins physically closed, opens through the production door state, admits the real 0.4 m player capsule, supports the player on the room floor and stops lateral movement at a real wall. Both open workshop arches and all seven door buildings pass.

## Blind visual outcomes

No settlement comparison cleared the visual bar. These reports are retained without reinterpretation:

- `JUDGE-LANTERN-01.md`: no material preference between matched pairs. The judge saw a miniature-looking, disconnected settlement under oversized trees, no convincing routes or warm night focal point, and commercial quality below the supplied references.
- `JUDGE-RODLINE-PADS02.md`: mixed, with no convincing overall advance. One pair made the arch entrance more identifiable; the other retained a cleaner well base, more creature visibility and a less obstructive HUD. The more readable doorway did not settle the visual grounding problem.
- `JUDGE-RODLINE-WORKSHOP01.md`: no meaningful overall preference. A brighter doorway was a minor night-mood advantage only; ground coverage, depth, settlement authorship and material/lighting cohesion remained below the bar.
- `JUDGE-LANTERN-WORKSHOP01.md`: no meaningful preference. The workshop was not visually identifiable as a workshop at the catalogue distance, and the settlement still read as separated objects without paths or purposeful activity grouping.
- `JUDGE-RODLINE-TIMBER02.md`: no meaningful overall preference. The withdrawn brown timber patch gave the entrance slightly more material definition but did not improve the dominant scene composition, ground coverage, tree scale, depth or lighting/material cohesion. Neither pair met commercial visual quality.

The TIMBER02 candidate itself was physically coherent: three installed `Floor_WoodDark` slabs mounted vertically inside the rear wall, no new collider, 5 mm side margins, upper plaster retained. `.artifacts/broad-visual-0910/runs/workshop-wainscot-bounds-unit-first` passed 3 tests and 1,875 assertions with no errors. That receipt describes the archived candidate, not current source. The blind no-preference verdict is why it was withdrawn.

Current catalogue evidence may include frames captured while that visual-only timber candidate was present, notably `shots/catalogue/stormwood/broad-workshop-timber-rim01` and `.artifacts/broad-visual-0910/neutral-rodline-timber02`. Those frames are valid records of the judge attempt but are not exact images of the current rear-wall material state. Earlier `broad-workshop-dressing01` captures show the retained furniture/light state without the timber lining.

## Source and generated-file scope

Retained source/data:

- `scripts/world/village.gd`
- `scripts/world/stormwood_heightfield.gd`
- `scripts/world/workshop_interior.gd` and generated `.uid`
- `data/config/building_prefabs.json`
- `data/config/stormwood_settlements.json`
- `data/config/stormwood_trainers.json`
- `data/config/terrain_stormwood.json`
- `tests/test_stormwood_settlement_grounding.gd` and generated `.uid`
- `tests/test_stormwood_fenn_clearance.gd`
- `tests/smoke_stormwood_settlement_traversal.gd` and generated `.uid`

Retained generated data:

- `data/terrain/stormwood/manifest.json` plus the six region resources listed above
- `data/scatter/stormwood/manifest.json` plus the five region bins listed above

Diagnostic-only source:

- `tools/_probe_stormwood_settlement_grounding.gd` and generated `.uid`; retained for measurement provenance, not a passing validation tool

Withdrawn candidate archive:

- `.artifacts/broad-visual-0910/SETTLEMENT-GROUNDING-01-TIMBER02-WITHDRAWN.patch`

After the exact TIMBER02 withdrawal, JSON parsing, `git diff --check`, and `git apply --check` for the archived patch pass. No terrain, scatter, village placement, interior, trainer or collision behavior changed during the withdrawal.
