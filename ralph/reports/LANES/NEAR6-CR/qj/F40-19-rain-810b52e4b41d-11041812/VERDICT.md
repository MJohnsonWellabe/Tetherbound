# Quick judge F40-19-rain-810b52e4b41d-11041812: F40#19-rain

- Head `cb6d39dbd6f68f1b1a92ce0c363bb4eba049165f`, tree `5951ebc914b0-949ba9d8`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/cloudreach_visual.json": {"weather_arms": {"rain_storm": {"enabled": true}}}}`
- Capture: 1 launch(es); base 1394s, candidate 1320s, wall 2714s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.1501, intercept -0.2945, r 0.9502, anchor RMSE 0.254, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#19-rain | Cloudreach realm gate in day rain (F40 matrix piece 4) | 5.69 | **5.80** | +0.11 | 5.4 5.2 5 / 5.5 5.3 5.1 | PRESENT / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
