# CAUSE-TIDEWAKE lane (tb/cause-tidewake): Tidewake F39 water, light and shore

## STATUS

- Criteria closed: zero (no GPU verdict yet). Every change is flag-off.
- CPU check PASSED (Low, llvmpipe, 22:45 UTC). `_sheet_cpu_g1.jpg`: left OFF, right sea+light+dunes ON. Rows: First Shore approach, Brine Steps close, Lastlight approach, Sluice bridge close. Nothing clips or goes black, and there are no shader or script errors.
  - Sea: the hard navy band is gone. Water grades from turquoise to a teal shelf to blue-teal, then hazes to the horizon, with a broken surf line.
  - Light: a paler haze horizon; the far islands and the Veilfall recede.
  - Dunes: the steep faces carry wind runnels.
- CPU rounds: r1 haze 0.6 washed the sea milky and caps blotched; r2 cross-bedding drew contour lines; r3 runnels swirled on flat ground; r4 OK, but restoring dune grass and stones made sand barer, so those two stay off.
- Manifest: `MANIFEST.json`.
  - Group 1: light and dunes.
  - Group 2: sea (retuned after an elevated-view check) and the new currents part.
  - Group 3: the horizon part.

## Group 3 (1 Nov, 23:35 UTC)

- **New part, `horizon`:** `cause_tidewake.horizon.enabled`, for "empty horizons".
  - It places 8 rocky islets (the installed current-wake rock cluster, fitted to 28–52 m) and 6 distant sails (the moored sloop at 7 m) in deep open water 400–1900 m off the islands.
  - Each seat was chosen from a heightfield sample with ground below −6 m. No colliders; presentation only.
  - It feeds `water_landmark_models.gd` through a new `cause_horizon_props` list (one line).
  - CPU: a sail shows on the First Shore horizon, and low islets show on the far horizon of the current-state views, receding in the light part's haze. No errors.

## Group 2 (1 Nov, 23:20 UTC)

- **New part, `currents`:** `cause_tidewake.currents.enabled`, for P2-066, P2-067 and P2-026.
  - CPU current-state frames with `current_flow` on show that the restored state still draws white dashes, chevron outlines and dashed channel edges. current_flow's restored override inherits them from water_veilfall.json.
  - The part zeroes them in the restored state and keeps soft seams, gentle wavelets and a faint clear channel. It brings current_flow into play itself, so it works whether or not `watersky_sections_on` lands.
  - CPU: the dashes are gone from S1 and S2 restored.
- **Sea retune:** the elevated current-state view showed the r4 sea losing all deep value (light cyan everywhere) and slicks reading as radial rays.
  - Deep is now #0f3f5a at full strength by 18 m (shipping navy #0a2c46 by 12 m).
  - Slicks are 0.16 (were 0.35) and caps 0.22 (were 0.45).
  - CPU: from above, the sea grades from turquoise shallows to a blue-teal deep with soft wind streaks; from the beach the r4 read is kept.

## Group 1 (1 Nov): three parts under `data/config/tidewake_look.json:cause_tidewake`

Each part is `cause_tidewake.<part>.enabled` (default false). When a part is on, it:
- brings its listed `sections_off` candidates into play;
- merges its `merge` map over the profile's top-level sections (`tidewake_look_profile.gd` `cause_parts`/`resolve`).

A capture can force a part without editing the config: `--tidewake-cause=sea,light,dunes`.

| Part | Judge theme it answers | What changes |
|---|---|---|
| `sea` | flat single-value navy water, hard light-cyan shallows band, empty horizons | Turquoise shallows, then a teal shelf (mid stop at 4 m, contour wandering ±1.4 m), then a lighter blue-teal deep (#15506c instead of #0a2c46) with broad value patches. The deep keeps some sky fresnel (0.05 → 0.35). New `water.gdshader` uniforms (all default 0, so Meadows and shipping water are unchanged): distance haze toward the sky horizon, soft wind slicks (smoother, lighter streaks that glint), rare small whitecaps. Plus a broken surf line at the sand. |
| `light` | flat light, no atmosphere, empty horizons | Day only: a clearer sky top, a pale haze horizon, whiter lit clouds, and aerial fog (0.0006) so far islands and the Veilfall recede. It is applied last (`cause_light_look`), so it composes over `watersky_light_candidate`. |
| `dunes` | sheet-like vertical dune walls, bare sand discs | Steep sand gets wind-scoured runnels; level sand gets sparse low scrub and wrack stains (new `coastal_rock_material.gd` uniforms, default 0; the strata uniform stays 0). It also brings in the swim-lesson dune clusters (`lesson_clusters_candidate`). |

Composition: the only shared files touched are `shaders/water.gdshader` (new uniforms, default 0), `coastal_rock_material.gd` (new uniforms, default 0), `tidewake_look_profile.gd` (`resolve` split out, cause parts) and `tidewake_world_look.gd` (one overlay line). `watersky_sections_on` and every other lane's flag are unaffected.

Test: `tests/test_tidewake_cause.gd`. It checks that with every part off the profile is unchanged, and that each part applies exactly its keys.
