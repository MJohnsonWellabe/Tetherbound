# Quick judge F38-9-cf81c113e9aa-11042121: F38#9

- Head `2086023c00512fdf77b77f3eb40355cedbf83b12`, tree `513ca438d2ff`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/menu.json": {"shell_scenic": {"floor_art_alpha": 0.45, "floor_art_start": 0.38, "collapse_status": true}}}`
- Capture: 1 launch(es); base 414s, candidate 425s, wall 839s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.7292, intercept -3.8038, r 0.9898, anchor RMSE 0.194, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#9 | menu shell | 6.34 | **6.34** | +0.00 | 6 5.5 6.1 / 6 5.6 6 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
