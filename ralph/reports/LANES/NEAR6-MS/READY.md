# NEAR6-MS (4 Nov 2026): running status

Lane: tb/near6-ms-1104 (from origin/main 12e76f2a, #813). Items F38#29, #6, #26, #7, #32 and F41#9, #20, #15, #3 (board 5.4-6.0). Yardstick: `tools/visual_judge/quick_judge.py` (CPU llvmpipe Low/Compatibility, base and candidate on the same stands, JUDGE_PROMPT verbatim, 3+ anchor pairs, three code-blind judges, calibrate.py). Owner 4 Nov: any judged CPU gain ships ON; flat or worse stays OFF.

## Landing-ready (flag, score, test, commit)

- **F41#20 P2-084 named character dialogue: CPU 4.72 -> 5.64** (`qj/F41-20-afe828ee024f-11040806/`). ON: `camfx.json fight_fade` and `camfx.json dialogue_open` (judged together; `_why_on` carries the score). Fenn's dialogue frame was black (camera inside a dark blocker); with the fade it shows Fenn. Test: `test_camfx_candidates.gd` (JUDGED_ON map; OFF paths still checked with the block forced off). **Tests passed (10:00 UTC):** test_camfx_candidates, test_conversation_camera, test_fight_camera, test_foliage_fight_fade, test_storm_cams_candidates, test_combat_camera_clear_orbit, test_texture_import_policy, test_near6_ms_1104, test_capacitor_spacing_override: 90 tests, 2102 assertions, 0 failed. Commit: see `git log` (flip commit after 4cebe0eb).

## Arms built (OFF until judged)

- F38#29 P2-065: `npc_post_stances.json beaten_trainer_stance.immediate_1104` (the beaten trainer drops to both knees, head bowed, the moment they lose; `post_stance.gd` rows take an optional hip drop). Test `test_near6_ms_1104.gd`. First candidate run was cut off by a timeout; rerun queued.
- F41#3 P2-092: `combat.json contact_spacing.named_overrides.capacitor_alpha` (taken from VIS-STORMWOOD `ea108029`). Test `test_capacitor_spacing_override.gd`.

## Judged flat or worse (stay OFF)

- **F38#29 P2-065 round 1: CPU 6.14 -> 6.22 (+0.08, flat)** (`qj/F38-29-6d8f80b7ac71-11040957/`). Arms: `npc_post_stances.json beaten_trainer_stance.immediate_1104` (beaten kneel) + `art.json grunt_a.clip_candidate`. One judge saw the hunched grunt (PARTIAL); the others saw no change because the grunt is a few pixels tall, behind or beside the player, in all three frames. All three judges asked for a camera beat that frames the defeated trainer. Next idea: a short post-victory shot on the beaten trainer (game presentation, not a capture stand change).

## Blockers / notes

- Harness note: a plain `git fetch origin <branch>` on this shallow clone pulled a 15 GB temp pack and filled the disk; `git fetch --depth=1 origin <branch>:refs/remotes/origin/<branch>` takes the same branches in seconds.
- **For the coordinator:** `send_message` from this lane is refused (untrusted device), so this file is the handoff. The F41#20 flip you asked for is on `tb/near6-ms-1104` at `f07442cc` with the touched tests passing.
- F38#29 kneel checked by render (`tools/_probe_beaten_kneel.gd`, grunt_a on a stage: knees flex back and rest on the floor, hips lowered, head bowed) before its round.
