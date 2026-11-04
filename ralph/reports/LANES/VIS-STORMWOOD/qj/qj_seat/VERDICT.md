# Quick judge qj_seat: F41#19

- Head `0eb3267f6aa9f5ae99aa3abe9c966f4c63d69a1c`, tree `6fafffc16359`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormwood_glass_field.json": ["seam_clear_1104.seat_1104"]}`
- Capture: 1 launch(es); base 658s, candidate 650s, wall 1308s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3232, intercept -0.9706, r 0.9012, anchor RMSE 0.6, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#19 | Glass Field spike bases | 5.56 | **5.56** | +0.00 | 4.6 5.4 4.8 / 4.6 5.4 4.8 | PARTIAL,PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
