# Quick judge qj_groves: F40#1, F40#4, F40#7

- Head `d02df5264ae66564d3436ac87fe04c4976c1f95d`, tree `920f0ae7d3ec`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/cloudreach_cause.json": ["meadow_groves", "cloud_sea"]}`
- Capture: 2 launch(es); base 1813s, candidate 1750s, wall 3563s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.1728, intercept 0.057, r 0.7967, anchor RMSE 0.697, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#1 | open terrain | 6.39 | **6.16** | -0.23 | 5.4 5.4 5.4 / 5.2 5.2 5.2 | PRESENT / PRESENT |
| F40#4 | exposed landform edges | 6.47 | **6.31** | -0.16 | 5.5 5.4 5.5 / 5.3 5.3 5.4 | PRESENT / PRESENT |
| F40#7 | grass and stone finish | 6.51 | **6.51** | +0.00 | 5.4 5.6 5.5 / 5.4 5.7 5.4 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
