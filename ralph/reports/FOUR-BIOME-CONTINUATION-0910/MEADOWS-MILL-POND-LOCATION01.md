# Meadows named-location pass — The Pond mill

Date: 2026-09-11

Source inspected: `b71aa3a9b` plus the isolated candidate below

Renderer: Godot 4.7 Compatibility / OpenGL 3, 1280×800

## Scope and retained work

This pass reassessed the OW5D-relocated Pond group at the production location:
the mill at `(-382, 514)`, the footbridge, ranger station, water, wildlife and
approved dense shoreline. The recently improved **Old Mill Crossing** in Band 3
was explicitly out of scope and its script, placement and vegetation were not
changed.

The current baseline already had a strong high arrival view: the pond water,
tall half-timber mill, ranger station and lush pocket read together. The real
remaining defect was the west-bank working view. The shared prefab's small
fence-piece wheel vanished into the wall, leaving the dedicated wheel frame to
read as a blank mill facade.

## Candidate

- `scripts/world/mill_pond_identity.gd` adds one Pond-only working silhouette:
  a 4.7 m timber wheel, ten spokes and paddles, an axle into the west wall and a
  restrained patch of pale wash at the bottom paddles.
- `scripts/world/village.gd` attaches that identity only to the village `mill`
  placement. It does not change the shared mill recipe or the independently
  built Old Mill Crossing.
- The original water, terrain, vegetation, wildlife, buildings, doors and
  placement remain unchanged.

## Fresh production evidence

`tools/_capture_locations.gd -- --only=02-mill-pond --fast` completed with three
frames written and zero failures:

- `shots/locations/02-mill-pond-approach-day.png`
- `shots/locations/02-mill-pond-standing-day.png`
- `shots/locations/02-mill-pond-wheel-day.png`

The approach still carries the accepted pond-and-mill vista. The wheel-side
frame now presents a large radial working shape against the previously blank
wall, with pond water and water creatures visible behind it. Screenshots are
local evidence payloads and are not staged as source.

## Validation

- `test_mill_pond_identity.gd`: 2 tests, 9 assertions, 0 failed.
- `test_gate_a_front_door_and_world.gd`: 4 tests, 24 assertions, 0 failed.
- `test_old_mill_crossing_visual_identity.gd`: 4 tests, 26 assertions, 0 failed.

## Honest remaining limits

- No self-authored visual verdict is claimed. These three frames should be
  included in the next independent Meadows named-location regrade.
- The ordinary ground-level standing frame still emphasizes the building and
  characters more than the pond; water reads as a narrow strip in that one
  angle. The approach and wheel-side frames carry the broader water context.
- The wheel is static visual dressing. Its existing prefab collision still
  covers the same wall-side working volume; animation was not invented for a
  named-location art pass.
