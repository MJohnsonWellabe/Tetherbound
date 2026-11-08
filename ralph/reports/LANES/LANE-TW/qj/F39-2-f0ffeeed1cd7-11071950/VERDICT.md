# Quick judge F39-2-f0ffeeed1cd7-11071950: F39#2

- Head `a567d3393840fa3c221bde6e0011e3946af5d3c9`, tree `cd7b5932d41a`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/hero_landmarks_1101.json": {"veilfall": {"enabled": true, "model": "res://assets/props/blender-1107/veilfall_tiered/veilfall_tiered.glb", "across_m": 1000.0, "yaw_deg": 172.0, "sink_m": 6.0, "hide_siblings_from_m": 1100.0, "hide_sibling_nodes": ["VeilfallCragKitbash", "VeilfallCliffR3", "VeilfallTieredR2", "VeilfallRidgeBlockout", "WaterfallPassage"]}}}`
- Capture: 2 launch(es); base 641s, candidate 577s, wall 1217s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.2792, intercept -0.9335, r 0.8356, anchor RMSE 0.634, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#2 | Veilfall silhouette | 6.57 | **5.46** | -1.11 | 5.4 6.4 5.8 / 4.6 5.4 5 | FIXED,PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
