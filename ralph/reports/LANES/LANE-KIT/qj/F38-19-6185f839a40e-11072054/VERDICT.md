# Quick judge F38-19-6185f839a40e-11072054: F38#19

- Head `002f4dca134a70f047320e931e10b39721910d18`, tree `ae36709a6982`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/hud.json": {"exploration_hotbar": {"panel_alpha": 0.35}, "exploration_vitals": {"idle_alpha": 0.7}, "clarity_pass": {"daytime_plate_alpha": 0.35}}}`
- Capture: 1 launch(es); base 1341s, candidate 1338s, wall 2679s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.1453, intercept 0.2762, r 0.7797, anchor RMSE 0.722, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#19 | exploration HUD | 6.58 | **6.58** | +0.00 | 5.4 5.7 5.4 / 5.4 5.7 5.4 | PARTIAL,PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
