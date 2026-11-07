# Quick judge F38-30_F38-24-354ca63271b5-11071915: F38#30, F38#24

- Head `ec9ae6383c0c038ce10675b08fcc6e6d96b35dc8`, tree `765b36a12dbe`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/burrow_warrens.json": {"bank": {"hill_shell": {"at": [-1.1, -5.8, 54.0]}}}}`
- Capture: 1 launch(es); base 0s (cached), candidate 507s, wall 507s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.6937, intercept -2.8128, r 0.9172, anchor RMSE 0.46, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#30 | Burrow Warrens hillside | 2.95 | **3.51** | +0.56 | 3.2 3.6 3.4 / 3.6 3.8 3.8 | PARTIAL,PRESENT / PRESENT |
| F38#24 | distant mountains | 3.28 | **3.51** | +0.23 | 3 4.2 3.6 / 3 4.2 4 | PARTIAL,PRESENT / PARTIAL,PRESENT |

**Warnings:**
- some candidates lie more than 0.5 outside the anchors' measured range (extrapolated)

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
