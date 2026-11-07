# Quick judge F40-17-53b0b6dc0941-11041858: F40#17

- Head `377fa338f521b975b7148c9d08ef24f6ef25d014`, tree `348be887ab48`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/cloudreach_physical_runtime.json": {"rim_pickup_cluster": {"enabled": true}}}`
- Capture: 1 launch(es); base 941s, candidate 989s, wall 1930s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 0.8457, intercept 1.2238, r 0.6352, anchor RMSE 0.614, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#17 | High Perches rim mushroom | 5.85 | **6.19** | +0.34 | 5.4 5.6 5.4 / 5.7 5.9 6 | FIXED,PARTIAL / FIXED,PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
