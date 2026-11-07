# Quick judge F39-17-fe66447e263e-11072141: F39#17

- Head `b8c2dee1b0841536855e6a2b41db67b1b0c44d41`, tree `ee1e961375bc`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/tidewake_look.json": {"current_flow": {"state_shader": {"restored": {"channel_tint_opacity": 0.35, "channel_tint_colour": "#5fb8c8", "lane_glint": 0.6, "seam_opacity": 0.35}}}}}`
- Capture: 1 launch(es); base 0s (cached), candidate 790s, wall 790s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.167, intercept -0.2323, r 0.8488, anchor RMSE 0.61, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#17 | current restoration environment | 6.85 | **6.85** | +0.00 | 6.2 6 6 / 6.2 6 6 | PRESENT / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
