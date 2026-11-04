# Quick judge f38_20-keep-fog: F38#20

- Head `a8a54cdec4c7ccb5c7ec6667b00195ac74da5cee`, tree `fc7a109cc6b1`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stronghold.json": {"p2_003_candidate": {"keep": {"fog_disable": true}}}}`
- Capture: 2 launch(es); base 389s, candidate 396s, wall 785s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.1441, intercept -0.2797, r 0.8458, anchor RMSE 0.448, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#20 | Team Tether stronghold | 5.86 | **6.01** | +0.15 | 5.3 5.2 5.6 / 5.8 5.5 5.2 | PARTIAL,PRESENT / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
