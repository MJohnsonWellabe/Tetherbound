# Quick judge F40-1-r1: F40#1

- Head `ad96e176cbdb9c52b05d940cbfcdaf99be0a9640`, tree `765e19a5d467`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/cloudreach_f40_items.json": ["candidates.12"]}`
- Capture: 2 launch(es); base 858s, candidate 842s, wall 1700s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.022, intercept 0.7206, r 0.7783, anchor RMSE 0.724, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#1 | open terrain | 6.17 | **6.03** | -0.14 | 4.9 5.7 5.4 / 4.8 5.6 5.2 | PARTIAL,PRESENT / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
