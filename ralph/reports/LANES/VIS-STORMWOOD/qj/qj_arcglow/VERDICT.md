# Quick judge qj_arcglow: F41#1

- Head `26efd7181756351ab24c911b9cdecdf9b2df29c2`, tree `32fbe2f8c40c`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormheart_presentation.json": ["hero_interior.round2.arcs.glow_1104"]}`
- Capture: 2 launch(es); base 506s, candidate 491s, wall 997s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 0.9449, intercept 0.8485, r 0.8063, anchor RMSE 0.739, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#1 | Stormheart finale | 5.13 | **4.85** | -0.28 | 4.4 4.6 4.6 / 4.1 4.3 4.3 | PRESENT / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
