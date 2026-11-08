# Quick judge F38-17-f8ab7f3fcf77-11072319: F38#17

- Head `17a89e072ee91e020f7fc04608826ca0a380e6f5`, tree `246539e5a1c8`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/character_appearance_variants.json": {"variants": {"lanekit_f38_17_solene": {"enabled": true}, "lanekit_f38_17_hald": {"enabled": true}}}}`
- Capture: 1 launch(es); base 336s, candidate 326s, wall 662s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.4131, intercept -1.8668, r 0.8963, anchor RMSE 0.511, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#17 | named trainer dialogue subject visibility | 5.81 | **7.32** | +1.51 | 5.5 5.6 5.2 / 6.6 6.6 6.3 | FIXED,PARTIAL / FIXED |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
