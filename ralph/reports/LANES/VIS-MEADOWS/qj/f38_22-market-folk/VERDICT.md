# Quick judge f38_22-market-folk: F38#22

- Head `2511d8e5f08fea69db9f8197f9e4669147b466db`, tree `03861ae4a085`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/village_npcs.json": ["market_folk"]}`
- Capture: 1 launch(es); base 479s, candidate 485s, wall 964s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3265, intercept -2.08, r 0.8952, anchor RMSE 0.395, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#22 | mill and settlements | 6.32 | **6.32** | +0.00 | 6.3 6.3 6.4 / 6.3 6.3 6.4 | PRESENT / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
