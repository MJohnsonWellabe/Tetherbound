# Quick judge qj_seam: F41#19

- Head `ea108029ac1a957867073fd8ef2360a4e3ac32b2`, tree `006434beee94`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormwood_glass_field.json": ["seam_clear_1104"]}`
- Capture: 1 launch(es); base 601s, candidate 570s, wall 1170s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.5207, intercept -3.0116, r 0.9904, anchor RMSE 0.14, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#19 | Glass Field spike bases | 4.34 | **5.30** | +0.96 | 4.9 4.8 4.8 / 5.5 5.6 5.3 | PRESENT / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
