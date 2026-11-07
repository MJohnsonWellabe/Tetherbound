# Quick judge f38_17-grade87: F38#17

- Head `ab1a8347c3e1d4393609e366f7866c9d5db66703`, tree `3d542d0f0ae2`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stronghold.json": {"p2_087_grade_candidate": {"enabled": true}}}`
- Capture: 1 launch(es); base 393s, candidate 388s, wall 781s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.0665, intercept 0.0476, r 0.8566, anchor RMSE 0.433, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#17 | named trainer dialogue subject visibility | 6.70 | **6.70** | +0.00 | 6 6.4 6.3 / 6 6.4 6.3 | FIXED / FIXED |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
