# Water deprecated Fresnel binding candidate

## Mechanism

The Water realm used the shared `water.gdshader` but left its deprecated near-white Fresnel defaults active. The candidate explicitly binds the mature Meadows water contract already recorded in `data/config/water.json`: Fresnel `#6e97a0`, power `5.0`, strength `0.34`, roughness `0.10`, and wave UV scale `0.12`. `water_surface.gd` maps the authored `roughness` key to the shader's actual `roughness_value` uniform.

This is isolated to surface presentation. Existing Water depth falloff `3.0`, alpha `0.9/0.45`, foam depth `0.4`, wave strength `0.25`, baked height data, mesh, collision, hazards, currents, and swimming are unchanged.

## Frozen files

- `data/config/water_visual.json`
- `scripts/world/water_surface.gd`
- `tests/test_water_surface_material.gd`

## Root validation

The canonical unit runner's `--only=water_surface_material` tests build the real WaterSurface from production configs, inspect its final bound ShaderMaterial values, and guard unchanged depth/alpha/foam/wave-strength inputs. They passed in the final combined run `deepwood-circuit-fallback-final` (05:43:45–05:43:50 UTC; 23 tests, 678 assertions overall, zero errors). This is material binding evidence, not a full Water campaign pass.

The Root Walk blind comparison narrowly preferred the candidate. The earlier Gull Rest pair did not show visible water, so it produced no useful material preference and is not evidence for this candidate. The isolated Water opening fixture completed arrival, Pell's production dialogue and 64.490m of physical swimming cleanly from 05:27:43 to 05:28:57. That fixture starts directly in Water and is not an earned Stormwood-to-Water transition.

The production-camera Gull Rest diagnostic `broad-water-open-view01` completed 5/5 native OpenGL frames without errors from 05:32:27 to 05:33:46. Its added open-water day/night views use the real player and spring camera at the preceding authored waypoint, rotated through ordinary look input. A matched OFF-control subclass restores only the five former Fresnel parameters after mounting the same production world and records their actual shader readback before the identical five-frame sequence. That control completed 5/5 frames cleanly from 05:41:18 to 05:42:35 in `water-fresnel-open-control-first`.

The fresh open-water judge preferred candidate F03/F04 for richer water colour and better integration. It still found horizon striping, angular water-value boundaries and repetitive grass; key-art world, Palworld game-type presentation in this particular view, and commercial quality were all No. See `JUDGE-WATER-OPEN01.md`. This adds a second bounded visible preference to Root Walk's result, not realm acceptance.

## Disposition

Retain the explicit Fresnel/roughness/wave-scale bindings. Neither grass nor horizon defects are solved by this change. The prior Gull Rest views without visible water remain preserved as unsuitable evidence rather than being counted as a pass. Native receipts live under `.artifacts/broad-visual-0910/runs/`, images under `shots/catalogue/water/`, and the two controls document their process-local parameter overrides.
