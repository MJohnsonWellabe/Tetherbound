# Quick judge F38-31-01cde1ac0ff1-11071806: F38#31

- Head `4e3f0cc00a1d8a748115b84c3468eafbac111a8d`, tree `1a485322150f`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/creatures_visual.json": ["alpha_presence_1105"]}`
- Capture: 1 launch(es); base 268s, candidate 203s, wall 471s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.4697, intercept -2.0795, r 0.8974, anchor RMSE 0.509, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#31 | alpha rarity read | 6.69 | **6.84** | +0.15 | 5.7 6.3 5.9 / 5.9 6.3 6 | PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
