# Quick judge F40-17-ade4ecff4c0e-11040935: F40#17

- Head `0e7df5ab38a67cd778117d64f8983e8544e77008`, tree `4ca1579c58bc`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/cloudreach_physical_runtime.json": {"rim_pickup_inset": {"enabled": true}}}`
- Capture: 1 launch(es); base 0s (cached), candidate 1006s, wall 1006s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.7716, intercept -4.2266, r 0.9843, anchor RMSE 0.248, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#17 | High Perches rim mushroom | 4.57 | **4.57** | +0.00 | 5 4.9 5 / 5.3 4.8 4.8 | PARTIAL,PRESENT / FIXED |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
