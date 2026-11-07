# Quick judge qj_obs2: F41#10

- Head `4a25c87307f2e766d607aca623a2d3e9a870f596`, tree `7eae0eaf8f82`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormwood_glass_sink.json": ["obsidian_1104.r2"]}`
- Capture: 3 launch(es); base 586s, candidate 588s, wall 1174s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3291, intercept -1.5187, r 0.8631, anchor RMSE 0.422, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#10 | Glass Sink landmark | 3.93 | **4.02** | +0.09 | 4.2 3.9 4.2 / 4.2 4 4.3 | PRESENT / PRESENT |

**Warnings:**
- some candidates lie more than 0.5 outside the anchors' measured range (extrapolated)

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
