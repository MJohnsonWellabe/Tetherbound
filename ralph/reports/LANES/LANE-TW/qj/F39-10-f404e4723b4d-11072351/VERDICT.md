# Quick judge F39-10-f404e4723b4d-11072351: F39#10

- Head `9c3e9ea0858b680b24fcdd2a6b4cb6e835cae4c7`, tree `2e5dfa87585e`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/tidewake_look.json": {"shore_water_candidate": {"water": {"depth_falloff": 24.0, "mid_depth_m": 6.0, "depth_band_break_m": 2.2}}}}`
- Capture: 2 launch(es); base 0s (cached), candidate 627s, wall 627s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.5832, intercept -2.8259, r 0.9326, anchor RMSE 0.416, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#10 | water and island depth | 7.15 | **7.25** | +0.10 | 6.2 6.4 6.3 / 6.2 6.5 6.4 | FIXED,PARTIAL / FIXED,PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
