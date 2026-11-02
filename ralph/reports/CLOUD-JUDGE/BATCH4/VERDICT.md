# Batch 4 (all lanes merged, candidate flags ON) vs main: mapped Bar A

GPU frames from origin/tb/gpu-frames-1101 (batch4/ vs main/, same tool and camera). Standard JUDGE_PROMPT v1, 3 anchor pairs per folder (anchor_tiles.py), 3 independent code-blind judges per folder, calibrate.py --bar 7.0 (mapped_mean). Items with many stands were split into sub-sets of at most 4 stands; the item score is the mean of its sub-sets.

| Item | main | batch 4 | delta | pairs | crossed 7.0 | notes |
|---|---|---|---|---|---|---|
| F36 (0) #3 Galewisp | 5.43 | 7.59 | +2.16 | 4 | YES |  |
| F36 (1) Glimmermoth | 4.51 | 6.49 | +1.98 | 4 |  |  |
| P2-066 | 3.56 | 5.19 | +1.63 | 3 |  |  |
| F36 (0) #14 Fulgocobra | 5.26 | 6.86 | +1.60 | 4 |  |  |
| F36 (0) #11 Cloudfang | 6.01 | 7.50 | +1.49 | 4 | YES |  |
| P2-012 | 4.97 | 6.44 | +1.47 | 5 |  |  |
| F36 (1) Breezetail | 5.65 | 7.09 | +1.44 | 4 | YES |  |
| P2-067 | 3.65 | 4.87 | +1.22 | 3 |  |  |
| F36 (0) #12 Aeriex | 6.60 | 7.55 | +0.95 | 4 | YES |  |
| F36 (0) #9 Mirejaw | 6.18 | 6.94 | +0.76 | 4 |  |  |
| F36 (0) #4 Mudsnout | 7.21 | 7.93 | +0.72 | 4 | held |  |
| F36 (1) Frostclaw | 6.76 | 7.45 | +0.69 | 4 | YES |  |
| F36 (1) Cindercub | 7.40 | 8.08 | +0.68 | 4 | held |  |
| P2-006 | 5.69 | 6.22 | +0.53 | 4 |  | excluded: meadows-locations/meadows__landmark__old_mill_crossing__day__approach.jpg |
| P2-026 | 4.96 | 5.43 | +0.47 | 3 |  |  |
| F39 ground-cover clustering (P2-008 shore landforms, P2-057 grass around named characters) | 5.37 | 5.82 | +0.45 | 10 |  |  |
| F38 light (all exterior) | 6.00 | 6.42 | +0.42 | 11 |  |  |
| P2-038 | 5.33 | 5.67 | +0.34 | 3 |  |  |
| P2-008 | 5.47 | 5.80 | +0.33 | 3 |  |  |
| P2-056 | 5.27 | 5.53 | +0.26 | 3 |  |  |
| OWNER-1031 floating drums: rock-shoulder shelves/outcrops over meadows (P2-023) | 5.52 | 5.75 | +0.23 | 2 |  |  |
| F39 shared light (P2-008, P2-009, P2-011, P2-026, P2-057, P2-073, P2-074, P2-075 and other Tidewake scene items) | 6.08 | 6.31 | +0.23 | 22 |  |  |
| P2-050 | 6.17 | 6.31 | +0.14 | 3 |  |  |
| F36 (0) #6 Burrowback | 7.66 | 7.78 | +0.12 | 4 | held |  |
| P2-055 | 5.27 | 5.27 | +0.00 | 3 |  |  |
| OWNER-1031 floating drums: drum bottoms and beacon plinths (P2-023) | 6.47 | 6.41 | -0.06 | 3 |  |  |
| P2-003 | 5.86 | 5.71 | -0.15 | 6 |  |  |
| F40 ground-cover clustering (P2-021 open terrain, P2-025 grass and stone finish) | 6.08 | 5.77 | -0.31 | 14 |  | missing: cloudreach__upper_cloudreach__10__old_wind_observatory__day__approach |
| F36 (0) #17 Cannonback | 6.68 | 6.34 | -0.34 | 4 |  |  |
| OWNER-1031 floating drums: cliff wall profile (P2-023) | 6.56 | 6.20 | -0.36 | 3 |  |  |
| P2-095 | 7.28 | 6.70 | -0.58 | 1 | LOST |  |
| P2-096 | 7.28 | 6.70 | -0.58 | 1 | LOST | shares the P2-095 crafting frame and set (both catalog defects recorded on it) |
| F36 (1) Mangrove Monitor | 6.17 | 5.53 | -0.64 | 4 |  |  |
| F40 shared light (P2-021, P2-023, P2-025, P2-049, P2-068, P2-076, P2-077, P2-102 and other Cloudreach scene items) | 7.11 | 6.42 | -0.69 | 22 | LOST | missing: cloudreach__upper_cloudreach__10__old_wind_observatory__day__approach |
| F36 (1) Craghorn | 6.92 | 6.17 | -0.75 | 4 |  |  |
| F36 (1) Cragclaw | 6.70 | 5.90 | -0.80 | 4 |  |  |
| F36 (1) Duskhush | 7.08 | 6.28 | -0.80 | 4 | LOST |  |
| F36 (1) Aquaryn | 7.32 | 6.30 | -1.02 | 4 | LOST |  |
| F36 (1) Cliffspike | 6.60 | 5.58 | -1.02 | 4 |  |  |
| F36 (0) #16 Ashtusk | 7.40 | 6.00 | -1.40 | 4 | LOST |  |
| P2-108 | n/a | n/a | n/a | 0 |  | no control frames on main for these stands |

