# Quick judge F38-5-6a59b14720f3-11071825: F38#5

- Head `54eac75be95827817c0832b7ae242636023d58bd`, tree `0c9c0f800af1`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/creature_scale_flags.json": {"flags": {"creatures_f36_taller_than_trainer_5": {"enabled": true}}}}`
- Capture: 1 launch(es); base 170s, candidate 171s, wall 341s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.5059, intercept -2.1415, r 0.8957, anchor RMSE 0.513, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#5 | normal creature scale | 7.14 | **7.40** | +0.26 | 6 6.2 6.3 / 6.1 6.3 6.6 | PARTIAL,PRESENT / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
