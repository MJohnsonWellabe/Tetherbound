# Quick judge F36-70-76438ddef11e-11072206: F36#70

- Head `60b70ed03307f5be0ad14b56e900ab4f4090f8b9`, tree `fbdbfa6bf667`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/creature_model_flags.json": {"flags": {"lanekit_sparkit_legs_1107": {"enabled": true}}}}`
- Capture: 1 launch(es); base 198s, candidate 199s, wall 397s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3539, intercept -0.9706, r 0.856, anchor RMSE 0.596, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F36#70 | Sparkit (storm fennec) model and poses | 4.49 | **4.49** | +0.00 | 4 4.3 3.8 / 4 4.3 3.8 | PRESENT / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
