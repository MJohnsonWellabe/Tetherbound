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
