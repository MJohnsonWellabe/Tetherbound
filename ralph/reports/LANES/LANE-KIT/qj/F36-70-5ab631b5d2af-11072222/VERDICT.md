# Quick judge F36-70-5ab631b5d2af-11072222: F36#70

- Head `8c347327a136f34534d065a6f7ba196b61b3ab04`, tree `63d3238ddd49`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/creature_model_flags.json": {"flags": {"lanekit_sparkit_legs_1107": {"species": {"sparkit": {"model": "res://assets/creatures/tetherbound/sparkit/candidate_owner1101/models/creature_sparkit_owner1101_legs18.glb"}}}}}}`
- Capture: 1 launch(es); base 13s, candidate 14s, wall 27s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.1972, intercept -0.5967, r 0.8532, anchor RMSE 0.601, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F36#70 | Sparkit (storm fennec) on a neutral stage beside a 1.80 m human ruler: walk cycle and hit react | 5.91 | **6.03** | +0.12 | 5.4 5.5 5.4 / 5.5 5.6 5.5 | PARTIAL,PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
