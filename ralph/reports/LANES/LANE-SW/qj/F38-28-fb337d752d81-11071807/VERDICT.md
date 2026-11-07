# Quick judge F38-28-fb337d752d81-11071807: F38#28

- Head `ec9ae6383c0c038ce10675b08fcc6e6d96b35dc8`, tree `765b36a12dbe`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/combat.json": ["arena.boundary_per_trainer_candidate"], "data/config/stronghold.json": ["p2_064_r2_candidate"]}`
- Capture: 1 launch(es); base 2822s, candidate 2540s, wall 5362s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.1451, intercept -0.0157, r 0.7578, anchor RMSE 0.753, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#28 | Warden arena boundary | 6.82 | **6.36** | -0.46 | 6 6 5.9 / 5.6 5.6 5.5 | PARTIAL / PARTIAL |

**Warnings:**
- anchor residual RMSE 0.75 > 0.75: these judges do not rank the anchors like the reference judges; report the mapped scores with this caveat

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
