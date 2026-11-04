# Quick judge r24: F39#24

- Head `57cb42fdefc96810757332660df21f6ee81f6ed0`, tree `8dc00387a20a`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/water_creature_rest_visual.json": {"prone_rest": {"enabled": true}}}`
- Capture: 1 launch(es); base 191s, candidate 163s, wall 355s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3202, intercept -1.6699, r 0.9019, anchor RMSE 0.467, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#24 | creature rest poses | 5.02 | **6.69** | +1.67 | 5.3 5.3 4.6 / 6.4 6.4 6.2 | PRESENT / FIXED |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
