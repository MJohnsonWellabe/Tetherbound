# F01-a: village road topology as data

Evidence for WORLD §3.2 and ACCEPTANCE F01/M1, part a: the overhead plan comparing the old and new traversable road topology. The in-engine day/night walk and the bakes still belong to the lead.

- `plan_old_new.png` is the labelled overhead plan. OLD is `data/config/terrain_playground.json` at 47774c350; NEW is this branch. `make_plan.py` regenerates it from the JSON, and `topology.py` holds the road-graph rules, which `tests/test_village_road_topology.gd` also implements.
- `proposed_moves.json` lists shared-file moves that have not been applied. The NEW panel draws them as dashed lines.
- `tools/_probe_f01_road_slope.gd` measures the grade of each road using the heightfield the bake uses.

## Topology (computed, not drawn by hand)

| | OLD | NEW |
|---|---|---|
| Road arms within 8 m of the well | 5 | 2 (the through-road passes it) |
| Junctions (degree ≥ 3) | (7,-7) d5, (10,-10) d3, (14,20) d3, (27.5,-16) d3 | (-8,-13.96) d3 Pond, (-1.5,-11.64) d4 inn crossroads, (10.05,-0.9) d3 Rise |
| Junctions on the through-road | 1 of 4 | 3 of 3 |
| Home door → TrailGate | 56.0 m | 56.0 m, unchanged |
| Fence crossings | Pond, Road and TrailGate | the same three points |
| Road centreline inside a building | the band1 stub runs through Mira's shop, and three spokes start inside the well apron | none |

## Slopes (2 m baseline, within 75 m of the well)

New segments are at most 9.3° (Stoneyard Lane 0.4°, inn stub 0°, the new Rise leg in the square 0°). The steepest points are on unchanged pieces: The Rise reaches 22.2° at (36.5,-19.1) beside RoadGate, as it did before; the Pond reaches 11.6° past (-14,14); band1 reaches 16.2° outside TrailGate.

## Bakes the lead must run (Godot writers, serialized)

```
L=/tmp/claude-0/-home-user/c5e09b24-64e9-5f4d-827d-b9212dd8b5d5/scratchpad/godot-writer.lock
flock $L ~/godot-bin/godot --headless --path . --script scripts/world/build_playground_terrain.gd
flock $L ~/godot-bin/godot --headless --path . --script scripts/world/bake_playground_scatter.gd
~/godot-bin/godot --headless --path . --script tests/run_tests.gd -- --only=test_terrain_bake_freshness.gd,test_scatter_perf_budget.gd::test_playground_bake_is_committed_and_fresh
```

Commit `data/terrain/playground/` (the regions and `manifest.json`) and `data/scatter/playground/`. If the shared-file proposals below are granted, apply them first and bake once.

## Shared-file changes

Applied under the F01 grant:

- `village.json`: `cottage_b` turns from yaw -110 to yaw 40, so that its real door fronts the Rise lane 4.1 m away. The doorstep moves from [15.72,-18.13] to [21.78,-16.25]. The `building_aprons` entry for [19,-18] follows the new yaw.
- `village_boundary.json`: **no change needed.** Every road crosses the fence at exactly the old point: PondGate, RoadGate and TrailGate. `test_village_boundary.gd` now checks the approaches and the Lower Meadows spine as well as `routes`.
- `village_npcs.json`: no change. There are still five street villagers: Mira, Oskar, Tam, Bram and Halda.
- The vegetation footprint exclusion for cottage_b is a circle (r 5.3), so the re-yaw leaves it unchanged.

Still proposed, because these files are outside the grant:

- `bands/band1_lower_meadows/props.json`: move `work_area` (anvil, workbench, whetstone, crate, pickaxe) by (+17.5,-32.5), from about (-5,-3) to about (12.5,-35.5), into The Stoneyard. Today the cluster sits inside the inn apron.
- `bands/band1_lower_meadows/vegetation.json` `clearings`: add x 16.5, z -33.0, radius 8.0 so that random trees and rocks stay out of The Stoneyard.
- `bands/band1_lower_meadows/harvest.json`: berry node 10 [20,-16] and the `cottage_b_backyard` props [19,-18.6] lie inside cottage_b's footprint, about 1 m behind the front wall. The 0912 move left them there; this change did not cause it. Proposal: move the node to [26.0,-19.5], which is 3.5 m off the Rise lane and inside the fence, so that its prompt does not compete with the cottage door.
