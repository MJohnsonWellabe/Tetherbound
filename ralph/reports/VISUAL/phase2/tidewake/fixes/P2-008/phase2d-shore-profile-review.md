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
- Before: original production `p2008-dunes-04-before-locations` and `p2008-dunes-04-before-routes`. Current candidate: `p2008-phase2d-duneridge01-locations` and `p2008-phase2d-duneridge01-routes`.

All eight pairs are native 1920×1080 day captures at seed 2042. Both before and after manifests are complete with no frame failures. Requested positions and player XZ coordinates match exactly; maximum horizontal camera drift is 0.000252 m. Ground/camera Y changes by at most 7.210 m because the physical shore was graded. The Brine Steps walk03 image has a player standing in the shallows in both versions; it is not a traversal acceptance frame.

## Work and checks

- Broadened eleven ordinary-island beach profiles to 16–32 m with 4–8 m inner coastal height; Veilfall stays on its mountain profile. Rebaked all 31 Terrain3D regions. The final bake manifest SHA-256 matches `water_world.json`.
- Enabled the pale sand/mineral treatment and sage/straw dune-grass cover. The fuller tuft has twelve pointed leaves and four basal blades, with bare gaps and sparse pioneers.
- Regrounded 138 changed authored encounter elevations to the physical rebake; moved Brine Steps wild site 008 by 7.62 m from a 47.3° face to a supported 13.36° position. Twenty-one other unchanged site centres now exceed the old 28° authoring target but remain below the 45° player floor limit. Runtime footprint admission remains authoritative; the scene encounter smoke passed, but it does not exercise every wild site.
- Analytic main-route grades are unchanged from the original config; Drowned Garden's three 38.99° samples are pre-existing. `test_water_heightfield`, `test_water_shellwatch_segment`, `test_water_encounter_runtime_data` pass together: 29 tests, 13,348 assertions. `test_water_dune_cover`: 8 tests, 132 assertions. `smoke_water_scene_encounters`: 40 checks, zero failures. `smoke_water_loops_shortcuts --case=brine_terrace_circuit`: 26 checks, zero failures or defects; 666.5 m walked on baked ground. An earlier uncorrected full-loop run was interrupted after the Reedhaven loop when the Brine site was found; it is not cited as a pass.

No claim is made for regional completion, motion quality, the full loop/shortcut matrix, every encounter site or chapter acceptance. Remaining broad dune faces and the full art-bar failures are visible in the paired evidence for the owner's call.

## Ongoing iteration after the failed full-art verdict

The full-art and reference verdicts above remain **NO/PARTIAL**. A second material pass now uses an original wind-ripple sand source with triplanar terrain sampling. Native four-location and four-route captures are in `.artifacts/phase2/p2008-phase2d-sandtex03-locations` and `.artifacts/phase2/p2008-phase2d-sandtex03-routes`. The first two texture captures (`sandtex01`/`sandtex02`) lacked a Godot import, so they are invalid comparisons; the third capture loaded the texture and had no shader/script errors. Shellwatch and Gull Rest now show readable foreground sand ripples. Distant dune faces, Veilfall, ecological layering and landmark depth still fail the full art bar. This is progress evidence, not a new pass claim.

The next native eight-view candidate is `.artifacts/phase2/p2008-phase2d-grassgap01-locations` and `.artifacts/phase2/p2008-phase2d-grassgap01-routes`. It adds more exposed sand between slightly darker beach-grass colonies. Veilfall's far visual mesh now has three local crag crowns and a less washed-out rock tone, leaving its physical heightfield and waterfall sampling intact. The First Shore route frame shows a clearer twin-peak destination silhouette; it is still a simple dark mass beside the board's layered white-falls mountain. Gull Rest and Shellwatch foreground transitions improve, while Sluice Isle remains a broad smooth sand wall. All eight manifests completed with no frame failures or script/shader errors. Focused tests: `test_veilfall_far_crag_presentation.gd` 3 tests/19 assertions; `test_water_dune_cover.gd` 8 tests/132 assertions; both zero failures. **The reference match and Bars A/B still do not pass.**

The current eight-view candidate in the paired gallery adds bounded, wind-aligned height relief to ordinary island interiors. Coast shoulders, summits, Veilfall and route rest shoals retain their heights. All 31 Terrain3D regions were rebaked; the bake manifest matches the builder, world config and heightfield source hashes. Sixty encounter/site elevations and associated wild-site slopes were regrounded. Gull Rest has a more readable crest; Sluice gains some layering and nearby trees, but the huge nearly white face remains the strongest failure. The revised heightfield test passes 15 tests/11,041 assertions, scene encounters pass 40 checks, and the baked Brine terrace walk passes 26 checks over 666.6 m with no falls, teleports or health loss. These checks support physical consistency; they do not establish visual acceptance. **The owner-photo match remains partial and both full game art bars remain NO.**
