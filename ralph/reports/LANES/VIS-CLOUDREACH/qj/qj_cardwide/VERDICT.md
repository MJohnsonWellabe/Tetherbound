# Quick judge qj_cardwide: F40#18

- Head `ce470ed448c6a2699e90d00bdad3c9e374a60b07`, tree `28b5bee23011`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/hud.json": {"catch_card": {"card_half_width": 560.0}}}`
- Capture: 1 launch(es); base 806s, candidate 792s, wall 1598s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.5924, intercept -3.6146, r 0.9659, anchor RMSE 0.267, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#18 | full-party catch choice legibility | 5.99 | **6.74** | +0.75 | 6.3 5.6 6.2 / 6.8 6.1 6.6 | FIXED / FIXED |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).

**Lane note:** first F40#18 round with the banner yaw pinned (ce470ed44): both sides frame the same terrace edge and cloud sea, only the fighters' spots differ slightly. All three judges prefer the wider card (the full-team line stays on one line). **Ships ON.** Remaining asks: a selection cursor and controller prompts (they belong to the release ceremony, which has the input), a grounded orb, and Cloudreach dressing on the plateau.
