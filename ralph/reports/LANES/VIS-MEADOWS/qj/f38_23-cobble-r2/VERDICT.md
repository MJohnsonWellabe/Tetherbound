# Quick judge f38_23-cobble-r2: F38#23

- Head `97fab135721312041029c2f658328d6fd46ab51a`, tree `2bc4c03274aa`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/tether_relay.json": {"ground_pad": {"surface_candidate": {"r2": {"enabled": true}}}}}`
- Capture: 1 launch(es); base 644s, candidate 648s, wall 1293s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.5318, intercept -2.4146, r 0.9656, anchor RMSE 0.349, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#23 | Tether Relay yard | 6.73 | **6.93** | +0.20 | 5.8 5.8 6.3 / 6.2 6.2 5.9 | FIXED / FIXED |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
