# Quick judge F36-70-76438ddef11e-11072217: F36#70

- Head `b08305560d77cffb306b407345129a06c6441203`, tree `80b027568f21`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/creature_model_flags.json": {"flags": {"lanekit_sparkit_legs_1107": {"enabled": true}}}}`
- Capture: 1 launch(es); base 13s, candidate 13s, wall 27s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.235, intercept -0.5335, r 0.8625, anchor RMSE 0.584, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F36#70 | Sparkit (storm fennec) on a neutral stage beside a 1.80 m human ruler: walk cycle and hit react | 6.51 | **6.71** | +0.20 | 5.6 5.6 5.9 / 6 5.6 6 | PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
