# Quick judge qj_macro: F41#5

- Head `c8443273a2dc310a60586083624b0dfb74cd8b6f`, tree `e53bfa4b1661`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormwood_ground_finish.json": ["macro_1104"]}`
- Capture: 2 launch(es); base 502s, candidate 489s, wall 992s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.2064, intercept -0.8829, r 0.8861, anchor RMSE 0.371, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#5 | forest ground and distance layers | 5.31 | **5.35** | +0.04 | 5.4 5 5 / 5.4 5.1 5 | PRESENT / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
