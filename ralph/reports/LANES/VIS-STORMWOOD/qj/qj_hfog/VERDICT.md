# Quick judge qj_hfog: F41#5, F41#4, F41#2

- Head `5d952b8f10d6ecdc37c9efe4108f51d4b013a3b2`, tree `ba597c11e48f`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormwood_surge.json": ["presentation.height_fog"]}`
- Capture: 3 launch(es); base 1507s, candidate 1467s, wall 2974s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.2893, intercept -1.4091, r 0.8906, anchor RMSE 0.445, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#5 | forest ground and distance layers | 4.78 | **4.69** | -0.09 | 4.6 4.8 5 / 4.6 4.7 4.9 | PRESENT / PRESENT |
| F41#4 | named destination identities | 5.21 | **5.17** | -0.04 | 4.7 5.3 5.4 / 4.7 5.3 5.3 | PARTIAL / PARTIAL |
| F41#2 | Surge phase presentation | 5.08 | **4.91** | -0.17 | 4.9 5 5.2 / 4.8 4.9 5 | PRESENT / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
