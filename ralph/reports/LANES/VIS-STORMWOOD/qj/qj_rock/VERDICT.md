# Quick judge qj_rock: F41#10, F41#4

- Head `25238cd63812b0f54599a61602fbe3041114c9d4`, tree `7eae0eaf8f82`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormwood_ground_finish.json": ["rock_value_1104"]}`
- Capture: 4 launch(es); base 589s, candidate 1208s, wall 1797s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.2192, intercept -1.1872, r 0.8692, anchor RMSE 0.601, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#10 | Glass Sink landmark | 4.50 | **4.50** | +0.00 | 4.6 4.6 4.8 / 4.6 4.6 4.8 | PARTIAL,PRESENT / PARTIAL,PRESENT |
| F41#4 | named destination identities | 5.15 | **5.15** | +0.00 | 5 5 5.6 / 5 5 5.6 | PARTIAL,PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
