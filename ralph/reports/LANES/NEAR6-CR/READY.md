# NEAR6-CR lane (tb/near6-cr-1104), 4 Nov 2026

## HANDOFF 7 Nov

All scores are mapped CPU Bar A (quick_judge, llvmpipe Low); none closes a row (rows close on the GPU). Every ON flag has a test in `tests/test_near6_cr_judged_on.gd` (14 tests pass) and its verdict under `qj/`.

**Shipped this lane (flag ON)**
- F40#8 P2-053: `cloudreach_npc_runtime.json:world_payoffs.anchor_vessel_quiet` 5.87 -> 6.32 (4558ec49).
- F40#17 P2-102: `cloudreach_physical_runtime.json:rim_pickup_in_view` 5.09 -> 5.72 (ec870b02); `rim_pickup_cluster` 5.85 -> 6.19 (caed2863).
- F40#9 P2-068: `cloudreach_npc_runtime.json:post_role_props` 5.05 -> 5.25 (0e41fe16); `post_dais` 5.44 -> 5.62 (ade5619b; 0.4 m collision dais, Maela walk-up smoke passes).
- F40#2 P2-022: `cloudreach_f40_items.json:summit_silhouette` 5.64 -> 6.16 (d720ad38).
- F40#4 P2-023: `cloudreach_f40_items.json:shelf_edge_fringe` 5.96 -> 6.27 (d3ffce66).
- F40#19 night (matrix piece 7): `cloudreach_visual.json:time_override_arms.night_foreground_fill` 5.10 -> 5.84 (2d7066c0); `gate_path_braziers` 5.00 -> 5.51 (799a0872); `gate_path_verge` 5.54 -> 5.81 (e9c2160a).
- F40#19 rain (matrix piece 4): `cloudreach_visual.json:weather_arms.rain_storm` 5.69 -> 5.80 (9a918a92); `rain_streaks` 5.48 -> 5.61 (39247ac8).
- P2053_LINE

**Open items**
- F40#9 P2-068 (5.62): judges want the NPC clear of the trainer and larger; the capture stand puts the trainer 2 m in front of the post. Next idea: none in scene scope; needs a stand change.
- F40#17 P2-102 (6.19): defect FIXED on 2 of 3; judges mark "plastic blob mushrooms on low-detail turf". Next idea: rim turf dressing (installed grass/flower clusters) around the cluster.
- F40#4 P2-023 (6.27): judges ask for sculpted, irregular, stratified rock edges. Next idea: new_art (Meshy shelf lip) or a chamfered kitbash on `cloudreach_cliff_shelf_edge`.
- F40#19 rain (5.61): defect PARTIAL; judges want wet sheen on path/stone, puddles/splashes, a storm sky without blue gaps and mist at the gate. Next idea: path/stone roughness and darkening under rain (material wetness hook), sky gap removal in the rain preset.

**Parked**
- F40#19 night (~5.8): two flat rounds (face_uplights 5.71 -> 5.71, night_moon_grade 5.45 -> 5.41). Remaining asks are the gate framed clear of the quest box/minimap (capture camera) and a hero gate (new_art).
- F40#15 P2-049 (6.36 GPU, defect FIXED): scored frames are a camera hugging a dark wall and an open aerie lawn; camera or new_art.
- F40#16 P2-054 (6.48): Wild -> installed shelf fungus judged worse (6.47 -> 5.92); the shipped orange Wild already separates by colour. Further gain needs new_art.
- F40#2 P2-022: the procedural aviary arms were invisible (hidden under the imported Meshy set); Blender install in scratch was refused by the permission classifier (not worked around).

**OFF arms left in the tree** (all judged flat/worse or invisible): `objective_beacon.json:realm_styles.cloudreach`; `cloudreach_physical_runtime.json:rim_pickup_inset`; `cloudreach_aviary.json:drum.terrace`; `cloudreach_f40_visual.json:aviary.sanctuary.drum_uplights`; `cloudreach_aviary.json:towers.silhouette_raise`; `cloudreach_visual.json:geology.rim_fringe` and `.outcrops`; `cloudreach_f40_items.json:shelf_edge_soften`; `cloudreach_visual.json:weather_arms.rain_mood`; `cloudreach_visual.json:time_override_arms.night_moon_grade`; `cloudreach_realm_gate_crag_visual.json:face_uplights`; `data/config/mushroom_pickup_variants.json`.

