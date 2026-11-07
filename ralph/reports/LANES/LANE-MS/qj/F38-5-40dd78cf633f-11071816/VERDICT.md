# Quick judge F38-5-40dd78cf633f-11071816: F38#5

- Head `ec9ae6383c0c038ce10675b08fcc6e6d96b35dc8`, tree `765b36a12dbe`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/creature_scale_flags.json": {"flags": {"creatures_f36_taller_than_trainer_4": {"enabled": true}}}}`
- Capture: 1 launch(es); base 172s, candidate 170s, wall 341s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3732, intercept -1.419, r 0.8465, anchor RMSE 0.614, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#5 | normal creature scale | 6.59 | **7.37** | +0.78 | 5.6 5.9 6 / 6.4 6.4 6.4 | PARTIAL,PRESENT / FIXED,PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
