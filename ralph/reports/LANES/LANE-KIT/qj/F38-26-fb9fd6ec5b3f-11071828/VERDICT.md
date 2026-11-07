# Quick judge F38-26-fb9fd6ec5b3f-11071828: F38#26

- Head `4e3f0cc00a1d8a748115b84c3468eafbac111a8d`, tree `1a485322150f`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/creature_grass_clear.json": {"enabled": false}}`
- Capture: 1 launch(es); base 0s (cached), candidate 343s, wall 343s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.0431, intercept 0.5503, r 0.7991, anchor RMSE 0.693, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#26 | creature ground contact | 6.53 | **6.53** | +0.00 | 6 5.6 5.6 / 6 5.6 5.6 | PARTIAL,PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
