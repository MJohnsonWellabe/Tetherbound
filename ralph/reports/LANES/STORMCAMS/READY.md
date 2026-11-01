# STORMCAMS lane (tb/vis-storm-cams): status

## Summary (1 Nov, 16:15 UTC; rolling batches, coordinator sweeps every ~45 min)
- **Criteria closed: zero.** Nothing here is judged; every candidate is flag-OFF on this branch and listed in `MANIFEST.json` (32 rows, one per item x flag x tool/biome; `group` 1 = dialogue camera + Nalia + plaza paving, `group` 2 = Stormwood scene + catch camera).
- **Stand names** are the capture tools' own frame names: Tidewake dialogue frames are `water__...` (the tool's prefix; the catalogue says `tidewake__`), catch frames are the tool's file names (`03-strike`) under a per-biome camera set.
- **Biggest swings (CPU sanity only, no scores):**
  - Dialogue camera (11 items): `twoshot_v2` + `speaker_light_candidate`. Every dialogue frame captured on CPU now frames its speaker medium-close beside the panel (Marrow, Nysa, Nerissa, Nalia, Bex, Irva, Kelm, Veyra, Solene, Hald, Quarry Foreman).
  - P2-083/P2-081 Marrow: fixed in the dialogue capture fixture (always on): it stood the player on the forest floor 150 m under Marrow's Dynamo deck. **Both GPU arms must use this branch's `tools/phase2_capture_dialogue.gd`** or the Marrow frames are not comparable.
  - P2-074 Nalia: authored spot is up a sand wall with no stand; placement candidate moves her to the flat below.
  - P2-041 Crown Arch: the catalogue camera (and the road) saw the Meshy arch edge-on; round 2 turns it to face the road and it reads as an arch.
  - P2-076 plaza paving around Kelm and Veyra (anchored on their runtime bodies; Veyra's on the measured summit floor).
  - P2-046 bigger harvest heroes, distinct crown silhouette; P2-043 rock collars at the spike feet.
  - P2-113/P2-059: existing never-judged `catching.json framed_camera` (no change here).
- **Parked:** P2-070 Glass Sink material (fog sets the floor colour at that depth; needs basin geometry).
- **Composability:** flag keys are new blocks inside existing configs; code hunks are local (`conversation_camera.gd`, `cloudreach_world.gd` route-detail loop, Water NPC placement reads via one helper). No overlap found with tb/vis-water-sky's `cloudreach_world.gd` hunks.
- **Landing note (twoshot_v2 ON):** `test_conversation_camera_aftermath_profile.gd::test_aftermath_lens_stays_near_a_far_speaker` asserts the ordinary push-in's lens stays more than 6 m from an 18 m speaker; twoshot_v2 frames closer by design, so that assertion fails with the flag on. It is left untouched here; landing the flag ON needs it re-stated, not skipped. My own 'ships OFF' assertions also flip at landing.
- **Checks:** 328 focused unit tests (every test file touching a changed script, incl. flag scopes) pass, 0 failed, with all flags OFF.
- **Not in scope / not attempted:** P2-087's stronghold orange grade itself (only the push-in and speaker light reach it), P2-056, P2-044 (creature lane), P2-038, P2-092, P2-040.

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
| P2-045 (group 3) | `data/config/pickup_grounding.json` `tier_candidate.enabled` | Candy tiers as one / two / three sweets with a size step. Un-parked with a new idea: `candy_pickup_presentation.gd` tints and rings the candy after the pickup builds it, so copies are now made at the end of that dress. CPU r4: Good one green sweet, Great a blue pair, Rare a gold trio. |
| P2-082, P2-084 (group 3) | dialogue flags above | Stormwood dialogue items with the same fixture. Fenn's push-in framed a scattered trunk: twoshot_v2 now also makes the sight test see tall MultiMesh scatter (`speaker_sight_multimesh`). |
| P2-056 (group 3) | `data/config/stormwood_character_rim.json` `enabled` | Cool fresnel backlight edge on every Stormwood person and trainer (material overlay). CPU r1 at 0.45 read only up close; r2 at 0.75 / power 2.4 gives Varga and Dace a visible edge against the dark ground in the post views. |
| P2-038 (group 3) | `data/config/stormwood_lantern_pools.json` `lantern_model.enabled` and `arrival_pools.enabled` | Two existing, never GPU-judged flags (Meshy lantern posts, +0.75 on CPU 26 Oct; two pools inside the arrival view). CPU: three pools with glowing lips now read in the Lantern Pools frame. |
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
