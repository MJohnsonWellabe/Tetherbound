# Quick judge f38_15-mount-scale: F38#15

- Head `d7ee177afb9ffd19e218ffda9a3faa4317b9498d`, tree `a2dd06a552f9`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/fly_traversal.json": {"capabilities": {"galecrest": {"presentation_scale_enabled": true, "presentation_height_m": 3.2}, "galewisp": {"presentation_scale_enabled": true, "presentation_height_m": 3.0}}}}`
- Capture: 1 launch(es); base 326s, candidate 305s, wall 632s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.5275, intercept -2.904, r 0.9129, anchor RMSE 0.51, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#15 | flight and landing pose read | 6.21 | **7.08** | +0.87 | 5.9 5.9 6.1 / 6.3 6.6 6.7 | PARTIAL,PRESENT / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
