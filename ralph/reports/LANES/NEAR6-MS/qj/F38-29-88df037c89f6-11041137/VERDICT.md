# Quick judge F38-29-88df037c89f6-11041137: F38#29

- Head `ab6e5cddfc15402e62b5eb9069709cfaf10fda54`, tree `e70e18fdaf5b`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/npc_post_stances.json": ["beaten_trainer_stance.immediate_1104"], "data/config/trainer_aftermath.json": ["silent_victory_shot_1104"]}`
- Capture: 1 launch(es); base 1288s, candidate 1210s, wall 2498s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 0.8494, intercept 1.0277, r 0.7346, anchor RMSE 0.539, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#29 | trainer defeated presentation | 5.76 | **6.18** | +0.42 | 5.5 5.5 5.7 / 6 6 6.2 | PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
