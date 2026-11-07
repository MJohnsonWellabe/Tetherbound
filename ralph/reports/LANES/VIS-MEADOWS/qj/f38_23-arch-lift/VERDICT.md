# Quick judge f38_23-arch-lift: F38#23

- Head `3cf634e2156b3b9a78ccebda190e6e034f4f7ef4`, tree `1755ee1df726`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/tether_relay.json": {"site": {"support_finish": {"variants": {"arch": {"tint": "#e4d8c2", "macro_strength": 0.2}}}}}}`
- Capture: 1 launch(es); base 638s, candidate 652s, wall 1290s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3224, intercept -2.074, r 0.7625, anchor RMSE 0.568, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#23 | Tether Relay yard | 5.90 | **6.04** | +0.14 | 5.9 5.9 6.3 / 6 6 6.4 | FIXED / FIXED |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
