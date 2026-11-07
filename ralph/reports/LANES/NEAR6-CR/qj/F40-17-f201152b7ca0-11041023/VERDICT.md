# Quick judge F40-17-f201152b7ca0-11041023: F40#17

- Head `e44333c2d6b101da1dc7ef2ba897f32ebe5c7471`, tree `aac6747bc5dc`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/cloudreach_physical_runtime.json": {"rim_pickup_in_view": {"enabled": true}}}`
- Capture: 1 launch(es); base 0s (cached), candidate 976s, wall 1185s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.0, intercept 0.1233, r 0.6829, anchor RMSE 0.63, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#17 | High Perches rim mushroom | 5.09 | **5.72** | +0.63 | 5.2 4.9 4.8 / 5.9 5.3 5.6 | PARTIAL / FIXED,PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
