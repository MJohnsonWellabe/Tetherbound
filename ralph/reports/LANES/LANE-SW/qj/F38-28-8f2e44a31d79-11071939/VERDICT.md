# Quick judge F38-28-8f2e44a31d79-11071939: F38#28

- Head `ec9ae6383c0c038ce10675b08fcc6e6d96b35dc8`, tree `765b36a12dbe`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/combat.json": {"arena": {"boundary_per_trainer_candidate": {"enabled": true, "warden_aldis": {"boundary_alpha": 0.05, "boundary_height": 0.3}}}}}`
- Capture: 1 launch(es); base 0s (cached), candidate 2567s, wall 2567s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.2562, intercept -0.6224, r 0.8374, anchor RMSE 0.63, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#28 | Warden arena boundary | 6.71 | **6.50** | -0.21 | 5.2 6 6.3 / 5.6 5.6 5.8 | FIXED,PARTIAL / FIXED,PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
