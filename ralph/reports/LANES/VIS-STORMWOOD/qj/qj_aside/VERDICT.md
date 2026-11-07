# Quick judge qj_aside: F39#7

- Head `3ccbbd4e467923b07e49144d63475e24969fd8c6`, tree `da9dcff7b430`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/combat.json": ["trainer_aside.realm_1104"]}`
- Capture: 1 launch(es); base 672s, candidate 479s, wall 1151s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.4876, intercept -3.0015, r 0.9168, anchor RMSE 0.339, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#7 | fight actor composition | 6.57 | **5.87** | -0.70 | 6.4 6.3 6.6 / 6 5.9 6 | FIXED / FIXED,PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
