# Quick judge qj_seam2: F41#19

- Head `fe2f2b977481685e8f07dc136708537968716ea3`, tree `9b09a9c69682`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormwood_glass_field.json": ["seam_clear_1104"]}`
- Capture: 1 launch(es); base 600s, candidate 594s, wall 1205s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.2872, intercept -1.2324, r 0.7986, anchor RMSE 0.71, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#19 | Glass Field spike bases | 4.77 | **5.59** | +0.82 | 4.6 4.8 4.6 / 5.2 5.5 5.2 | PRESENT / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
