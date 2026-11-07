# Quick judge qj_partynames: F40#18

- Head `b36ec26f3dc31555738ec6c0bdb54735d9e0f6e6`, tree `d9f148032723`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/hud.json": {"catch_card": {"full_team_line": {"party_row": {"px": 96, "name_px": 22, "gap_px": 18}}}}}`
- Capture: 1 launch(es); base 819s, candidate 1174s, wall 1993s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.1949, intercept -1.3059, r 0.7135, anchor RMSE 0.615, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#18 | full-party catch choice legibility | 5.58 | **6.18** | +0.60 | 5.9 5.8 5.6 / 6.3 6.2 6.3 | FIXED / FIXED |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).

**Lane note:** base is the shipped 64 px unnamed row; candidate 96 px portraits with names (name_px 22, gap 18). All three judges prefer the named row and cite the names; post-catch camera yaw again differs between runs (base frames creature and cliffs, candidate the road). **Ships ON.** Remaining asks: a selection highlight and controller confirm/cancel prompts (those belong to the release ceremony, which has the input; the card has none), and wrap the long traits line cleanly.
