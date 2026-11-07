# Quick judge r20b: F39#20

- Head `c0a1946389ee4d5f24a076553a5e9be70a399812`, tree `5b10c45ae0fe`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/water_resource_models.json": {"fight_ring_hide": {"enabled": true}}}`
- Capture: 1 launch(es); base 547s, candidate 567s, wall 1114s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.1822, intercept -1.2252, r 0.7528, anchor RMSE 0.541, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#20 | fight background creature ground contact | 5.87 | **6.42** | +0.55 | 5.9 5.9 6.2 / 6.4 6.4 6.6 | PRESENT / FIXED |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
