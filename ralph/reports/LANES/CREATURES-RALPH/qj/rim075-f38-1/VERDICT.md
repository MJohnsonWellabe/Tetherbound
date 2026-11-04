# Quick judge rim075-f38-1: F38#1

- Head `41e25f1f1e0de1fe42884c50855824b32bbdf8d1`, tree `8ec2b8328251`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/creature_rim.json": {"energy": 0.75}}`
- Capture: 1 launch(es); base 465s, candidate 365s, wall 831s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.6598, intercept -3.4962, r 0.9817, anchor RMSE 0.198, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#1 | creature collapse and rest | 5.91 | **5.91** | +0.00 | 5.8 5.6 5.6 / 5.8 5.6 5.6 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
