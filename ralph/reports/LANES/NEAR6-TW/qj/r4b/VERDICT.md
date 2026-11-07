# Quick judge r4b: F39#4

- Head `beb110516f2809040c1c09146b8f7f6d7adde306`, tree `5b10c45ae0fe`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/creatures_visual.json": {"shiny_cue": {"enabled": true, "overlay": {"enabled": true, "energy": 1.6, "power": 1.5, "fill_energy": 0.2}}}}`
- Capture: 1 launch(es); base 178s, candidate 198s, wall 388s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 0.9233, intercept 0.6118, r 0.7402, anchor RMSE 0.559, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#4 | shiny creature finish | 6.21 | **6.21** | +0.00 | 6 6.2 6 / 6 6.2 6 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
