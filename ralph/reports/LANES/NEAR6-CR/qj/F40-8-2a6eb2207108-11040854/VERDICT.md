# Quick judge F40-8-2a6eb2207108-11040854: F40#8

- Head `8317e62c3da3d7acef0b0ac52adf3a6d0861d9f7`, tree `5a00b7817bfb`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/cloudreach_npc_runtime.json": {"world_payoffs": {"anchor_vessel_quiet": {"enabled": true}}}}`
- Capture: 3 launch(es); base 0s (cached), candidate 1295s, wall 1295s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 0.795, intercept 1.3072, r 0.671, anchor RMSE 0.589, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#8 | bright Cloudreach route markers | 5.87 | **6.32** | +0.45 | 5.8 5.9 5.5 / 6.3 6.4 6.2 | PRESENT / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
