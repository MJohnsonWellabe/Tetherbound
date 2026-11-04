# Quick judge f38_20-crag2: F38#20

- Head `0e028b09106094256477c4e24d8aa7a3bb278b3b`, tree `bf41499c3cd0`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stronghold.json": {"p2_003_candidate": {"add_companions": [{"id": "crag", "path": "res://assets/props/meshy-1024/meadows_cliff_a/meadows_cliff_a.glb", "width_m": 230.0, "offset": [0.0, -5.0, 150.0], "yaw_deg": 180.0, "albedo_tint": "#9a958c", "fog_disable": true}]}}}`
- Capture: 2 launch(es); base 419s, candidate 421s, wall 840s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.0706, intercept 0.0515, r 0.7638, anchor RMSE 0.784, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#20 | Team Tether stronghold | 5.87 | **6.05** | +0.18 | 5.3 5.5 5.5 / 5.4 5.6 5.8 | PRESENT / PARTIAL,PRESENT |

**Warnings:**
- anchor residual RMSE 0.78 > 0.75: these judges do not rank the anchors like the reference judges; report the mapped scores with this caveat

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
