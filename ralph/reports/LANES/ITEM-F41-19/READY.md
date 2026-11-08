STATUS: parked
BRANCH: tb/item-f41-19  HEAD: see the commit that adds this READY (pushed head)

Lane LANE-MESHY, queue row 15 (coordinator 8 Nov): F41#19 P2-043 Glass Field spike bases. No config or code change ships; the collider code was dropped.

## Diagnosis (today's main, CPU)
- `_sheet_live_walk03.jpg`: the shipped arms (seam_clear_1104, rock_collar + footing_1104, meshy_spikes) have replaced the flat dark base. The spikes now break out of a ring of grey rock-family boulders.
- The frame's dominant defect is now the trainer standing **inside** a cluster: legs hidden behind collar stones, glass caps over the body. The seeded walk_03 stand lands there because the field is non-colliding.
- That field is **non-colliding by design** (below), so a player really can stand there. walk_03 is a reachable view and stays as it is (coordinator 8 Nov; unlike the Warrens stand, which was inside solid collision).
- A taller Blender spike cluster, the queued idea, would not change this.

## Parked arm: cluster colliders (code dropped)
- `colliders_1108` (OFF while it existed): convex colliders for each Meshy spike model, and the collar stones kept the rock family's own colliders. 528 static bodies and shapes.
- Footprint probe with it on: 760 Stormwood points within 260 m, 0 conflicts. The points were the `stormwood_world.json` routes densified at 2 m, the glass-field route centreline, encounters, pickups, harvests including stormglass, trainers, camps, settlements, pockets and rod stations. The probe checked centres only, not the alpha fight arena's full radius.
- Stand: with colliders on, the existing preflight rejected the inside-cluster stand ("physical floor differs from the resolved terrain") and settled 5 m away at (-282.9, 5021.3).
- Visibility (`_sheet_visibility.jpg`): live at that moved stand, shot via `--spot` with the identical camera, vs colliders on: 2.0% of pixels changed (rain). The colliders are invisible; every visible gain came from the stand move, which earns no credit. Not judged.
- **Why parked:** `tests/test_stormwood_glass_field_identity.gd` encodes a design contract. The glass field carries no CollisionObject3D ("visual identity added collision to the road, fight, or final approach"; the scorched-scar and fulgurite passes stay "still non-colliding"). With the arm on, 3 of its tests fail. The field holds the voltarach alpha fight and the final approach. Changing that is an owner decision, not a stale assertion.
- **Cost result, kept for the record in case the owner ever changes the rule:** with a hull built per instance (`create_convex_collision`), headless Stormwood boot went from 10.6-11.3 s off to 36.3-38.2 s on (+25 s). With one convex hull cached per unique mesh and shared by every instance, it was 10.6-11.4 s on, the same as off. The physics step averaged 20.5-21.3 ms on vs 19.1-21.6 ms off over 300 frames, within noise.

## For the GPU re-score
- walk_03 stays as is. Its defect is the designed walk-through overlap of the trainer and a spike cluster.
- A future fix is art or placement that keeps spikes and collar stones off walkable stand areas, or an owner change to the non-colliding rule.

## Other checks seen
- `smoke_stormwood_b_named_detour_dryrun` fails on main too ("Stormwood never became current"); unrelated.
- `smoke_stormwood_route_walks` needs `--from-save` and fails without it; unrelated.
- `smoke_stormwood_road_arrival` and `smoke_stormwood_pocket_walks` passed with the arm on.

## Files
`ralph/reports/LANES/ITEM-F41-19/**` only.
