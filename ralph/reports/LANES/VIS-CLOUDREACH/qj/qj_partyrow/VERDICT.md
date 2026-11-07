# Quick judge qj_partyrow: F40#18

- Head `8d9341a775dc534cd79bfb4d8b38790765ee4fc4`, tree `25ac9af5d77d`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/hud.json": {"catch_card": {"full_team_line": {"party_row": {"enabled": true}}}}}`
- Capture: 1 launch(es); base 1543s, candidate 788s, wall 2330s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.1542, intercept -0.2651, r 0.8795, anchor RMSE 0.4, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#18 | full-party catch choice legibility | 5.58 | **6.85** | +1.27 | 5 5.5 4.7 / 6.3 6.6 5.6 | PARTIAL / FIXED,PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).

**Lane note:** both sides caught the same pinned pebbik (arbiter window 600000 ms, zero not_claimant), but the post-catch camera yaw differs (it follows the throw direction, which depends on the live fight): the base frames the terrace road, the candidate the creature and trainer. All three judges named the party row as the reason for preferring the candidate and called the base "no choice shown". **Ships ON** (owner rule). Judges' next ask: larger portraits with names and levels, a teal selection frame and controller confirm/back prompts.