## Crossed 7.0 (main below, batch 4 at or above)

- F36 (0) #3 Galewisp: 5.43 -> 7.59
- F36 (0) #11 Cloudfang: 6.01 -> 7.50
- F36 (1) Breezetail: 5.65 -> 7.09
- F36 (0) #12 Aeriex: 6.60 -> 7.55
- F36 (1) Frostclaw: 6.76 -> 7.45

## Gains of +0.3 or more and their most plausible flags

- F36 (0) #3 Galewisp (+2.16): creature_model_flags.json remake_owner1101_<creature>; creature_coat_flags.json creatures_vis_coat_<creature>; creature_scale_flags / creature_clip_flags / f36_pose_candidates (where the creature is named)
- F36 (1) Glimmermoth (+1.98): creature_model_flags.json remake_owner1101_<creature>; creature_coat_flags.json creatures_vis_coat_<creature>; creature_scale_flags / creature_clip_flags / f36_pose_candidates (where the creature is named)
- P2-066 (+1.63): tidewake_look.json watersky_light_candidate.enabled / watersky_sections_on; water.json river.surface_candidate.enabled
- F36 (0) #14 Fulgocobra (+1.60): creature_model_flags.json remake_owner1101_<creature>; creature_coat_flags.json creatures_vis_coat_<creature>; creature_scale_flags / creature_clip_flags / f36_pose_candidates (where the creature is named)
- F36 (0) #11 Cloudfang (+1.49): creature_model_flags.json remake_owner1101_<creature>; creature_coat_flags.json creatures_vis_coat_<creature>; creature_scale_flags / creature_clip_flags / f36_pose_candidates (where the creature is named)
- P2-012 (+1.47): burrow_warrens.json bank.hill_shell.enabled / r2.enabled; meadows_look.json light_candidate.enabled
- F36 (1) Breezetail (+1.44): creature_model_flags.json remake_owner1101_<creature>; creature_coat_flags.json creatures_vis_coat_<creature>; creature_scale_flags / creature_clip_flags / f36_pose_candidates (where the creature is named)
- P2-067 (+1.22): tidewake_look.json watersky_light_candidate.enabled / watersky_sections_on; water.json river.surface_candidate.enabled
- F36 (0) #12 Aeriex (+0.95): creature_model_flags.json remake_owner1101_<creature>; creature_coat_flags.json creatures_vis_coat_<creature>; creature_scale_flags / creature_clip_flags / f36_pose_candidates (where the creature is named)
- F36 (0) #9 Mirejaw (+0.76): creature_model_flags.json remake_owner1101_<creature>; creature_coat_flags.json creatures_vis_coat_<creature>; creature_scale_flags / creature_clip_flags / f36_pose_candidates (where the creature is named)
- F36 (0) #4 Mudsnout (+0.72): creature_model_flags.json remake_owner1101_<creature>; creature_coat_flags.json creatures_vis_coat_<creature>; creature_scale_flags / creature_clip_flags / f36_pose_candidates (where the creature is named)
- F36 (1) Frostclaw (+0.69): creature_model_flags.json remake_owner1101_<creature>; creature_coat_flags.json creatures_vis_coat_<creature>; creature_scale_flags / creature_clip_flags / f36_pose_candidates (where the creature is named)
- F36 (1) Cindercub (+0.68): creature_model_flags.json remake_owner1101_<creature>; creature_coat_flags.json creatures_vis_coat_<creature>; creature_scale_flags / creature_clip_flags / f36_pose_candidates (where the creature is named)
- P2-006 (+0.53): water.json river.surface_candidate.enabled; grass_field.json meadows_ground_candidate.enabled; meadows_look.json light_candidate.enabled
- P2-026 (+0.47): tidewake_look.json watersky_light_candidate.enabled; water_ground_cover.json watersky_cluster_candidate.enabled / built_feather_enabled
- F39 ground-cover clustering (P2-008 shore landforms, P2-057 grass around named characters) (+0.45): water_ground_cover.json watersky_cluster_candidate.enabled / built_feather_enabled; water_npc_placement_candidate.json enabled
- F38 light (all exterior) (+0.42): meadows_look.json light_candidate.enabled; grass_field.json meadows_ground_candidate.enabled; water.json river.surface_candidate.enabled
- P2-038 (+0.34): stormwood_glass_field.json rock_collar_candidate.enabled; stormwood_lantern_pools.json arrival_pools / lantern_model; stormwood_harvest_hero2.json enabled
- P2-008 (+0.33): water_ground_cover.json watersky_cluster_candidate.enabled / built_feather_enabled; tidewake_look.json watersky_light_candidate.enabled

