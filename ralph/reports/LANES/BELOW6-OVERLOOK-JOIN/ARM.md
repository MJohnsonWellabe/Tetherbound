# BELOW6-OVERLOOK-JOIN: approach ridge lifted to the overlook ledge (F40#15)

Row: F40#15 (5.77, lowest on the board). Also in `route_day` and `vista_dusk`, which feed F40#0 and F40#21. Recorded on both sides of G-below6-overlook-stone (3/3): "a dark seam across the grass at the trainer's feet plus a dark wedge".

## Cause

The Stormward Overlook is the one landmark whose crown follows two sloped strips (cap radius 0). Away from those strips the ledge crown eases back up to the landmark height. The approach ridge's rows are pinned to the crown only inside the ledge's flat radius (20.7 m); just outside it they drop to the ridge's own height. The gap is a 0.2 to 0.3 m notch where the top of the ledge wall shows, growing toward the east side.

## Arm

`data/config/cloudreach_visual.json` `landmass.overlook_ridge_join_1113` (OFF, scope world_geometry), read by `_overlook_join_height` in `scripts/world/cloudreach_world.gd`:

- A ridge vertex within 9 m outside that rim is lifted toward the crown height at the nearest rim point, eased to nothing at 9 m. Never lowered.
- No lift across a route ribbon's own width (the first try buried the dirt path), easing in over the next 4 m.
- Only the pad with cap radius 0, so only this landmark. With the flag off the row heights are unchanged.
- The collider is built from the same rows, so it moves with the render: identical on every peer, no save state.

## Proof (CPU)

- `_sheet_base_top_arm_bottom.jpg`: vista_dusk (left) and route_day (right), seed 2042. The straight seam at the trainer's feet is gone and the path is intact. The dark wedge beside the path is shorter but still there: it sits inside the road's keep-clear width, where the lift is held off.
- Walk check with the flag ON: `tests/smoke_cloudreach_waterward_overlook_join.gd` (real-input traversal from the west summit-loop waypoint to the overlook crown) passes: `CLOUDREACH WATERWARD OVERLOOK PASS ... distance_m=386.2`.
- `tests/test_overlook_ridge_join_flag.gd`.

## For the GPU run

No-loss sets: overlook walk_02 and the High Perches stands, as you said. If the remaining wedge still reads, the next lever is lowering the ledge crown to the road there instead of raising the grass.
