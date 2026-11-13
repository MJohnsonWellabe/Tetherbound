# BELOW6-OVERLOOK-PANE: Stormward Overlook amber pane (bug fix)

Rows: the overlook route frames (F40#15 and the routes that pass the Stormward Overlook).

## What it was

- **The pane** is `banners[1]` in `data/config/cloudreach_stormward_overlook_visual.json`: a flat 2.0 m by 4.5 m plane (`#d0a94c`) hung beside the right pier with its bottom edge at about head height. The route camera for `walk_02_day` sits next to that pier, so the card fills over half the frame. Proof: the same capture with `banners: []` shows the pier wall and no pane.
- **The white ball** on the grass is a beacon glow: a default `SphereMesh` (1 m across) at emission 2.8.

Neither is an occluder fade, a trigger volume or a gizmo. Both are authored overlook dressing.

## Fix (`pane_fix_1112`, ON)

- Streamers are narrow swallow-tailed pennants (42% of the width, 62% of the height, darker cloth with a darker hem) hung from the same top edge, so they sit well overhead.
- Beacon glows are small embers (radius 0.3 m, emission 1.0) seated in their bowls. The beacon lights are unchanged.
- Visual only. No collision, route or stand changes.

## Proof

- CPU before/after, all five route frames, seed 2042: `_sheet_before_after.jpg` (top row before, bottom row after). The pane and the ball are gone in `walk_02_day`; the other four frames keep their composition.
- `tests/test_overlook_pane_fix.gd` and `tests/test_cloudreach_stormward_overlook.gd`: 7 tests, 0 failed.

## Not fixed here

`walk_02_day` and `walk_03_day` still have the camera pressed against a pier wall, which fills the left half of the frame with masonry. That is the route stand, not the dressing. A GPU look should confirm the row gain before it is counted.
