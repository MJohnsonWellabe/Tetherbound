# Quick judge f38_35-stances: F38#35

- Head `cbc7afb278bf4a293f3acc47c3a6dc76ed4ccaaa`, tree `0db654ed87de`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/npc_post_stances.json": ["enabled"]}`
- Capture: 1 launch(es); base 514s, candidate 511s, wall 1025s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.6243, intercept -3.5543, r 0.9307, anchor RMSE 0.396, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#35 | human post poses | 6.57 | **6.57** | +0.00 | 6.2 6.1 6.4 / 6.2 6.1 6.4 | PRESENT / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
