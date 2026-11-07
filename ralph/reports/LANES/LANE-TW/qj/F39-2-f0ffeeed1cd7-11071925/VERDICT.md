# Quick judge F39-2-f0ffeeed1cd7-11071925: F39#2

- Head `8ca7a76c35eef3466ff7f13c1c6ce3f73a7dee03`, tree `e61f94017094`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/hero_landmarks_1101.json": {"veilfall": {"enabled": true, "model": "res://assets/props/blender-1107/veilfall_tiered/veilfall_tiered.glb", "across_m": 1000.0, "yaw_deg": 172.0, "sink_m": 6.0, "hide_siblings_from_m": 1100.0, "hide_sibling_nodes": ["VeilfallCragKitbash", "VeilfallCliffR3", "VeilfallTieredR2", "VeilfallRidgeBlockout", "WaterfallPassage"]}}}`
- Capture: 2 launch(es); base 632s, candidate 596s, wall 1227s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.2517, intercept -0.53, r 0.8543, anchor RMSE 0.599, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#2 | Veilfall silhouette | 6.77 | **6.31** | -0.46 | 6 5.5 6 / 5.6 5.3 5.5 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
