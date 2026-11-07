# Quick judge f38_33-clear-reticle2: F38#33

- Head `8ef77f3898bc02a3dba3e7347264169a93a181b2`, tree `f648fbbf2678`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/hud.json": {"catch_card": {"result_clears_reticle": true}}}`
- Capture: 1 launch(es); base 1829s, candidate 1718s, wall 3547s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.4011, intercept -2.0405, r 0.9481, anchor RMSE 0.261, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#33 | catch result hierarchy | 6.32 | **7.11** | +0.79 | 6 6 5.9 / 6.7 6.6 6.3 | PRESENT / PARTIAL |

Missing frames (not judged): F38#33:meadows__catching__09-caught-banner

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
