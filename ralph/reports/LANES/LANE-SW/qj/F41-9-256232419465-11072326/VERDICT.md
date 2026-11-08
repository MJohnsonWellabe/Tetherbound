# Quick judge F41-9-256232419465-11072326: F41#9

- Head `79a298c59a234a7bf5f943d2bf4dbc8a12769b8f`, tree `c6f4a4ab3ebe`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormwood_harvest_hero2.json": ["lane_sw_1107_r3"]}`
- Capture: 1 launch(es); base 236s, candidate 239s, wall 475s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.5506, intercept -2.4655, r 0.8959, anchor RMSE 0.513, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#9 | harvest resource identity | 4.98 | **5.65** | +0.67 | 4.5 4.9 5 / 4.9 5.3 5.5 | PARTIAL,PRESENT / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
