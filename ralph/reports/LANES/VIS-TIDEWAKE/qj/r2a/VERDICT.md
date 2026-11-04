# Quick judge r2a: F39#1, F39#2, F39#3, F39#15

- Head `31629e3c3406b1a98861583a9417b9962c2f7a6b`, tree `13dc241d0141`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/hero_landmarks_1101.json": {"veilfall": {"enabled": true}}, "data/config/tidewake_look.json": {"sections_off": ["current_flow_visual", "night_creature_floor", "dock_village_candidate", "dock_dressing_candidate", "surfaces_candidate", "veilfall_hero_candidate", "veilfall_facade_candidate", "forward_plus_candidate", "veilfall_rock_detail_candidate", "first_shore_declutter_candidate", "veilfall_formation_relief_candidate", "veilfall_formation_relief_fill_candidate", "veilfall_falls_candidate", "rain_fog_candidate", "rain_grade_candidate", "rain_veil_candidate", "swim_candidate", "dune_grass_candidate", "shore_water_candidate", "veilfall_mountain_candidate", "waterline_declutter_candidate", "golden_sky_candidate", "current_bands_candidate", "current_tint_candidate", "veilfall_cladding_candidate", "veilfall_buttress_candidate", "swim_stroke_candidate", "beach_groups_candidate"], "cause_tidewake": {"dunes": {"enabled": true}}}}`
- Capture: 2 launch(es); base 2836s, candidate 3037s, wall 6078s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.5886, intercept -3.1265, r 0.9505, anchor RMSE 0.374, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#1 | shore landforms | 5.40 | **5.45** | +0.05 | 5.4 5.4 5.3 / 5.4 5.5 5.3 | PARTIAL,PRESENT / PARTIAL,PRESENT |
| F39#2 | Veilfall silhouette | 5.35 | **5.19** | -0.16 | 5.3 5.4 5.3 / 5.2 5.2 5.3 | PARTIAL,PRESENT / PARTIAL,PRESENT |
| F39#3 | named destination read | 5.45 | **5.40** | -0.05 | 5.4 5.6 5.2 / 5.4 5.5 5.2 | PRESENT / PRESENT |
| F39#15 | Veilfall approach shallows | 5.50 | **5.56** | +0.06 | 5.5 5.4 5.4 / 5.5 5.5 5.4 | PRESENT / PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
