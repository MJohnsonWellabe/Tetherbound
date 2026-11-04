# VIS-STORMWOOD: READY

**Landing-ready flags (judged CPU gains, ON, tests assert ON with the score):**

| Item | Flags ON | CPU score | Verdict | Commit | Test |
|---|---|---|---|---|---|
| ~~F41#19 seam clear r1~~ | **withdrawn**: r1 dropped the fissure ribbons and broke `test_stormwood_glass_field_identity` (24 fissures expected, got 0; coordinator held it OFF in batch 9). r2 (`e85d4d85`, OFF) keeps every fissure, darkened; re-judge `qj_seam2` queued, then the identity test runs with r2 ON before it is turned on | (r1 4.34 -> 5.30) | `qj/qj_seam/` | `e85d4d85` | `test_stormwood_basalt_crust`, `test_stormwood_glass_field_identity` |
| F41#10 Glass Sink | `hero_landmarks_1101.glass_sink`, `stormwood_glass_sink` `dark_pool_candidate` + `obsidian_1104` | **4.03 -> 5.07** | `j4/` | `84f06e8a` | `test_vis_stormwood_judged_on`, `test_hero_landmarks_1101`, `test_storm_cams_candidates`, `test_stormwood_glass_sink_obsidian` |
| F41#1 Stormheart | `stormheart_presentation` `deck_light_1101`, `hollow_floor`, `hero_interior.round2` | **3.22 -> 3.94** | `j1/` | `c1ebc1ff` | `test_vis_stormwood_judged_on`, `test_cause_stormwood_candidates` |
| F41#4 destinations | `stormwood_lantern_pools` `arrival_pools`, `basin`, `lantern_model`, `glow_fungi`, `grove` | **4.00 -> 4.59** | `j1/` | `c1ebc1ff` | `test_vis_stormwood_judged_on`, `test_stormwood_lantern_pools_grove` |
| F41#8 named silhouettes | `npc_role_accessories` | **4.72 -> 4.96** (offset-map caveat) | `j3/` | `155cdd39` | `test_vis_stormwood_judged_on` |

**FOR THE COORDINATOR (4 Nov ~08:45 UTC):** seam clear r1 has been withdrawn. r2 is OFF, re-judge queued. Region identity and look tests now run before any flag goes ON. Queued on this head:
- `test_stormheart_*` (presentation, ancient_trunk, canopy_atlas, split_bark, wayfinding)
- `test_stormwood_look`, `test_stormwood_crown_overlook`, `test_stormwood_charged_ground`, `test_stormwood_route_walkability`, `test_stormwood_surge`
- `test_character_appearance_variants`
- `test_stormwood_struck_sentinel_identity`, `test_stormwood_capacitor_grove_identity`, `test_stormwood_glass_field_identity`

Results land here.

**Tests on the synced head (06:20 UTC, after main merge `9faa85e1` and the j1-j4 commits), all 0 failed:**
- `test_vis_stormwood_judged_on` 4/25
- `test_cause_stormwood_candidates` 11/95
- `test_stormwood_lantern_pools_grove` 3/11
- `test_stormheart_branching_crown` 2/9
- `test_stormwood_basalt_crust` 2/5
- `test_hero_landmarks_1101` 8/76
- `test_storm_cams_candidates` 15/56
- `test_stormwood_glass_sink_obsidian` 2/8
- `test_stormwood_rank_marks` 2/11
- `test_stormwood_pool_satin` 2/4
- `test_stormwood_surge_presentation` 53/730
- `test_stormwood_restored_sky` 2/39
- `test_texture_import_policy` 2/1591

**Judged flat or worse, stay OFF:**
- F41#2 `phase_grade_1104` r1: 5.46 -> 5.46. r2 is built.
- F41#18 rim r2 + `rank_marks_1104`: 4.96 -> 4.99.
- F41#5 `pool_satin_1104`: 4.13 -> 4.20, and the judges split.
- F41#9 `stormwood_harvest_hero2`: 4.76 -> 4.59.

- F41#19 `basalt_crust_1104`: 5.25 -> 4.42 (`qj/qj_basalt/`).
- F41#2 `phase_grade_1104` r2: 4.40 -> 4.23 (`qj/qj_phase2/`). The approach is parked after two flat rounds.

