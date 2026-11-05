# Quick judge F40-19-3060ae8a4f11-11050109: F40#19

- Head `c9fe3ce97247a6601574d8dc13e6ff86a38e3107`, tree `6c9be6c6be90`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/cloudreach_realm_gate_crag_visual.json": {"face_uplights": {"enabled": true}}}`
- Capture: 1 launch(es); base 0s (cached), candidate 2081s, wall 2081s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 0.6264, intercept 2.3857, r 0.5889, anchor RMSE 0.642, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#19 | Cloudreach realm gate at night (F40 matrix piece 7) | 5.71 | **5.71** | +0.00 | 5.2 5.3 5.4 / 5.2 5.3 5.4 | FIXED / FIXED |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
