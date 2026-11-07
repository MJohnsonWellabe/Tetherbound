# Quick judge f38_20-yard-centre2: F38#20

- Head `bbab837e0f1c45c55d71d45ae8ec8b8dd64d269f`, tree `2b3df2546346`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/bands/band5_stronghold_approach/props.json": ["clusters.6.candidate"]}`
- Capture: 2 launch(es); base 383s, candidate 392s, wall 775s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 0.8734, intercept 0.7106, r 0.59, anchor RMSE 0.658, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#20 | Team Tether stronghold | 5.51 | **5.75** | +0.24 | 5.5 5.5 5.5 / 5.8 5.8 5.7 | PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
