# Quick judge F40-9-68037b4643f8-11041154: F40#9

- Head `26650df80530a176426da40b25e50bd12038eaad`, tree `f343d44a32e2`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/cloudreach_npc_runtime.json": {"post_role_props": {"enabled": true}}}`
- Capture: 1 launch(es); base 0s (cached), candidate 1449s, wall 1449s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.1993, intercept -1.3421, r 0.8598, anchor RMSE 0.424, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#9 | named NPC post readability | 5.05 | **5.25** | +0.20 | 5.5 5.3 5.2 / 5.6 5.5 5.4 | PRESENT / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
