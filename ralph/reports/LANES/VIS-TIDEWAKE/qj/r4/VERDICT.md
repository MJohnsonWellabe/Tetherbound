# Quick judge r4: F39#5

- Head `6d448dbed0f9c62da5215f99fa9641e24a80ad76`, tree `75dd3db09707`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/human_water_contact_visual.json": {"ring_diameter_m": 2.1, "trail_lifetime_s": 2.6, "trail_spacing_m": 0.55, "trail_interval_s": 0.12, "max_trail_rings": 12}}`
- Capture: 1 launch(es); base 914s, candidate 905s, wall 1819s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.5938, intercept -3.5129, r 0.9585, anchor RMSE 0.288, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#5 | surface swimming trainer pose | 5.31 | **5.63** | +0.32 | 6 5.4 5.2 / 6.2 5.6 5.4 | PRESENT / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
