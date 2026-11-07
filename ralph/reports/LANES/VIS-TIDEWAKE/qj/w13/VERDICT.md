# Quick judge w13: F39#13

- Head `cd1d36013dbad1896e0998d8fe126d2b8595d29d`, tree `d31f54c3b3b7`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/meshy_camp_props.json": {"workbench": {"vl_candidate": {"enabled": true}}}}`
- Capture: 1 launch(es); base 0s (cached), candidate 188s, wall 188s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.5258, intercept -2.6406, r 0.9077, anchor RMSE 0.512, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#13 | authored camp workbench identity | 6.41 | **5.14** | -1.27 | 6 6.1 5.7 / 5.3 5.2 4.8 | PARTIAL / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
