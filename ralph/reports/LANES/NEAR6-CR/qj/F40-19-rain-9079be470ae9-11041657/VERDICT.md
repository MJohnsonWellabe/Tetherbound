# Quick judge F40-19-rain-9079be470ae9-11041657: F40#19-rain

- Head `2580547d6f69784f47d33d3ec1828b104d1ca0e6`, tree `d0d777473d72`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/cloudreach_visual.json": {"weather_arms": {"rain_mood": {"enabled": true}}}}`
- Capture: 1 launch(es); base 1341s, candidate 1337s, wall 2678s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 0.7435, intercept 1.7419, r 0.5513, anchor RMSE 0.705, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#19-rain | Cloudreach realm gate in day rain (F40 matrix piece 4) | 5.81 | **5.81** | +0.00 | 5.8 5.2 5.4 / 5.8 5.2 5.4 | PARTIAL,PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
