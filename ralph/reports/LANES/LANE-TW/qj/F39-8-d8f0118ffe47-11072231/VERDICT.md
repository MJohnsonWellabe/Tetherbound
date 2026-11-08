# Quick judge F39-8-d8f0118ffe47-11072231: F39#8

- Head `96855e2beaa322ce546db09e11f1987832da9081`, tree `ebc8404415f0`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/water_mount_presentation.json": {"mounts": {"water_aquaryn": {"rider_shadows_off": true, "extra_sink_m": 1.4}}}}`
- Capture: 1 launch(es); base 992s, candidate 1016s, wall 2008s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.4801, intercept -2.2344, r 0.9105, anchor RMSE 0.477, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#8 | Aquaryn mounted-water pose | 5.41 | **6.75** | +1.34 | 5.6 5 4.9 / 6.3 6 5.9 | PRESENT / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
