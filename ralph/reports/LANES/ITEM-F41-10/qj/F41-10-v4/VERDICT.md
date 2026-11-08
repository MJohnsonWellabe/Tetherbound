# Quick judge F41-10-v4: F41#10

- Head `9e983966a2918760a1ec8f1cfd6d3f13c1e49d2d`, tree `09d6afea6ed5`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/stormwood_glass_sink.json": {"meshy_rim": {"shards": {"enabled": true}}, "fused_glass": {"enabled": true}}}`
- Capture: 3 launch(es); base 408s, candidate 413s, wall 821s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.2886, intercept -0.5472, r 0.8137, anchor RMSE 0.67, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F41#10 | Glass Sink landmark | 6.20 | **6.24** | +0.04 | 4.9 5.3 5.5 / 5 5.3 5.5 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
