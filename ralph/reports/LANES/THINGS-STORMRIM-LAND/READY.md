STATUS: land

# THINGS-STORMRIM landing (Stormwood character rim off)

Branch `tb/things-stormrim-land`, cut from main f421556c.

Verdict: `ralph/reports/GPU-PASS/1108/G-things-stormrim.md` on tb/item-scout-1108 b3b9fbd4 (GPU High, three judges, 3/3 prefer the arm on every set, nothing loses).

| Set | Before | After | Gain |
|---|---|---|---|
| F41#18 row | 5.60 | 6.22 | +0.62 (clears the 6 floor) |
| F41#18 dialogue | 6.18 | 6.63 | +0.45 |
| F41#15 row | 6.18 | 6.59 | +0.41 |
| Sera, Ivo, Tamsin | 6.42 | 6.87 | +0.45 |

Change (config only): `player_character_rim_scale` 1.0 -> 0.0 in `stormwood_look.json` `rig.environment` and in `stormwood_surge.json` `presentation.storm_base.overrides.environment`, each with `_why_on_rim_1112`. Both files are LANE-PLACES' look files; the key only drives character materials and nothing in the world changes.

Tests: new `tests/test_stormwood_character_rim_1112.gd` (2). No older test pins the key (grep of `tests/`). Ran with test_stormwood_look, test_stormwood_surge, test_stormwood_surge_presentation, test_night_shadow_contract, test_cause_stormwood_candidates, test_stormwood_rank_marks, test_realm_look_overlay, test_stormwood_trainers_data: 0 failed.

Next lever per the judges (3/3): the officers render pale lilac-grey in the world while their portraits are near-black; darken the uniforms to match and add a readable rank trim (copper, not oxblood).
