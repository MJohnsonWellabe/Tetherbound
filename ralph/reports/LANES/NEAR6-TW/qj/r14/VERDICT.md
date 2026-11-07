# Quick judge r14: F39#14

- Head `1f3bce4fc817f81109f1f530e235f733b09cc451`, tree `09602e71a76c`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/human_water_contact_visual.json": {"wake_trail": {"enabled": true}}}`
- Capture: 1 launch(es); base 811s, candidate 774s, wall 1585s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3182, intercept -2.0752, r 0.7929, anchor RMSE 0.515, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#14 | swimmer water contact | 6.10 | **6.80** | +0.70 | 6.3 6 6.3 / 6.9 6.5 6.8 | PRESENT / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
