# Quick judge F40-4-r1: F40#4

- Head `5463787c570750ad3a98788e71c7b899ce6cd254`, tree `421f46d49ff6`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/cloudreach_f40_items.json": ["candidates.13"]}`
- Capture: 1 launch(es); base 612s, candidate 612s, wall 1224s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3454, intercept -1.017, r 0.8708, anchor RMSE 0.567, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#4 | exposed landform edges | 7.19 | **5.98** | -1.21 | 5.9 6.3 6.1 / 4.9 5.6 5.1 | PARTIAL / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