- Stormwood `stormwood_look.foliage_grade_1104` (F41#5, F41#4): flat, 0.00 on both rows (`qj/qj_foliage/`). Both sides render identically: the variant_retint overlay does not reach the visible canopy. The cause needs an engine probe.

**Ownership change (coordinator, 4 Nov ~07:40):** F41#9, F41#20, F41#15 and F41#3 move to lane NEAR6-MS. My OFF arm `combat.contact_spacing.named_overrides.capacitor_alpha` (`ea108029`, `test_capacitor_spacing_override` 1/5) is theirs to judge. quick_judge cannot capture `phase2_capture_stormwood_fights.gd` (the tool refuses output outside its Phase 2 report folder); `tools/visual_judge/lane_bin/run_group.sh` retries under that folder.

**In the queue:**
- F41#1 `stormheart_presentation.meshy_interior` (carved root-wall panels).
- F41#10 `stormwood_glass_sink.obsidian_1104.r2` (sparser, fainter veins over larger plates; `ed9c65f7`).

**Open:**
- F41#20: Fenn's dialogue frame is black in both arms. The camera sits behind a dark blocker next to Fenn's seat. Moving the seat stales the scatter bake, so this needs an engine probe of the blocker first.
- Blender is blocked in this session.

**FOR THE COORDINATOR (4 Nov ~02:50 UTC; send_message is refused here, untrusted device):** merged as asked. `ae954029` merges `origin/tb/creatures-ralph` 7568796b: storm-light set ON, `phase_grade_1104` OFF, main's newer CI, routes and docs kept. One commit after it adds the F41#18 `rank_marks_1104` arm (OFF). Tests on this head, all 0 failed:
- `test_stormwood_surge_presentation` 53 tests / 728 assertions
- `test_stormwood_restored_sky` 2/39
- `test_cause_stormwood_candidates` 11/95
- `test_storm_cams_candidates` 15/55
- `test_stormwood_rank_marks` 2/11

## Session 2 (4 Nov 2026, shallow clone): setup

- Godot 4.7-stable installed by `tools/cloud_setup.sh` (first half); full import running; about 11 GB free.
- **Blocked: Blender.** Running a downloaded portable Blender is refused by this session's auto-mode safety check ("code from external"), so new meshes are built as procedural Godot geometry (scene-level, in code) instead. Owner or coordinator can allow it with a Bash permission rule.
- Merged without history (a shallow `--deepen` fetch grew past 4 GB and was stopped): `dc709159` takes the creatures-ralph versions of every lane file (storm-light set retuned and ON, flag-OFF arms, tests, `tools/visual_judge/lane_bin`) and the rim r1 ON from #808 (`tb/land-vis-11`). Nothing main changed later (CI, routes, `tools/earned_saves`) is touched.

## New arms (OFF until judged)

| Item | Arm | Commit | Test |
|---|---|---|---|
| F41#18 P2-056 uniforms | `stormwood_character_presentation.json rank_marks_1104`: pale shoulder knots (LeftArm/RightArm) and a neck collar ring in each officer's identity colour, larger for lieutenants and the captain | see `git log` | `test_stormwood_rank_marks.gd` (2/11) |
| F41#2 P2-042 surge phases | `stormwood_surge.json presentation.phase_grade_1104`: Calm higher-key sky with cloud breaks, Building lower indigo sky, denser fog and rain; Break, energies and ambient unchanged | `442053bb` | `test_cause_stormwood_candidates.gd test_phase_grade_separates_calm_from_building_and_keeps_break_rules` |

## Capture queue (one Godot at a time, `tools/visual_judge/lane_bin`)

1. `s1_base`: rows F41#1,2,3,4,5,8,9,10,15,16,18,19,20,21 (13 boots, `job.json` repro commands).
2. `s1_cand`: the same with `cand1` ON: rim r2 (F41#18), `npc_role_accessories` (F41#8), Stormheart `deck_light_1101`/`hollow_floor`/`hero_interior.round2` (F41#1), `hero_landmarks_1101.glass_sink` + `dark_pool_candidate` (F41#10), lantern pools `arrival_pools`/`basin`/`lantern_model`/`glow_fungi`/`grove` (F41#4), `stormwood_harvest_hero2` (F41#9), `phase_grade_1104` (F41#2), `hud.victory_focus` (F41#21), `combat.contact_spacing.named_overrides.hollows_alpha` (F41#3). Road puddles excluded (3/3 judges called them flat slabs in v1/b10).
3. Unscored baselines: `capture_stormwood_f10_matrix.gd --phases=calm,break` (F41#22, F41#24) and `capture_named_fights_f10_6.gd` (F22#4, Stormwood half).
