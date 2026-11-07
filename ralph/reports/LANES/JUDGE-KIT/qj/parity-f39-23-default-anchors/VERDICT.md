# Quick judge parity-f39-23-batch1: F39#23

- Head `4c37a80f28021e6e6c2d11f3b6ab57abd4f8ef96`, tree `5c805ea68ffa`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/capture_readout_visual.json": {"readout_side_enabled": false, "contrast_r2": {"enabled": false}}}`
- Capture: 1 launch(es); base 0s (cached), candidate 943s, wall 943s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3116, intercept -2.1475, r 0.882, anchor RMSE 0.397, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#23 | catch chance HUD contrast | 6.38 | **5.11** | -1.27 | 6.6 6.7 6.2 / 5.6 5.7 5.3 | FIXED / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
