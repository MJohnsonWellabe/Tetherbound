# VIS-STORMWOOD: READY

**Landing-ready flags: none yet** (first CPU base and candidate are capturing).

## Session 2 (4 Nov 2026, shallow clone): setup

- Godot 4.7-stable installed by `tools/cloud_setup.sh` (first half); full import running; about 11 GB free.
- **Blocked: Blender.** Running a downloaded portable Blender is refused by this session's auto-mode safety check ("code from external"), so new meshes are built as procedural Godot geometry (scene-level, in code) instead. Owner or coordinator can allow it with a Bash permission rule.
- Merged without history (a shallow `--deepen` fetch grew past 4 GB and was stopped): `dc709159` takes the creatures-ralph versions of every lane file (storm-light set retuned and ON, flag-OFF arms, tests, `tools/visual_judge/lane_bin`) and the rim r1 ON from #808 (`tb/land-vis-11`). Nothing main changed later (CI, routes, `tools/earned_saves`) is touched.

## New arms (OFF until judged)

| Item | Arm | Commit | Test |
|---|---|---|---|
| F41#2 P2-042 surge phases | `stormwood_surge.json presentation.phase_grade_1104`: Calm higher-key sky with cloud breaks, Building lower indigo sky, denser fog and rain; Break, energies and ambient unchanged | `442053bb` | `test_cause_stormwood_candidates.gd test_phase_grade_separates_calm_from_building_and_keeps_break_rules` |

## Capture queue (one Godot at a time, `tools/visual_judge/lane_bin`)

1. `s1_base`: rows F41#1,2,3,4,5,8,9,10,15,16,18,19,20,21 (13 boots, `job.json` repro commands).
2. `s1_cand`: the same with `cand1` ON: rim r2 (F41#18), `npc_role_accessories` (F41#8), Stormheart `deck_light_1101`/`hollow_floor`/`hero_interior.round2` (F41#1), `hero_landmarks_1101.glass_sink` + `dark_pool_candidate` (F41#10), lantern pools `arrival_pools`/`basin`/`lantern_model`/`glow_fungi`/`grove` (F41#4), `stormwood_harvest_hero2` (F41#9), `phase_grade_1104` (F41#2), `hud.victory_focus` (F41#21), `combat.contact_spacing.named_overrides.hollows_alpha` (F41#3). Road puddles excluded (3/3 judges called them flat slabs in v1/b10).
3. Unscored baselines: `capture_stormwood_f10_matrix.gd --phases=calm,break` (F41#22, F41#24) and `capture_named_fights_f10_6.gd` (F22#4, Stormwood half).
