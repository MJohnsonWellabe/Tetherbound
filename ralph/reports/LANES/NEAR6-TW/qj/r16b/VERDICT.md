# Quick judge r16b: F39#16

- Head `006b3c38c74e9920d5f78973750449c525265acd`, tree `ba6e71c6f210`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/tidewake_look.json": {"current_flow": {"state_shader": {"live": {"seam_opacity": 0.1, "chop_cap_opacity": 0.45, "fleck_amount": 0.16}}, "shader": {"seam_wander_m": 9.0, "seam_gap": 0.65}}}}`
- Capture: 1 launch(es); base 1254s, candidate 1255s, wall 2509s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.4513, intercept -2.6021, r 0.8367, anchor RMSE 0.491, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#16 | live current streaks | 5.96 | **6.54** | +0.58 | 6.2 5.6 5.9 / 6.6 5.9 6.4 | PARTIAL,PRESENT / FIXED |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
