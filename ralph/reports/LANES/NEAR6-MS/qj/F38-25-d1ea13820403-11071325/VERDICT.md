# Quick judge F38-25-d1ea13820403-11071325: F38#25

- Head `b1e7ca15719af5d7e59c872939817f2e3b20a037`, tree `dc9d0c957e5f`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/creatures_visual.json": {"shiny_cue": {"enabled": true, "overlay": {"enabled": true, "energy": 1.6, "power": 1.5, "fill_energy": 0.2}}}}`
- Capture: 1 launch(es); base 0s (cached), candidate 253s, wall 253s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3067, intercept -1.3792, r 0.9516, anchor RMSE 0.255, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#25 | shiny palette distinction | 6.85 | **6.85** | +0.00 | 6.3 6.3 6.3 / 6.3 6.3 6.3 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
