# mt: P2-106 (F40#11) thinner island mist, 4 Nov 2026

Arm: `cloudreach_visual.json:island_roots.mist_core_alpha` 0.62 -> 0.45 and `island_roots.low_mist.mist_below_m` 170 -> 260 (quick_judge `qj_mistthin`, tree dafcf4d3f2fe; scramble 0.3, landing_tree_clear and low_mist already ON in both arms).
Frames: terrace mounted at edge, terrace 1.0 s, terrace after recovery, terrace road back 1.5 s (CPU, Compatibility, 1920x1080). Three fresh code-blind judges, standard JUDGE_PROMPT, 3 anchor pairs (craft, f36_0_npc, f36_0_gap; seed 2626); `calibrate.py` linear, r 0.92, anchor RMSE 0.33 -> `calibrated.json`.

| Arm | Raw judges | Measured | Mapped |
|---|---|---|---|
| base | 5.7 / 5.6 / 5.7 | 5.67 | 6.00 |
| candidate | 6.1 / 6.0 / 6.0 | 6.03 | **6.43** |

Gain +0.43 mapped, all three judges prefer the candidate; puff defect PRESENT 3/3 -> PARTIAL 3/3 (the bank directly behind the deer now shows cliff, the remaining puffs are greyer and blend into the cloud floor). **Ships ON** (owner rule: a judged CPU gain ships ON).

Still asked (all three): the dark oval grass patch on the terrace reads as a decal; the grass is one saturated carpet; the cart floats with a weak contact shadow; the sky has no time-of-day grade.
