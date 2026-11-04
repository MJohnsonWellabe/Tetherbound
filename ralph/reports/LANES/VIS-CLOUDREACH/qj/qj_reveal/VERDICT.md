# Quick judge qj_reveal: F40#18

- Head `13fff99909821f79b1456b46e900e8ae4691b01b`, tree `03591d049e18`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/catching.json": {"seal_reveal": {"enabled": true}}}`
- Capture: 1 launch(es); base 1766s, candidate 1512s, wall 3279s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.17, intercept -0.8834, r 0.6502, anchor RMSE 0.642, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#18 | full-party catch choice legibility | 5.63 | **3.33** | -2.30 | 5.6 5.5 5.6 / 3.6 3.4 3.8 | PARTIAL / PARTIAL |

**Warnings:**
- some candidates lie more than 0.5 outside the anchors' measured range (extrapolated)

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
