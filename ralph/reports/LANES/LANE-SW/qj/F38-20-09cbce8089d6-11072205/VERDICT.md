# Quick judge F38-20-09cbce8089d6-11072205: F38#20

- Head `b5aeaa59ae63377097d661bcaf87d81a77a84d4a`, tree `2b1259b571e0`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stronghold.json": ["keep_hill_1107"]}`
- Capture: 2 launch(es); base 420s, candidate 443s, wall 863s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.1337, intercept -0.0262, r 0.8498, anchor RMSE 0.608, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#20 | Team Tether stronghold | 6.32 | **6.32** | +0.00 | 5.5 5.9 5.4 / 5.5 5.9 5.4 | PARTIAL,PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
