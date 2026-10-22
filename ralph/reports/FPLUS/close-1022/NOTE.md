# FPLUS close 1022

## TO COORDINATOR

- 2026-10-22 READY tb/fplus-grade @ 711e9a01d (from origin/main, no PR). Forward+ grade multipliers, Medium/High only.
  - **Where they apply:** `scripts/world/world_look.gd::_apply_environment()`. Every path goes through it: apply_time, the _apply_blended clock, weather and storm surge, and reapply. It calls `_apply_renderer_grade(env, GRAPHICS_PREFS.renderer_grade())` right after writing fog_density, tonemap_exposure and adjustment_* fresh from cfg, and before `GRAPHICS_PREFS.apply_environment`.
  - **What it does:** fog ×fog_density_scale and exposure ×exposure_scale. When saturation_scale ≠ 1 it also sets adjustment_enabled = true and multiplies adjustment_saturation; brightness and contrast keep their written values.
  - **No compounding:** each write starts from the cfg value, so the factors apply once per write. Meadows and Tidewake subclasses go through super. Cloudreach's own per-frame fog scale keys off the value WorldLook wrote, so it layers on top without compounding.
  - **Config:** `art.json` `graphics_presets.{Medium,High}.forward_plus_grade` = {fog_density_scale 0.5, exposure_scale 1.3333333, saturation_scale 1.2}.
  - **Compatibility:** `renderer_grade()` returns {} unless the running renderer is forward_plus, so Compatibility gets no multiply and no extra writes.
  - **Validation:** factors must be finite and in (0, 4]; anything else is 1.0.
  - **Checks:**
    - tests/test_forward_plus_grade.gd: 7 tests, 53 assertions, 0 failed.
    - Related look/graphics suites: 127 tests, 1448 assertions, 0 failed.
    - smoke_graphics_settings --graphics-proof: 0 failures.
  - **Still needed:** a GPU Forward+ measurement.
- 2026-10-22 READY tb/fplus-grade @ 245b23533 (review fixes on top of 493ebb9ff).
  - **Defect 1 fixed** (`world_look.gd::_apply_renderer_grade`): if the write left adjustment off and saturation_scale ≠ 1, enabling it now resets brightness, contrast and saturation to 1.0 and clears the LUT, then applies ×1.2. If adjustment was already on, the written values are kept. Fog and exposure are unchanged, so the GPU lane's measured values still hold.
  - **Defect 2 covered:**
    - `test_weather_layers_before_the_grade`: weather fog +0.0004 and saturation ×0.8 come first, then the grade applies once; re-rolls don't compound.
    - `test_cloudreach_realm_fog_scale_layers_on_the_grade`: the real `cloudreach_look._process` gives base ×0.5 ×0.55, with no compounding.
    - New `test_an_enabled_adjustment_keeps_its_written_grade`.
  - **Checks:** test_forward_plus_grade passes 10/10. With the related suites: 137 tests, 1511 assertions, 0 failed.
  - **Pre-existing bug, not changed** (it affects Compatibility too): on a rewrite with the same value, `cloudreach_look._process` (around line 2190) compares the new scaled value with its cached `_fog_scaled_density` instead of `env.fog_density`. It skips the write, so the realm fog scale is lost until the base changes, for example on a frozen-clock reapply. The one-line fix is to compare with `_fog_env.fog_density`. It needs its own lane because it changes Low's Cloudreach fog.
