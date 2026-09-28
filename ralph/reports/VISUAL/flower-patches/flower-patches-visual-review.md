# Independent flower-patch presentation review

2026-09-27. Status: complete Stormwood and Meadows verdict. Code-blind image comparison. No production source, diffs, implementation rationale or engine runs used.

## Scope and reference basis

All 12 native 1920x1080 PNGs in `D:/tetherbound/visual-acceptance/shots/flower-patches-paired/region/stormwood` were opened. References previously inspected in this continuous review session: `docs/design/ART_DIRECTION.md`; `docs/reference/boards-2026-09-06/stormwood-stormheart-tree-stronghold-board-a.png` and `stormwood-stormheart-tree-stronghold-board-b.png`; `docs/reference/palworld-01-boss-fight-forest.jpg`, `palworld-02-open-field-path.jpg`, `palworld-03-field-boss-meadow.jpg`, `palworld-04-plateau-landmark.jpg`, `palworld-05-base-building.jpg`. The standard is readable natural vegetation groups with useful spaces between them, restrained detail around subjects/routes, and a rich forest identity.

These are matched staged positions, flags, party and weather phase with HUD hidden. Metadata says companion parked; the visible figures and creatures still occlude parts of the images. Weather/time advance between paired frames. Rain streaks, gold path pulse positions and creature poses differ and must not be attributed to the vegetation variant. Calm/Break are phase comparisons, not day/night.

## Stormwood decision

**Candidate is worth retaining as a modest, bounded improvement to flower distribution and scale in these Stormwood views.** It replaces some of the uniform field of equally prominent pale flower disks with smaller accents, local groups and flower-poor intervals. Grass, ferns, shrubs, mushrooms and scattered flowers retain a planted floor. The improvement is clearest at Glowmoss Calm005/006; it is not a whole-scene redesign or a complete forest-ground pass.

No consequential loss of biome identity is evident. Purple storm atmosphere, large trunks, luminous routes, ferns and blue creatures remain. Some purple floral richness is reduced, particularly beside the Glowmoss route, but the remaining local flower groups make that an acceptable tradeoff against repetitive foreground decoration in this bounded packet.

## Pair preferences

Ordinal scores: +2 clear candidate preference, +1 slight candidate preference, 0 practical tie, -1 slight baseline preference, -2 clear baseline preference. Scores summarize visual judgment, not an automated acceptance calculation.

| View / phase | Baseline / candidate IDs | Score | Evidence |
|---|---|---:|---|
| Cinder Verge, Calm | 001 / 002 | +1 | Candidate has smaller flower heads and visible changes in local concentration, with relatively flower-poor ground toward the tree/boulder group and flower clusters nearer the foreground sides. It is less evenly studded with large white-purple disks. The bottom-center patch still contains many isolated thin stems, so the grouping benefit is modest rather than comprehensive. |
| Cinder Verge, Break | 003 / 004 | +1 | The smaller, less uniform flower accents remain visible without becoming a repeated bright grid over the dark floor. Trainer silhouette and route remain usable to essentially the same degree. Heavy rain and existing darkness limit the whole-frame gain. |
| Glowmoss Hollows, Calm | 005 / 006 | +2 | Strongest witness: baseline's dense repeated flower disks along the lower-left edge and immediately right of the trainer recede into a mostly grassy interval in candidate. Small groups survive farther left and deeper around trunks. Ferns, shrubs and grass still provide layers, while route/trainer read with less decorative competition. |
| Glowmoss Hollows, Break | 007 / 008 | +1 | Candidate reduces repeated pale flower accents along both foreground route margins. It is calmer and the remaining cover still outlines the ground. It does not brighten or restore the dark trainer/lower terrain. Rain and path pulses prevent a stronger lighting conclusion. |
| Conductor Run, Calm | 009 / 010 | +1 | Exposed side ground has fewer uniformly prominent flower accents and a more localized grouping toward lower right. Fern masses and blue creatures remain dominant. Benefit is small; the large blue foreground creature blocks much of the central ground. |
| Conductor Run, Break | 011 / 012 | 0 | Ground-cover differences are too subordinate to dark values, rain, luminous paths and creature occlusion to establish a meaningful whole-frame preference. No visible loss of the route or remaining plant mass. |

## Residuals and regressions

