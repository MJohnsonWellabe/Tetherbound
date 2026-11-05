# Quick judge r29p: F39#29

- Head `d72b8a42782a9a2f6d80f913a65ad41da9a8355b`, tree `63a999d17b09`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/water_npc_posts_candidate.json": {"enabled": true, "offsets": {"water_trainer_rune": null}}}`
- Capture: 1 launch(es); base 0s (cached), candidate 260s, wall 260s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.1382, intercept -0.6831, r 0.6876, anchor RMSE 0.597, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#29 | dialogue speaker visibility | 5.54 | **6.34** | +0.80 | 5.6 5.4 5.4 / 6.2 6.2 6.1 | PARTIAL / FIXED |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