**Known tool/capture bugs**
- `git fetch origin main` pulls an ~11.8 GB pack and fills the session disk; use `git fetch --filter=blob:none origin main`.
- quick_judge writes verdicts to `ralph/reports/VISUAL/quick/` even with `QJ_LANE` set; move them to the lane `qj/` by hand.
- `ground_height_at` returns NaN beside the realm-gate path (no lawn surface indexed); props there need an explicit `ref_y`.
- `Bush_Common.gltf` renders red under the Cloudreach night grade (red is Team Tether only); keep it out of night dressing.
- Waiters using `pgrep -f "<pattern>"` match their own command line; wait on log contents instead.
- Matrix capture tools need `--biome` and `--source-commit` (quick_judge passes them; logged under Harness fixes).

Items: F40#9 P2-068, F40#4 P2-023, F40#8 P2-053, F40#2 P2-022, F40#17 P2-102 (handed over from VIS-CLOUDREACH). CPU-only (Godot 4.7 llvmpipe, Low/Compatibility); mapped CPU Bar A via `tools/visual_judge/quick_judge.py`.

## Landing-ready flags (ON, judged CPU gain)

| Flag | Item | CPU base -> ON | Test | Commit |
|---|---|---|---|---|
| `data/config/cloudreach_npc_runtime.json:world_payoffs.anchor_vessel_quiet` | F40#8 P2-053 | 5.87 -> **6.32** | `tests/test_near6_cr_judged_on.gd` | 4558ec49 |
| `data/config/cloudreach_physical_runtime.json:rim_pickup_in_view` | F40#17 P2-102 | 5.09 -> **5.72** | `tests/test_near6_cr_judged_on.gd` | ec870b02 |
| `data/config/cloudreach_npc_runtime.json:post_role_props` | F40#9 P2-068 | 5.05 -> **5.25** | `tests/test_near6_cr_judged_on.gd` | 0e41fe16 |
| `data/config/cloudreach_npc_runtime.json:post_dais` | F40#9 P2-068 | 5.44 -> **5.62** (post_role_props ON in both arms) | `tests/test_near6_cr_judged_on.gd` | ade5619b |
| `data/config/cloudreach_physical_runtime.json:rim_pickup_cluster` | F40#17 P2-102 | 5.85 -> **6.19** (with rim_pickup_in_view ON) | `tests/test_near6_cr_judged_on.gd` | caed2863 |
| `data/config/cloudreach_visual.json:weather_arms.rain_storm` | F40#19 (matrix piece 4, day rain) | 5.69 -> **5.80** | `tests/test_near6_cr_judged_on.gd` | 9a918a92 |
| `data/config/cloudreach_f40_items.json:shelf_edge_fringe` | F40#4 P2-023 | 5.96 -> **6.27** | `tests/test_near6_cr_judged_on.gd` | d3ffce66 |
| `data/config/cloudreach_visual.json:time_override_arms.night_foreground_fill` | F40#19 (matrix piece 7, night) | 5.10 -> **5.84** | `tests/test_near6_cr_judged_on.gd` | 2d7066c0 |
| `data/config/cloudreach_f40_items.json:summit_silhouette` | F40#2 P2-022 | 5.64 -> **6.16** | `tests/test_near6_cr_judged_on.gd` | d720ad38 |
| `data/config/cloudreach_visual.json:gate_path_braziers` | F40#19 (matrix piece 7, night) | 5.00 -> **5.51** (night_foreground_fill ON in both arms; this batch's anchors map lower than the 5.84 round) | `tests/test_near6_cr_judged_on.gd` | 799a0872 |
| `data/config/cloudreach_visual.json:gate_path_verge` | F40#19 (matrix piece 7, night) | 5.54 -> **5.81** (braziers + night fill ON in both arms) | `tests/test_near6_cr_judged_on.gd` | e9c2160a |
| `data/config/cloudreach_visual.json:rain_streaks` | F40#19 rain (matrix piece 4) | 5.48 -> **5.61** (rain_storm ON in both arms) | `tests/test_near6_cr_judged_on.gd` | 39247ac8 |

## Arms in flight (flag OFF)

