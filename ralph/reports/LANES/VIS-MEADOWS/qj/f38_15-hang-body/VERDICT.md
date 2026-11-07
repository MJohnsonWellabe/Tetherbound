# Quick judge f38_15-hang-body: F38#15

- Head `96a3e48fb15fd67914175632d5a96f281a552ef0`, tree `d1c480565a5c`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/fly_traversal.json": ["hang_pose.body"]}`
- Capture: 1 launch(es); base 0s (cached), candidate 0s, wall 0s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.2862, intercept -1.8182, r 0.8245, anchor RMSE 0.501, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#15 | flight and landing pose read | 5.86 | **5.86** | +0.00 | 6 6 5.9 / 6 6 5.9 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
