# BELOW6-OVERLOOK-SOLID: solid overlook ruins plus the two walk stands (F40#15)

Row: F40#15 (5.77). Its overlook frame is `walk_03_day`. Also fixes the walk_02 "translucent ghost planes" (3/3 on both sides of G-below6-overlook-pane and -stone).

This replaces BELOW6-OVERLOOK-STANDS (stands alone) as one arm, as the coordinator asked.

## Cause

The overlook's piers and ruined wings were presentation-only. A player could walk into the masonry, and the seeded walk_02 and walk_03 capture stands land inside or behind it. From inside, the camera's occluder fade draws the walls see-through: the ghost planes.

## Arm (one overlay, `overlay.json`)

1. `data/config/cloudreach_stormward_overlook_visual.json` `ruin_collision_1113` (OFF, scope world_geometry): `build_ruin_collision()` in `scripts/world/cloudreach_stormward_overlook.gd` returns one static body with a box per pier and wing, 90 percent of the visible stone's size, with each piece's lean, yaw and roll, on the ordinary world layer. The arch opening between the piers (about 5 m either side of the centre line) and the route ribbon are clear. The presentation node itself stays collision-free; `cloudreach_world.gd` adds the body only when the flag is on.
2. Two `capture_stands.json` `heading_overrides.frames` rows: walk_02 at (-419, 5642) heading 340 and walk_03 at (-441, 5636) heading 43, both on open ground facing the arch. With solid ruins nobody can stand where the seeded stands were.

## Proof (CPU)

- `_sheet_base_top_arm_bottom.jpg`: route_day, vista_dusk, walk_01, walk_02, walk_03, seed 2042. route_day, vista_dusk and walk_01 are unchanged. walk_02 and walk_03 now show the arch, compass ring and both pennants with the trainer on grass.
- Walk check with the overlay on: `tests/smoke_cloudreach_waterward_overlook_join.gd` passes (`CLOUDREACH WATERWARD OVERLOOK PASS ... distance_m=386.5`). It is the only Cloudreach smoke that walks to this crown.
- `tests/test_overlook_ruin_collision_flag.gd`, plus the existing overlook tests.

## To know

- The right wing stands on the east loop edge's crown strip (that strip is 26 m wide; the wing is 7 m). A walker goes round it. No smoke walks that edge.
- If this ships, the landing needs both parts: the flag ON and the two stand rows in `capture_stands.json`.
