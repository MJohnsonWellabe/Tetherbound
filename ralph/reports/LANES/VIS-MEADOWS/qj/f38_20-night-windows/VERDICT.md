# Quick judge f38_20-night-windows: F38#20

- Head `bfd4f96fbbd9f961304eac6fab5687b17c599b83`, tree `2743f44e039c`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stronghold.json": {"p2_003_candidate": {"keep": {"emission_energy": 18.0, "emission_colour": "#ffb066"}}}}`
- Capture: 2 launch(es); base 414s, candidate 420s, wall 834s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.2859, intercept -2.0234, r 0.8402, anchor RMSE 0.443, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#20 | Team Tether stronghold | 5.52 | **5.48** | -0.04 | 6 6 5.6 / 5.9 6 5.6 | PARTIAL,PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
