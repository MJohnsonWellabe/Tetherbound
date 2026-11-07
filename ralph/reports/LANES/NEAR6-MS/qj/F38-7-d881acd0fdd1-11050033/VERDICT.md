# Quick judge F38-7-d881acd0fdd1-11050033: F38#7

- Head `68b2d3697597199fe1e3728ff91e5e2452216e0a`, tree `de6e1501d3e8`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/combat.json": ["camera.occlusion_fade.aim_hide_1104"]}`
- Capture: 1 launch(es); base 1495s, candidate 1548s, wall 3042s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.345, intercept -2.1001, r 0.8835, anchor RMSE 0.401, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#7 | catch aim readability | 5.93 | **7.00** | +1.07 | 6 6.3 5.6 / 6.9 7 6.4 | PRESENT / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
