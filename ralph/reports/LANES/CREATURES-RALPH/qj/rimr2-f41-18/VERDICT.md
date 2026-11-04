# Quick judge rimr2-f41-18: F41#18

- Head `d11a775e5470fae8dc956062e1e1f02c3ac72571`, tree `64f810a18af1`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormwood_character_rim.json": ["r2"]}`
- Capture: 1 launch(es); base 592s, candidate 569s, wall 1161s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.7589, intercept -4.9856, r 0.9789, anchor RMSE 0.173, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#18 | uniformed character readability | 5.10 | **4.98** | -0.12 | 5.5 6 5.7 / 5.5 5.8 5.7 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
