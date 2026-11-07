# Quick judge r14s: F41#14

- Head `31f90813d22da0cf0182ef947f031a944ad8162d`, tree `f4021383096a`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/pickup_grounding.json": {"tier_candidate": {"enabled": true, "items": {"good_candy": {"scale_mult": 1.45}, "great_candy": {"scale_mult": 1.6}, "rare_candy": {"scale_mult": 1.75}}}}}`
- Capture: 1 launch(es); base 523s, candidate 352s, wall 875s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 0.8364, intercept 1.2475, r 0.6369, anchor RMSE 0.657, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#14 | candy pickup tiers | 5.57 | **5.26** | -0.31 | 5.3 4.8 5.4 / 5 4.5 4.9 | FIXED,PARTIAL / FIXED |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
