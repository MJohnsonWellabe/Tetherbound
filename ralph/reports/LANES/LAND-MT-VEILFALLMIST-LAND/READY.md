# READY: tb/land-mt-veilfallmist-land

STATUS: land. Correctness fix with a test; a small visible change, no score claimed.

**What.** The Veilfall base mist never rendered. In `shaders/water_veilfall_spray.gdshader` the billow gate `smoothstep(0.2, 0.75, billow + radial * 0.35)` took every spray puff to nothing. CPU probes on the F39#31 views (`F39-look.json` `veilfall-vista`, `veilfall-near`):
- spray colour magenta at opacity 1.0: nothing on screen;
- alpha forced to 1: a solid box at the main fall's base, so the quads draw;
- alpha = opacity * radial: a soft glow at the base;
- so the gate was the cause.
This matches the judges' "no mist at the base" (G-floor2-dawn-haze-storm-grade, 3/3).

**Change.**
- New uniforms `billow_floor` and `size_scale` (defaults 0 and 1 keep the old maths).
- `water_veilfall.json` `falls.spray_shader.billow_floor` 0.55, so the noise breaks the mist up without erasing it.
- Puff size and placement are unchanged.

**Visible effect.** Small: a faint whitening at the main fall's base in `veilfall-vista`. The puffs are not yet where the visible falls end (the cascade's spray sits at its 200 m foot); placing them is follow-up art, flag-off in `LAND-MT-BASEMIST`.

**Tests.** `tests/run_tests.gd --only=test_veilfall_spray_floor.gd`: 2 tests, 5 assertions, 0 failed (headless, on this tree's config).

**No-loss to watch.** F39#2 and F39#31 frames (the mist only adds a faint layer at the fall foot).
