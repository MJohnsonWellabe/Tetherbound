# CAUSE-TIDEWAKE lane (tb/cause-tidewake): Tidewake F39 water, light and shore

## STATUS

- Criteria closed: zero (no GPU verdict yet). Every change is flag-off.
- CPU check: pending (the container import is still running). Do not batch group 1 until this line says the CPU capture passed.
- Manifest: `MANIFEST.json` (group 1: one entry per item per part).

## Group 1 (1 Nov): three parts under `data/config/tidewake_look.json:cause_tidewake`

Each part is `cause_tidewake.<part>.enabled` (default false). When a part is on, it:
- brings its listed `sections_off` candidates into play;
- merges its `merge` map over the profile's top-level sections (`tidewake_look_profile.gd` `cause_parts`/`resolve`).

A capture can force a part without editing the config: `--tidewake-cause=sea,light,dunes`.

| Part | Judge theme it answers | What changes |
|---|---|---|
| `sea` | flat single-value navy water, hard light-cyan shallows band, empty horizons | Turquoise shallows, then a teal shelf (mid stop at 4 m, contour wandering ±1.4 m), then a lighter blue-teal deep (#15506c instead of #0a2c46) with broad value patches. The deep keeps some sky fresnel (0.05 → 0.35). New `water.gdshader` uniforms (all default 0, so Meadows and shipping water are unchanged): distance haze toward the sky horizon, soft wind slicks (smoother, lighter streaks that glint), rare small whitecaps. Plus a broken surf line at the sand. |
| `light` | flat light, no atmosphere, empty horizons | Day only: a clearer sky top, a pale haze horizon, whiter lit clouds, and aerial fog (0.0006) so far islands and the Veilfall recede. It is applied last (`cause_light_look`), so it composes over `watersky_light_candidate`. |
| `dunes` | sheet-like vertical dune walls, bare sand discs | Steep sand gets wind-scoured runnels and faint cross-bedding; level sand gets sparse low scrub and wrack stains (new `coastal_rock_material.gd` uniforms, default 0). It also brings in the existing unjudged dressing: random-keep dune grass with wider gaps, pebbles grouped at the tide line, and the swim-lesson dune clusters. |

Composition: the only shared files touched are `shaders/water.gdshader` (new uniforms, default 0), `coastal_rock_material.gd` (new uniforms, default 0), `tidewake_look_profile.gd` (`resolve` split out, cause parts) and `tidewake_world_look.gd` (one overlay line). `watersky_sections_on` and every other lane's flag are unaffected.

Test: `tests/test_tidewake_cause.gd`. It checks that with every part off the profile is unchanged, and that each part applies exactly its keys.
