# Quick judge F38-26-8ba717064855-11072338: F38#26

- Head `688cf22ad2d025db0e6aa6d6b1fbb63c3ad94ef2`, tree `b1698bc82326`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/creature_pose_settle.json": {"lanekit_mosshell_scope": {"enabled": true}}}`
- Capture: 1 launch(es); base 343s, candidate 351s, wall 695s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.4905, intercept -1.8772, r 0.8803, anchor RMSE 0.547, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#26 | creature ground contact | 6.27 | **6.97** | +0.70 | 5.3 5.6 5.5 / 5.8 6 6 | PARTIAL,PRESENT / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
