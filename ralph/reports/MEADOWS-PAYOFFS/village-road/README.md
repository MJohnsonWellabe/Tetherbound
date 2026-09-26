# F01 village road topology (work orders F01-a, F01-b and F01-c)

Evidence for WORLD §3.2 and ACCEPTANCE F01/M1, part a: the overhead plan comparing the old and new traversable road topology. The in-engine day/night walk and the bakes still belong to the lead.

- `plan_old_new.png` is the labelled overhead plan. OLD is 47774c350; NEW is this branch. `make_plan.py` regenerates it from the JSON, and each panel reads the village, boundary and NPC data at its own revision.
- `topology.py` holds the road-graph rules. `tests/test_village_road_topology.gd` implements the same rules.
- `proposed_moves.json` is empty: no moves are pending. The NEW panel draws the work_area props where they now stand.
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
  - Holds the `work_area` props (anvil, workbench, whetstone, crate, pickaxe), moved here from inside the inn apron by ee6cf86ca.
  - Its own scatter clearing is band1 `clearings` order 1929.
  - It is the end of **Stoneyard Lane**: (-1.5,-11.64) → (4,-18) → (13.6,-20) → (14.2,-26) → (14.6,-31). The lane passes 2.8 m in front of the stone cottage's threshold, so cottage_b keeps its 0912 pose.
  - The fingerpost stands at (-4.2,-15.6).
- **Berry Field**: centre (-8.5,-23), radius 6.
  - Holds berry node 1036 [-9,-19], the only harvestable bush in the field.
  - Planted rows: 10 low Bush_Common shrubs from a band1 `layer_anchors.bushes` entry. These are deliberately flowerless and about knee height, not the flowering Bush_Common_Flowers the harvest nodes use, so the one pickable bush is the one that looks pickable.
  - An L of fence rails from `village.json`: north rail at [-9,-28.5], west rail at [-12,-25.5].
  - It is the end of **Berry Lane**: (-8,-13.96) → (-7.2,-20.5).
  - The fingerpost stands at (-11,-17.2).
- **The Grove**: centre (-20,6), radius 8.
  - Six `village.json` oaks with trunk-only colliders, standing 3.7 m or more from the road.
  - A 6-bush understorey anchor, round stone node 6.
  - Its own scatter clearing (band1 order 1930, radius 9.5) keeps baked random trees and rocks off the oaks. The understorey anchor opts out of that clearing.
  - The Pond lane runs through its east margin.
  - The fingerpost stands at (-15,1.5).

## Slopes (2 m baseline)

- New lanes are at most 0.6°.
- Subarea terrain: The Stoneyard up to 7.5° (0.8 m relief), Berry Field up to 6.2° (0.3 m), The Grove up to 20.2° (2.9 m). The grove's value is below the 45° walk limit.
- The steepest point on any village road is still the unchanged Rise segment beside RoadGate, at 22.2°.

## Bakes the lead must run

Run these as Godot writers, serialized, under the lane's Godot writer lock (for example `flock <lane lock file> <command>`). Run them on the branch head, after the F01-c commit.

```
~/godot-bin/godot --headless --path . --script scripts/world/build_playground_terrain.gd
~/godot-bin/godot --headless --path . --script scripts/world/bake_playground_scatter.gd
~/godot-bin/godot --headless --path . --script tests/run_tests.gd -- --only=test_terrain_bake_freshness.gd,test_scatter_perf_budget.gd::test_playground_bake_is_committed_and_fresh,test_ridgeline_groundmat_composition.gd
```

Then commit `data/terrain/playground/` (the regions and `manifest.json`) and `data/scatter/playground/`.

## Shared-file decisions

- **Kept: work_area moves to The Stoneyard** (ee6cf86ca). The live band1 `props.json` and its baseline mirror move together, which `test_band_content` requires. The commit also corrects the tournament cluster's `_why_vp5`.
- **Reverted: berry nodes 10 and 1033 into the Berry Field** (5645fb3f9, reverted in 3d1cb7cd9). Gate-F segments S03, S03C, S03p3, S03Cp3 and diag_night_preconditions_0919 script a walk to node 10 at [20,-16].
  - Node 10 therefore still sits inside cottage_b's walls, 3.66 m from its door. That is outside the door prompt's 3.0 m radius, and the door test guards the 3.2 m margin.
  - Moving the node needs those segments re-pointed first.
- **Stale references in shared files, left for the lead to update:**
  - `tests/test_gate_a_build_segment_contract.gd:49` pins the `(18,-24)` "Practice Meadow road bend" waypoint line, which is now open ground and no longer on the road.
  - `data/config/map_landmarks.json:9,12` gives reveal circles for "the village square" (10,-10) and "Practice Meadow road, midpoint" (18,-24). Both are still inside the village, but the labels are stale.
  - `tools/capture_prop_clusters.gd:28` frames the work_area cluster at its old site: `WORK_AREA_CENTRE` (-5,-2.8).
