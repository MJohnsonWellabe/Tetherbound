# Batch 5 (all lanes merged, candidate flags ON) vs main: mapped Bar A

GPU frames from origin/tb/gpu-frames-1101 (batch5/ vs main/, same tool and camera). Standard JUDGE_PROMPT v1, 3 anchor pairs per folder (anchor_tiles.py), 3 independent code-blind judges per folder, calibrate.py --bar 7.0 (mapped_mean). Items with more than 4 stands were split into sub-sets of at most 4 stands; the item score is the mean of its sub-sets. Creatures are 2x2 pose grids (hit-000, hit-050, faint-050, faint-100).

| Item | main | batch 5 | delta | pairs | crossed 7.0 | notes |
|---|---|---|---|---|---|---|
| F36 (0) #22 Abyssal Guardian | 6.09 | 6.96 | +0.87 | 4 |  |  |
| F36 (1) Paddlenewt | 6.50 | 7.16 | +0.66 | 4 | YES |  |
| SHARED-CAM-OCCLUSION [dialogue stormwood] | 5.32 | 5.94 | +0.62 | 16 |  |  |
| SHARED-STORMWOOD-LIGHT [dialogue stormwood] | 5.32 | 5.94 | +0.62 | 16 |  | same frames as SHARED-CAM-OCCLUSION [dialogue stormwood]; shares its sets and score |
| P2-071 | 6.60 | 7.21 | +0.61 | 3 | YES |  |
| SHARED-CAM-OCCLUSION [dialogue meadows] | 4.97 | 5.50 | +0.53 | 3 |  | missing: meadows__inventory__character__garrick__dialogue, meadows__inventory__trainer__captain_field__dialogue, meadows__inventory__trainer__old_champion_bram__dialogue, meadows__inventory__trainer__stronghold_courtyard__dialogue, meadows__inventory__trainer__stronghold_elite__dialogue, meadows__inventory__trainer__tournament_final_oskar__dialogue, meadows__inventory__trainer__tournament_quarter_mira__dialogue, meadows__inventory__trainer__tournament_semi_tam__dialogue |
| P2-048 | 7.01 | 7.52 | +0.51 | 1 | held |  |
| SHARED-STORMWOOD-LIGHT [locations stormwood] | 5.64 | 5.99 | +0.35 | 12 |  |  |
| SHARED-CAM-OCCLUSION [dialogue cloudreach] | 6.61 | 6.84 | +0.23 | 5 |  |  |
| SHARED-CAM-OCCLUSION [meadows-dialogue] | 5.33 | 5.52 | +0.19 | 9 |  | excluded: meadows-dialogue/meadows__inventory__character__corin.jpg (blank on main) |
| SHARED-STORMWOOD-LIGHT [world_inventory stormwood] | 5.51 | 5.70 | +0.19 | 6 |  |  |
| SHARED-STORMWOOD-LIGHT [stormwood_glass_sink stormwood] | 5.29 | 5.46 | +0.17 | 3 |  |  |
| P2-040 | 5.73 | 5.89 | +0.16 | 3 |  |  |
| SHARED-STORMWOOD-LIGHT [routes stormwood] | 6.23 | 6.36 | +0.13 | 1 |  |  |
| SHARED-CAM-OCCLUSION [meadows-locations] | 5.55 | 5.65 | +0.10 | 24 |  |  |
| P2-020/P2-017 | 7.64 | 7.67 | +0.03 | 8 | held |  |
| SHARED-CAM-OCCLUSION [meadows-world_inventory] | 6.28 | 6.30 | +0.02 | 6 |  |  |
| P2-013 | 6.19 | 6.19 | +0.00 | 5 |  |  |
| P2-065 [world_inventory] | 6.21 | 6.21 | +0.00 | 3 |  |  |
| SHARED-CAM-OCCLUSION [meadows-build_systems-07f6f8] | 6.24 | 6.24 | +0.00 | 4 |  |  |
| P2-065 [fights] | 6.17 | 6.17 | +0.00 | 3 |  |  |
| SHARED-CAM-OCCLUSION [meadows-routes] | 6.02 | 6.01 | -0.01 | 15 |  |  |
| SHARED-CAM-OCCLUSION [dialogue water] | 6.35 | 6.32 | -0.03 | 9 |  |  |
| P2-069 | 6.35 | 6.26 | -0.09 | 1 |  |  |
| F36 (1) Mosshock | 6.55 | 6.45 | -0.10 | 4 |  |  |
| SHARED-CAM-OCCLUSION [meadows-fights-f312a5] | 5.64 | 5.47 | -0.17 | 68 |  | excluded: meadows-fights-f312a5/warden_aldis-r01.jpg (blank on main), meadows-fights-f312a5/warden_aldis-r02.jpg (blank on main), meadows-fights-f312a5/warden_aldis-r03.jpg (blank on main), meadows-fights-f312a5/warden_aldis-r04.jpg (blank on main) |
| SHARED-STORMWOOD-LIGHT [stormwood_fights stormwood] | 5.76 | 5.53 | -0.23 | 8 |  | missing: stormwood-stormwood_fights-296dd9/hollows_alpha-i13.jpg (no batch5) (no main) |
| F36 (0) #7 Meadowhart | 7.67 | 6.91 | -0.76 | 4 | LOST |  |

