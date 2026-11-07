# Quick judge qj_lanterns2: F41#1

- Head `84be909ca730efc1d19538e3c4224765b741306e`, tree `db67a22df9ae`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormheart_presentation.json": ["floor_lanterns_1104"]}`
- Capture: 2 launch(es); base 489s, candidate 465s, wall 954s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.2317, intercept -1.0653, r 0.9177, anchor RMSE 0.397, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#1 | Stormheart finale | 4.15 | **4.15** | +0.00 | 4 4.5 4.2 / 4 4.5 4.2 | PRESENT / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
