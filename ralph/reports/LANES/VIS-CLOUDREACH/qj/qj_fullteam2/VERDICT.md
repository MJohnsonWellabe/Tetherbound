# Quick judge qj_fullteam2: F40#18

- Head `7cbfb74035af582fa897c000940e6b5651730385`, tree `f266a26a79cd`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/hud.json": {"catch_card": {"full_team_line": {"enabled": true}}}}`
- Capture: 1 launch(es); base 0s (cached), candidate 1503s, wall 1503s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 0.8989, intercept 1.0843, r 0.7284, anchor RMSE 0.551, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#18 | full-party catch choice legibility | 3.57 | **4.98** | +1.41 | 2.5 3.2 2.6 / 4.3 4.8 3.9 | PRESENT / PARTIAL |

**Warnings:**
- some candidates lie more than 0.5 outside the anchors' measured range (extrapolated)

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
