# Quick judge F38-21-db50e927ec7b-11050229: F38#21

- Head `969ca4b8e2068a45a35eacf5beb79edf2cf5f178`, tree `e849f0f97449`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/grass_field.json": {"meadows_ground_candidate": {"merge": {"stones": {"enabled": true, "count": 25000, "centre_bias": 0.58, "seed": 771131, "sides": 7, "stone_size": 0.16, "size_jitter": 0.85, "sink": 0.42, "density_gain": 0.9, "clump_scale": 0.16, "clump_contrast": 0.95, "tint_stone": "#8c8377", "tint_jitter": 0.38, "ground_blend": 0.35, "contact_darken": 0.45, "stray_chance": 0.05, "verge_gain": 0.55, "reach_m": 28.0, "ground": ["rock", "path"]}}, "tiers": {"flowers": {"patch_start": 0.68, "patch_full": 0.76, "density_gain": 3.2, "drift_contrast": 1.4}, "flowers_gold": {"patch_start": 0.6, "patch_full": 0.7, "density_gain": 3.0, "item_size": 0.55, "drift_contrast": 1.4}}}}}`
- Capture: 2 launch(es); base 0s (cached), candidate 459s, wall 459s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.2336, intercept -1.2135, r 0.7803, anchor RMSE 0.533, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#21 | ground cover | 6.11 | **6.23** | +0.12 | 5.6 6.4 5.8 / 5.7 6.5 5.9 | PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
