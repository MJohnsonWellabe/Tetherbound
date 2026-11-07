# Quick judge F41-8-12e5730a78f0-11072254: F41#8

- Head `d37144500c1bdd2291cccf044a278f3d35b89456`, tree `fd8fc8393fb7`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/character_appearance_variants.json": {"variants": {"lanekit_f41_8_bryn": {"enabled": true}, "lanekit_f41_8_maud": {"enabled": true}}}}`
- Capture: 1 launch(es); base 410s, candidate 398s, wall 808s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.0864, intercept 0.5464, r 0.8283, anchor RMSE 0.646, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#8 | named character silhouettes | 5.47 | **5.83** | +0.36 | 4.8 4.6 4.2 / 5.2 4.9 4.5 | PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
