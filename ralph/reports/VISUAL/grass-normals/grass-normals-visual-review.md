# Independent grass presentation review

Status: complete combined Meadows, Cloudreach and Stormwood review. Image-only comparison, 2026-09-27. No production source, diffs or engine runs used.

## Scope and standard

All 12 native 1920x1080 Meadows PNGs in `D:/tetherbound/visual-acceptance/shots/grass-normals-paired/region/meadows` were opened, covering three stands in day and night, baseline and candidate. Frame IDs below are the numbered filenames in that directory. Metadata supplies matched cameras and staged location/party/flags/clock, HUD hidden and companion parked. This is a fixture-based still comparison, not normal gameplay acceptance. The visible creature beside the trainer at Ironwood is part of the captured scene; parking metadata does not establish its role. Meadowhart's dynamic-location metadata skip is not a missing member of these six pairs. Small blade/flower pose changes between captures are not evidence of geometry edits or motion quality.

Basis: `docs/design/ART_DIRECTION.md`, and previously inspected `docs/reference/tetherbound-meadows-keyart.png`, `palworld-01-boss-fight-forest.jpg`, `palworld-02-open-field-path.jpg`, `palworld-03-field-boss-meadow.jpg`, `palworld-04-plateau-landmark.jpg`, `palworld-05-base-building.jpg`. Desired ground cover forms coherent masses and clearings with readable routes and subjects, within vibrant natural color and legible light/shade. An isolated shader-looking difference is judged by the resulting picture, without attributing implementation.

## Meadows preference scores

Ordinal scale: -2 clear baseline preference, -1 slight baseline preference, 0 practical tie, +1 slight candidate preference, +2 clear candidate preference. Scores express visual preference, not acceptance measurements.

| View / time | Baseline / candidate IDs | Score | Evidence |
|---|---|---:|---|
| Lower Meadows village, day | 001 / 002 | -1 | Candidate reduces dark segments on individual blades, but the foreground on both sides of the trainer becomes a brighter pale-green wire pattern. Baseline grass sits more quietly beneath the buildings and trainer. Bare-earth routes remain readable in both. |
| Lower Meadows village, night | 003 / 004 | 0 | Cool blade values shift only modestly. Neither visibly changes the warm inn focal point, trainer silhouette or route. No convincing scene-level improvement. |
| Stone/root quarry, day | 005 / 006 | -1 | Candidate pale tufts left of the trainer and across the left hill are more conspicuous against olive ground. The more even blade lighting does not improve the patchwork of cover or approach readability. |
| Stone/root quarry, night | 007 / 008 | 0 | Grass remains sparse cool lines over dark ground. The foreground fence, trainer, large boulders and lamp retain their previous hierarchy. Night ground darkness is unresolved in both. |
| Upper Meadows Ironwood, day | 009 / 010 | -2 | Strongest witness: dense right slope and foreground become a near-continuous bright line network in candidate. Baseline has harsh dark blade bases, but candidate makes many more pale blades compete with the trainer and white flowers instead of reading as a soft planted mass. |
| Upper Meadows Ironwood, night | 011 / 012 | 0 | Some candidate blade faces look more continuous, but the same thin teal network remains against very dark turf. Trainer/creature separation and the pale diagonal route at left are materially unchanged. |

## Meadows decision

**Do not retain this candidate as a demonstrated Meadows grass-presentation improvement in its present appearance.** Daytime shading is more uniform along individual blades, but that benefit trades into increased pale-line clutter, clearest in 009/010. Three daylight pairs favor baseline; all three night pairs are practical ties. This is a modest local regression in visual hierarchy, not a catastrophic rendering failure.

No broad lighting regression is visible: sky, architecture, rocks, tree canopies, trainer exposure and practical lights keep their prior appearance. Trainer remains identifiable, and the established broad village paths remain open. The candidate does not meaningfully improve lower-body or route separation. It also does not resolve the underlying repeated isolated tufts, similarly prominent flowers, mottled ground, or generic coverage spacing visible in both sets. Those are picture-level residuals, not a source diagnosis.

Next visual target: keep blade faces coherent while lowering pale tip/face prominence enough that dense grass reads as a grouped green mass at gameplay distance. Acceptance witness is the same Ironwood day camera: trainer silhouette and a clear ground/route organization should take priority over individually bright blades; a nearby shaded stand and night pair must keep grass grounded without crushed patches. Motion and camera travel must then separately check temporal noise; stills cannot establish shimmer or its absence.

**Bar A identity: open / partial.** Meadows village warmth, green vegetation and blue distance remain recognizable and are preserved. Neither variant reaches the reference's composed natural ground-cover grouping. **Bar B finish: open / below target.** Thin repeated grass ribbons and flower disks over mottled ground remain conspicuous at native gameplay scale. The candidate is not a full polish pass. No chapter, earned-gameplay, combat, animation or performance acceptance follows from this packet.

## Cloudreach regional review

