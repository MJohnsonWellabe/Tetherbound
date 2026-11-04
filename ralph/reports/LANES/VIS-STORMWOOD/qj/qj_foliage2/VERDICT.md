# Quick judge qj_foliage2: F41#5, F41#4

- Head `3e647230a6cdfe7d2df471b58a8d00908658a0ba`, tree `dad295b63f2d`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormwood_look.json": ["foliage_grade_1104"]}`
- Capture: 2 launch(es); base 866s, candidate 905s, wall 1770s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.0569, intercept -0.2956, r 0.7773, anchor RMSE 0.564, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#5 | forest ground and distance layers | 5.09 | **4.88** | -0.21 | 4.5 5.3 5.5 / 4.4 5 5.3 | PARTIAL,PRESENT / PRESENT |
| F41#4 | named destination identities | 5.24 | **5.02** | -0.22 | 4.7 5.2 5.8 / 4.5 5 5.6 | PARTIAL,PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
