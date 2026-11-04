# Quick judge r1: F39#1

- Head `616d049a1377e02e9b325bcac932265e78b59563`, tree `309a004360c5`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/water_dune_cover.json": {"shore_ecology_candidate": {"shipped_sites": ["f26_deep_watch_beach_transition", "welcome_bay", "horizon_headland", "east_beach"]}}, "data/config/water_ground_cover.json": {"built_feather_enabled": true}}`
- Capture: 2 launch(es); base 930s, candidate 920s, wall 1850s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.0459, intercept 0.2656, r 0.8684, anchor RMSE 0.411, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#1 | shore landforms | 6.37 | **6.44** | +0.07 | 6 5.5 6 / 6.1 5.5 6.1 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
