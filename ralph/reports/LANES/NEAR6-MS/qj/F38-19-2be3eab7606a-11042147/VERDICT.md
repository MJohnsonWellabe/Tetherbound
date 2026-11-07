# Quick judge F38-19-2be3eab7606a-11042147: F38#19

- Head `e715dc26254bc6d46613fe9fd3b6815b03593ad9`, tree `068c68b5a4a2`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/hud.json": ["quiet_empty_chips_1104"]}`
- Capture: 1 launch(es); base 2002s, candidate 1940s, wall 3942s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.4876, intercept -3.0828, r 0.9824, anchor RMSE 0.193, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#19 | exploration HUD | 5.64 | **5.69** | +0.05 | 5.5 6.1 6 / 5.7 6 6 | PRESENT / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
