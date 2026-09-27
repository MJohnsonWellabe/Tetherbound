# Independent revised Meadows grass review

Date: 2026-09-27. Code-blind visual review. All 12 native 1920x1080 PNGs in `D:/tetherbound/visual-acceptance/shots/grass-normals-balanced/region/meadows` were opened. No source, diffs or engine used; no production files edited.

## Decision

**The revision resolves the earlier excessive pale-wire appearance in the two grass-rich daylight views, but I would not retain this exact revision as an overall improvement over the original baseline.** Its daytime hierarchy is somewhat calmer at the village and Ironwood. The corresponding night views trade that benefit for dark blade groups that merge into shadow, and the quarry daylight tufts still look conspicuously pale. This is a mixed result with local regressions, not a rendering failure.

The comparison is against the original baseline included in this packet. The earlier brighter candidate was reviewed in the preceding task; it is not used as a lower acceptance standard. Improvement over that rejected candidate alone is insufficient.

## Pair preferences

Scores are ordinal visual preferences: -2 clear baseline, -1 slight baseline, 0 practical tie, +1 slight revised candidate, +2 clear revised candidate. They are not numerical acceptance tests.

| Stand / time | Baseline / revised IDs | Score | Native-frame evidence |
|---|---|---:|---|
| Lower Meadows village, day | 001 / 002 | +1 | Revised blades across the foreground and right of the trainer are greener and less pale. They compete less with trainer/buildings, and broad dirt routes keep their separation. Cover still reads as isolated ribbons and tufts, so the improvement is modest. |
| Lower Meadows village, night | 003 / 004 | -1 | Revised grass behind the bare foreground shrub and around the trainer becomes notably darker, with more near-black tuft silhouettes against the already dark turf. It is quieter, but loses useful blade/ground separation. White flower heads become relatively more detached and prominent. Trainer and inn exposure remain stable. |
| Stone/root quarry, day | 005 / 006 | -1 | Revised thin straw-colored tufts immediately left of the trainer, beside the right boulder, and across the upper-left slope still have more conspicuous continuous pale faces than baseline. The foreground is sparsely planted, so these brighter line clusters read individually rather than as a coherent planted mass. This failure case is not solved merely by the better green-grass views elsewhere. |
| Stone/root quarry, night | 007 / 008 | 0 | Sparse cool blade lines, dark turf, fence, trainer and lamp retain essentially the same hierarchy. Small changes do not demonstrate a useful gain. The already dark approach is not repaired, but no material additional readability loss is established from this pair. |
| Upper Meadows Ironwood, day | 009 / 010 | +1 | The dense right slope and foreground lose the previous candidate's near-continuous pale network. Relative to baseline, the revised green blades also sit somewhat more quietly beneath the trainer, creature and flowers. Left-of-creature/tree-root shadow groups become darker; daytime ground remains readable, but this is a tradeoff rather than uniformly better shading. |
| Upper Meadows Ironwood, night | 011 / 012 | -1 | The most useful shadow witness. Revised grass below the left trees, around the creature and across the center/right field becomes a patchwork of near-black clumps with occasional cool tips. Baseline is wire-like but preserves more continuous information about the cover. The revised image makes the pale flowers and left diagonal route stand apart more sharply from vegetation. Trainer remains recognizable; this is loss of vegetation/ground coherence, not disappearance of the trainer. |

## What improved and what still fails

The earlier dense pale-wire regression is visibly reduced at village002 and Ironwood010. This is a real local benefit; it should not be dismissed because the overall retention decision is negative. Trainer/path separation in those daylight pictures is at least preserved and slightly less distracted by bright blades.

However, the successful daylight suppression does not carry through as equally successful shadow presentation. Village004 and Ironwood012 show less readable blade groups and darker clump silhouettes over turf. Ironwood010 already hints at this around the left tree roots. Simply making vegetation quieter is not sufficient if the result separates into black tufts and bright flower heads. Quarry006 also retains the pale-line problem on its finer, straw-colored grass.

No broad whole-frame lighting regression is visible: sky, building surfaces, boulders, tree canopies, trainer exposure and practical lights retain their appearance across each pair. No new route obstruction or decisive trainer silhouette failure is established. The concern is localized material/value coherence in grass and shade.

The underlying grass shape, spacing and coverage still read as repeated isolated ribbons rather than the reference's integrated natural masses. Both variants retain mottled turf, prominent repeated flower disks and inconsistent density transitions. Those are visible residuals, not claims about source causes.

**Retention answer: no, not as a finished Meadows improvement over baseline across the sampled day/night conditions.** Two slight revised-candidate preferences, three slight baseline preferences, and one tie express the tradeoffs above. This verdict does not request another small adjustment round.

## Bar A and Bar B

Reference basis reused from the same continuous image-review session: `docs/design/ART_DIRECTION.md`; `docs/reference/tetherbound-meadows-keyart.png`; `palworld-01-boss-fight-forest.jpg`, `palworld-02-open-field-path.jpg`, `palworld-03-field-boss-meadow.jpg`, `palworld-04-plateau-landmark.jpg`, and `palworld-05-base-building.jpg`. The relevant standard is vibrant natural cover arranged into readable masses, routes and clearings, with coherent materials and legible shade.

**Bar A identity: open / partial.** Meadows warmth, green cover, blue distance and village character survive. The revision does not establish the composed, naturally grouped ground cover of the keyart.

**Bar B finish: open / below target.** Daylight improvement is too small and inconsistent across grass/shadow appearances to close the finish gap. Native stills retain obvious ribbon/tuft repetition and the darkness-versus-pale-line tradeoff. This is not whole-region, whole-game or chapter acceptance.

## Scope and limitations

Capture metadata discloses staged location/party/flags/clock, hidden HUD, and a companion parking fixture. The visible creature at Ironwood remains part of the scene; the metadata does not establish its role. The skipped Meadowhart dynamic-location record is not a missing member of these six selected pairs. Cameras match within the packet.

These are still images. Small blade/flower pose changes cannot establish altered geometry or animation. No motion stability, shimmer, camera-travel, combat, performance or ordinary gameplay claim is made. The revised packet covers Meadows only; no conclusion about revised Cloudreach/Stormwood behavior follows.

## Exact native images inspected

- `001_meadows_place_grass_review_env_band1_lower_meadows_0_day_baseline.png`
- `002_meadows_place_grass_review_env_band1_lower_meadows_0_day_candidate.png`
- `003_meadows_place_grass_review_env_band1_lower_meadows_0_night_baseline.png`
- `004_meadows_place_grass_review_env_band1_lower_meadows_0_night_candidate.png`
- `005_meadows_place_grass_review_env_band2_stone_and_root_0_day_baseline.png`
- `006_meadows_place_grass_review_env_band2_stone_and_root_0_day_candidate.png`
- `007_meadows_place_grass_review_env_band2_stone_and_root_0_night_baseline.png`
- `008_meadows_place_grass_review_env_band2_stone_and_root_0_night_candidate.png`
- `009_meadows_place_grass_review_env_band4_upper_meadows_ironwood_0_day_baseline.png`
- `010_meadows_place_grass_review_env_band4_upper_meadows_ironwood_0_day_candidate.png`
- `011_meadows_place_grass_review_env_band4_upper_meadows_ironwood_0_night_baseline.png`
- `012_meadows_place_grass_review_env_band4_upper_meadows_ironwood_0_night_candidate.png`
