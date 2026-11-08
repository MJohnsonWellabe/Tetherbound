# Quick judge F38-20-7117b2d2ef08-11072224: F38#20

- Head `15f541a3645002b60c8f881a5f0efb6ef3716d51`, tree `15c689023899`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stronghold.json": ["keep_hill_1107", "keep_walls_1107"]}`
- Capture: 2 launch(es); base 420s, candidate 424s, wall 845s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3475, intercept -1.26, r 0.868, anchor RMSE 0.573, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#20 | Team Tether stronghold | 6.38 | **6.78** | +0.40 | 5.6 5.6 5.8 / 5.9 5.9 6.1 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
