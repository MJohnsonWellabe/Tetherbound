# Quick judge parity-f39-23: F39#23

- Head `4c37a80f28021e6e6c2d11f3b6ab57abd4f8ef96`, tree `5c805ea68ffa`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/capture_readout_visual.json": {"readout_side_enabled": false, "contrast_r2": {"enabled": false}}}`
- Capture: 1 launch(es); base 0s (cached), candidate 943s, wall 943s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.4047, intercept -1.1731, r 0.8089, anchor RMSE 0.678, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#23 | catch chance HUD contrast | 6.79 | **5.57** | -1.22 | 5.7 5.8 5.5 / 4.9 4.9 4.6 | FIXED / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
