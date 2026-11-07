# Quick judge F40-19-rain-7dbc7c42c9d7-11050224: F40#19-rain

- Head `ea4a0e6f863ed8a2c3afceb9b1e3ce13c4b08ca1`, tree `ace9730c110c`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/cloudreach_visual.json": {"rain_streaks": {"enabled": true}}}`
- Capture: 1 launch(es); base 2053s, candidate 2067s, wall 4120s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.234, intercept -1.2633, r 0.8154, anchor RMSE 0.513, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#19-rain | Cloudreach realm gate in day rain (F40 matrix piece 4) | 5.48 | **5.61** | +0.13 | 5.5 5.5 5.4 / 5.3 5.8 5.6 | PARTIAL,PRESENT / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
