# Quick judge F41-1-589bb668d6a4-11072122: F41#1

- Head `7a9c0073365b26390e5358f34af07d7601b6dff9`, tree `a67b1ccf648f`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormheart_presentation.json": ["heart_cradle_1107"]}`
- Capture: 2 launch(es); base 381s, candidate 379s, wall 760s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.1604, intercept -0.0878, r 0.8007, anchor RMSE 0.691, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#1 | Stormheart finale | 5.60 | **5.29** | -0.31 | 4.8 5 4.9 / 4.6 4.7 4.6 | PARTIAL,PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
