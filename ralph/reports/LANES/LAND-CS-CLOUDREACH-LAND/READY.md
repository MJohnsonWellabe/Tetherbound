STATUS: land

# tb/land-cs-cloudreach-land: TURFGRAIN (F40#1, F40#4, F40#7); WALL-BAND withdrawn

**AMENDED 14 Nov: WALL-BAND is OFF on this branch.** LANE-JUDGE amended G-below6-wall-band-main to DO NOT SHIP: the F40#8 no-loss check loses on the Three Bells bridge (6.29 -> 5.86, 0/3; the band repaints a whole cliff face). The last commit turns `wall_top_band_1113` OFF with `_why_off` and makes its test an OFF pin. TURFGRAIN is unchanged and still ships.

One branch for both, as the coordinator asked, from main 1405def4d. It merges `tb/land-cs-turfgrain-land` and `tb/land-cs-wallband-land` (each has its own READY.md with the full detail); land this one instead of those two.

## Verdicts (GPU High, LANE-JUDGE tb/judge 589da6bec; one confirming batch, r 0.886, RMSE 0.64)
- `G-land-cs-turfgrain-rows.md`: `surface.turf_detail_1113` ON. F40#1 6.19 -> 6.39 (+0.20), F40#4 6.55 -> 6.74 (+0.19), F40#7 6.66 -> 6.90 (+0.24), each 3/3; no row loses.
- `G-below6-wall-band-main.md`: `landmass.wall_top_band_1113` ON (LANE-BELOW6 arm). F40#1 6.19 -> 6.51 (+0.32, 3/3); no row loses.
- `gate_crag_terrace_1113` stays OFF (thin 2/3; held for round 2 and a combined re-judge). The wall-band pin checks it.

## Do they compose?
They were judged in the same batch on separate arms. They touch different things: the turf shader's fine grain (every lawn) and the cliff material of the first wall band under island rims. No shared uniform, mesh or key.

## Files
`data/config/cloudreach_visual.json` (both flags ON, each with `_why_on`), `shaders/cloudreach_turf.gdshaderinc`, `scripts/world/cloudreach_environment_materials.gd`, `tests/test_cloudreach_turf_detail_flag.gd`, `tests/test_cloudreach_wall_top_band_flag.gd`, the two single-landing READY.md files and this one.

## Tests run (14 Nov, on this branch)
Twelve Cloudreach look test files in one run: 58 tests, 283 assertions, 0 failed (both pins, `test_gate_crag_terrace_flag`, `test_cloudreach_environment`, `test_vis_cloudreach_landed`, `test_cloudreach_cause`, `test_near6_cr_judged_on`, `test_cloud_sea_landed`, `test_cloudreach_rain_storm_sky`, `test_cloudreach_ground_wet_path`, `test_below6_knifeedge_landed`, `test_below6_masonry_landed`). Both changes are material or shader only: no collision or route change, so no route smoke.
