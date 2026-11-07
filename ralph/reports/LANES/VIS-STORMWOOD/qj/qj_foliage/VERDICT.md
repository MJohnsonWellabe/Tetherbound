# Quick judge qj_foliage: F41#5, F41#4

- Head `5c7da8aed5a916a1fb602cd5f7acce3fdbbd74fe`, tree `02e382248bfe`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormwood_look.json": ["foliage_grade_1104"]}`
- Capture: 2 launch(es); base 800s, candidate 836s, wall 1636s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.6365, intercept -3.0443, r 0.9479, anchor RMSE 0.428, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#5 | forest ground and distance layers | 4.37 | **4.37** | +0.00 | 4.4 4.4 4.8 / 4.4 4.4 4.8 | PRESENT / PRESENT |
| F41#4 | named destination identities | 4.81 | **4.81** | +0.00 | 4.6 4.6 5.2 / 4.6 4.6 5.2 | PARTIAL,PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
