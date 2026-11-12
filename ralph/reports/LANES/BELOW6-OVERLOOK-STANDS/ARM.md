# BELOW6-OVERLOOK-STANDS: overlook walk_02 and walk_03 capture stands

Follows BELOW6-OVERLOOK-PANE. With the pane gone, `walk_02_day` and `walk_03_day` still show a pier wall across half the frame. The seeded walk offsets (about 14 m either side of the route) drop the trainer inside the overlook's ruined wings, which are visual only, so the production camera ends up against the masonry.

Arm: two `heading_overrides.frames` rows in `data/config/capture_stands.json` (the same block the Warrens walk_03 row uses), supplied as `overlay.json` only so the pane run stays clean:

- `walk_02_day`: (-419, 5642), heading 340: the approach lawn facing the arch, compass ring, both pennants.
- `walk_03_day`: (-441, 5636), heading 43: the west shoulder looking across to the arch.

A first try at (-408, 5636) had no supported ground and was dropped.

CPU sheet `_sheet_before_after.jpg`: top row is the pane-fix branch (seeded stands), bottom row is with the overlay. Capture stand only; the game is unchanged. Needs the coordinator's stand review and a GPU look before the rows are added to config.

Seen in these frames and not fixed: the ruined wings can be walked through (no collision), the right wing overhangs the plateau edge, and a tree stands in the middle of the arch.
