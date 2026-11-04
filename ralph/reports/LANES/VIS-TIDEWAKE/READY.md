# VIS-TIDEWAKE lane (tb/vis-tidewake-1104): Tidewake F39 + F13#5, CPU judged

Owner rule (4 Nov): any judged CPU gain ships ON; only flat or worse stays OFF. Yardstick: `tools/visual_judge` (JUDGE_PROMPT verbatim, anchors, 3 judges, calibrate), via `quick_judge.py` from tb/judge-kit-1104.

## Landing-ready flags

| Flag | Row(s) | CPU base -> cand | Test | Commit |
|---|---|---|---|---|
| `water_mount_presentation.json` `enabled` (sink, bob, no blob shadow, new Aquaryn `wake`) | F39#8 | CPU 4.93 -> 6.09 | `test_uiposes_water_mount.gd::test_ships_on_with_its_judged_score` | this commit |
| `water_mount_presentation.json` `camera_hide.enabled` | F39#22 | CPU 5.25 -> 6.28 (FIXED 3/3) | same test; `smoke_camera_pass_through.gd` (hidden inside, shown outside) | this commit |
| `tidewake_look.json` `cause_tidewake.currents.enabled` | F39#17 | CPU 5.54 -> 6.09 | `test_tidewake_cause.gd::test_every_part_ships_off_and_off_changes_nothing`; `smoke_tidewake_b_current_restore.gd` (71 checks, 0 failed) | this commit |

Round 1 verdict: `qj/r1/VERDICT.md` (calibration r 0.73, RMSE 0.55, confirming). Local: the touched tests plus `test_texture_import_policy.gd` and `test_follower_leader_view_fade.gd`: 19 tests, 0 failed. Both smokes pass.

**Round 1, held OFF (flat or worse in the stacked c1 arm):** F39#1 shore 6.15 -> 5.99; F39#2 Veilfall 6.28 -> 5.19; F39#3 destinations 6.47 -> 5.83; F39#15 approach 6.21 -> 5.48; F39#16 live streaks 6.02 -> 5.89; F39#5 swim pose 5.93 -> 5.67; F39#14 swim contact 5.96 -> 5.57. All three judges blame the c1 Veilfall, a pale floating crystal crown from `veilfall_mountain_candidate` plus the light haze. The swim sections dropped the foam ring that the judges credit. Round 2 judges sea, light, horizon and dunes as separate arms, without the Veilfall mountain section and with the shipping swim ring kept.

## In flight

- **Round 1** (base vs c1, same boots): rows F39#1, #2, #3, #15, #16, #17, #5, #14, #8, #22 via quick_judge; F39#30/#31/#32 and F13#5 via `capture_tidewake_f13_5.gd` F39-look + T2-current.
  - c1 = `tidewake_look.json` cause_tidewake sea, light, currents, horizon, dunes ON; sections shore_surf(_vary), first_shore_declutter, stones, lesson_clusters, golden_sky, veilfall_falls, rain_veil, rain_fog, veilfall_mountain, swim, swim_stroke restored; `water_mount_presentation.json` enabled + new `camera_hide` (P2-109) + new Aquaryn `wake` (P2-108).
- New flag-off code: `creature_body.gd` camera_hide (`87f017f86`), `water_mount_wake.gd` (P2-108 wake).

## Status 04:21 UTC

- Round 1 base: 5/5 boots captured (routes 30, locations 2, current states 16, swimming 7, mounted swim 17 frames). Candidate boots began at 04:05; the judge packet is due about 05:45.
- After round 1: merge origin/main, then single-item quick_judge rounds from the cached base. Each judged gain is pushed ON with its score and a READY line as it passes.

## Plan

- 03:05 UTC: quick_judge is on main (c907b9997). origin/main merges into this branch once round 1's base and candidate captures finish, because a merge mid-round changes the render tree and drops the cached base. From then on, main's `tools/visual_judge/quick_judge.py` replaces the local copy.
- Container note: a container restart at ~01:55 wiped /dev/shm (import and the first base captures). The chain is now `runbook/resume.sh` (resumable, with .done markers) with a tracked background waiter.

## Round 2a (07:55 UTC): flat, stays OFF

Arm: `hero_landmarks_1101.veilfall`, `cause_tidewake.dunes`, and the shore_surf, shore_surf_vary, stones and lesson_clusters sections. Calibration r 0.95, RMSE 0.37 (`qj/r2a/VERDICT.md`).
F39#1 5.40 -> 5.45, F39#2 5.35 -> 5.19, F39#3 5.45 -> 5.40, F39#15 5.50 -> 5.56. All flat.
- Frame diffs change only 2-8% of pixels. The Meshy Veilfall draws only past 1100 m and none of these route stands is that far, so the arm never shows.
- Every judge asks for the same fixes:
  - new art: a terraced, green Veilfall with several broad falls and mist at the base;
  - scene: irregular shallows instead of the rest-shoal disc chain, plus wet-sand, foam, rock and driftwood bands and haze;
  - new art: hero structures at the destinations.
- Owner reassignment (coordinator, 07:42): F39#27/#1/#6/#7/#20/#2/#14/#19/#4 move to the NEAR6-TW lane. This lane keeps #3, #15, #16, #17, #5, #8, #22, #24, #21, #30, #31, #32 and F13#5.

## Harness finding for main's quick_judge.py

- `find_frame` misses every Tidewake route and location frame. Those tools write `water__<stand>__…` files, but job.json ids are `tidewake__<stand>__…`, so F39#1/#2/#3/#15 (and every route row) build no sets. Fix: `runbook/qj_patch.py` part 1 (try `water__` + the id's tail). Main's copy at c907b9997 has the same bug.

## Blockers

- **No merge of origin/main here:** a depth-1 fetch has no merge base, and `git fetch --deepen=40` ran out of disk (66 MB free). The coordinator's landing PR has to merge this branch with main.

- Container disk: the 21 GB `.git` pack fills the allowance (117 MB free). Godot's `.godot` import cache, captures and judge folders run from `/dev/shm` (RAM). Rewriting the pack to depth 1 was refused by the permission classifier.
