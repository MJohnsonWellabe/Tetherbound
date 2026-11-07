# Quick judge f38_38-readable-r4: F38#38

- Head `cb3cddac960567e55cbe0d206fe69339df3ca6b7`, tree `725e4f7e8377`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/craft_presentation.json": {"readable_r4": true}}`
- Capture: 1 launch(es); base 289s, candidate 298s, wall 587s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 0.9026, intercept 0.9771, r 0.5918, anchor RMSE 0.678, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#38 | craft action hint contrast | 7.17 | **7.33** | +0.16 | 6.9 6.9 6.8 / 7.2 7 6.9 | PARTIAL / FIXED |

**Warnings:**
- some candidates lie more than 0.5 outside the anchors' measured range (extrapolated)

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
