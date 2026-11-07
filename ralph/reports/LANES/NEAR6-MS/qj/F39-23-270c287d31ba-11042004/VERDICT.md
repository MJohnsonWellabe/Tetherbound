# Quick judge F39-23-270c287d31ba-11042004: F39#23

- Head `84bfcbb23fb29c8d35a71a4729ca24b3b9dc4b02`, tree `8f93c58733aa`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/capture_readout_visual.json": ["ring_style_1104"]}`
- Capture: 1 launch(es); base 0s (cached), candidate 953s, wall 953s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.5609, intercept -3.5856, r 0.9544, anchor RMSE 0.257, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#23 | catch chance HUD contrast | 5.26 | **5.62** | +0.36 | 6 5.2 5.8 / 6.2 5.5 6 | FIXED / FIXED |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
