# Quick judge F40-2-edb6d881b763-11041450: F40#2

- Head `391f84627796ee7f53ac5d51348c93f8b56abe3d`, tree `b7d554b8a804`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/cloudreach_f40_items.json": {"summit_silhouette": {"enabled": true}}}`
- Capture: 3 launch(es); base 0s (cached), candidate 1464s, wall 1732s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.4268, intercept -1.8791, r 0.9148, anchor RMSE 0.382, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#2 | summit aviary | 5.64 | **6.16** | +0.52 | 5.6 4.6 5.6 / 6 5 5.9 | PARTIAL,PRESENT / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
