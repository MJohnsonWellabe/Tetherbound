# Quick judge F38-12-2a9b43ffa703-11071803: F38#12

- Head `ec9ae6383c0c038ce10675b08fcc6e6d96b35dc8`, tree `765b36a12dbe`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/meadows_orb_reward_presentation.json": {"enabled": true}}`
- Capture: 1 launch(es); base 342s, candidate 244s, wall 586s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.331, intercept -1.3129, r 0.8006, anchor RMSE 0.691, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#12 | harvest reward identity | 6.27 | **5.47** | -0.80 | 5.6 5.6 5.9 / 5 5 5.3 | PARTIAL / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
