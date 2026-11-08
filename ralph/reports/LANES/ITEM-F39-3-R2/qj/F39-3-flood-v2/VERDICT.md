# Quick judge F39-3-flood-v2: F39#3-dg

- Head `770893c14927d4615e50d274e9e90bc41a600ee4`, tree `ae61d6b16498-327202a6`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/water_garden_flood.json": ["enabled"]}`
- Capture: 1 launch(es); base 382s, candidate 373s, wall 755s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3862, intercept -1.4651, r 0.8812, anchor RMSE 0.545, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#3-dg | Drowned Garden Terraces named destination, Tidewake route arrival view | 6.16 | **6.30** | +0.14 | 5.5 5.8 5.2 / 5.9 5.4 5.5 | PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
