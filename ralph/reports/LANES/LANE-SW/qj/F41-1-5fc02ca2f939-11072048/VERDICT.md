# Quick judge F41-1-5fc02ca2f939-11072048: F41#1

- Head `8211ae20a5da25e619bb8d557a1e20eff6209352`, tree `f2a3bb886f64`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormheart_presentation.json": ["root_vault_1107"]}`
- Capture: 2 launch(es); base 338s, candidate 362s, wall 700s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.1385, intercept 0.2335, r 0.8153, anchor RMSE 0.668, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#1 | Stormheart finale | 4.75 | **5.24** | +0.49 | 4.2 3.8 3.9 / 4.7 4.1 4.4 | PRESENT / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
