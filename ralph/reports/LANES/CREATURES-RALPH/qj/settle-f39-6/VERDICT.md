# Quick judge settle-f39-6: F39#6

- Head `528cd29c2400b329cb5e0bbb4095501c4c2cb285`, tree `ed4249e26878`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/creature_pose_settle.json": ["tidewake_scope"]}`
- Capture: 1 launch(es); base 0s (cached), candidate 188s, wall 188s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.0164, intercept 0.0293, r 0.609, anchor RMSE 0.696, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#6 | creature faint state | 5.86 | **5.11** | -0.75 | 5.6 6 5.6 / 4.7 5.3 5 | PARTIAL / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
