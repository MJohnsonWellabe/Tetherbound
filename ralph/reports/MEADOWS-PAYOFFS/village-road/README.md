# F01 village road topology (work orders F01-a and F01-b)

Evidence for WORLD §3.2 and ACCEPTANCE F01/M1, part a: the overhead plan comparing the old and new traversable road topology. The in-engine day/night walk and the bakes still belong to the lead.

- `plan_old_new.png` is the labelled overhead plan. OLD is 47774c350; NEW is this branch. `make_plan.py` regenerates it from the JSON, and each panel reads the village, boundary and NPC data at its own revision.
- `topology.py` holds the road-graph rules. `tests/test_village_road_topology.gd` implements the same rules.
- `proposed_moves.json` lists the moves held in the two `PENDING GRANT` commits. The NEW panel draws them as dashed lines.
- `tools/_probe_f01_road_slope.gd` measures road grades and the slope across each subarea, using the heightfield the bake uses.

## Topology (computed from the data)

| | OLD | NEW |
|---|---|---|
| Road arms within 8 m of the well | 5 | 2 (the through-road passes it) |
| Junctions (degree ≥ 3) | (7,-7) d5, (10,-10) d3, (14,20) d3, (27.5,-16) d3 | (-8,-13.96) d4 Pond/Berry crossroads, (-1.5,-11.64) d4 inn/Stoneyard crossroads, (10.05,-0.9) d3 Rise; all three are on the through-road |
| Home door → TrailGate | 56.0 m | 56.0 m, unchanged |
| Fence crossings | Pond, Road and TrailGate | the same three points; `village_boundary.json` is unchanged |

## The three named subareas

Each subarea is named by a one-arm fingerpost on the road that serves it.

- **The Stoneyard** (stone-working area): centre (16.5,-33), radius 7.
  - Holds stone nodes 4 [22,-34] and 1037 [11,-32], with deadwood 0 at its rim.
  - Its own scatter clearing is band1 `clearings` order 1929.
  - It is the end of **Stoneyard Lane**: (-1.5,-11.64) → (4,-18) → (13.6,-20) → (14.2,-26) → (14.6,-31). The lane passes 2.8 m in front of the stone cottage's threshold, so cottage_b keeps its 0912 pose.
  - The fingerpost stands at (-4.2,-15.6).
- **Berry Field**: centre (-8.5,-23), radius 6.
  - Holds berry node 1036 [-9,-19].
  - A planted row of 7 Bush_Common_Flowers bushes (a band1 `layer_anchors.bushes` entry), sized like a harvest node.
  - An L of fence rails from `village.json`: north rail at [-9,-28.5], west rail at [-12,-25.5].
  - It is the end of **Berry Lane**: (-8,-13.96) → (-7.2,-20.5).
  - The fingerpost stands at (-11,-17.2).
- **The Grove**: centre (-20,6), radius 8.
  - Six `village.json` oaks with trunk-only colliders, standing 3.7 m or more from the road.
  - A 6-bush understorey anchor, round stone node 6.
  - The Pond lane runs through its east margin.
  - The fingerpost stands at (-15,1.5).

## Slopes (2 m baseline)

- New lanes are at most 0.6°.
- Subarea terrain: The Stoneyard up to 7.5° (0.8 m relief), Berry Field up to 6.2° (0.3 m), The Grove up to 20.2° (2.9 m). The grove's value is below the 45° walk limit.
- The steepest point on any village road is still the unchanged Rise segment beside RoadGate, at 22.2°.

## Bakes the lead must run

Run these as Godot writers, serialized, under the lane's Godot writer lock (for example `flock <lane lock file> <command>`). Run them after deciding on the two `PENDING GRANT` commits, so that the bake sees the final data.

```
~/godot-bin/godot --headless --path . --script scripts/world/build_playground_terrain.gd
~/godot-bin/godot --headless --path . --script scripts/world/bake_playground_scatter.gd
~/godot-bin/godot --headless --path . --script tests/run_tests.gd -- --only=test_terrain_bake_freshness.gd,test_scatter_perf_budget.gd::test_playground_bake_is_committed_and_fresh,test_ridgeline_groundmat_composition.gd
```

Then commit `data/terrain/playground/` (the regions and `manifest.json`) and `data/scatter/playground/`.

## Pending-grant commits (drop or keep)

- **work_area → The Stoneyard.** In band1 `props.json`, the anvil, workbench, whetstone, crate and pickaxe move by (+17.5,-32.5), from about (-5,-3), inside the inn apron, to about (12.5,-35.5). The commit also corrects the tournament cluster's `_why_vp5`, which still describes the removed spine leg.
- **Berry nodes → Berry Field.** In band1 `harvest.json`, node 10 moves from [20,-16] to [-5.8,-24] and node 1033 from [-32,-1] to [-10.8,-25.8]. Node 10 has sat inside cottage_b's walls since the 0912 move. The village node count stays 28.
  - Risk: gate-F segments S03, S03C, S03p3, S03Cp3 and diag_night_preconditions_0919 script a walk to node 10 at [20,-16]. They need re-pointing if this commit is kept.
