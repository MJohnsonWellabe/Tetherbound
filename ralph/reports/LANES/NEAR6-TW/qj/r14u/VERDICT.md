# Quick judge r14u: F41#14

- Head `34e393fa1f3777149af356da684ba57ec79b9e90`, tree `f4021383096a`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/pickup_grounding.json": {"tier_candidate": {"enabled": true, "items": {"good_candy": {"scale_mult": 1.2}, "great_candy": {"scale_mult": 1.3}, "rare_candy": {"scale_mult": 1.2, "count": 1}}}}}`
- Capture: 1 launch(es); base 0s (cached), candidate 343s, wall 343s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.6901, intercept -3.7305, r 0.9901, anchor RMSE 0.173, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#14 | candy pickup tiers | 4.49 | **4.78** | +0.29 | 4.8 5 4.8 / 5 5.1 5 | PARTIAL / FIXED,PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