## Regressions (delta <= -0.3)

- F40 ground-cover clustering (P2-021 open terrain, P2-025 grass and stone finish) (-0.31): suspect cloudreach_ground_cluster.json enabled; cloudreach_visual.json route_details.plaza_paving_candidate.enabled; cloudreach_grounding.json clear_paved_grass
- F36 (0) #17 Cannonback (-0.34): suspect creature_model_flags.json remake_owner1101_<creature>; creature_coat_flags.json creatures_vis_coat_<creature>; creature_scale_flags / creature_clip_flags / f36_pose_candidates (where the creature is named)
- OWNER-1031 floating drums: cliff wall profile (P2-023) (-0.36): suspect cloudreach_grounding.json enabled / skip_floating_shelves / monotonic_walls / clear_paved_grass; cloudreach_light_candidate.json enabled
- P2-095 (-0.58): suspect craft_presentation.json readable_r3 / readable_r4 / rendered_item_icons
- P2-096 (-0.58): suspect craft_presentation.json readable_r3 / readable_r4 / rendered_item_icons
- F36 (1) Mangrove Monitor (-0.64): suspect creature_model_flags.json remake_owner1101_<creature>; creature_coat_flags.json creatures_vis_coat_<creature>; creature_scale_flags / creature_clip_flags / f36_pose_candidates (where the creature is named)
- F40 shared light (P2-021, P2-023, P2-025, P2-049, P2-068, P2-076, P2-077, P2-102 and other Cloudreach scene items) (-0.69): suspect cloudreach_light_candidate.json enabled; cloudreach_grounding.json (all four); crown_arch_hero.json round2_candidate.enabled
- F36 (1) Craghorn (-0.75): suspect creature_model_flags.json remake_owner1101_<creature>; creature_coat_flags.json creatures_vis_coat_<creature>; creature_scale_flags / creature_clip_flags / f36_pose_candidates (where the creature is named)
- F36 (1) Cragclaw (-0.80): suspect creature_model_flags.json remake_owner1101_<creature>; creature_coat_flags.json creatures_vis_coat_<creature>; creature_scale_flags / creature_clip_flags / f36_pose_candidates (where the creature is named)
- F36 (1) Duskhush (-0.80): suspect creature_model_flags.json remake_owner1101_<creature>; creature_coat_flags.json creatures_vis_coat_<creature>; creature_scale_flags / creature_clip_flags / f36_pose_candidates (where the creature is named)
- F36 (1) Aquaryn (-1.02): suspect creature_model_flags.json remake_owner1101_<creature>; creature_coat_flags.json creatures_vis_coat_<creature>; creature_scale_flags / creature_clip_flags / f36_pose_candidates (where the creature is named)
- F36 (1) Cliffspike (-1.02): suspect creature_model_flags.json remake_owner1101_<creature>; creature_coat_flags.json creatures_vis_coat_<creature>; creature_scale_flags / creature_clip_flags / f36_pose_candidates (where the creature is named)
- F36 (0) #16 Ashtusk (-1.40): suspect creature_model_flags.json remake_owner1101_<creature>; creature_coat_flags.json creatures_vis_coat_<creature>; creature_scale_flags / creature_clip_flags / f36_pose_candidates (where the creature is named)

Folder notes: {}
