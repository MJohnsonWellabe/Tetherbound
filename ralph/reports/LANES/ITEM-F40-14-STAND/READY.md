STATUS: withdrawn
BRANCH: tb/item-f40-14-stand  HEAD: see the commit that adds this READY (pushed head)

Lane LANE-MESHY, F40#14 P2-048 Cloudreach map region label. **Withdrawn (coordinator 8 Nov): do not land.** The previous commit is reverted on this branch; job.json is unchanged from main.

## Why withdrawn
- The map opens at 32x by default. There the on-map region label is hidden because the region centre is off screen. That is what a player sees, so moving the judged frame to the 4x zoom sample would hide a real defect (the no-reframing rule).
- Route (2) (restore an originally judged zoom) does not apply:
  - The 2 Nov GPU batch 5 P2-048 set (`ralph/reports/CLOUD-JUDGE/BATCH5/CREATURES-UI`, 7.01 -> 7.52) judged one stand: the job's default `cloudreach__menu_map` frame (the frame id never changed).
  - The flag it judged is `menu.json map_region_header` ("You are here: <region>" in the map header), which shows at every zoom including the default 32x.
  - So the label the judges saw was the header, not an on-map label at another zoom.

## Evidence kept
- Probes `.artifacts/f4014/ui_zoom_s0` and `ui_zoom_s400` (local): at 4x and 8x the on-map label "Cloudreach Gate / Lower Cliffs" draws in full; at 16x and 32x it is absent; the survey fixture makes no difference.
- `tab_map.gd` `_draw_region_label`: at zoom >= `_local_label_margin_zoom` a label draws only if the region centre is on the canvas.

## Route (1) for later (game fix)
- At local zooms, draw the player's current region label when any of the region is in view, anchored at the player marker or the visible part of the region and clamped to the screen, instead of requiring the region centre on screen. Then judge it at the default 32x frame against live.
- Also: widen the "You are here" box so "Cliffs" does not wrap.
