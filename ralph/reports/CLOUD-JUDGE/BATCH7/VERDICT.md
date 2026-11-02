# Batch 7 (all lanes merged, candidate flags ON) vs main: mapped Bar A

GPU frames from origin/tb/gpu-frames-1101 (batch7/ vs main/, same tool and camera). Standard JUDGE_PROMPT v1, 3 anchor pairs per folder (anchor_tiles.py), 3 independent code-blind judges per folder, calibrate.py --bar 7.0 (mapped_mean). Items with more than 4 stands were split into sub-sets of at most 4 stands; the item score is the mean of its sub-sets. Creatures are 2x2 pose grids (hit-000, hit-050, faint-050, faint-100).

| Item | main | batch 7 | delta | pairs | crossed 7.0 | notes |
|---|---|---|---|---|---|---|
| Character look: grunt | 6.29 | 6.85 | +0.56 | 3 |  |  |
| Character look: farmer | 6.38 | 6.84 | +0.46 | 2 |  |  |
| Character look: local_historian | 6.45 | 6.88 | +0.43 | 2 |  |  |
| Character look: lost_traveler | 6.10 | 6.53 | +0.43 | 2 |  |  |
| Character look: field_researcher | 6.53 | 6.84 | +0.31 | 2 |  |  |
| Character look: warden | 6.99 | 7.25 | +0.26 | 2 | YES |  |
| Character look: grunt_a | 6.21 | 6.47 | +0.26 | 2 |  |  |
| Character look: grunt_c | 6.47 | 6.71 | +0.24 | 2 |  |  |
| Character look: officer_b | 6.64 | 6.87 | +0.23 | 2 |  |  |
| Character close-ups: dialogue key and rim light (all speakers) | 5.20 | 5.42 | +0.22 | 51 |  | excluded: meadows-dialogue/meadows__inventory__character__corin.jpg (blank on batch7 and main) |
| Character look: officer_a | 6.41 | 6.61 | +0.20 | 2 |  |  |
| Character look: inn_helper | 7.11 | 7.31 | +0.20 | 2 | held |  |
| Character look: creature_caretaker | 6.94 | 7.14 | +0.20 | 2 | YES |  |
| Character look: captain_a | 6.54 | 6.67 | +0.13 | 2 |  |  |
| Character look: lyra | 7.07 | 7.17 | +0.10 | 2 | held |  |
| Character look: alpha_tracker | 6.21 | 6.28 | +0.07 | 2 |  |  |
| Character look: sera | 7.17 | 7.09 | -0.08 | 2 | held |  |
| Character look: grunt_b | 6.39 | 6.31 | -0.08 | 2 |  |  |
| Character look: kael | 7.17 | 7.07 | -0.10 | 2 | held |  |
| Character look: villager_keeper | 6.85 | 6.72 | -0.13 | 2 |  |  |
| Character look: former_tether_member | 5.68 | 5.54 | -0.14 | 2 |  |  |
| Character look: captain_b | 7.11 | 6.94 | -0.17 | 2 | LOST |  |
| Character look: craftsperson | 7.41 | 7.24 | -0.17 | 2 | held |  |
| Character look: rival_trainer | 6.38 | 6.21 | -0.17 | 2 |  |  |
| Character look: courier | 6.53 | 6.28 | -0.25 | 2 |  |  |
| Character look: villager_farmer | 6.90 | 6.26 | -0.64 | 2 |  |  |
| Character look: villager_smith | n/a | n/a | n/a | 0 |  | no comparable frame pair (stand missing on one side or not in the capture tool); missing: (not in the cast tool; villager_smith appears in-world) |
| Character look: villager_quarryman | n/a | n/a | n/a | 0 |  | no comparable frame pair (stand missing on one side or not in the capture tool); missing: (not in the cast tool; villager_quarryman appears in-world) |
| Character look: villager_ranger | n/a | n/a | n/a | 0 |  | no comparable frame pair (stand missing on one side or not in the capture tool); missing: (not in the cast tool; villager_ranger appears in-world) |

## Crossed 7.0 (main below, batch 7 at or above)

- Character look: warden: 6.99 -> 7.25
- Character look: creature_caretaker: 6.94 -> 7.14

## Gains of +0.3 or more and their flags

- Character look: grunt (+0.56): data/config/character_body_flags.json:flags.npc_vis_look_grunt.enabled
- Character look: farmer (+0.46): data/config/character_body_flags.json:flags.npc_vis_look_farmer.enabled
- Character look: local_historian (+0.43): data/config/character_body_flags.json:flags.npc_vis_look_local_historian.enabled
- Character look: lost_traveler (+0.43): data/config/character_body_flags.json:flags.npc_vis_look_lost_traveler.enabled
- Character look: field_researcher (+0.31): data/config/character_body_flags.json:flags.npc_vis_look_field_researcher.enabled

## Regressions (delta <= -0.3)

- Character look: villager_farmer (-0.64): suspect data/config/character_body_flags.json:flags.npc_vis_look_villager_farmer.enabled

## Flags ON in batch 7 (git diff origin/tb/vis-batch-7^ origin/tb/vis-batch-7 -- data/config)

- data/config/camera.json: conversation.speaker_lights.enabled
- data/config/character_body_flags.json: flags.npc_vis_look_kael.enabled, flags.npc_vis_look_sera.enabled, flags.npc_vis_look_lyra.enabled, flags.npc_vis_look_villager_farmer.enabled, flags.npc_vis_look_villager_keeper.enabled, flags.npc_vis_look_villager_smith.enabled, flags.npc_vis_look_villager_quarryman.enabled, flags.npc_vis_look_villager_ranger.enabled, flags.npc_vis_look_warden.enabled, flags.npc_vis_look_grunt.enabled, flags.npc_vis_look_grunt_a.enabled, flags.npc_vis_look_grunt_b.enabled, flags.npc_vis_look_grunt_c.enabled, flags.npc_vis_look_officer_a.enabled, flags.npc_vis_look_officer_b.enabled, flags.npc_vis_look_captain_a.enabled, flags.npc_vis_look_captain_b.enabled, flags.npc_vis_look_inn_helper.enabled, flags.npc_vis_look_craftsperson.enabled, flags.npc_vis_look_creature_caretaker.enabled, flags.npc_vis_look_farmer.enabled, flags.npc_vis_look_local_historian.enabled, flags.npc_vis_look_rival_trainer.enabled, flags.npc_vis_look_field_researcher.enabled, flags.npc_vis_look_lost_traveler.enabled, flags.npc_vis_look_alpha_tracker.enabled, flags.npc_vis_look_courier.enabled, flags.npc_vis_look_former_tether_member.enabled

Folder notes: {}
