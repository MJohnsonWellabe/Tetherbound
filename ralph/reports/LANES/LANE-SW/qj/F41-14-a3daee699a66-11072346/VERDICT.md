# Quick judge F41-14-a3daee699a66-11072346: F41#14

- Head `9284c51a7c9f2d0626963a83d8bfde614a1ced97`, tree `e4fea75dba3d`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormwood_candy_tiers_1107.json": {"enabled": true}}`
- Capture: 1 launch(es); base 315s, candidate 307s, wall 622s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.2245, intercept -0.4923, r 0.7814, anchor RMSE 0.719, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#14 | candy pickup tiers | 5.83 | **6.04** | +0.21 | 5.2 5 5.3 / 5 5.4 5.6 | FIXED,PARTIAL / FIXED,PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
