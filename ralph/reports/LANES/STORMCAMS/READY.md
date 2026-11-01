# STORMCAMS lane (tb/vis-storm-cams): status

Lane scope: Stormwood (F41) scene/material/placement items and every dialogue-camera item; camera-class items.
Hand-off per coordinator update (1 Nov): no single-candidate READY lines; every candidate is listed in `MANIFEST.json` with its flag (all default OFF on this branch) for the 18:00 UTC `tb/vis-batch1` build.

## Candidates on this branch (all flags OFF)
| Item(s) | Flag | What it changes |
|---|---|---|
| P2-083, P2-081, P2-074, P2-073, P2-076, P2-087, P2-075, P2-077, P2-078, P2-079, P2-086 | `data/config/camera.json` `conversation.twoshot_v2.enabled` | Dialogue push-in closer (2.9 m), leans onto the speaker (0.86), wider swing (22 deg) with the speaker-in-frame search; trainer becomes a shoulder at the edge. |
| same | `data/config/camera.json` `conversation.speaker_light_candidate.enabled` | Soft lens-side key and cool rim light on the speaker while the push-in is up; freed on close. |
| P2-083, P2-081 (always on, capture fixture) | `tools/phase2_capture_dialogue.gd` | The dialogue fixture stands the player on Captain Marrow's Dynamo deck (raised collider within 2.5 m of the speaker's height) instead of the forest floor 150 m below. Tool change only; game unchanged. |
| P2-076 | `data/config/cloudreach_visual.json` `route_details.plaza_paving_candidate.enabled` | Stone paving apron and edge rocks around Kelm's and Veyra's posts. |
| P2-070 | `data/config/stormwood_glass_sink.json` `dark_pool_candidate.enabled` | Near-black obsidian sink floor with pale seams; far fade so it stops mirroring the sky. |
| P2-041 | `data/config/crown_arch_hero.json` `round2_candidate.enabled` | Arch 7.0 m; rock dressing breaks the square slab edge. |
| P2-043 | `data/config/stormwood_glass_field.json` `rock_collar_candidate.enabled` | Rock collar at each Meshy spike foot; flat scar patch hidden. |
| P2-045 | `data/config/pickup_grounding.json` `tier_candidate.enabled` | Candy tiers as one / two / three sweets with a size step. |
| P2-046 | `data/config/stormwood_harvest_hero2.json` `enabled` | Bigger harvest heroes; crown uses the tall glass-spike silhouette; grass clearings. Separate file so the scatter bake stays fresh. |
| P2-113, P2-059 | `data/config/catching.json` `framed_camera.enabled` | Existing, never GPU-judged catch camera candidate (wider aim, stand-off resolve shot). No change on this branch. |

## CPU sanity (Low/Compatibility llvmpipe; no scores)
- Stormwood dialogue, twoshot_v2 + fixture fix: Marrow (character and dynamo core) now framed on his deck with no overhead slab; Nysa medium-close. At 26 deg the trainer left frame entirely, so the swing is 22 deg.
