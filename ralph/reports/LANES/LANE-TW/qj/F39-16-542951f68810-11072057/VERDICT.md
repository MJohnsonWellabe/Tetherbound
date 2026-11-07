# Quick judge F39-16-542951f68810-11072057: F39#16

- Head `4745a9d468c386219eb4bf8591b9cd62e9065d3d`, tree `2e7e10d73009`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/tidewake_look.json": {"current_flow": {"shader": {"cap_scatter": 1.0, "chop_cap_density": 0.22}}}}`
- Capture: 1 launch(es); base 0s (cached), candidate 806s, wall 806s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.4573, intercept -1.8663, r 0.8539, anchor RMSE 0.6, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#16 | live current streaks | 7.65 | **7.56** | -0.09 | 6.4 6.6 6.6 / 6.5 6.5 6.4 | FIXED / FIXED |

**Warnings:**
- meets the bar only above the top anchor (7.35): F39#16 base, F39#16 cand; extrapolated, but this batch's anchors reach 7.35 or more, so it is the confirming batch

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
