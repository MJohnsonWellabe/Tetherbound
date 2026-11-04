# Quick judge F40-4-24add0c49b36-11041519: F40#4

- Head `dccd74a7f6a52c22fe8d138aa3b230fefd3dd952`, tree `0b19c6041eff`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/cloudreach_f40_items.json": {"shelf_edge_soften": {"enabled": true}}}`
- Capture: 1 launch(es); base 0s (cached), candidate 677s, wall 2057s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.5252, intercept -2.9027, r 0.9907, anchor RMSE 0.138, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#4 | exposed landform edges | 6.35 | **5.69** | -0.66 | 6.6 5.8 5.8 / 6.1 5.3 5.5 | PARTIAL,PRESENT / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
