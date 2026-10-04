# F35 signature ultimates — tb/vfx (Claude) evidence

Scope: presentation only (`scripts/vfx/ultimates/**`, the move library and
`data/config/vfx.json` `move_library`). `data/moves/ultimates.json` (combat
lane) is not edited. The ultimate's frozen F23 row, actor binding, timing and
receipt ownership are unchanged. No F35 criterion is claimed here.

## Capture harness

`tests/smoke_move_effects_library.gd --batch=ultimates` launches each authored
ultimate through the real `ULTIMATES.launch` contract on the shipped Meadows
world stage (read-only), auto-framing attacker and target (legendaries are
many times a starter's size), at breakthrough counts 0 and 5, with windup /
travel / contact / peak / late shutters on the presentation clock. Attacker is
the ultimate's own species where it has a model, else one of its type
(recorded). `--ultimates=`, `--breakthroughs=`, `--camera=`, `--no-autoframe`
serve affected reruns and close-ups. Software (llvmpipe) Compatibility; frame
times are meaningless.

## Water ultimates (owner direction, 2026-10-04)

The owner judged the Abyssal Guardian's sculpted nautilus-spiral signature
"garbage" and directed that water ultimates read as a wave or a water ball like
the fireball, depending on the move. `move_library.ultimate_overrides` routes
Abyssal Crown, Turning Tide and the shared current/wall finales to a
`great_wave` presentation of the tidal wave, and Broadside Bloom and the shared
charger/diver finales to `water_ball` (a variant of the water projectile).
`ultimate_library.launch` hands the validated frozen row to
`move_effect_library.launch_presentation`; breakthroughs select the growth
tier; the effect joins the ultimate group so cancellation works.

Iterations (all real Meadows world unless noted):
- v1 rejected by me: upright glass column with sawtooth holes (the water
  shader drove alpha from a sine stripe pattern) and a ~5 m grey splash cloud.
- v2 (`water-v2/`, sent to owner): wave shape reads; splashes grey mist; water
  balls stacked and bubble-like.
- v3 rejected by me: splash a white cotton puff with grey steam streaks.
- Close-ups on the clearing stage diagnosed the splash; `splash_crown` (curved
  water sheets with foamed lips) plus solid droplets replaced foam puffs.
- v4 (`water-v4/`, sent to owner): wave/balls travel, water-crown splash with
  droplets, damp patch afterwards; Abyssal Guardian, Cannonback, Ripplet at
  breakthrough 0, exit 0, 0 failures. Cannonback balls bunched; volley spread
  widened afterwards (9babea175, not yet rendered).

Open: breakthrough-5 water captures, the nine non-water uniques' blind
distinguishability review (baseline captured on the old compositions), shared
type x role ultimates, four-player readability, owner sign-off.
