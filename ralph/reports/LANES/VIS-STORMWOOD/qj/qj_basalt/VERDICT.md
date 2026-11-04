# Quick judge qj_basalt: F41#19

- Head `57000a240a42246688f42c2451c7e3eddbb621fc`, tree `c38c8557d31d`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormwood_glass_field.json": ["basalt_crust_1104"]}`
- Capture: 1 launch(es); base 579s, candidate 560s, wall 1139s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.4626, intercept -2.0112, r 0.9412, anchor RMSE 0.467, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#19 | Glass Field spike bases | 5.25 | **4.42** | -0.83 | 5.3 4.8 4.8 / 4.5 4.3 4.4 | PARTIAL / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
