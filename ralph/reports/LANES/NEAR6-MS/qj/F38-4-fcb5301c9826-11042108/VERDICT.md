# Quick judge F38-4-fcb5301c9826-11042108: F38#4

- Head `6d6d078da7557910585c17f1686bb5e7b6d2de5d`, tree `eaf61ee347d9-8e728f9e`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/map.json": ["fog_veil.chart_grid_1104"]}`
- Capture: 1 launch(es); base 281s, candidate 264s, wall 544s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.2226, intercept -0.8508, r 0.9121, anchor RMSE 0.337, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#4 | map | 6.81 | **6.93** | +0.12 | 6.1 6.4 6.3 / 6.3 6.4 6.4 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
