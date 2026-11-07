# Quick judge EYES-939043818257-11072236: EYES

- Head `76930cd2b2debb35c325bc13b2873ac0f1fc99ff`, tree `8f330f78d530`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/creature_coat_flags.json": {"flags": {"lanekit_face_read_fulgocobra": {"enabled": true}, "lanekit_face_read_mirejaw": {"enabled": true}}}}`
- Capture: 2 launch(es); base 20s, candidate 21s, wall 41s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.2197, intercept -0.576, r 0.8494, anchor RMSE 0.609, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| EYES | Fulgocobra (storm king cobra) and Mirejaw (swamp axolotl predator) on a neutral stage beside a 1.80 m human ruler: idle and hit react | 6.09 | **6.78** | +0.69 | 5.3 5.6 5.5 / 5.9 6.2 6 | PRESENT / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
