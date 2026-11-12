STATUS: land

# READY: Cloudreach rain_time_grade ON (LANE-PLACES, 12 Nov 2026)

Branch `tb/places-raintime-land`, cut from main 328c598a (#914). The code landed flag-off with #914; this branch only turns the flag on.

## Verdict
GPU High, `G-places-raintime.md` (tb/item-scout-1108 6dfc3711), three code-blind judges: **SHIP**.
- All 12 rain sets (realm gate, summit eyrie, stormward overlook) prefer the arm 3/3. Mean 5.04 → 5.74 (+0.70); no set loses.
- Night +0.80 to +1.50, golden +0.80 to +0.89, dawn +0.61 to +0.75, day +0.14 to +0.28.
- Rain still reads with the thinner streaks. Worth about +0.3 on F40#0 if it holds across the matrix; re-sample the matrix before the board moves. Closes no row.

## What lands
- `data/config/cloudreach_visual.json`: `rain_time_grade.enabled` true with `_why_on`.
- `tests/test_places_storm_phase_rain_grade.gd`: the pin now asserts it ships ON with its verdict (was "OFF until judged").
- No new assets. Cloudreach scene only; Tidewake and Meadows rain are untouched. Device-local presentation.

## Tests
`--only=places_storm,cloudreach,weather,world_look`: 413 tests, 0 failed, with the flag ON.

## Still holding F40#0 back (judges, both sides)
New art: slab "box" walls at the overlook, sky islands rendering as black cut-outs, a billboard cloud slab in reverse views. Scene: gate cobbles as large as the trainer's torso that bury the trainer to the shins; flat single-green ground and flat grey fog.
