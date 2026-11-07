# Quick judge F39-25-a46982c0a52b-11071809: F39#25

- Head `174b04e2f15bff7378f9a08a6affb338694c3520`, tree `4f25d6963890`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/map.json": {"fog_veil": {"keyboard_hint_one_device": true, "cloud_fog": {"tones": {"water": ["#8c8266", "#cfc3a0"]}}, "chart_grid_1104": {"realms": ["meadows", "water"]}}}}`
- Capture: 1 launch(es); base 0s (cached), candidate 91s, wall 91s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.4595, intercept -1.9103, r 0.9029, anchor RMSE 0.496, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#25 | map active region | 7.38 | **8.11** | +0.73 | 6.3 6.4 6.4 / 6.6 6.8 7.2 | FIXED / FIXED |

**Warnings:**
- meets the bar only above the top anchor (7.35): F39#25 cand; extrapolated, but this batch's anchors reach 7.35 or more, so it is the confirming batch

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
