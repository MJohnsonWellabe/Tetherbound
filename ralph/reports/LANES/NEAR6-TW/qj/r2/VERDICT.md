# Quick judge r2: F39#2

- Head `a4ca50970d4df9440ebdd9e0c4159d0201030581`, tree `23279553ef64`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/hero_landmarks_1101.json": {"veilfall": {"enabled": true, "across_m": 1150.0, "shader": {"fog_keep_near": 1.0, "fog_keep_far": 0.85, "white_lift": 0.35}}}}`
- Capture: 2 launch(es); base 968s, candidate 979s, wall 1946s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.1982, intercept -0.538, r 0.9092, anchor RMSE 0.576, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#2 | Veilfall silhouette | 6.41 | **5.73** | -0.68 | 5.6 6.2 5.6 / 5.2 5.6 4.9 | PARTIAL / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