## Crossed 7.0 (main below, batch 5 at or above)

- F36 (1) Paddlenewt: 6.50 -> 7.16
- P2-071: 6.60 -> 7.21

## Gains of +0.3 or more and their flags

- F36 (0) #22 Abyssal Guardian (+0.87): data/config/creature_model_flags.json:remake_owner1101_abyssal_guardian
- F36 (1) Paddlenewt (+0.66): data/config/creature_model_flags.json:remake_owner1101_paddlenewt
- SHARED-CAM-OCCLUSION [dialogue stormwood] (+0.62): data/config/camera.json:occlusion_fade.enabled
- SHARED-STORMWOOD-LIGHT [dialogue stormwood] (+0.62): data/config/stormwood_look.json:light_pass_1101.enabled
- P2-071 (+0.61): data/config/human_swim_visual.json:uiposes_stroke_candidates
- SHARED-CAM-OCCLUSION [dialogue meadows] (+0.53): data/config/camera.json:occlusion_fade.enabled
- P2-048 (+0.51): data/config/menu.json:map_region_header.enabled
- SHARED-STORMWOOD-LIGHT [locations stormwood] (+0.35): data/config/stormwood_look.json:light_pass_1101.enabled

## Regressions (delta <= -0.3)

- F36 (0) #7 Meadowhart (-0.76): suspect data/config/creature_model_flags.json:remake_owner1101_meadowhart

## Flags ON in batch 5 (git diff origin/tb/vis-batch-5^ origin/tb/vis-batch-5 -- data/config)

- data/config/art.json: grunt_a.clip_candidate.enabled
- data/config/bands/band3_the_river_lock/props.json: clusters[relay_station].candidate_props.enabled
- data/config/camera.json: occlusion_fade.enabled
- data/config/creature_model_flags.json: flags.remake_owner1101_meadowhart.enabled, flags.remake_owner1101_mosshock.enabled, flags.remake_owner1101_paddlenewt.enabled, flags.remake_owner1101_abyssal_guardian.enabled
- data/config/creature_scale_flags.json: flags.creatures_f36_taller_than_trainer_4.enabled
- data/config/fly_traversal.json: landing_presentation.wing_fold_enabled
- data/config/human_swim_visual.json: uiposes_stroke_candidates
- data/config/menu.json: map_region_header.enabled
- data/config/npc_post_stances.json: beaten_trainer_stance.enabled
- data/config/stormwood_look.json: light_pass_1101.enabled
- data/config/stormwood_road_current.json: puddle_candidate.enabled

Folder notes: {}
