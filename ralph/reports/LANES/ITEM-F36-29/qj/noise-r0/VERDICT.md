# Quick judge F36-29-noise-r0: F36#29

- Head `b0e3a12ea8d634e266dbb825d5c8cb41fcbeb28f`, tree `manual`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"_noise_floor": "live vs live (two separate live captures)"}`
- Capture: 1 launch(es); base 0s, candidate 0s, wall 0s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.6173, intercept -2.6091, r 0.8856, anchor RMSE 0.536, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F36#29 | Innkeeper (Wilhelm) body and face, F36(0) close stand | 7.36 | **7.36** | +0.00 | 6.3 6 6.2 / 6.3 6 6.2 | PARTIAL,PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
