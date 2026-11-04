# Quick judge r7: F39#7

- Head `e3e034ef6ca89bb4dcb2267ed818ca37cc43a7b9`, tree `be1e199acf9b-574c4984`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/combat.json": {"contact_spacing": {"all_pairs": {"enabled": true}}}}`
- Capture: 1 launch(es); base 538s, candidate 551s, wall 1108s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3531, intercept -2.4684, r 0.8599, anchor RMSE 0.423, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#7 | fight actor composition | 6.19 | **5.42** | -0.77 | 6.4 6.4 6.4 / 5.9 5.8 5.8 | FIXED / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
