# Quick judge qj_rootfloor3: F41#1

- Head `0a87d7c7122ea083d714e27f73361bac910fcc5b`, tree `352586fb6afb`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormheart_presentation.json": ["root_floor_1104"]}`
- Capture: 2 launch(es); base 499s, candidate 504s, wall 1003s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.0091, intercept 0.3647, r 0.6142, anchor RMSE 0.667, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#1 | Stormheart finale | 4.64 | **3.83** | -0.81 | 4.7 4.2 3.8 / 3.9 3.4 3 | PRESENT / PRESENT |

**Warnings:**
- some candidates lie more than 0.5 outside the anchors' measured range (extrapolated)

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
