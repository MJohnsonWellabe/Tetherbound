# Quick judge qj_inn: F36#29

- Head `3ccbbd4e467923b07e49144d63475e24969fd8c6`, tree `da9dcff7b430`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/character_body_flags.json": ["npc_vis_body_innkeeper"]}`
- Capture: 1 launch(es); base 672s, candidate 479s, wall 1151s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 0.8376, intercept 1.0022, r 0.5984, anchor RMSE 0.675, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F36#29 | Innkeeper (Wilhelm) body and face | 6.20 | **6.20** | +0.00 | 6 6.1 6.5 / 6 6.1 6.5 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
