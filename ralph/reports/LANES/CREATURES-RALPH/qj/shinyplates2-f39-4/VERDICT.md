# Quick judge shinyplates2-f39-4: F39#4

- Head `cba7ab8dcfdf12bdf6042cd41901919b169db8fa`, tree `3eee1c63c182`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/creatures_visual.json": ["shiny_remake_textures"]}`
- Capture: 1 launch(es); base 177s, candidate 177s, wall 354s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.4366, intercept -2.3355, r 0.9797, anchor RMSE 0.171, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#4 | shiny creature finish | 5.61 | **6.76** | +1.15 | 5.4 5.6 5.6 / 6.3 6.3 6.4 | PARTIAL,PRESENT / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
