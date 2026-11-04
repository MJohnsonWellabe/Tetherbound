# Quick judge F40-19-63afb3c3967f-11041555: F40#19

- Head `a7002be5dff63124f3f80fbf41eff889ed224c91`, tree `5efdbfc6df6a`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/cloudreach_visual.json": {"time_override_arms": {"night_foreground_fill": {"enabled": true}}}}`
- Capture: 1 launch(es); base 1369s, candidate 1381s, wall 2750s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 0.8238, intercept 1.362, r 0.5883, anchor RMSE 0.672, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#19 | Cloudreach realm gate at night (F40 matrix piece 7) | 5.10 | **5.84** | +0.74 | 4.6 4.5 4.5 / 5.5 5.4 5.4 | PRESENT / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
