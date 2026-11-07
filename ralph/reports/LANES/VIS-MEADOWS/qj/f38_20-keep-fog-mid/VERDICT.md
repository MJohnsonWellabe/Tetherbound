# Quick judge f38_20-keep-fog-mid: F38#20

- Head `5f3130fc236bb92306b221d9901f92f1ce65fbb2`, tree `fc7a109cc6b1`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stronghold.json": {"p2_003_candidate": {"keep": {"fog_disable": true, "albedo_tint": "#b3ab9c"}}}}`
- Capture: 2 launch(es); base 0s (cached), candidate 379s, wall 379s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.1977, intercept -0.7643, r 0.9238, anchor RMSE 0.414, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#20 | Team Tether stronghold | 5.22 | **5.70** | +0.48 | 5 5 5 / 5.3 5.4 5.5 | PRESENT / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
