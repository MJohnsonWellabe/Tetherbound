# Quick judge qj_portrait: F40#18

- Head `22dd75c30c587d21a67b0b7db0d2ec91b24cffe5`, tree `f3d6ddfe97f8`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/hud.json": {"catch_card": {"portrait": {"enabled": true}}}}`
- Capture: 1 launch(es); base 1245s, candidate 1748s, wall 2992s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.4362, intercept -2.6058, r 0.847, anchor RMSE 0.616, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#18 | full-party catch choice legibility | 5.29 | **3.14** | -2.15 | 5.3 5.6 5.6 / 4 3.8 4.2 | FIXED,PARTIAL / FIXED,PARTIAL |

**Warnings:**
- some candidates lie more than 0.5 outside the anchors' measured range (extrapolated)

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).

**Lane note (confound):** the two catches landed at different random spawn spots; the candidate's post-catch camera sat inside a grass slope (all three judges: "camera in the ground, no sky"), the base framed the orb on a ledge with sky. No judge faulted the portrait itself. `catch_card.portrait` stays OFF (worse on the yardstick). Every judge's first ask: frame the post-catch camera so it never sits in terrain, which is the next arm.
