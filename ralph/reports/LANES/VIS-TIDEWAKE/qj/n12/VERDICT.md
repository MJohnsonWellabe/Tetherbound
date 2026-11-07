# Quick judge n12: F39#12

- Head `cd1d36013dbad1896e0998d8fe126d2b8595d29d`, tree `d31f54c3b3b7`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/meshy_camp_props.json": {"bed": {"nest_candidate": {"enabled": true}}}}`
- Capture: 1 launch(es); base 253s, candidate 196s, wall 449s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.4465, intercept -2.9397, r 0.9592, anchor RMSE 0.239, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#12 | authored camp creature bed silhouette | 5.35 | **5.98** | +0.63 | 5.6 5.9 5.7 / 6.1 6.5 5.9 | PARTIAL,PRESENT / FIXED,PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
