# Quick judge F40-9-bf0f5543f8e6-11042046: F40#9

- Head `db95dc9a1f4064f84b7688a20cbd96e9dec4805b`, tree `c99216cdd1bc`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/cloudreach_npc_runtime.json": {"post_dais": {"enabled": true}}}`
- Capture: 1 launch(es); base 0s (cached), candidate 1436s, wall 1436s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3392, intercept -1.9694, r 0.9688, anchor RMSE 0.205, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#9 | named NPC post readability | 5.44 | **5.62** | +0.18 | 5.9 5.4 5.3 / 6.1 5.5 5.4 | PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
