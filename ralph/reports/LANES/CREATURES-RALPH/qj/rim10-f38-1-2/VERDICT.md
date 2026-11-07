# Quick judge rim10-f38-1-2: F38#1, F38#2

- Head `a03083ece334fb8bb6b99c4fc828ea6dd13f92f8`, tree `4e749e24954d`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/creature_rim.json": {"enabled": true, "energy": 1.0, "power": 1.8}}`
- Capture: 1 launch(es); base 703s, candidate 736s, wall 1439s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.0233, intercept -0.162, r 0.6514, anchor RMSE 0.641, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#1 | creature collapse and rest | 5.53 | **5.84** | +0.31 | 5.5 5.7 5.5 / 5.8 5.9 5.9 | PARTIAL,PRESENT / PARTIAL |
| F38#2 | creature hurt and movement poses | 5.84 | **5.81** | -0.03 | 6 5.5 6.1 / 5.9 5.6 6 | PRESENT / PRESENT |

Missing frames (not judged): F38#1:meadows__terrapup__resting

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
