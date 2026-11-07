# Quick judge F38-4_F38-9-8b3b7f6af458-11042024: F38#4, F38#9

- Head `e2da3eaec543c5704d029c7ecb366bd7ce93b3dc`, tree `4cbdcdd95ca2`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/map.json": {"fog_veil": {"cloud_fog": {"tones": {"meadows": ["#8c8266", "#cfc3a0"]}}}}, "data/config/menu.json": ["satchel_focus"]}`
- Capture: 1 launch(es); base 485s, candidate 489s, wall 974s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.7225, intercept -3.7244, r 0.8608, anchor RMSE 0.434, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#4 | map | 6.15 | **7.18** | +1.03 | 5.8 5.3 6.1 / 6.2 6.2 6.6 | PARTIAL,PRESENT / PARTIAL |
| F38#9 | menu shell | 7.13 | **7.36** | +0.23 | 6.2 6.2 6.5 / 6.4 6.3 6.6 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
