# VIS-TIDEWAKE lane (tb/vis-tidewake-1104): Tidewake F39 + F13#5, CPU judged

Owner rule (4 Nov): any judged CPU gain ships ON; only flat or worse stays OFF. Yardstick: `tools/visual_judge` (JUDGE_PROMPT verbatim, anchors, 3 judges, calibrate), via `quick_judge.py` from tb/judge-kit-1104.

## Landing-ready flags

| Flag | Row(s) | CPU base -> cand | Test | Commit |
|---|---|---|---|---|
| (none yet) | | | | |

## In flight

- **Round 1** (base vs c1, same boots): rows F39#1, #2, #3, #15, #16, #17, #5, #14, #8, #22 via quick_judge; F39#30/#31/#32 and F13#5 via `capture_tidewake_f13_5.gd` F39-look + T2-current.
  - c1 = `tidewake_look.json` cause_tidewake sea, light, currents, horizon, dunes ON; sections shore_surf(_vary), first_shore_declutter, stones, lesson_clusters, golden_sky, veilfall_falls, rain_veil, rain_fog, veilfall_mountain, swim, swim_stroke restored; `water_mount_presentation.json` enabled + new `camera_hide` (P2-109) + new Aquaryn `wake` (P2-108).
- New flag-off code: `creature_body.gd` camera_hide (`87f017f86`), `water_mount_wake.gd` (P2-108 wake).

## Plan

- 03:05 UTC: quick_judge is on main (c907b9997). origin/main merges into this branch once round 1's base and candidate captures finish, because a merge mid-round changes the render tree and drops the cached base. From then on, main's `tools/visual_judge/quick_judge.py` replaces the local copy.
- Container note: a container restart at ~01:55 wiped /dev/shm (import and the first base captures). The chain is now `runbook/resume.sh` (resumable, with .done markers) with a tracked background waiter.

## Blockers

- Container disk: the 21 GB `.git` pack fills the allowance (117 MB free). Godot's `.godot` import cache, captures and judge folders run from `/dev/shm` (RAM). Rewriting the pack to depth 1 was refused by the permission classifier.
