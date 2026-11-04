# Quick judge F38-26-662667cd3005-11041311: F38#26

- Head `76017a9c4a8169f33601bb5f69a0d36bf82ebb0e`, tree `c435776cd35c`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/creature_rim.json": {"enabled": true}}`
- Capture: 1 launch(es); base 373s, candidate 371s, wall 744s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.7132, intercept -4.382, r 0.9074, anchor RMSE 0.355, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#26 | creature ground contact | 5.95 | **6.07** | +0.12 | 6.2 6.1 5.8 / 6.2 6.2 5.9 | PARTIAL,PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
