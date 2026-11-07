# Quick judge F38-32-48f121f0ded9-11041358: F38#32

- Head `f8680b91c78e69d4f2d1f41368980741e231c83e`, tree `c5ddab2a5633`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/combat.json": {"arena": {"wild_keep_clear": [{"at": [30.0, -40.0], "radius_m": 10.0, "why": "Practice Meadow camp build site (objectives tournament_build_home beacon)"}, {"id": "trail_camp_1104", "enabled": true, "scope": "world_presentation: wild spawn and wander placement only (host-authoritative, same rule as the other keep-clear zones)", "at": [343.2, 936.4], "radius_m": 14.0, "why": "NEAR6-MS (4 Nov 2026), F38#32 P2-035 camp and workshop prop legibility (board 5.85; judges: crates, barrels, chest and bed sit among a wolf, a rabbit and other creatures). The trail camp (band1 props.json trail_camp camp_floor, radius 5.2 m) is a rest point; wild bodies wander through it and stand among the camp furniture. When enabled, wild bodies neither spawn nor settle a wander target within 14 m of the camp floor centre (encounter_director.gd::_wild_keep_clear_zones skips a zone whose enabled is false). OFF until judged."}]}}}`
- Capture: 1 launch(es); base 594s, candidate 572s, wall 1166s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.4888, intercept -3.0238, r 0.982, anchor RMSE 0.195, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#32 | camp and workshop prop legibility | 5.61 | **5.81** | +0.20 | 5.4 5.8 6.2 / 5.6 5.9 6.3 | PARTIAL,PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
