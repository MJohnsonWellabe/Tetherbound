# Quick judge verheaddown-f38-1: F38#1

- Head `66669f727859ee357be9f080cb493a4d387df50e`, tree `1e55a5978649`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/creature_model_flags.json": ["flags.creatures_ralph_veridian_faint_headdown"]}`
- Capture: 1 launch(es); base 451s, candidate 445s, wall 896s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3287, intercept -1.4975, r 0.9273, anchor RMSE 0.502, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#1 | creature collapse and rest | 6.21 | **6.30** | +0.09 | 5.7 5.8 5.9 / 5.8 5.9 5.9 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
