# Quick judge hero-card-r1: F39#21, F41#21

- Head `49145e0c7700cefb1dda3829139c65a1a2fb6494`, tree `aff758e12065`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/hud.json": {"victory_focus": {"hero_card": {"enabled": true}}}}`
- Capture: 4 launch(es); base 10603s, candidate 10083s, wall 20686s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 0.9643, intercept 1.0548, r 0.7797, anchor RMSE 0.722, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#21 | named fight victory hierarchy | 5.62 | **6.33** | +0.71 | 4.6 4.8 4.8 / 5.4 5.5 5.5 | PARTIAL,PRESENT / PARTIAL |

Missing frames (not judged): F39#21:tidewake__fight__venn_resolve__aftermath-142_53, F41#21:stormwood__fight__hollows_win__hollows_alpha-99-after, F41#21:stormwood__fight__hollows_aftermath__hollows_alpha-100-aftermath

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).

