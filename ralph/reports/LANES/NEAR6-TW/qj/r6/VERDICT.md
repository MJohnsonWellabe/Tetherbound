# Quick judge r6: F39#6

- Head `123ff12c2eb0046b46a55aba40184e8fc25b984d`, tree `0ebb64bb84d6`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/creatures/f36_pose_candidates.json": {"lane_role_flags": {"uiposes_riptusk_side_faint_prone_rest": {"enabled": true}}}}`
- Capture: 1 launch(es); base 252s, candidate 174s, wall 426s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.6958, intercept -4.486, r 0.8767, anchor RMSE 0.426, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#6 | creature faint state | 5.29 | **5.29** | +0.00 | 5.9 5.9 5.5 / 5.9 5.9 5.5 | PRESENT / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
