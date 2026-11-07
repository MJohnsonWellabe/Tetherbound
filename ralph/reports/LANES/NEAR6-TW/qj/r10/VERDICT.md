# Quick judge r10: F41#10

- Head `541487722ed55d9b9ce3a0af4e16f1149f76752b`, tree `829ad816c1bd`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormwood_crown_overlook.json": {"massif": {"near_hide_1104": {"enabled": true}}}}`
- Capture: 3 launch(es); base 650s, candidate 626s, wall 1276s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.1952, intercept -0.5799, r 0.8495, anchor RMSE 0.641, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#10 | Glass Sink landmark | 4.84 | **5.36** | +0.52 | 4.2 4.9 4.5 / 4.7 5.3 4.9 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
