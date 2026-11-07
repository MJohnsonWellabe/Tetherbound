# Quick judge EYES-939043818257-11072232: EYES

- Head `639acd3c5076fcc11321e24fa549f7331e3b4f29`, tree `af2f61d9f74c`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/creature_coat_flags.json": {"flags": {"lanekit_face_read_fulgocobra": {"enabled": true}, "lanekit_face_read_mirejaw": {"enabled": true}}}}`
- Capture: 2 launch(es); base 20s, candidate 20s, wall 40s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3501, intercept -1.1987, r 0.8994, anchor RMSE 0.504, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| EYES | Fulgocobra (storm king cobra) and Mirejaw (swamp axolotl predator) on a neutral stage beside a 1.80 m human ruler: idle and hit react | 6.14 | **6.14** | +0.00 | 5.4 5.4 5.5 / 5.4 5.4 5.5 | PRESENT / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