No broad scene-lighting, trainer-exposure or material regression is evident from the paired stills. Routes remain unobstructed. This is a flower-composition change, and its useful effect is reduced decorative competition rather than improved illumination.

Candidate Cinder Verge002/004 still has many bare-looking vertical flower stems and pale heads across the lower foreground. Local concentration is better, but it does not yet read like botanically integrated leaf-and-flower masses everywhere. In both variants, repeated fine grass tufts and mottled soil continue to dominate the ground texture. The candidate does not repair those independent appearance issues.

Glowmoss006/008 loses some foreground purple color, but retains enough fern, shrub, grass and occasional flower variation to avoid a visibly empty or stripped forest floor. This is the clearest richness tradeoff to preserve in later ordinary-play checks. The large-scale sparse tree arrangement, open sky/horizon and severe Break darkness remain unresolved. They are not candidate regressions.

## Separate visual bars

**Bar A identity: open / partial.** The candidate preserves the current Stormwood palette and recognizable storm/tree/creature motifs and makes the floral distribution a little more natural. It does not establish the reference boards' sheltered, integrated forest composition.

**Bar B finish: open / below target.** Acceptable as a bounded comparative improvement, not a finished vegetation or whole-scene pass. Thin stems, grass repetition, mottled ground and dark Break subject separation remain conspicuous.

Stills do not establish motion stability, wind quality, temporal aliasing, performance, earned gameplay, combat readability or whole-game acceptance. A later ordinary gameplay witness should preserve the improved Glowmoss grouping while keeping enough visible vegetation in shadow; these staged views alone cannot certify that.

## Exact Stormwood native evidence

- `001_stormwood_place_flower_review_env_cinder_verge_0_calm_baseline.png`
- `002_stormwood_place_flower_review_env_cinder_verge_0_calm_candidate.png`
- `003_stormwood_place_flower_review_env_cinder_verge_0_break_baseline.png`
- `004_stormwood_place_flower_review_env_cinder_verge_0_break_candidate.png`
- `005_stormwood_place_flower_review_env_glowmoss_hollows_0_calm_baseline.png`
- `006_stormwood_place_flower_review_env_glowmoss_hollows_0_calm_candidate.png`
- `007_stormwood_place_flower_review_env_glowmoss_hollows_0_break_baseline.png`
- `008_stormwood_place_flower_review_env_glowmoss_hollows_0_break_candidate.png`
- `009_stormwood_place_flower_review_env_conductor_run_1_calm_baseline.png`
- `010_stormwood_place_flower_review_env_conductor_run_1_calm_candidate.png`
- `011_stormwood_place_flower_review_env_conductor_run_1_break_baseline.png`
- `012_stormwood_place_flower_review_env_conductor_run_1_break_candidate.png`

## Meadows regional review

All 12 native 1920x1080 PNGs in `D:/tetherbound/visual-acceptance/shots/flower-patches-paired/region/meadows` were opened. Additional reference basis reused from this review session: `docs/reference/tetherbound-meadows-keyart.png`, together with ART_DIRECTION and the five Palworld images listed above.

Three stands, each day/night and baseline/candidate, were captured in a paired live scene. Staged positions/flags/party/clock and hidden HUD limit acceptance. The unselected Meadowhart dynamic-place metadata skip is not a missing frame in these six pairs. Small blade/flower poses and distant actor changes are not scored as vegetation geometry or shading changes.

### Meadows preferences

Same ordinal scale as Stormwood.

