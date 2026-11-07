# Quick judge headdown-f39-6: F39#6

- Head `6ae6887092ef2a550dd13be6b19bf465e1a919e6`, tree `8962486d963e`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/creature_model_flags.json": ["flags.creatures_ralph_aquaryn_faint_headdown"]}`
- Capture: 1 launch(es); base 182s, candidate 182s, wall 364s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.152, intercept -0.5558, r 0.8644, anchor RMSE 0.492, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#6 | creature faint state | 6.05 | **6.24** | +0.19 | 5.6 6.2 5.4 / 5.6 6.6 5.5 | PARTIAL,PRESENT / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
