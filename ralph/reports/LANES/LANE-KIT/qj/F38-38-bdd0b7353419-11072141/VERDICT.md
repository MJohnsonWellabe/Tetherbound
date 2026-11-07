# Quick judge F38-38-bdd0b7353419-11072141: F38#38

- Head `b9e3a0532b1bfe8cc9f30afcd20b48400e295b0e`, tree `2da9576374a4`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/craft_presentation.json": {"quiet_missing_r5": true}}`
- Capture: 1 launch(es); base 215s, candidate 209s, wall 425s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: offset, slope 1.0, intercept 0.915, r 0.9433, anchor RMSE 0.669, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#38 | craft action hint contrast | 7.55 | **7.35** | -0.20 | 6.7 6.5 6.7 / 6.4 6.3 6.6 | FIXED,PARTIAL / FIXED,PARTIAL |

**Warnings:**
- offset fallback (least-squares slope 2.016 outside 0.5-2.0): the map is only a mean offset; these judges spread the anchors differently from the reference judges
- meets the bar only above the top anchor (7.35): F38#38 base; extrapolated, but this batch's anchors reach 7.35 or more, so it is the confirming batch
- some candidates lie more than 0.5 outside the anchors' measured range (extrapolated)

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
