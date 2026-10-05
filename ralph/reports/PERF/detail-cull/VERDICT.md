# Screen-size detail cull: before/after evidence

Change: `scripts/world/detail_cull.gd`, configured by `performance.json` `detail_cull` and hooked from `world_look.gd::_ready`. Every MeshInstance3D or MultiMeshInstance3D without an authored visibility range gets one: the distance at which its world bounds would cover fewer than 2.5 px of a 1080-line frame at 70° FOV, and never less than 150 m. Ranges of 9 km or more are left unset.

The cull skips:
- emissive surfaces;
- Terrain3D's own scatter;
- the player's subtree;
- nodes with meta `detail_cull_skip`.

## Tidewake (far floor 6.5 km), structural numbers at the F26 stands

| Stand | Before at 6.5 km | Before at 520 m | After at 6.5 km |
|---|---:|---:|---:|
| stand_0 | 3,030 | 1,278 | 1,374 |
| stand_1 | 453 | 435 | 451 |
| stand_2 | 1,096 | 1,077 | 1,040 |

Before the change, the attribution at stand_0 (6.5 km) put the far-floor cost on:
- `WaterCamps` creature-bed dressing: 1,064 draws;
- `WaterLocalChains`: 380 draws;
- `RenewableResources`: 216 draws.

Probe files: `../probe/water_fixes.json` (before, with A/B and attribution) and `../probe/water_cull.json` (after).

## Visual check (Tidewake)

There are 6 route stills (3 stands, day and night, 1920x1080, Low). The pairs were relabelled X/Y at random (`judge5_key.json`) and given to a code-blind judge, which rated all 6 pairs **EQUIVALENT**:
- nothing goes missing or pops at distance;
- silhouettes, lighting and shadows match;
- the only content difference was which wild species spawned in the middle distance, at the same places and scale (random spawn selection between runs).

The Stormwood verdict is added below once it is captured.
