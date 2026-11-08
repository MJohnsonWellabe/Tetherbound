# Quick judge HITREACT-33acc782d931-11072245: HITREACT

- Head `5b8787dad1f0efbf317ea338facb367601d34c04`, tree `c9690e67b061`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/creature_model_flags.json": {"flags": {"lanekit_hitreact_grounded_1107": {"enabled": true}}}}`
- Capture: 4 launch(es); base 39s, candidate 39s, wall 78s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.1287, intercept 0.119, r 0.8019, anchor RMSE 0.689, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| HITREACT | Shadelet, Paddlenewt, Glimmermoth and Tempestwing hit react mid on a neutral stage beside a 1.80 m human ruler | 6.14 | **6.14** | +0.00 | 5.6 4.9 5.5 / 5.6 4.9 5.5 | PARTIAL,PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