| View / time | Baseline / candidate IDs | Score | Evidence |
|---|---|---:|---|
| Lower Meadows village, day | 001 / 002 | +1 | Candidate separates a more flower-rich patch to the trainer's right from quieter left foreground and the main dirt route. White-purple and occasional yellow accents retain meadow color. The right patch is still busy, but the distribution is less uniformly sprinkled across the whole foreground. |
| Lower Meadows village, night | 003 / 004 | 0 | Grouping is visible, but the concentrated tall pale flowers right of the trainer and at bottom-right remain conspicuous against dark ground. Quieter left ground offsets this; neither version provides a decisive whole-frame advantage. Inn/trainer/path hierarchy remains intact. |
| Stone/root quarry, day | 005 / 006 | +2 | Candidate removes much of the large flower-head clutter along the foreground fence and immediately around the trainer, leaving smaller purple/yellow accents and clearer green shrub shapes. It is easier to read the sparse stony working area as a whole. The fence still obstructs the foreground because of this camera stand; that is unchanged. |
| Stone/root quarry, night | 007 / 008 | +1 | Fewer large pale disks compete with the trainer and lamp. Local clusters survive around right foreground and along the approach. Ground remains dark, but fewer flowers do not create an additional route or trainer visibility problem. |
| Upper Meadows Ironwood, day | 009 / 010 | +2 | Strong Meadows witness: flowers gather more around the left trees/creature and deeper cover, while the broad right foreground becomes a grassy interval. The baseline's repeated large disks across most of the lower frame are reduced. Scene retains abundant grass, shrubs and flowering patches; it does not read stripped. |
| Upper Meadows Ironwood, night | 011 / 012 | +1 | Candidate reduces isolated bright disks across the right half and leaves a more localized flowering area at left. The trainer and visible creature still separate from the ground to roughly their previous degree. Fine teal grass noise and dark cover persist; this change does not fix them. |

### Meadows retention and tradeoffs

**Worth retaining as a bounded improvement to floral grouping and scene hierarchy.** The most convincing evidence is quarry005/006 and Ironwood009/010. Richness comes more from areas of flower concentration separated by grass/soil than from placing equally prominent disks everywhere.

The village candidate is less decisive: its right-hand patch is conspicuous, especially at night004, and some very tall thin stems still read as disconnected heads rather than full plants. That is a localized residual, not a major regression that outweighs the other gains in this packet. Do not describe every candidate frame as quieter: some locations gain more concentrated visible flowers.

Meadows keeps its green, warm, inhabited character and enough purple/yellow floral color. Quarry is deliberately visually sparser in the candidate, but shrubs, grass, stone and nearby vegetation preserve texture. Ironwood remains lush. No meaningful loss of biome richness or broad lighting/material failure is visible. Buildings, rocks, trainer exposure, practical lights and broad route shapes remain stable.

Remaining shortcomings in both variants include coarse flower silhouettes on thin stems, repeated grass ribbons, mottled turf and imperfect integration of plant masses with tree roots/terrain. The candidate improves distribution; it does not prove completion of asset quality or overall vegetation art direction.

**Bar A identity: open / partial.** Candidate preserves Meadows warmth, color and village/forest cues and modestly improves natural variation in plant grouping. The keyart's stronger composition, terrain layering and integrated cover are not achieved by this change alone.

**Bar B finish: open / below target.** Bounded comparison favors candidate, but native flower/stem shapes, grass repetition and other material/composition issues remain. This is not a whole Meadows acceptance.

## Combined decision

**Retain this flower-patch candidate as a modest comparative improvement in the two reviewed regions.** It provides observable variation in floral concentration and reduces repeated prominent flower heads in several high-exposure foregrounds without visibly stripping the plant palette or harming routes/trainer hierarchy.

Stormwood: five candidate preferences (one clear, four slight), one tie. Meadows: five candidate preferences (two clear, three slight), one tie. These counts summarize the frame evidence, not a mathematical acceptance rule. The decisive witnesses are Stormwood Glowmoss Calm005/006 and Meadows quarry day005/006 plus Ironwood day009/010.

No broad whole-frame lighting regression or consequential biome-identity loss is visible. Remaining concerns are repeated thin stems and simplified heads, a bright village night patch, persistent grass/ground noise, existing dark Stormwood Break subjects and incomplete large-scale environment composition. Retention is bounded to the observed distribution/scale improvement.

**Bar A and Bar B remain separate and open in both regions.** All 24 native stills were reviewed, but fixtures, hidden HUD, occluders, advancing weather/time and lack of motion prevent whole-game, ordinary gameplay, performance or animation acceptance.

## Exact Meadows native evidence

- `001_meadows_place_flower_review_env_band1_lower_meadows_0_day_baseline.png`
- `002_meadows_place_flower_review_env_band1_lower_meadows_0_day_candidate.png`
- `003_meadows_place_flower_review_env_band1_lower_meadows_0_night_baseline.png`
- `004_meadows_place_flower_review_env_band1_lower_meadows_0_night_candidate.png`
- `005_meadows_place_flower_review_env_band2_stone_and_root_0_day_baseline.png`
- `006_meadows_place_flower_review_env_band2_stone_and_root_0_day_candidate.png`
- `007_meadows_place_flower_review_env_band2_stone_and_root_0_night_baseline.png`
- `008_meadows_place_flower_review_env_band2_stone_and_root_0_night_candidate.png`
- `009_meadows_place_flower_review_env_band4_upper_meadows_ironwood_0_day_baseline.png`
- `010_meadows_place_flower_review_env_band4_upper_meadows_ironwood_0_day_candidate.png`
- `011_meadows_place_flower_review_env_band4_upper_meadows_ironwood_0_night_baseline.png`
- `012_meadows_place_flower_review_env_band4_upper_meadows_ironwood_0_night_candidate.png`

