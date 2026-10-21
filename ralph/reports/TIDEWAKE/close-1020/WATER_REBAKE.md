# Corrective Water terrain rebake (Tidal Cradle Saddle Camp)

Root cause: `data/terrain/water` was last baked 10 Oct (eab26f0d5). The `tidal_cradle_saddle_camp_spur` trail grading (the graded tread to the Saddle Camp) was added to `water_world.json` on 12 Oct (0fe49ed5a) and never baked, so the shipped ground at the camp was the ungraded slope and `Game.debug_teleport_to`'s walkability guard (45° floor limit) refused catalogue destination 10.

Bake inputs changed since eab26f0d5 (`git log eab26f0d5..origin/main` over water_world.json, water_visual.json, water_pickups.json, water_heightfield.gd, build_water_terrain.gd): only 0fe49ed5a, the 28-line spur entry, merged on main. Baked once from origin/main's config with `build_water_terrain.gd` and `build_water_surface.gd`; P2-026 shoal shapes not included. Changed outputs: `terrain3d_01_03.res` (the camp region), `surface_height.res`, `manifest.json` (config_sha256 now matches main).

Camp check on the baked Terrain3D data (Terrain3D sampled the way `ground_height_at` does, 1 m span as the guard):

| Point | Old bake slope | New bake slope |
|---|---|---|
| Camp landmark (841.4, 1595.9) | 46.8° | 3.4° |
| Spur end (838.8, 1598.9) | 46.8° | 7.0° |
| (845.0, 1592.0) | 46.6° | 2.0° |
| Spur bend (851.9, 1583.9) | 45.6° | 1.0° |

Tests on the new bake (tb/tidewake code with main's water config): 58 water test files touching terrain/route/swim/encounter/spawn, 364 tests, 0 failed. Smokes: swimming OK (22), combat pause OK (38), camps 129/0, loops/shortcuts 164/0, walked hops 23 PASS / 0 FAIL, scene encounters 47 checks / 1 failure "Actual Water fight displays its move controls", which also fails on the old bake (48/1), so it predates this change.

Also included: 129fadfe8, production WorldWeather in `water_archipelago.tscn` (the F39#0 recapture was taken with it) and the F13#5 capture's clear-weather pin.
