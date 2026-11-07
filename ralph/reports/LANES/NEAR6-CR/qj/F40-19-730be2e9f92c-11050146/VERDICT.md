# Quick judge F40-19-730be2e9f92c-11050146: F40#19

- Head `a7040e7e99c7521ee4d4eca7ffe03614045bc2b4`, tree `fa4371b37d94`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/cloudreach_visual.json": {"time_override_arms": {"night_moon_grade": {"enabled": true}}}}`
- Capture: 1 launch(es); base 0s (cached), candidate 2063s, wall 2063s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.0842, intercept -0.5153, r 0.7577, anchor RMSE 0.542, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#19 | Cloudreach realm gate at night (F40 matrix piece 7) | 5.45 | **5.41** | -0.04 | 5.5 5.2 5.8 / 5.6 5.3 5.5 | FIXED,PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
