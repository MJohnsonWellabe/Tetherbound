# P2-008 — Phase 2d first-item pass report

## Issue and standard

**Queue item P2-008, shore landforms:** repeated green domes and steep, smooth gray rock skirts make Tidewake look like grassy islands instead of a layered sand-dune coast. Grass-to-sand transitions are weak. This item covers the eight recorded First Shore, Brine Steps, Gull Rest, Salt Crown, Shellwatch and Sluice Isle sightings. The owner's two supplied photos establish the dune-crest, open-water and grass-framed-path aesthetic. `docs/design/ART_DIRECTION.md` separately requires a Bar A identity comparison and Bar B polished-creature-adventure comparison against the local board and Palworld gameplay references.

## Verdict

| Question | Self-review verdict | Evidence |
|---|---|---|
| Does the pass resolve the recorded P2-008 gray-skirt/grass-to-sand defect? | **PASS at the eight catalogue sightings, pending owner review.** | Paired renders replace broad gray skirts and green carpet with graded pale sand, bare passages and upright beach-grass colonies. First Shore and Gull Rest read most clearly; Shellwatch and Sluice retain broad smooth slopes. |
| Do the renders fully match the supplied dune photos? | **PARTIAL.** | Sand colour, exposed crests, sea views and grass-framed routes align. Fine wind ripples, layered dune relief, natural grass variation and the references' light depth remain weaker. |
| Does Tidewake pass Bar A, its full regional art identity? | **NO.** | The shore language improves, but the region still lacks the board's layered shore detail and destination richness. Distant Veilfall remains a simplified gray mass in several frames. This item did not change Veilfall. |
| Does it pass Bar B or look like Palworld-quality gameplay? | **NO.** | Against `docs/reference/palworld-02-open-field-path.jpg` and the Tidewake board, material detail, ecological layering, landmark dressing, midground depth and creature staging are below target. No independent code-blind Bar A/B review has been performed. |
| Is the first item ready to count as a final visual pass? | **NO.** | The local defect improves, but the reference match and both game-level art bars fail. This remains an incomplete visual item. |

The pass fixes the specific gray-skirt symptom at the recorded views, but **P2-008 fails overall visual acceptance**. The owner requested review after the first queue item, so the other queue items remain untouched and P2-008 stays open on the board.

## Before / after evidence

- Full-resolution eight-pair gallery: `.artifacts/phase2/P2-008-phase2d-before-after.html`.
- Contact sheets: `.artifacts/phase2/P2-008-phase2d-before-after-locations.jpg` and `.artifacts/phase2/P2-008-phase2d-before-after-routes.jpg`.
- Before: original production `p2008-dunes-04-before-locations` and `p2008-dunes-04-before-routes`. After: final enabled build `p2008-phase2d-shore07-final-locations` and `p2008-phase2d-shore07-final-routes`.

All eight pairs are native 1920×1080 day captures at seed 2042. Both before and after manifests are complete with no frame failures. Requested positions and player XZ coordinates match exactly; maximum horizontal camera drift is 0.000252 m. Ground/camera Y changes by at most 5.486 m because the physical shore was graded. The Brine Steps walk03 image has a player standing in the shallows in both versions; it is not a traversal acceptance frame.

## Work and checks

- Broadened eleven ordinary-island beach profiles to 16–32 m with 4–8 m inner coastal height; Veilfall stays on its mountain profile. Rebaked all 31 Terrain3D regions. The final bake manifest SHA-256 matches `water_world.json`.
- Enabled the pale sand/mineral treatment and sage/straw dune-grass cover. The fuller tuft has twelve pointed leaves and four basal blades, with bare gaps and sparse pioneers.
- Regrounded 138 changed authored encounter elevations to the physical rebake; moved Brine Steps wild site 008 by 7.62 m from a 47.3° face to a supported 13.36° position. Twenty-one other unchanged site centres now exceed the old 28° authoring target but remain below the 45° player floor limit. Runtime footprint admission remains authoritative; the scene encounter smoke passed, but it does not exercise every wild site.
- Analytic main-route grades are unchanged from the original config; Drowned Garden's three 38.99° samples are pre-existing. `test_water_heightfield`, `test_water_shellwatch_segment`, `test_water_encounter_runtime_data` pass together: 29 tests, 13,348 assertions. `test_water_dune_cover`: 8 tests, 132 assertions. `smoke_water_scene_encounters`: 40 checks, zero failures. `smoke_water_loops_shortcuts --case=brine_terrace_circuit`: 26 checks, zero failures or defects; 666.5 m walked on baked ground. An earlier uncorrected full-loop run was interrupted after the Reedhaven loop when the Brine site was found; it is not cited as a pass.

No claim is made for regional completion, motion quality, the full loop/shortcut matrix, every encounter site or chapter acceptance. Remaining broad dune faces and the full art-bar failures are visible in the paired evidence for the owner's call.
