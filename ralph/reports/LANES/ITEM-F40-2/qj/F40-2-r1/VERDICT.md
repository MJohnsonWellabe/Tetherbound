# Quick judge F40-2-r1: F40#2

- Head `563f4a1692c35051a9c6f59856b349bfc2eb9637`, tree `916e35dff453`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/cloudreach_f40_items.json": ["candidates.12"]}`
- Capture: 3 launch(es); base 1335s, candidate 1312s, wall 2648s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.6852, intercept -3.3965, r 0.9106, anchor RMSE 0.477, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#2 | summit aviary | 6.88 | **6.15** | -0.73 | 6.4 5.6 6.3 / 5.9 5.2 5.9 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
