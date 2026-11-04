# NEAR6-MS (4 Nov 2026): running status

Lane: tb/near6-ms-1104 (from origin/main 12e76f2a, #813). Items F38#29, #6, #26, #7, #32 and F41#9, #20, #15, #3 (board 5.4-6.0). Yardstick: `tools/visual_judge/quick_judge.py` (CPU llvmpipe Low/Compatibility, base and candidate on the same stands, JUDGE_PROMPT verbatim, 3+ anchor pairs, three code-blind judges, calibrate.py). Owner 4 Nov: any judged CPU gain ships ON; flat or worse stays OFF.

## Landing-ready (flag, score, test, commit)

(none yet)

## Arms built (OFF until judged)

- F38#29 P2-065: `npc_post_stances.json beaten_trainer_stance.immediate_1104` (deeper bow attached the moment the trainer is beaten). Test `test_near6_ms_1104.gd`.
- F41#3 P2-092: `combat.json contact_spacing.named_overrides.capacitor_alpha` (taken from VIS-STORMWOOD `ea108029`). Test `test_capacitor_spacing_override.gd`.

## Judged flat or worse (stay OFF)

## Blockers / notes

- Harness note: a plain `git fetch origin <branch>` on this shallow clone pulled a 15 GB temp pack and filled the disk; `git fetch --depth=1 origin <branch>:refs/remotes/origin/<branch>` takes the same branches in seconds.
