# Stormwood permanent-storm shadow contract — 2026-09-09

## Result

Stormwood's scene-authored canopy shadow opacity now survives WorldLook updates in
Calm, Building and Fading (`0.68`). Break alone uses fully hard shadows (`1.0`), as
the biome brief specifies. The change is realm-local: global lighting, time-of-day
presets, energy, ambient colour/energy, fog, phase timing and phase gameplay are
unchanged.

This addresses a concrete contract violation rather than another Crown Arch material
round. `scenes/world/stormwood.tscn` authors `Sun.shadow_opacity = 0.68`, while
`WorldLook._apply_sun()` defaults an omitted value to `1.0`. Stormwood's phase weather
delta previously omitted the field, so every WorldLook reapplication replaced the
authored permanent-storm value. `stormwood_surge.json` now owns the four-phase map and
`stormwood_surge.gd::light_delta_for_phase()` supplies that value through WorldLook's
existing weather layer.

This is not claimed as the explanation for Meadows' separate night collapse. The
proven omission and correction are specific to Stormwood and affect both day and night
under its permanent canopy.

Independent Wave 7 review accepts the **narrow daylight readability gain** and finds no
major regression. It keeps both overall scene verdicts at **A No / B No**: the sparse
ordinary-space identity, repeated props and missing creature presence remain. This
contract correction therefore does not establish night, location or global visual
acceptance, and there is no second lighting round.

## Scope

- `data/config/stormwood_surge.json`: presentation-only four-phase shadow map.
- `scripts/world/stormwood_surge.gd`: one pure phase-to-light delta used by the existing
  application path.
- `tests/test_stormwood_surge_presentation.gd`: mapping and real WorldLook/Sun coverage.
- `tools/_capture_stormwood_shadow_contract.gd`: tiny catalogue subclass adding
  per-frame phase/live-Sun telemetry; it does not change route, camera, clock, HUD or
  production state.

No Crown files, shared WorldLook/art config, actor, route, terrain/scatter, collision,
progression, save, network or encounter files changed.

Final source SHA-256 values:

- `data/config/stormwood_surge.json`:
  `b7ab8b08000b1afdc206f4212ca46cd95a24795907b7c709690cef36e2c05d51`
- `scripts/world/stormwood_surge.gd`:
  `a8eb74e804bea46150e1280009ad4abef8e147c96f7fb97612d30d3950ed6763`
- `tests/test_stormwood_surge_presentation.gd`:
  `7d0a9028635c8e7c5f80b524e3584d8dd317986bbf715a2f4faed73e0caf21da`
- `tools/_capture_stormwood_shadow_contract.gd`:
  `3554ee79dd7cf67009f6ebb342fff7709879bd6f524deab1fd9499f1265d0e7a`

## Focused verification

Artifact: `.artifacts/stormwood-shadow-test-0909`

- PID/process completed from `2026-09-09T14:17:38.5930102Z` to
  `2026-09-09T14:17:42.1018594Z`.
- Exit `0`; **2 tests / 24 assertions / 0 failed**.
- Pure checks cover all four phase values and the unchanged sun-energy,
  ambient-colour, ambient-energy and fog deltas.
- The second test calls production `_apply_phase_light()` through an actual WorldLook
  node and DirectionalLight3D. It observes `0.68`/`0.85` in Calm and `1.0`/`0.65` in
  Break for shadow opacity/energy multiplier.
- Raw `ERROR:`, `SCRIPT ERROR:`, parse-error scan: clean.
- Focused raw log has zero warning headers.

## Production matched capture

Output:
`shots/catalogue/stormwood/round-shadow-contract-20260909T1418Z`

- Standard Settings-catalogue `Crown Overlook` subset; production scene, player,
  CameraRig/SpringArm3D, HUD, route-derived heading and debug travel contract.
- Day/night pair complete **2/2**, exit `0`, no capture failures.
- Both records have identical player position
  `[160, 27.2946186065674, 1980]`, identical route heading/basis, and production
  camera positions matching within `0.000002m` of settle-frame float drift.
- Per-frame live telemetry: Day = `phase calm`, `Sun.shadow_opacity 0.68`; Night =
  `phase calm`, `Sun.shadow_opacity 0.68`.
- Capture subclass SHA-256:
  `3554ee79dd7cf67009f6ebb342fff7709879bd6f524deab1fd9499f1265d0e7a`, also embedded
  in the manifest.
- PNG SHA-256: day
  `d85ded9be4d8095de4a2db877548947e21b70003366a2430f95fcc8afc48675c`;
  night `3f06a1ca5963215b8d3ddd2be93a9a43e53da44e5749d812d4ac05d2a7236b3d`.
- Process PID `5048`, `2026-09-09T14:18:37.1731240Z` to
  `2026-09-09T14:19:28.7932193Z`, elapsed `51.620s`, exit `0`.
- Guard stayed clear: peak system commit `70.7%`, peak process count `253`, 62 retained
  samples; no 600-second, 90%-commit or 400-process limit fired.
- Complete raw-log error scan is clean. Existing Terrain3D missing-mipmap and deprecated
  interpolation warnings remain visible in the retained raw log and were not hidden:
  13 warning headers total (one interpolation deprecation plus albedo/normal mipmap
  warnings for the six existing Stormwood terrain texture families).

This is matched image evidence for independent review, not a self-acceptance verdict.
