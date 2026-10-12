# F17#6 interior set: hall pools + sealed reveal ON, signage OFF (landmarks-claude)

Source `tb/ev-landmarks-claude` at 645c48e7, with `hall_interiors_claude_enabled` turned on locally for the
capture only. The committed flag is OFF, and `signage.enabled` is off. Captured with
`tests/capture_f17_visual_matrix.gd`, the real farmhouse → Main Street → Hall walk, at 1920x1080 on
Low/Compatibility (llvmpipe), with the HUD as played. The run logged `F17 matrix PASS: 43 frames`.
`interior-set-Low.jpg` shows the six interior stations at 08:00 and 23:00 clear, scaled to 1280x720.
`frames.json` is the tool's receipt.

## Own code-blind judge: FAIL

| Named defect | Result |
|---|---|
| Floating debug-looking labels | Gone: plaques sit on boards and pedestal names are carved. Some text is too small at distance. |
| Daylight windows at 23:00 | Gone: night windows are dark, lanterns glow, and the floor pools are warm. |
| Leaning loose door over a blue surface | Not in view: every door is upright and framed. |
| Raw unframed wall cut | Gone for the arches. Possible gap: sky and a separate roof show at the top left of `nave-arches-right` day. |
| Bench clipping the companion | Still shows, now as pedestals: in `shrine-pedestals` (lower right) and `shrine-pedestals-reverse` (the "Cloudreach Cliffs" stand) the companion's body passes through a lectern-pedestal, day and night. |

Other defects:
- At 23:00 the companion turns saturated blue-violet, worst in `nave-forward`.
- The companion's back fills about half of both `nave-forward` frames.
- In the shrine frames the pedestal tops crowd the Quick Items row.

None of these is in this lane's quick scope: companion placement or pedestal clearance, and creature night lighting.
