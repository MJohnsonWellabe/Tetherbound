# Quick judge F36-29-look-r1: F36#29

- Head `b0e3a12ea8d634e266dbb825d5c8cb41fcbeb28f`, tree `manual`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/character_body_flags.json": ["npc_vis_look_innkeeper"]}`
- Capture: 1 launch(es); base 0s, candidate 0s, wall 0s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.0824, intercept 0.506, r 0.8214, anchor RMSE 0.658, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F36#29 | Innkeeper (Wilhelm) body and face, F36(0) close stand | 6.78 | **6.64** | -0.14 | 5.7 6.2 5.5 / 5.3 5.7 6 | PARTIAL,PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
