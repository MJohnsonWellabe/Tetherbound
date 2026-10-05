# Shipping render source review

**PASS for the two notes' bounded source/receipt claims, with attribution limits retained.** Reviewed the [vista-floor note](D:/tetherbound/redesign-lookdev/ralph/reports/LOOKDEV/f26/shipping-vista-floor-source-candidate.md), [sky note](D:/tetherbound/redesign-lookdev/ralph/reports/LOOKDEV/f26/shipping-sky-source-candidate.md), four shipping receipts, and relevant files in the supplied accepted runtime root `D:/tetherbound/render-perf-6632f2fd`. The receipts all identify `33431f9abab32c28898d52daecbd24f48012c490`; this review did not independently retrieve Git history or mutate it.

## Camera and preset evidence

| Shipping receipt | Preset | Recorded camera far |
| --- | --- | ---: |
| [Meadows Low](D:/tetherbound/.artifacts/pr2/main334/shipping-low-meadows/receipt.json) | Low | 2000 m |
| [Meadows Medium](D:/tetherbound/.artifacts/pr2/main334/shipping-medium-meadows/receipt.json) | Medium | 2000 m |
| [Water Low](D:/tetherbound/.artifacts/pr2/main334/shipping-low-water/receipt.json) | Low | 6500 m |
| [Water Medium](D:/tetherbound/.artifacts/pr2/main334/shipping-medium-water/receipt.json) | Medium | 6500 m |

[art.json](D:/tetherbound/render-perf-6632f2fd/data/config/art.json:1167) defines Near/Normal/Far as 320/520/900 m, with viewport mesh LOD thresholds 4/2/1. [graphics_prefs.gd](D:/tetherbound/render-perf-6632f2fd/scripts/ui/graphics_prefs.gd:244) sets camera far to `max(camera.near + 1, preset_far, vista_far_floor_m)`. [WorldLook](D:/tetherbound/render-perf-6632f2fd/scripts/world/world_look.gd:233) applies camera preferences each process tick, including while the clock is frozen.

[Meadows](D:/tetherbound/render-perf-6632f2fd/scripts/world/playground_world.gd:784) installs the floor from [meadows_horizon.json](D:/tetherbound/render-perf-6632f2fd/data/config/meadows_horizon.json:4), which specifies 2000 m. [Water](D:/tetherbound/render-perf-6632f2fd/scripts/world/water_world.gd:75) sets both camera far and its floor from [water_visual.json](D:/tetherbound/render-perf-6632f2fd/data/config/water_visual.json:41), which specifies 6500 m. The code explains the equal far planes recorded within each chapter.

Equal far planes do **not** make Low and Medium identical. [Preset definitions](D:/tetherbound/render-perf-6632f2fd/data/config/art.json:1113) select Compatibility versus Forward+, Near versus Normal LOD, different shadow filter quality, and different volumetric fog/SSAO/glow settings; SSIL is disabled in both. The receipt commands confirm different requested renderers. [Preference application](D:/tetherbound/render-perf-6632f2fd/scripts/ui/graphics_prefs.gd:197) applies effect settings and viewport LOD/shadow settings, subject to renderer support. The floor affects camera clipping; it does not establish distant object activity, collision, AI, terrain workload, or occlusion behavior.

## Sky candidate evidence

[sky_clouds.gdshader](D:/tetherbound/render-perf-6632f2fd/shaders/sky_clouds.gdshader:275) uses wrapped `TIME` in `sky()`. Its procedural cloud path contains multiple noise evaluations and has no `AT_CUBEMAP_PASS` distinction or half/quarter-resolution render mode. Both sky uses therefore share the same directional shader logic, including its existing hemisphere and opacity conditions; this does not establish actual pass counts or cost. [WorldLook](D:/tetherbound/render-perf-6632f2fd/scripts/world/world_look.gd:996) selects the shader for positive cloud coverage and assigns uniforms at line 1039 onward. Normal clock blending runs on its 0.2 s cadence at lines 166 and 266; this is not proof that every setter changes a uniform or causes extra work on every call.

Godot's primary [sky-shader documentation](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/sky_shader.html) states that `TIME` use requires a radiance-cubemap update each frame and that visible background shading is separate. The [Sky documentation](https://docs.godotengine.org/en/stable/classes/class_sky.html) describes automatic mode choosing realtime for `TIME`/`POSITION`. The relevant scene Sky resources do not explicitly override process mode ([Meadows](D:/tetherbound/render-perf-6632f2fd/scenes/world/meadows_playground.tscn:33), [Water](D:/tetherbound/render-perf-6632f2fd/scenes/world/water_archipelago.tscn:23)). This supports a recurring render-work candidate, not a measured shipping bottleneck. Documentation checked 2026-10-05; no runtime sky-pass inspection occurred.

## Limits

The shipping receipts contain wall-frame measurements and cached process/physics monitors, with no per-frame true CPU or GPU timestamps. Runtime maxFPS/VSync/physics/time settings were not explicitly verified by that packaged route. No CPU-versus-GPU dominance, component milliseconds, optimization gain, or regression onset follows. No comparable prior release baseline was supplied. Any candidate change remains subject to owning PERF review, required vista preservation, matched day/night/weather visuals, and release remeasurement.

This review used bounded source/receipt reads and primary-document lookup, wrote only this evidence report, and ran no engine, benchmark, tests, new tooling, source patch, Git command, or image judgment. Full visual/material and performance acceptance remain **OPEN**.
