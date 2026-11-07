# Quick judge r2b: F39#16, F39#5, F39#14

- Head `19a34fcb5f6ec281a2dff596a8c80393998f2913`, tree `f62c2aa03a49`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/tidewake_look.json": {"cause_tidewake": {"sea": {"enabled": true}, "horizon": {"enabled": true}}}}`
- Capture: 2 launch(es); base 2166s, candidate 2240s, wall 4406s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.0785, intercept -0.2238, r 0.8398, anchor RMSE 0.453, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#16 | live current streaks | 6.18 | **6.00** | -0.18 | 6.2 5.9 5.7 / 5.6 6.3 5.4 | PARTIAL / PARTIAL,PRESENT |
| F39#5 | surface swimming trainer pose | 6.03 | **5.60** | -0.43 | 5.7 5.8 5.9 / 5.3 5.4 5.5 | PRESENT / PRESENT |
| F39#14 | swimmer water contact | 6.32 | **5.82** | -0.50 | 6.1 6.1 6 / 5.5 5.7 5.6 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
