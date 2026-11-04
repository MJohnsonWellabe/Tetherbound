# Quick judge r2c: F39#5, F39#14

- Head `dbfffc5012cb65114660054a90108ec98613b4ca`, tree `14cab78da72c`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/tidewake_look.json": {"sections_off": ["current_flow_visual", "night_creature_floor", "dock_village_candidate", "dock_dressing_candidate", "surfaces_candidate", "stones_candidate", "veilfall_hero_candidate", "veilfall_facade_candidate", "forward_plus_candidate", "veilfall_rock_detail_candidate", "first_shore_declutter_candidate", "veilfall_formation_relief_candidate", "veilfall_formation_relief_fill_candidate", "shore_surf_candidate", "shore_surf_vary_candidate", "veilfall_falls_candidate", "rain_fog_candidate", "rain_grade_candidate", "rain_veil_candidate", "swim_candidate", "dune_grass_candidate", "shore_water_candidate", "veilfall_mountain_candidate", "waterline_declutter_candidate", "golden_sky_candidate", "current_bands_candidate", "lesson_clusters_candidate", "current_tint_candidate", "veilfall_cladding_candidate", "veilfall_buttress_candidate", "beach_groups_candidate"]}}`
- Capture: 1 launch(es); base 855s, candidate 869s, wall 1723s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.7051, intercept -3.873, r 0.9778, anchor RMSE 0.235, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#5 | surface swimming trainer pose | 5.85 | **5.85** | +0.00 | 6.1 5.5 5.5 / 6.1 5.5 5.5 | PRESENT / PRESENT |
| F39#14 | swimmer water contact | 6.98 | **6.98** | +0.00 | 6.7 6.2 6.2 / 6.6 6.3 6.2 | PARTIAL / PARTIAL |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
