# Quick judge qj_footing: F41#19

- Head `948d7942634651be77cd97588a2436abad993bc8`, tree `c10a402b01a6`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormwood_glass_field.json": ["rock_collar_candidate.footing_1104"]}`
- Capture: 1 launch(es); base 561s, candidate 578s, wall 1140s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3028, intercept -1.949, r 0.7946, anchor RMSE 0.513, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#19 | Glass Field spike bases | 5.09 | **5.22** | +0.13 | 4.8 5.8 5.6 / 5 5.5 6 | PARTIAL / FIXED,PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
