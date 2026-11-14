STATUS: land

# tb/land-cs-turfgrain-land: fine grass grain on the Cloudreach turf (F40#1, F40#4, F40#7)

**Verdict:** GPU High, `ralph/reports/GPU-PASS/1108/G-land-cs-turfgrain-rows.md` on tb/judge 589da6be (confirming batch, r 0.886, RMSE 0.64, about ±0.3): every judged row gains, each 3/3: F40#1 6.19 -> 6.39 (+0.20), F40#4 6.55 -> 6.74 (+0.19), F40#7 6.66 -> 6.90 (+0.24). No row loses. The arm won on both A/B sides, so no position bias.

**Flag:** `data/config/cloudreach_visual.json surface.turf_detail_1113`, ON with `_why_on` (strength 1.25, fine scale 3.1, fine strength 0.8).

**Files (5):**
- `shaders/cloudreach_turf.gdshaderinc`: the `turf_detail_1113` uniform (default strength 0 = the shipped turf) and the fine-detail term.
- `scripts/world/cloudreach_environment_materials.gd`: `turf_detail()` / `turf_detail_from()`, set on every turf, trail-shoulder and blade material.
- `data/config/cloudreach_visual.json`: the flag ON.
- `tests/test_cloudreach_turf_detail_flag.gd`: ON pin (verdict file and score), OFF passes nothing, shader default 0.
- this READY.md.

**Scope:** shader uniforms only. No geometry, collision, route or scatter change. Compiles on Compatibility (CPU, 13 Nov, flag on, 0 shader errors) and on the GPU lane's Forward+ High.

**Tests run (14 Nov, on this branch):** eight Cloudreach look test files in one run: 53 tests, 264 assertions, 0 failed (`test_cloudreach_turf_detail_flag`, `test_cloudreach_environment`, `test_vis_cloudreach_landed`, `test_cloudreach_cause`, `test_near6_cr_judged_on`, `test_cloud_sea_landed`, `test_cloudreach_rain_storm_sky`, `test_cloudreach_ground_wet_path`).

**Not judged yet:** the F40#0/#19/#21 matrix stands (the GPU lane runs them later) and F40#3 as no-loss. Judges' next ask: break the grain's near-camera tiling with macro variation.
