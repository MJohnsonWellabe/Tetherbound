# Quick judge F40-4-f99566cca348-11041557: F40#4

- Head `28c3f5936a3d3b3d12a6044cdf9e7da652dc2d20`, tree `995cca9b5de3`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/cloudreach_f40_items.json": {"shelf_edge_fringe": {"enabled": true}}}`
- Capture: 1 launch(es); base 0s (cached), candidate 681s, wall 3340s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.0438, intercept -0.1317, r 0.8422, anchor RMSE 0.446, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#4 | exposed landform edges | 5.96 | **6.27** | +0.31 | 6.1 5.9 5.5 / 6.3 6.3 5.8 | PRESENT / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
