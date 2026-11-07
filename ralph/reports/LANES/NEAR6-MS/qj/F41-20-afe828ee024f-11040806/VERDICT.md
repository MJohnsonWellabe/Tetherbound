# Quick judge F41-20-afe828ee024f-11040806: F41#20

- Head `12e76f2aa11fafc43f6bd7471874a7d2ce8827ce`, tree `275beaaffd17-5a4b4f43`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/camfx.json": ["fight_fade", "dialogue_open"]}`
- Capture: 1 launch(es); base 1108s, candidate 897s, wall 2005s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3107, intercept -1.9228, r 0.9252, anchor RMSE 0.514, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#20 | named character dialogue reuse | 4.72 | **5.64** | +0.92 | 5.4 5.2 4.6 / 6.2 6.1 5 | FIXED / FIXED |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
