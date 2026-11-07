# Quick judge F40-16-98dc09bfe90b-11071348: F40#16

- Head `65c00b7600a958e3419e592b497ee4710c3159a8`, tree `161fc2ad1059`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/mushroom_pickup_variants.json": {"enabled": true}}`
- Capture: 1 launch(es); base 0s (cached), candidate 536s, wall 536s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3761, intercept -1.6076, r 0.8668, anchor RMSE 0.54, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#16 | mushroom pickup variants | 6.47 | **5.92** | -0.55 | 5.6 6 6 / 5.2 5.6 5.6 | FIXED / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
