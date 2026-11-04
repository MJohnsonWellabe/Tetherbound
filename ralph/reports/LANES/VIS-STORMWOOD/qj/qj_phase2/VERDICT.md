# Quick judge qj_phase2: F41#2

- Head `aaca79220b11bd81104bbedccf6c61e8bc7683dc`, tree `c38c8557d31d`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormwood_surge.json": ["presentation.phase_grade_1104"]}`
- Capture: 1 launch(es); base 540s, candidate 563s, wall 1103s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.6722, intercept -3.6308, r 0.8856, anchor RMSE 0.538, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#2 | Surge phase presentation | 4.40 | **4.23** | -0.17 | 4.3 5.3 4.8 / 4.3 5.3 4.5 | PARTIAL,PRESENT / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
