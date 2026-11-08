# Quick judge F38-30_F38-24-bde88113b20a-11072156: F38#30, F38#24

- Head `b8c2dee1b0841536855e6a2b41db67b1b0c44d41`, tree `ee1e961375bc`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/capture_stands.json": {"buried_stand_guard": {"enabled": true, "window_m": 30.0, "fallback_offsets_m": [18.0, 26.0, 40.0, 55.0]}}, "data/config/burrow_warrens.json": {"bank": {"hill_shell": {"scale_xyz": [1.45, 2.0, 1.25]}}}}`
- Capture: 1 launch(es); base 511s, candidate 554s, wall 1065s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.0628, intercept 0.5502, r 0.8278, anchor RMSE 0.647, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#30 | Burrow Warrens hillside | 4.48 | **4.06** | -0.42 | 3.8 3.5 3.8 / 3.4 3.1 3.4 | PRESENT / PRESENT |
| F38#24 | distant mountains | 4.41 | **4.16** | -0.25 | 3.9 3.6 3.4 / 3.6 3.4 3.2 | PRESENT / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
