# Quick judge F39-16-0c6f9aef2eee-11072041: F39#16

- Head `04a27ead2ed546843224bcfdae0ee746bb451bab`, tree `2e7e10d73009`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/tidewake_look.json": {"current_flow": {"shader": {"cap_scatter": 1.0, "chop_cap_density": 0.55, "chop_cap_scale_m": 3.0}}}}`
- Capture: 1 launch(es); base 0s (cached), candidate 805s, wall 805s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.4537, intercept -2.1862, r 0.903, anchor RMSE 0.495, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#16 | live current streaks | 7.31 | **6.63** | -0.68 | 6.8 6.6 6.2 / 6.4 6.3 5.5 | PARTIAL / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
