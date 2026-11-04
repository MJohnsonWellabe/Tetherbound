# Quick judge r1: F39#1, F39#2, F39#3, F39#15, F39#16, F39#17, F39#5, F39#14, F39#8, F39#22

- Head `765abb854089d5b7c6cebd7bbf959cb5ec27f20b`, tree `1a1210754302`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/tidewake_look.json": {"sections_off": ["current_flow_visual", "night_creature_floor", "dock_village_candidate", "dock_dressing_candidate", "surfaces_candidate", "veilfall_hero_candidate", "veilfall_facade_candidate", "forward_plus_candidate", "veilfall_rock_detail_candidate", "veilfall_formation_relief_candidate", "veilfall_formation_relief_fill_candidate", "rain_grade_candidate", "dune_grass_candidate", "shore_water_candidate", "waterline_declutter_candidate", "current_bands_candidate", "current_tint_candidate", "veilfall_cladding_candidate", "veilfall_buttress_candidate", "beach_groups_candidate"], "cause_tidewake": {"sea": {"enabled": true}, "light": {"enabled": true}, "currents": {"enabled": true}, "horizon": {"enabled": true}, "dunes": {"enabled": true}}}, "data/config/water_mount_presentation.json": {"enabled": true, "camera_hide": {"enabled": true}}}`
- Capture: 5 launch(es); base 6118s, candidate 5878s, wall 11996s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 0.9645, intercept 0.4277, r 0.7322, anchor RMSE 0.548, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F39#1 | shore landforms | 6.15 | **5.99** | -0.16 | 5.7 6 6.1 / 5.6 5.8 5.9 | PARTIAL / PARTIAL |
| F39#2 | Veilfall silhouette | 6.28 | **5.19** | -1.09 | 6 6.2 6 / 5 4.8 5 | PARTIAL / PRESENT |
| F39#3 | named destination read | 6.47 | **5.83** | -0.64 | 6.3 6.2 6.3 / 5.6 5.6 5.6 | PARTIAL / PARTIAL,PRESENT |
| F39#15 | Veilfall approach shallows | 6.21 | **5.48** | -0.73 | 6 6 6 / 5.2 5.3 5.2 | PRESENT / PRESENT |
| F39#16 | live current streaks | 6.02 | **5.89** | -0.13 | 5.8 6 5.6 / 5.7 5.4 5.9 | PARTIAL,PRESENT / PARTIAL |
| F39#17 | current restoration environment | 5.54 | **6.09** | +0.55 | 5.3 5.3 5.3 / 6 5.6 6 | PRESENT / PARTIAL,PRESENT |
| F39#5 | surface swimming trainer pose | 5.93 | **5.67** | -0.26 | 5.6 5.5 6 / 5.4 5.4 5.5 | PARTIAL,PRESENT / PARTIAL,PRESENT |
| F39#14 | swimmer water contact | 5.96 | **5.57** | -0.39 | 5.6 5.6 6 / 5.3 5.3 5.4 | PARTIAL / PRESENT |
| F39#8 | Aquaryn mounted-water pose | 4.93 | **6.09** | +1.16 | 4.8 4.6 4.6 / 5.9 5.8 5.9 | PRESENT / PARTIAL |
| F39#22 | Aquaryn dismount camera obstruction | 5.25 | **6.28** | +1.03 | 5 4.8 5.2 / 6.2 6 6 | PARTIAL / FIXED |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
