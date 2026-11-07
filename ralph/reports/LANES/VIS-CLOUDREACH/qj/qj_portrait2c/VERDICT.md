# Quick judge qj_portrait2c: F40#18

- Head `bd004d5564f06a26fc19a0459e5daa117291191a`, tree `c14e87d969e5`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/hud.json": {"catch_card": {"portrait": {"enabled": true}}}}`
- Capture: 1 launch(es); base 1053s, candidate 898s, wall 1951s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.6485, intercept -3.922, r 0.9609, anchor RMSE 0.329, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F40#18 | full-party catch choice legibility | 5.91 | **6.19** | +0.28 | 6 6 5.9 / 6.2 6.2 6 | FIXED,PARTIAL / FIXED,PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).

**Lane note:** first F40#18 round on the pinned capture (commits 564c65f9e, bd004d556): both sides caught the same pebbik at (-4, 105, -254) and reached 09-caught-banner with the same framing; the only scene difference is the card (portrait vs a traits line that rolled on the base side only). All three judges prefer the portrait side; gain +0.28. **Ships ON** (owner rule), applied after the concurrent `qj_resolveclear2` capture finishes reading hud.json.
