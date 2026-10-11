# F35#1 / F35#3 code-blind verdict (coordinator, 2026-10-11, 3:02 PM CT)

Frames: tb/ev-captures 63e453886e5bce5de1121fa98d08c89a643edfd5, ralph/reports/VISUAL-PROOF/F35-1-3/ (ultimates rework ba2afbfc, Low, --fixed-fps 30). Neutral names, key withheld; the judge read no code. Execution: smoke_move_effects_library --batch=ultimates, 24 cases (12 uniques x b0/b5), 0 failures, 1 arrival each.

| Criterion | Verdict | Reason |
|---|---|---|
| F35#1 Unique ultimates exist (12, incl. storm bear) | PASS | All 12 fire and arrive (smoke). The reworked Veridian (crystal eruption), Fulgocobra (zigzag bolt) and Solmane (crescent slashes) each land on the target, grow at b5 and are distinct. Notes: Veridian's low tier is green on green; Fulgocobra's and Solmane's peaks are both a gold ring. |
| F35#3 Four-player readability | FAIL | The target stays visible, but three of the four attackers stop being drawn from contact on (visible at travel). Returned to the ultimates lane for root cause. |

**F35#3 re-judge, 3:37 PM CT: PASS.** Recapture tb/ev-captures 4b771487 (ralph/reports/VISUAL-PROOF/F35-3/) at e6fef6aad. The cause was in the harness: re-showing hidden attackers turned their physics back on over a collider-less stage, and they fell through it. The smoke and wrapper were fixed, with an assertion that every attacker stays posed at each beat. All four attackers are visible in every frame and the target stays readable. At contact the hits read as several distinct hits, busy but readable, and they fade by the late frame. No blocking defect. Timing half: unit test, 2.4 s windup plus recovery. Notes: per-attacker impact colours could be stronger; Veridian is partly occluded in the bunched staging.
