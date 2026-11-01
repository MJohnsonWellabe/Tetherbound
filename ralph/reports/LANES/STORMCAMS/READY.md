# STORMCAMS lane (tb/vis-storm-cams): status

Lane scope: Stormwood (F41) scene/material/placement items and every dialogue-camera item; camera-class items.
Hand-off per coordinator update (1 Nov): no single-candidate READY lines; every candidate is listed in `MANIFEST.json` with its flag (all default OFF on this branch) for the 18:00 UTC `tb/vis-batch1` build.

## Candidates on this branch (all flags OFF)
| Item(s) | Flag | What it changes |
|---|---|---|
| P2-083, P2-081, P2-074, P2-073, P2-076, P2-087, P2-075, P2-077, P2-078, P2-079, P2-086 | `data/config/camera.json` `conversation.twoshot_v2.enabled` | Dialogue push-in closer (2.9 m), leans onto the speaker (0.86), wider swing (22 deg) with the speaker-in-frame search; trainer becomes a shoulder at the edge. |
| same | `data/config/camera.json` `conversation.speaker_light_candidate.enabled` | Soft lens-side key and cool rim light on the speaker while the push-in is up; freed on close. |
| P2-083, P2-081 (always on, capture fixture) | `tools/phase2_capture_dialogue.gd` | The dialogue fixture stands the player on Captain Marrow's Dynamo deck (raised collider within 2.5 m of the speaker's height) instead of the forest floor 150 m below. Tool change only; game unchanged. |
| P2-076 | `data/config/cloudreach_visual.json` `route_details.plaza_paving_candidate.enabled` | Stone paving apron and edge rocks around where Kelm and Veyra actually stand (their runtime bodies are 14 m and 100 m from the authored posts). |
| P2-074 | `data/config/water_npc_placement_candidate.json` `enabled` | Resident Nalia moves off the steep sand wall (her authored spot is ~12 m above the post with no walkable stand) to the flat ground 3.6 m from the post; body, host speech reach and grass clearance read the same offset. |
| P2-070 (PARKED, not in manifest) | `data/config/stormwood_glass_sink.json` `dark_pool_candidate.enabled` | Darker obsidian floor and far fade. CPU r1/r2: barely visible; at the sink's depth the Stormwood distance fog sets the floor colour, not its material, so no >0.5 gain is expected. Needs the basin geometry the judges asked for (new art). |
| P2-041 | `data/config/crown_arch_hero.json` `round2_candidate.enabled` | Arch visual turned 90 deg to face the road (the catalogue camera and every road approach saw it edge-on as a single pillar), 7.0 m tall; small rock dressing breaks the square slab edge. |
| P2-043 | `data/config/stormwood_glass_field.json` `rock_collar_candidate.enabled` | Rock collar at each Meshy spike foot; flat scar patch hidden. |
| P2-045 (PARKED, not in manifest) | `data/config/pickup_grounding.json` `tier_candidate.enabled` | Candy tiers as one / two / three sweets. CPU r1/r2: duplicated copies came back as oversized green sweets (both duplicate modes); r3 (copies from the pickup's own factory) produced no copies for the Stormwood candies. Two misses plus a changed approach: parked. Next idea: find which builder makes the Stormwood candy visual and add the tier copies there. |
| P2-046 | `data/config/stormwood_harvest_hero2.json` `enabled` | Bigger harvest heroes; crown uses the tall glass-spike silhouette; grass clearings. Separate file so the scatter bake stays fresh. |
| P2-113, P2-059 | `data/config/catching.json` `framed_camera.enabled` | Existing, never GPU-judged catch camera candidate (wider aim, stand-off resolve shot). No change on this branch. |

## CPU sanity (Low/Compatibility llvmpipe; no scores)
- Stormwood dialogue, twoshot_v2 + fixture fix: Marrow (character and dynamo core) now framed on his deck with no overhead slab; Nysa medium-close. At 26 deg the trainer left frame entirely, so the swing is 22 deg.
- Tidewake dialogue, twoshot_v2 + speaker light: Nerissa pushed in medium-close and lit (GPU had her small in a dim wide shot); Bex and Irva read as over-the-shoulder two-shots with the trainer's shoulder at the left edge. Nalia: authored body refused by every stand (on the wall); with the placement candidate she is framed; moved 3.6 m out after r1 framed her against the wall.
- Cloudreach dialogue: Kelm and Veyra framed medium-close; plaza paving anchors corrected to their runtime bodies (re-check queued).
- Stormwood locations: Crown Arch seen edge-on by the catalogue camera (cause of "single tall pillar"); with round 2 turned to face the road, r2 reads clearly as an arch with its crown keystone (slab edge still hard; six stones per side after r2). Glass Field spikes sit on rock collars (lightened after r1).
- Tidewake Nalia r2 (placement 3.6 m out): framed against a valley view to the shore instead of the sand wall.
- Meadows: Quarry Foreman visible among the rock faces (P2-079); Warder Solene medium-close and lit in the courtyard (the stronghold's warm grade remains; P2-087 relies on the push-in and speaker light).
- Stormwood inventory: harvest heroes larger, crown grade a tall spike cluster distinct from plain stormglass; candy tier copies failed three ways (see P2-045 row); parked.
- Glass Sink r1/r2: the floor colour is set by distance fog at that depth; the material candidate barely shows. Parked.