## Final loaded-settings regression check â€” 2026-09-27

This addendum qualifies the earlier retention recommendation. All eight native 1920x1080 stills in `D:/tetherbound/visual-acceptance/shots/flower-patches-final/region/meadows` were inspected, plus native movement samples `motion_00.png`, `motion_04.png`, `motion_08.png`, `motion_12.png`, `motion_16.png`, `motion_20.png`, and `motion_23.png`. No production source/config/diffs were read and no engine was run for this review. Reference basis remains the ART_DIRECTION, Meadows keyart and Palworld images listed above. Still fixtures use staged location/clock/party, hidden HUD and parked companion. Movement is production forward input from a staged Ironwood start with HUD hidden and director frozen. These fixtures do not count as whole-game acceptance.

**Final retention decision: block an unrestricted rollout of this exact candidate because Ridgeline loses a useful established planting group.** Ironwood remains improved. The earlier generic-stand results remain valid for those images, but they do not establish preservation of compositions at additional locations. This is a visible composition regression, not a source-derived judgment about how the plants were authored.

| Final pair | Preference | Visible evidence |
| --- | --- | --- |
| Ironwood day 001 baseline / 002 candidate | Candidate, clear | Candidate concentrates pale flowers toward the left tree-root/companion area and leaves a quieter grassy right foreground. The scene remains lush and the trainer reads clearly. |
| Ironwood night 003 baseline / 004 candidate | Candidate, slight | Fewer scattered bright flower disks compete across the right foreground; the left grouping remains. Ground and trainer readability do not show a new broad lighting loss. The companion is dark in both. |
| Ridgeline day 005 baseline / 006 candidate | Baseline, slight | In baseline, a purple-white flowering band follows the diagonal forest/route boundary from approximately x1150,y450 toward the right side around y600. Candidate largely removes that coherent color accent. More dispersed yellow foreground heads replace neither its location nor its directional role. The central-right route opening remains visible and grass/shrubs remain, so this is not a bare-ground or missing-route claim. |
| Ridgeline night 007 baseline / 008 candidate | Baseline, clear | Baseline's pale purple-white band distinctly traces the diagonal edge toward the opening. Candidate lets that edge merge into dark green/teal ground cover. Scattered foreground flowers remain, but the useful planted route-edge cue is substantially weaker. Trainer upper-body separation survives. |

The Ridgeline result trades useful biome richness and directional grouping for less color at the route boundary while retaining scattered foreground accents. That is an unfavorable trade here, even though reduced scattered flowers help the previously reviewed Ironwood and quarry views. No broad sky/tree/trainer lighting regression is evident in these matched stills; the blocker is the local loss of planting hierarchy.

Acceptance witness for resolving this blocker: the same Ridgeline day/night viewpoint must retain a readable, coherent flowering group along this diagonal boundary, with comparable directional and color value to 005/007, while keeping foreground clutter controlled. It need not reproduce every flower. It must preserve the composition's function. Ironwood 002/004's quieter right foreground should also remain. This review does not prescribe or infer implementation.

### Movement sample observations and limits

Samples 00/04 retain a recognizable left flower concentration, mixed grass/shrubs and a clear trainer torso. In 08/12/16, nearer pale flower heads become more prominent across the lower frame as the camera advances; vegetation stays visually populated, and the torso/backpack remain readable. These are selected still samples, not proof that there is no shimmer, popping, flicker or abrupt transition between them. There is no baseline movement counterpart here to isolate temporal regressions.

At sample20, a large tree root crosses in front of the trainer's lower body; at23, the close trunk/root occupy much of the left and lower frame. This is a visible obstruction in this straight staged approach. It is not evidence that flower changes caused it, and it prevents treating this short sequence as unobstructed whole-route presentation. The samples add no smoothness, performance, collision or whole-route guarantee.