| Arm | Item | State |
|---|---|---|
| `objective_beacon.json:realm_styles.cloudreach` (VIS-CLOUDREACH fdfb015a7, ported) | F40#8 P2-053 | Captured, **not judged: no visible change** on the three scored bridge frames (the cyan T there is the Storm Anchor bottled-wind vessel, not the objective beacon). Stays OFF. |
| `world_payoffs.anchor_vessel_quiet` | F40#8 P2-053 | Judged qj/F40-8-2a6eb2207108-11040854: gain, ON (above). Base frames reused from tree bc3299192181 (flag-off render path identical). |
| `cloudreach_physical_runtime.json:rim_pickup_inset` | F40#17 P2-102 | Round 1 judged flat (qj/F40-17-ade4ecff4c0e-11040935, 4.57 -> 4.57): hiding the cluster left the subject unreadable. Stays OFF. |
| `cloudreach_physical_runtime.json:rim_pickup_in_view` | F40#17 P2-102 | Round 2 judged gain (qj/F40-17-f201152b7ca0-11041023), ON (above). |
| `cloudreach_aviary.json:drum.terrace` | F40#2 P2-022 | Captured (qj F40-2-e17c8adb5fe0-11041024), **not judged: no visible change**: 0.42/0.2 m steps vanish in the turf at the approach distance, and a taller podium would need collision (route change). Stays OFF; next idea: night uplight on the drum (night silhouette) or a paved forecourt joining the court. |
| `cloudreach_f40_visual.json:aviary.sanctuary.drum_uplights` | F40#2 P2-022 | Captured (qj F40-2-e2eed70d21e6-11041108), **not judged: no visible change** (six warm 3.0-energy lights at 31 m read as nothing at the 100+ m approach stands). Stays OFF. **P2-022 parked** after two invisible arms: the item needs a silhouette-scale change (new_art/Meshy-class), not dressing. |
| `cloudreach_npc_runtime.json:post_role_props` | F40#9 P2-068 | Judged gain (qj/F40-9-68037b4643f8-11041154), ON (above). Defect still PRESENT: judges want the NPC itself clear of the trainer and larger; that is the capture stand (trainer 2 m in front of the post), which this lane does not reframe. |
| `cloudreach_visual.json:geology.rim_fringe` | F40#4 P2-023 | Round 1 captured (qj F40-4-41e840386d6b-11041218): **no visible change** on the scored stands (those pale shelves are crag-kit outcrops, not shelf/shoulder mesas). Not judged; stays OFF. |
| `cloudreach_visual.json:geology.rim_fringe.outcrops` | F40#4 P2-023 | Round 2 captured with a fresh base (qj F40-4-33a9d9ff23ed-11041233): **no visible change** either; the pale straight-edged shelves on the three stands are built by neither the shelf/shoulder mesa path nor the crag-kit outcrops. Stays OFF. **P2-023 parked** after two invisible arms; next step is to identify the builder of those shelves (node names from a scene dump at the sky shrine stand) before another arm. |
| `cloudreach_aviary.json:towers.silhouette_raise` | F40#2 P2-022 | Captured (qj F40-2-43dc52e38af7-11041416): **no visible change**. Cause found: the summit landmark in frame is the imported `cloudreach_f40_items.json` SummitEyrieStronghold set (54 m drum ring and four 26 m belvederes); the procedural `cloudreach_aviary.gd` build that all three earlier arms edited is hidden under it. Stays OFF. |
| `cloudreach_f40_items.json:summit_silhouette` | F40#2 P2-022 | Judged gain (qj/F40-2-edb6d881b763-11041450), ON (above). Judges still ask for a cliff plinth, cloud sea below and lit windows at night. |
| `cloudreach_f40_items.json:shelf_edge_soften` | F40#4 P2-023 | **Judged worse** (qj/F40-4-24add0c49b36-11041519): CPU 6.35 -> 5.69. Root cause found by a ray probe: the straight-edged pale shelves are the installed `cloudreach_cliff_shelf_edge` modules from the shared `stand_pattern` (P2-021 dressing). Turning and sinking them lost the layered pale strata the judges like; they ask for chamfered, overhanging, eroded lips instead. Stays OFF. Current CPU base for the item on this tree: **6.35**. |
| `cloudreach_visual.json:gate_path_braziers` | F40#19 night (matrix piece 7) | Round 2 judged gain (qj/F40-19-458a13de2967-11042202), ON (above). Judges still ask for the gate shown whole clear of the HUD (capture stand, not reframed here), a moon/stars/cloud sea night sky and broken-up foreground grass. |
| `cloudreach_visual.json:gate_path_verge` | F40#19 night (matrix piece 7) | Round 3: first capture showed nothing (no lawn surface indexed beside the path, `ground_height_at` NaN; now seats at `ref_y`). Round 3b capture rendered the installed `Bush_Common` **red** at night (red is Team Tether only), so it was not judged; bushes swapped for flowers and low rocks, then judged gain (qj/F40-19-9025b78edb4e-11050024), ON (above). **Note for owners of route dressing:** `Bush_Common.gltf` reads red under the Cloudreach night grade. |
| `cloudreach_realm_gate_crag_visual.json:face_uplights` | F40#19 night (matrix piece 7) | **Judged flat** (qj/F40-19-3060ae8a4f11-11050109): 5.71 -> 5.71, all three judges saw the sides as the same (the gate sits under the quest box/minimap at the capture stands). Stays OFF. Judges' consistent ask: a cool, darker, less saturated moonlit grade (the ground now reads day-lit under a night sky). |
| `cloudreach_visual.json:time_override_arms.night_moon_grade` | F40#19 night (matrix piece 7) | **Judged flat/worse** (qj/F40-19-730be2e9f92c-11050146): 5.45 -> 5.41 (one judge preferred the brighter base). Stays OFF. Second flat round in a row (after face_uplights): **F40#19 night parked** at CPU ~5.8 (fill + braziers + verge ON). Remaining asks are the gate framed clear of the HUD (capture camera, not this lane) and a hero gate (new_art). |
| `mushroom_pickup_variants.json` (Wild -> installed Mushroom_Laetiporus shelf fungus) | F40#16 P2-054 | **Judged worse** (qj/F40-16-98dc09bfe90b-11071348): CPU 6.47 -> 5.92; all three preferred the shipped orange Wild cluster (defect FIXED there) over the pale cream shelf. Stays OFF. First capture rendered the fungus oversized (fit by height only); refit to its largest extent before judging. |
| F40#15 P2-049 (no arm) | F40#15 | Base captured 7 Nov (qj F40-15-base-11071400). The GPU yardstick already marks the dark-strip defect FIXED (6.36); the two scored frames are a camera hugging a dark wall (walk_03) and an open aerie lawn at dusk, so the remaining points are camera framing (not this lane) or new_art. Not attempted. |
| `cloudreach_visual.json:weather_arms.rain_mood` | F40#19 rain (matrix piece 4) | **Judged flat** (qj/F40-19-rain-9079be470ae9-11041657): 5.81 -> 5.81, all three judges saw no difference. Stays OFF. Next idea (round 2): a stronger storm grade (darker sky, wet path sheen, low mist), which the judges asked for. |

