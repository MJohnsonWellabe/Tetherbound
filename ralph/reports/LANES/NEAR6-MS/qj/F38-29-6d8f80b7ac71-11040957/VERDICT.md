# Quick judge F38-29-6d8f80b7ac71-11040957: F38#29

- Head `e4026ec9de02009bbd4ebb088e4aab7ec4130359`, tree `610b6f8f8c98`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/npc_post_stances.json": ["beaten_trainer_stance.immediate_1104"], "data/config/art.json": ["grunt_a.clip_candidate"]}`
- Capture: 1 launch(es); base 1337s, candidate 1320s, wall 2656s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3344, intercept -1.6482, r 0.9216, anchor RMSE 0.334, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#29 | trainer defeated presentation | 6.14 | **6.22** | +0.08 | 5.7 5.6 6.2 / 6 5.6 6.1 | PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
