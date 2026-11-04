# Quick judge qj_heart: F41#1

- Head `ed9c65f75d167b706669f0a75f19388e2b9a7bb7`, tree `930e300cee0a`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormheart_presentation.json": ["meshy_interior"]}`
- Capture: 2 launch(es); base 445s, candidate 434s, wall 879s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.2949, intercept -0.7915, r 0.8364, anchor RMSE 0.657, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#1 | Stormheart finale | 4.91 | **4.91** | +0.00 | 4.2 4.6 4.4 / 4.2 4.6 4.4 | PRESENT / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
