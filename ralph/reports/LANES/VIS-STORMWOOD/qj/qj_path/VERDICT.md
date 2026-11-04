# Quick judge qj_path: F41#4

- Head `3d13a161774338eabbedc66fe21647cdf137a2cf`, tree `d9a4eb359f7d`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormwood_ground_finish.json": ["path_loam_1104"]}`
- Capture: 1 launch(es); base 571s, candidate 591s, wall 1162s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 0.8914, intercept 1.0484, r 0.7537, anchor RMSE 0.527, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#4 | named destination identities | 5.56 | **5.92** | +0.36 | 4.6 5.6 5 / 5 6 5.4 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
