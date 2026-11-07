# Quick judge qj_obs3: F41#10

- Head `5ed4e464681ab602187c1b8bf5f18f88f24103ca`, tree `ba597c11e48f`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormwood_glass_sink.json": ["obsidian_1104.r3"]}`
- Capture: 3 launch(es); base 633s, candidate 612s, wall 1269s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3932, intercept -1.5671, r 0.9774, anchor RMSE 0.283, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#10 | Glass Sink landmark | 3.96 | **4.38** | +0.42 | 4 4.5 3.4 / 3.8 5.2 3.8 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