All 12 native PNGs in `D:/tetherbound/visual-acceptance/shots/grass-normals-paired/region/cloudreach` were opened. Same ordinal preference scale as Meadows. Additional reference basis, previously inspected: `docs/reference/boards-2026-09-06/cloudreach-sky-aviary-stronghold-board.png` and `cloudreach-cliffs-creature-roster-board.png`. This is a grass comparison, not a new cliff or landmark acceptance.

| View / time | Baseline / candidate IDs | Score | Evidence |
|---|---|---:|---|
| Gate/lower cliffs, Galefoot Waycamp, day | 001 / 002 | 0 | Grass is confined mostly to lower-left and distant edges. Minor blade shading differences do not change the broad open lawn, route or trainer hierarchy. |
| Gate/lower cliffs, Galefoot Waycamp, night | 003 / 004 | -1 | Candidate lower-left patch has many more pale mint faces against the dark green lawn; it attracts the eye more than baseline and reads less grounded in the surrounding night values. Same tendency on far-left grass. Architecture and trainer retain exposure. |
| Windscar Ravine, day | 005 / 006 | +1 | Candidate lifts the abruptly dark-looking blade groups across center/right and more consistently connects them to the lit grass at left. Ground cover reads more uniformly lit. It still has pale angular ribbons, black-looking bases and a bright distant edge strip; improvement is limited. |
| Windscar Ravine, night | 007 / 008 | 0 | The dense distant patch is slightly quieter in candidate, but foreground ribbons and dark bases remain prominent. No reliable improvement in trainer or route reading at whole-frame scale. |
| High Roost/Sky Shrine, day | 009 / 010 | 0 | Very little grass is visible, mostly on the distant back edge/right margin. Both frame compositions are dominated by columns and floor. Weak grass witness; stable whole-frame appearance. |
| High Roost/Sky Shrine, night | 011 / 012 | 0 | Same grass-coverage limitation. Trainer, blue/gold floor emblem, columns and sky retain their appearance. No useful grass improvement established. |

**Cloudreach retention: mixed, insufficient for a regional endorsement.** The Windscar day benefit is worth preserving as an appearance target, but this exact variant also worsens the visible night patch at Waycamp. Do not count two nearly grass-free shrine ties as successful grass acceptance. No broad sky, cliff, architecture or trainer lighting regression is visible; the identified regression is local grass prominence.

Acceptance witness: Windscar day should keep continuous, believable blade shading while Waycamp night grass stays subordinate to its buildings and trainer, without a conspicuous pale foreground patch. A second genuinely grass-rich shaded plateau view would be more informative than the shrine interior for regional confidence.

**Bar A identity: open / partial.** Airy blue distance, pale cliffs and green plateau identity remain; the grass change neither completes nor erases that identity. **Bar B finish: open / below target.** Sparse angular ribbons over smooth lawn and abrupt dense grass borders still do not establish integrated natural coverage at the reference's finish. No full Cloudreach acceptance.

## Stormwood regional review

All 12 native PNGs in `D:/tetherbound/visual-acceptance/shots/grass-normals-paired/region/stormwood` were opened. These are **Calm and Break phase pairs**, not day/night pairs. Additional previously inspected references: `docs/reference/boards-2026-09-06/stormwood-stormheart-tree-stronghold-board-a.png` and `stormwood-stormheart-tree-stronghold-board-b.png`.

Rain streak positions, gold path pulses and some creature poses vary between paired stills. These temporal differences limit attribution; they are not evidence that this candidate changes weather, paths or creatures. Nearby figures occlude some central ground in Cinder Verge/Glowmoss; a large blue creature obstructs the lower center in Conductor Run. Exposed ground at either side remains usable for the grass comparison. Metadata parking language does not override visible occluders.

| View / phase | Baseline / candidate IDs | Score | Evidence |
|---|---|---:|---|
| Cinder Verge, Calm | 001 / 002 | -1 | Candidate's small green blades are more evenly bright, especially the broad right-hand field and foreground sides. This adds a fine bright line layer among the already numerous pale flowers instead of creating a calmer forest floor. Trainer and left path remain readable. |
| Cinder Verge, Break | 003 / 004 | 0 | Difference is too small relative to dark ground and rain to establish a practical improvement. Neither version resolves the dark lower-body/ground relationship. |
| Glowmoss Hollows, Calm | 005 / 006 | -1 | Candidate tufts along both route margins are somewhat more uniformly bright yellow-green. The finer line clutter does not improve the relationship between ground, flowers and large dark trunks. Baseline is slightly quieter. |
| Glowmoss Hollows, Break | 007 / 008 | 0 | Both retain barely legible dark vegetation and a dominant gold path. Variation in path pulse/rain should not be scored as candidate lighting change. |
| Conductor Run, Calm | 009 / 010 | 0 | Small grass value changes at exposed sides do not materially alter the scene; creatures, broad dark trunks and gold routes dominate. Central foreground is substantially occluded. |
| Conductor Run, Break | 011 / 012 | 0 | Both remain dark, with grass as fine subdued strokes. No confident improvement in trainer/creature separation; occlusion and differing rain/pulses limit stronger claims. |

