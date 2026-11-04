# Quick judge F39-23-49d54adda13f-11041824: F39#23

- Head `c5f1b9ed2bf8a91e0468e595d0b1413f86ff5448`, tree `77defa2ffcca`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/capture_readout_visual.json": ["ring_outline_1104"]}`
- Capture: 1 launch(es); base 659s, candidate 641s, wall 1300s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.9032, intercept -5.1971, r 0.951, anchor RMSE 0.277, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#23 | catch chance HUD contrast | 5.46 | **4.70** | -0.76 | 5.6 5.6 5.6 / 5.2 5.2 5.2 | FIXED,PARTIAL / FIXED,PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
