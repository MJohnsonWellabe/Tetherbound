# Quick judge F40-19-458a13de2967-11042202: F40#19

- Head `901fdbc40c9d0a6c27c4a8ae41918e483da836f9`, tree `ea4305e880b0`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/cloudreach_visual.json": {"gate_path_braziers": {"enabled": true}}}`
- Capture: 1 launch(es); base 1387s, candidate 1323s, wall 2710s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.2662, intercept -1.6651, r 0.748, anchor RMSE 0.55, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#19 | Cloudreach realm gate at night (F40 matrix piece 7) | 5.00 | **5.51** | +0.51 | 5.5 5.2 5.1 / 5.8 5.6 5.6 | PARTIAL / FIXED,PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
