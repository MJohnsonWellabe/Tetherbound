# STORMCAMS lane (tb/vis-storm-cams): status

## Summary (1 Nov, 17:50 UTC; rolling batches)
- **Criteria closed: zero.** Nothing here is judged yet. Every candidate is flag-OFF on this branch; `MANIFEST.json` has 42 rows (item x flag x tool/biome) in four groups:
  - **Group 1** (dialogue camera, 11 items + Nalia + plaza paving): `twoshot_v2`, `speaker_light_candidate`, `water_npc_placement_candidate`, `plaza_paving_candidate`.
  - **Group 2** (Stormwood scene + catch camera): Crown Arch round 2, Glass Field rock collars, harvest heroes round 2, `catching.json framed_camera`.
  - **Group 3**: candy tiers (P2-045, working after a new approach), P2-082/P2-084 dialogue, Lantern Pools flags (P2-038), Stormwood character rim (P2-056, P2-055).
  - **Group 4**: road puddles (P2-040).
- **Both GPU arms need this branch's `tools/phase2_capture_dialogue.gd`**: it stands the player on Captain Marrow's Dynamo deck (it used to shoot him from the forest floor 150 m below), which the P2-083/P2-081 frames depend on.
- **Stand names** are the capture tools' own frame names: Tidewake dialogue frames are `water__...`; catch frames are the tool's file names (`03-strike`) under a per-biome camera set.
- **Parked:** P2-070 Glass Sink material (fog sets the floor colour; needs basin geometry); Fenn's frame in P2-084 (he stands against a giant trunk; a scatter-aware sight check made it worse and is off).
- **Landing note (twoshot_v2 ON):** `test_conversation_camera_aftermath_profile.gd::test_aftermath_lens_stays_near_a_far_speaker` asserts the ordinary push-in's lens stays more than 6 m from an 18 m speaker; twoshot_v2 frames closer by design, so that one assertion fails with the flag on. Left untouched; landing the flag ON needs it re-stated, not skipped. The "ships OFF" assertions in `test_storm_cams_candidates.gd` and `test_conversation_camera.gd` also flip at landing.
- **Composability:** flags are new keys or blocks inside existing configs, plus new files (`stormwood_harvest_hero2.json`, `water_npc_placement_candidate.json`, `stormwood_character_rim.json`); code hunks are local. No overlap with tb/vis-water-sky's `cloudreach_world.gd` hunks.
- **Checks:** every test file touching a changed script passes with all flags OFF (328 tests at 16:10, plus the later focused reruns, 0 failed).
- **Not attempted (other lanes or new art):** P2-087's stronghold grade itself, P2-044 (creatures), P2-092 (fight spacing), P2-109/P2-112/P2-089/P2-062 (mount and fight cameras).

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
| P2-045 (group 3) | `data/config/pickup_grounding.json` `tier_candidate.enabled` | Candy tiers as one / two / three sweets with a size step. Un-parked with a new idea: `candy_pickup_presentation.gd` tints and rings the candy after the pickup builds it, so copies are now made at the end of that dress. CPU r4: Good one green sweet, Great a blue pair, Rare a gold trio. |
| P2-082, P2-084 (group 3) | dialogue flags above | Stormwood dialogue items with the same fixture. Fenn stands against a giant trunk and his push-in frames bark; a scatter-aware sight check (`speaker_sight_multimesh`) made it worse (fully black) on CPU r2/r3, so it is parked (false) and Fenn's frame is expected to stay weak. Rook and Elder Maud frame well. |
| P2-056 (group 3) | `data/config/stormwood_character_rim.json` `enabled` | Cool fresnel backlight edge on every Stormwood person and trainer (material overlay). CPU r1 at 0.45 read only up close; r2 at 0.75 / power 2.4 gives Varga and Dace a visible edge against the dark ground in the post views. |
| P2-055 (group 3, Stormwood stands only) | `data/config/stormwood_character_rim.json` `enabled` | Same rim on Hesk, Maud and Bryn's post views (judges: 'tiny, near-identical figures'); separation only, it does not change their silhouettes. Secondary candidate. |
| P2-040 (group 4) | `data/config/stormwood_road_current.json` `puddle_candidate.enabled` | Soft-edged dark glossy puddles along every Stormwood road (2,723 placed; one MultiMesh per route), skipped on uneven ground. CPU r3: wet sky-catching patches on the Lantern Hollow road beside the gold current (r1 buried under the coarse terrain mesh, r2 culled by a visibility range; both fixed). |
| P2-038 (group 3) | `data/config/stormwood_lantern_pools.json` `lantern_model.enabled` and `arrival_pools.enabled` | Two existing, never GPU-judged flags (Meshy lantern posts, +0.75 on CPU 26 Oct; two pools inside the arrival view). CPU: three pools with glowing lips now read in the Lantern Pools frame. |
| P2-046 | `data/config/stormwood_harvest_hero2.json` `enabled` | Bigger harvest heroes; crown uses the tall glass-spike silhouette; grass clearings. Separate file so the scatter bake stays fresh. |
| P2-113, P2-059 | `data/config/catching.json` `framed_camera.enabled` | Existing, never GPU-judged catch camera candidate (wider aim, stand-off resolve shot). No change on this branch. |

## CPU sanity (Low/Compatibility llvmpipe; no scores)
- Stormwood dialogue, twoshot_v2 + fixture fix: Marrow (character and dynamo core) now framed on his deck with no overhead slab; Nysa medium-close. At 26 deg the trainer left frame entirely, so the swing is 22 deg.
- Tidewake dialogue, twoshot_v2 + speaker light: Nerissa pushed in medium-close and lit (GPU had her small in a dim wide shot); Bex and Irva read as over-the-shoulder two-shots with the trainer's shoulder at the left edge. Nalia: authored body refused by every stand (on the wall); with the placement candidate she is framed; moved 3.6 m out after r1 framed her against the wall.
- Cloudreach dialogue: Kelm and Veyra framed medium-close; plaza paving anchors corrected to their runtime bodies (re-check queued).
- Stormwood locations: Crown Arch seen edge-on by the catalogue camera (cause of "single tall pillar"); with round 2 turned to face the road, r2 reads clearly as an arch with its crown keystone (slab edge still hard; six stones per side after r2). Glass Field spikes sit on rock collars (lightened after r1).
- Tidewake P2-075 with the close-pair swing: Adair and Iona framed with the trainer at the left edge in profile, no overlap on the speaker.
- Stormwood P2-056 rim r2 (0.75 / 2.4): Varga and Dace show a cool edge against the ground in the post views. P2-082 Rook framed well with the corrected key light (r1's key blew the trainer's face white in close pairs).
- Tidewake Nalia r2 (placement 3.6 m out): framed against a valley view to the shore instead of the sand wall.
- Meadows: Quarry Foreman visible among the rock faces (P2-079); Warder Solene medium-close and lit in the courtyard (the stronghold's warm grade remains; P2-087 relies on the push-in and speaker light).
- Stormwood inventory: harvest heroes larger, crown grade a tall spike cluster distinct from plain stormglass; candy tier copies failed three ways (see P2-045 row); parked.
- Glass Sink r1/r2: the floor colour is set by distance fog at that depth; the material candidate barely shows. Parked.
