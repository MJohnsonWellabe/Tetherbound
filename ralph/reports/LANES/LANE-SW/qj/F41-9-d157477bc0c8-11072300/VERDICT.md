# Quick judge F41-9-d157477bc0c8-11072300: F41#9

- Head `29ccae6e039d8f721d12e0fbc81781f062122b57`, tree `6557723e91fb`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormwood_harvest_hero2.json": ["lane_sw_1107"]}`
- Capture: 1 launch(es); base 233s, candidate 235s, wall 468s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.0456, intercept 0.4854, r 0.751, anchor RMSE 0.761, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#9 | harvest resource identity | 5.64 | **6.31** | +0.67 | 5.2 4.8 4.8 / 5.6 5.5 5.6 | PARTIAL,PRESENT / PARTIAL |

**Warnings:**
- anchor residual RMSE 0.76 > 0.75: these judges do not rank the anchors like the reference judges; report the mapped scores with this caveat

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
