STATUS: land
BRANCH: tb/floor2-land-2 (cut from origin/main 06b733767, which has #901). Carries only the files below.

# FLOOR2 landing 2: storm creatures glow on lines and eyes (F41#13); Tidewake dawn haze and storm grade (F39#30, F39#31)

## Verdicts (GPU High, LANE-SCOUT, three code-blind judges)
- **G-floor2-storm-glow-lines** (tb/item-scout-1108 3ccb770d2): F41#13 +0.64 on idle and on hurt, 3/3 each, sparkit control identical, row 6.66.
- **G-floor2-dawn-haze-storm-grade** (tb/item-scout-1108 5d0858f3b): F39#30 6.12 → 6.70 (+0.58, every set 3/3), "rain under a lit noon sky" FIXED 3/3, controls no loss; F39#31 Veilfall 5.56 → 6.02 (3/3).

## What ships (both overlays baked into their configs, each with a `_why` citing its verdict)
| File | Change |
|---|---|
| `data/config/creature_surface_finishes.json` | `charged_1105.species`: stormraven accent 1.6 → 0.4, value 1.0 → 0.82, mask back to the species' own (0.52 / 0.3), rim 0.4 → 0.25; fulgocobra accent 1.4 → 0.46, mask 0.32 → 0.44, rim 0.45 → 0.3. `_why_lines_1111`. |
| `data/config/creature_coat_flags.json` | `creatures_ralph_fulgocobra_goldvein` and `lanekit_face_read_fulgocobra`: `emission_energy` 2.0 → 1.3. `_why_emission_1111` at flag level (the coat spec only allows known keys). |
| `data/config/tidewake_look.json` | dawn `fog_density` 0.0004 → 0.004; `rain_grade_candidate`: sun 0.32 → 0.18, cloud colours, coverage 0.88, sharpness 0.5, ambient 0.75 → 0.62 with colour, saturation ×0.72; `rain_veil_candidate`: streaks 0.12 → 0.07 m, colour `#c3ced84d`. Top-level `_why_dawn_fog_1111`, `_why_storm_grade_1111`, `_why_rain_streaks_1111`. |
| `tests/test_stormwood_charged_finish.gd` | adds `test_charged_finish_glows_on_lines_not_the_whole_body` and `test_fulgocobra_vein_glow_ships_at_its_judged_strength`; the existing tests are unchanged and still pass. |
| `tests/test_tidewake_look_profile.gd` | adds `test_dawn_haze_and_storm_grade_ship_with_their_score`. |
| `ralph/reports/LANES/FLOOR2-STORMGLOW/`, `FLOOR2-DAWNRAIN/` | ARM.md, CAPTURE.json, overlay, one CPU sheet each. The overlays are now no-ops. |
| `ralph/reports/LANES/FLOOR2-LAND-2/READY.md` | this file. |

Config only. No game code, tool, asset, save or network change.

## Tests (CPU, headless, on this branch)
`--only=stormwood_charged_finish,creature_coat,surface_finish,tidewake_look_profile`: **21 tests, 1067 assertions, 0 failed.**

## Not included (stay on tb/floor2, flag OFF)
- Bow wake shader and code (parked).
- `stormwood_harvest_hero2.json floor2_presence` and its runtime code (not queued).

## Known leftovers from the verdicts
- **F39#30 dawn band is NOT fixed:** two of three judges still see it at 10× fog. The sun disc on the sand is the remaining dawn ask.
- F41#13: on GPU the raven's lines and the cobra's veins still bloom at their glow-map strengths (2.6 and 1.3); not retuned here.
- The CPU sheet for storm glow was rendered with accents 0.36 / 0.42; 0.4 / 0.46 ship (kept just above the species' base so the existing "glows brighter" test holds).
