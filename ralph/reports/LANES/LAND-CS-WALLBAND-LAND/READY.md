STATUS: land

# tb/land-cs-wallband-land: Realm Gate rim earth band as pale stone (F40#1)

**Verdict:** GPU High, `ralph/reports/GPU-PASS/1108/G-below6-wall-band-main.md` on tb/judge 589da6be (confirming batch, r 0.886, RMSE 0.64): F40#1 6.19 -> 6.51 (+0.32, 3/3). No row loses. The "smooth brown extruded disc-rim edge" now reads as "a pale grey-beige stone ledge band, which matches Cloudreach's pale stratified stone". Still "smooth, without strata or breakup".

**Flag:** `data/config/cloudreach_visual.json landmass.wall_top_band_1113`, ON with `_why_on`. Arm by LANE-BELOW6 (`BELOW6-WALL-BAND`), whose flag-off code is already on main; landed by LANE-LAND-CS.

**Landed alone, on purpose:** GATE-TERRACE also passed (+0.20, a thin 2/3), but LANE-JUDGE asks for the band and the terraces to be re-judged together before both land. `gate_crag_terrace_1113` stays OFF here, and the pin test checks that.

**Files (3):** `data/config/cloudreach_visual.json` (the flag ON), `tests/test_cloudreach_wall_top_band_flag.gd` (ON pin with verdict file and score; the terraces stay OFF), this READY.md.

**Scope:** material only: the first wall band of the listed masses goes into its own surface in a pale strata tint of the same cliff texture. No vertex, collision or route change, so no route smoke is needed.

**Tests run (14 Nov, on this branch):** eight files in one run: 45 tests, 242 assertions, 0 failed (`test_cloudreach_wall_top_band_flag`, `test_gate_crag_terrace_flag`, `test_cloudreach_environment`, `test_vis_cloudreach_landed`, `test_cloudreach_cause`, `test_near6_cr_judged_on`, `test_below6_knifeedge_landed`, `test_below6_masonry_landed`).

**Independent of** `tb/land-cs-turfgrain-land`: different keys in the same JSON file (`landmass` vs `surface`), so the two merge cleanly in either order.
