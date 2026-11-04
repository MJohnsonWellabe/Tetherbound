# Quick judge terralift-f38-1: F38#1

- Head `3c7d9ca1825b288ef10d9aa003819fa6fc3622f3`, tree `3f898bdbe283`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/creature_coat_flags.json": ["flags.creatures_ralph_terrapup_value_lift"]}`
- Capture: 1 launch(es); base 472s, candidate 464s, wall 936s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3337, intercept -1.6962, r 0.876, anchor RMSE 0.405, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#1 | creature collapse and rest | 6.04 | **6.04** | +0.00 | 6 5.4 6 / 6 5.4 6 | PARTIAL,PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