**Stormwood retention: no demonstrated benefit worth retaining as a regional grass improvement.** Two modest baseline preferences in Calm, four practical ties. Candidate does not catastrophically break lighting, but its more evenly visible blades do not make the cover more natural or the scene less noisy. Continuous forest-ground masses, quieter flower distribution and readable shaded subjects remain unresolved in both; these are observed appearance targets, not inferred implementation defects.

Acceptance witness: Calm Glowmoss should read as a coherent forest floor around a distinct route, with grouped cover rather than uniformly isolated little bright strokes. In a matched Break view, the trainer and nearby creatures should remain readable against that floor. A moving camera and weather-phase sequence are still needed before any temporal or normal-gameplay claim.

**Bar A identity: open / partial.** Purple storm atmosphere, large trunks, luminous path motifs and blue creatures remain recognizable. The exposed, finely speckled floor does not establish the sheltered, integrated forest identity of the boards. **Bar B finish: open / below target.** Repeated sparse tufts/flowers, dark subject loss in Break and dominating bright path bands remain. The grass candidate alone does not close these finish gaps.

## Combined bounded decision

**Do not retain the exact candidate as a global presentation improvement on this evidence.** Across all 36 native images / 18 pairs, there is one slight candidate preference (Cloudreach Windscar day), six baseline preferences (three Meadows day, Cloudreach Waycamp night, two Stormwood Calm), and eleven practical ties. These counts summarize the independently described judgments; they do not numerically prove a pass or failure.

The strongest decision witness is Meadows Ironwood day009/010: more uniform blade brightness produces a more distracting pale network. Cloudreach Waycamp night003/004 demonstrates that the same general appearance tradeoff can also occur at night. Windscar day005/006 supplies a real localized benefit, which should not be ignored, but it does not outweigh the repeated hierarchy regressions for a shared global change.

The visual target is coherent shading **and** restrained blade prominence. Preserve trainer silhouette, broad routes, village warmth, phase color and the successful Cloudreach cliff/sky separation. A revised candidate should first beat the three named witnesses, then be checked during camera travel for temporal noise and with ordinary gameplay framing. No animation, performance, earned play, whole chapter or whole-game claim is supported. **Bar A and Bar B remain separate and open in every reviewed region.**

## Exact native evidence index

All entries below were opened as native PNGs via image viewing, not judged solely from convenience sheets.

### meadows

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

### cloudreach

- `001_cloudreach_place_grass_review_env_gate_lower_cliffs_1_day_baseline.png`
- `002_cloudreach_place_grass_review_env_gate_lower_cliffs_1_day_candidate.png`
- `003_cloudreach_place_grass_review_env_gate_lower_cliffs_1_night_baseline.png`
- `004_cloudreach_place_grass_review_env_gate_lower_cliffs_1_night_candidate.png`
- `005_cloudreach_place_grass_review_env_windscar_ravine_0_day_baseline.png`
- `006_cloudreach_place_grass_review_env_windscar_ravine_0_day_candidate.png`
- `007_cloudreach_place_grass_review_env_windscar_ravine_0_night_baseline.png`
- `008_cloudreach_place_grass_review_env_windscar_ravine_0_night_candidate.png`
- `009_cloudreach_place_grass_review_env_high_roost_sky_shrine_1_day_baseline.png`
- `010_cloudreach_place_grass_review_env_high_roost_sky_shrine_1_day_candidate.png`
- `011_cloudreach_place_grass_review_env_high_roost_sky_shrine_1_night_baseline.png`
- `012_cloudreach_place_grass_review_env_high_roost_sky_shrine_1_night_candidate.png`

### stormwood

- `001_stormwood_place_grass_review_env_cinder_verge_0_calm_baseline.png`
- `002_stormwood_place_grass_review_env_cinder_verge_0_calm_candidate.png`
- `003_stormwood_place_grass_review_env_cinder_verge_0_break_baseline.png`
- `004_stormwood_place_grass_review_env_cinder_verge_0_break_candidate.png`
- `005_stormwood_place_grass_review_env_glowmoss_hollows_0_calm_baseline.png`
- `006_stormwood_place_grass_review_env_glowmoss_hollows_0_calm_candidate.png`
- `007_stormwood_place_grass_review_env_glowmoss_hollows_0_break_baseline.png`
- `008_stormwood_place_grass_review_env_glowmoss_hollows_0_break_candidate.png`
- `009_stormwood_place_grass_review_env_conductor_run_1_calm_baseline.png`
- `010_stormwood_place_grass_review_env_conductor_run_1_calm_candidate.png`
- `011_stormwood_place_grass_review_env_conductor_run_1_break_baseline.png`
- `012_stormwood_place_grass_review_env_conductor_run_1_break_candidate.png`
