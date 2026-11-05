# Quick judge F38-8-fd74f3f3ea83-11050219: F38#8

- Head `969ca4b8e2068a45a35eacf5beb79edf2cf5f178`, tree `e849f0f97449`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/fly_traversal.json": ["hang_pose.body"]}`
- Capture: 1 launch(es); base 305s, candidate 300s, wall 605s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.6161, intercept -3.4117, r 0.9247, anchor RMSE 0.456, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#8 | Fly carrier grip pose | 6.18 | **6.07** | -0.11 | 6.2 6 5.6 / 6.1 6 5.5 | PRESENT / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
