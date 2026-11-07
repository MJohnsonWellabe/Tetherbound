# Quick judge f16: F39#16

- Head `9c9acb0c6df04dc8e3a1985cc91b99c185f546b2`, tree `10fb383a7e8a`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/tidewake_look.json": {"sections_off": ["night_creature_floor", "dock_village_candidate", "dock_dressing_candidate", "surfaces_candidate", "veilfall_hero_candidate", "veilfall_facade_candidate", "forward_plus_candidate", "veilfall_formation_relief_fill_candidate", "swim_candidate", "veilfall_mountain_candidate", "current_bands_candidate", "current_tint_candidate", "veilfall_cladding_candidate", "veilfall_buttress_candidate", "swim_stroke_candidate", "beach_groups_candidate"]}}`
- Capture: 1 launch(es); base 931s, candidate 903s, wall 1833s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.2479, intercept -1.3196, r 0.8134, anchor RMSE 0.605, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#16 | live current streaks | 6.63 | **6.75** | +0.12 | 6.1 6.4 6.6 / 6.3 6.5 6.6 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
