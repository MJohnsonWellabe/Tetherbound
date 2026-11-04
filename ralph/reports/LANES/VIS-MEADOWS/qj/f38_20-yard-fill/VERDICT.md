# Quick judge f38_20-yard-fill: F38#20

- Head `80abd20e8e72ab0b8e273d414a59c9ed54648692`, tree `a1749ca5862f`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stronghold.json": {"courtyard_daylight_candidate": {"light": {"range": 52.0, "attenuation": 0.22, "energy": 12.0}}}}`
- Capture: 2 launch(es); base 416s, candidate 410s, wall 826s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.6962, intercept -3.2027, r 0.9795, anchor RMSE 0.173, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#20 | Team Tether stronghold | 4.71 | **5.73** | +1.02 | 4.9 4.6 4.5 / 5.4 5.4 5 | PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
