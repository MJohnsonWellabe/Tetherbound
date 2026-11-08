# Quick judge F41-9-55e013ff1e73-11072314: F41#9

- Head `c367c98890c502207098a251420900ed49d8f015`, tree `407cfdb22fde`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormwood_harvest_hero2.json": ["lane_sw_1107_r2"]}`
- Capture: 1 launch(es); base 240s, candidate 238s, wall 478s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.5767, intercept -1.9933, r 0.8193, anchor RMSE 0.661, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#9 | harvest resource identity | 5.52 | **6.00** | +0.48 | 5 4.7 4.6 / 5.3 5 4.9 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