## Status (4 Nov 17:10 UTC)

Six CPU gains ON (owner/coordinator batch): P2-053 5.87 -> 6.32, P2-102 5.09 -> 5.72, P2-068 5.05 -> 5.25 (the first three landed on main in #818/#820/#823), then P2-022 5.64 -> 6.16, P2-023 5.96 -> 6.27, F40#19 night 5.10 -> 5.84. Zero criteria closed (CPU scores rank only; rows close on the GPU).

Open for this lane: F40#19 rain (CPU 5.81 on this tree; the realm-scoped weather hook is built, round 1 flat). P2-068 is still under 6 (5.62 with the dais; the NPCs sit 2 m behind the trainer at the capture stand). **Gameplay note:** post_dais adds a 0.4 m collision dais under Tavi, Sora and Maela; `tests/smoke_cloudreach_aerie_services.gd` (production controller walks to Maela's post and uses the interaction arbiter) PASSES with the dais ON; Tavi and Sora posts not separately smoked. P2-102 now 6.19 with the cluster arm.

**Blocked:** installing portable Blender 4.2 LTS in scratch (coordinator item 2) was refused by this session's permission classifier ("code from external"). P2-022 was instead done in-engine on the installed belvedere meshes (no new mesh), which judged 6.16.

## Harness fixes

- `tools/visual_judge/quick_judge.py`: `QJ_JOB=<path>` merges extra item definitions (job.json schema) over the catalogue job. Blocker: F40#19 (F40 matrix night/rain pieces) has no stand in job.json, so no quick round could be built for it. Second, the matrix tools get `--source-commit` through `lookdev_capture_bootstrap.gd`, so quick_judge now also passes it to scripts that extend `capture_lookdev_catalogue` (reproduced: the launch exited in 15 s with "requires ... source SHA"). `tools/visual_judge/tests/test_quick_judge.py` 14 OK.

## Blockers

None.
