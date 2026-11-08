# Quick judge F38-6-6b6bc90bbae7-11072022: F38#6

- Head `d179a418b59ce77f3d2f5029d27d26822f892813`, tree `4b39ef180a73`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/meshy_item_visuals.json": {"items": {"rare_candy": {"model": "res://assets/props/meshy-1020/candy_pickup_set/model_candy_rare_cloth_r1/candy_rare_cloth_r1.glb"}}}}`
- Capture: 1 launch(es); base 365s, candidate 364s, wall 730s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.1501, intercept -0.3288, r 0.8143, anchor RMSE 0.67, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#6 | ground pickup identity | 6.50 | **6.76** | +0.26 | 6.4 5.5 5.9 / 6.6 5.8 6.1 | PARTIAL / FIXED,PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
