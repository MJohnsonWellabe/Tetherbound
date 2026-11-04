# Quick judge lathit4-f38-2: F38#2

- Head `74600dfa4863b959cbe83607d06e7e626e671c0d`, tree `b2995d2a1a16-5e9f3f12`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/creature_model_flags.json": ["flags.creatures_ralph_burrowback_lateral_hit"]}`
- Capture: 1 launch(es); base 310s, candidate 316s, wall 626s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3659, intercept -1.7907, r 0.9504, anchor RMSE 0.336, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#2 | creature hurt and movement poses | 6.18 | **6.40** | +0.22 | 6.1 5.8 5.6 / 6.4 6 5.6 | PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
