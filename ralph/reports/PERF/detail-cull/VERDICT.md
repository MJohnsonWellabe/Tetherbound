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

## Stormwood (far floor 9 km)

The first Stormwood measurement showed that large creature bodies were skipped as "emissive", because their materials glow a little. The exemption now applies only to emissive objects up to `emissive_skip_max_size_m` (1.5 m), such as lamps, lanterns and glints.

| Stand | Before at 9 km | Before at 520 m | After at 9 km |
|---|---:|---:|---:|
| stand_0 | 3,985 draws / 6.23M prims | 992 / 3.07M | 1,211 / 3.63M |
| stand_1 | — | — | 1,125 / 3.35M |
| stand_2 | — | — | 766 / 3.05M |

Before the change, the attribution at stand_0 put 1,566 draws and 2.5M primitives on the 802 wild creatures. After the change: `../probe/stormwood_cull.json`.

Visual check: 6 route stills (3 stands, day and night), relabelled at random (`judge6_key.json`). The code-blind judge rated all 6 pairs **EQUIVALENT**. Every difference was rain, path-glow phase or creature/NPC idle pose; the pylon chain, trees, cottages, rocks and horizon were identical.

The judge also noted, for both builds equally and not caused by this change, that the Stormwood "night" frames are as bright as the day frames. That realm's look is driven by its Surge state rather than the day clock; this is routed to the visual lanes.
