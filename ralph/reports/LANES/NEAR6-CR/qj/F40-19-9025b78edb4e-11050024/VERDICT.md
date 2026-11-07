# Quick judge F40-19-9025b78edb4e-11050024: F40#19

- Head `6fa796ba3b9a41b4113d925c5cc13b78564ed0ed`, tree `67c236554fea`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/cloudreach_visual.json": {"gate_path_verge": {"enabled": true}}}`
- Capture: 1 launch(es); base 0s (cached), candidate 2077s, wall 2077s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3606, intercept -1.9432, r 0.875, anchor RMSE 0.405, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#19 | Cloudreach realm gate at night (F40 matrix piece 7) | 5.54 | **5.81** | +0.27 | 5.5 5.6 5.4 / 5.7 5.7 5.7 | FIXED,PARTIAL / FIXED,PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
