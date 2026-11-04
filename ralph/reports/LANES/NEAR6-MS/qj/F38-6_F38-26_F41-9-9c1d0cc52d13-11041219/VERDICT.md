# Quick judge F38-6_F38-26_F41-9-9c1d0cc52d13-11041219: F38#6, F38#26, F41#9

- Head `d18f106fe7d35ac0efd7fc9b9214ce56871c7188`, tree `e70e18fdaf5b`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/pickup_grounding.json": ["tier_candidate"], "data/config/creature_grass_clear.json": {"radius_scale": 2.6}, "data/config/stormwood_harvest_hero2.json": {"enabled": true, "items": {"stormglass": null, "stormglass_crown": null, "glowmoss": {"models": [{"model": "res://assets/environment/stylized_nature/Rock_Medium_3.gltf", "height_m": [1.1, 1.1], "squash_y": 0.55, "sink_m": 0.25, "tint": "#2f5e44", "roughness": 0.95}, {"model": "res://assets/props/meshy-1020/storm_fungi/v1/storm_fungi_v1.glb", "count": 5, "ring_m": 0.55, "height_m": [0.9, 1.5], "sink_m": 0.04, "glow_colour": "#2fae7e", "glow_energy": 0.5, "shadow": false}]}}}}`
- Capture: 3 launch(es); base 1161s, candidate 1178s, wall 2339s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 0.9934, intercept 0.1196, r 0.613, anchor RMSE 0.667, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#6 | ground pickup identity | 5.95 | **6.15** | +0.20 | 5.6 5.8 6.2 / 5.7 6.3 6.2 | PARTIAL / PARTIAL |
| F38#26 | creature ground contact | 5.78 | **5.78** | +0.00 | 5.4 5.9 5.8 / 5.4 5.9 5.8 | PARTIAL,PRESENT / PARTIAL,PRESENT |
| F41#9 | harvest resource identity | 5.45 | **5.42** | -0.03 | 5.2 5.4 5.5 / 5 5.6 5.4 | PARTIAL / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
