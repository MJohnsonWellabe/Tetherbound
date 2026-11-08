# Quick judge F39-8-a298b52340f5-11072308: F39#8

- Head `1c1e53e46d8da6e2e706439032346d4f3ca934cf`, tree `ebc8404415f0`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/water_mount_presentation.json": {"mounts": {"water_aquaryn": {"rider_shadows_off": true, "extra_sink_m": 1.0}}}}`
- Capture: 1 launch(es); base 0s (cached), candidate 1023s, wall 1023s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.4101, intercept -1.5135, r 0.9179, anchor RMSE 0.458, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#8 | Aquaryn mounted-water pose | 4.97 | **6.38** | +1.41 | 4.5 4.8 4.5 / 5.6 5.6 5.6 | PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
