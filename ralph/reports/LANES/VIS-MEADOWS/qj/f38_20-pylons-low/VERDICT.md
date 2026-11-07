# Quick judge f38_20-pylons-low: F38#20

- Head `99c5d50dcd010f57354d2dc2458cdb3e4748bb4d`, tree `d1c480565a5c`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stronghold.json": {"approach_pylons": {"height": 7.0, "sag_scale": 1.3}}}`
- Capture: 2 launch(es); base 397s, candidate 393s, wall 790s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.5809, intercept -3.2289, r 0.9952, anchor RMSE 0.114, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#20 | Team Tether stronghold | 5.31 | **5.83** | +0.52 | 5.2 5.7 5.3 / 5.6 6 5.6 | PRESENT / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
