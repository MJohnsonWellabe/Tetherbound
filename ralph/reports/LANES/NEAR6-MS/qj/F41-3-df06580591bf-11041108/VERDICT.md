# Quick judge F41-3-df06580591bf-11041108: F41#3

- Head `ab6e5cddfc15402e62b5eb9069709cfaf10fda54`, tree `e70e18fdaf5b`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/combat.json": ["contact_spacing.named_overrides.capacitor_alpha"]}`
- Capture: 1 launch(es); base 829s, candidate 872s, wall 1701s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.5289, intercept -3.2042, r 0.8902, anchor RMSE 0.385, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#3 | named wild fight actor spacing | 4.70 | **4.75** | +0.05 | 5 5.4 5.1 / 5.3 5.4 4.9 | PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