### Separate acceptance status

- **Bar A â€” identity: partial/open.** The wooded Meadows palette and lush vegetation remain recognizable, with bounded Ironwood grouping improvement. Ridgeline's lost route-edge flower grouping is a specific local regression that must be preserved or restored before approving broad retention.
- **Bar B â€” finish: open/below reference target.** Dense repeated thin grass, simple exposed roots and ground treatment remain visible; later movement samples also show root occlusion. Neither the still comparisons nor seven movement samples establish finished gameplay presentation.
- **Final candidate retention: blocked globally; locally favorable at Ironwood.** Earlier Stormwood and other Meadows preferences do not cancel the new Ridgeline failure. Full temporal and whole-game acceptance remain open.

Exact final stills read:

- `001_meadows_place_flower_final_ironwood_day_baseline.png`
- `002_meadows_place_flower_final_ironwood_day_candidate.png`
- `003_meadows_place_flower_final_ironwood_night_baseline.png`
- `004_meadows_place_flower_final_ironwood_night_candidate.png`
- `005_meadows_place_flower_final_ridgeline_day_baseline.png`
- `006_meadows_place_flower_final_ridgeline_day_candidate.png`
- `007_meadows_place_flower_final_ridgeline_night_baseline.png`
- `008_meadows_place_flower_final_ridgeline_night_candidate.png`

## Revised Ridgeline preservation check â€” 2026-09-27

Four completed native 1920x1080 frames were inspected in `D:/tetherbound/visual-acceptance/shots/flower-patches-preserved-final/region/meadows`. The planned outer planting transition day/night stands were both skipped; the capture manifest records `camera spring collapsed`. This check therefore covers the Ridgeline core viewpoint only. No source/config/diffs were read, no engine was run, and the reference basis and staged/HUD-hidden limitations above remain unchanged.

**The specific visible Ridgeline planted-edge regression is resolved in these two pairs.** The revised candidate retains the coherent purple-white flowering band that was largely absent in the preceding blocked candidate. This supersedes the preceding blocker only for the observed loss at this core viewpoint. It does not establish quality of the uncaptured outer transition or clear full-region acceptance.

| Revised pair | Preference | Evidence |
| --- | --- | --- |
| 001 day baseline / 002 day candidate | Tie overall; preservation acceptable | Both show the pale purple-white diagonal group along the right-side tree/route boundary, running from the center-right opening toward the right edge. Candidate retains its color and directional role; it no longer reads as the predominantly green/yellow boundary in previous packet 006. Some foreground yellow heads differ in distribution, without a clear whole-frame advantage or new distracting cluster. Trainer and opening remain readable. |
| 003 night baseline / 004 night candidate | Tie overall; preservation acceptable | Both retain the pale blue-purple flowering band as a readable edge against darker cover. Revised candidate 004 preserves the useful cue missing from previous packet 008. The trainer stays distinct and the scene remains similarly dark; this is preservation, not a claim of improved night lighting. |

There is no conspicuous new planting seam within these four visible core frames. However, they do not view the intended outer transition closely enough to judge its boundary behavior. With both dedicated transition stands skipped, there is no visual basis to assert a smooth outer blend, absence of a cutoff, or acceptable traversal across it. That coverage gap must remain explicit rather than being converted into a pass or an observed failure.

Scoped retention: the revised candidate is acceptable for resolving the previously observed Ridgeline flower-band loss, in combination with the earlier favorable reviewed stands. The old exact candidate remains the failed historical comparison. The revised version has no demonstrated remaining blocker in this core view; global transition preservation is still unverified. Earlier Ironwood movement sampling limits, including root occlusion and no temporal smoothness guarantee, remain in force. No new movement sequence was reviewed for this revision.

Bar A identity remains partial/open: the local planting identity is preserved here, but a regional claim would exceed this scope. Bar B finish remains open/below reference target; this preservation check does not improve or close the broader finish issues. Neither bar, whole-route quality nor whole-game acceptance is declared passed.

Exact revised native files read:

- `001_meadows_place_flower_final_ridgeline_day_baseline.png`
- `002_meadows_place_flower_final_ridgeline_day_candidate.png`
- `003_meadows_place_flower_final_ridgeline_night_baseline.png`
- `004_meadows_place_flower_final_ridgeline_night_candidate.png`
