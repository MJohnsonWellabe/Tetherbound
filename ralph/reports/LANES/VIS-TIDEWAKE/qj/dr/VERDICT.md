# Quick judge dr: F39#3

- Head `3c0cd6284ed529fd0010ea7d977fe5e4dc95905e`, tree `127f7ef33619`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/tidewake_destination_read.json": {"enabled": true}}`
- Capture: 1 launch(es); base 1036s, candidate 1030s, wall 2065s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3131, intercept -1.693, r 0.9392, anchor RMSE 0.293, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#3 | named destination read | 5.75 | **5.84** | +0.09 | 5.9 5.3 5.8 / 5.6 5.6 6 | PARTIAL,PRESENT / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
