# Quick judge r27: F39#27

- Head `123ff12c2eb0046b46a55aba40184e8fc25b984d`, tree `0ebb64bb84d6`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/water_character_rim.json": {"enabled": true}}`
- Capture: 1 launch(es); base 328s, candidate 322s, wall 650s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.4548, intercept -2.5033, r 0.749, anchor RMSE 0.788, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#27 | grass around named characters | 6.03 | **6.23** | +0.20 | 6.4 5.6 5.6 / 6.5 5.7 5.8 | FIXED / FIXED |

**Warnings:**
- anchor residual RMSE 0.79 > 0.75: these judges do not rank the anchors like the reference judges; report the mapped scores with this caveat

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
