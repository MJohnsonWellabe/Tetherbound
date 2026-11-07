# Quick judge F38-33-91a1dca4cb6b-11072025: F38#33

- Head `002f4dca134a70f047320e931e10b39721910d18`, tree `ae36709a6982`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/hud.json": {"catch_card": {"step_back_on_break": true}}}`
- Capture: 1 launch(es); base 894s, candidate 743s, wall 1637s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.6742, intercept -2.8987, r 0.9073, anchor RMSE 0.485, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#33 | catch result hierarchy | 6.53 | **7.98** | +1.45 | 5.5 5.6 5.8 / 6.6 6.3 6.6 | PRESENT / PARTIAL |

**Warnings:**
- meets the bar only above the top anchor (7.35): F38#33 cand; extrapolated, but this batch's anchors reach 7.35 or more, so it is the confirming batch

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
