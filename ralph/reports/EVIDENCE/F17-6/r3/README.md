# F17#6 round 3: Hall interiors and street-mid-right, CAPTURE-READY

- **Source:** `tb/ev-coop-chapters` `ff6ddc413`; Low/Compatibility, llvmpipe; captured about 7:00–7:40 AM CT Mon 12 Oct.
- **Frames:** 4 interior frames (`tests/capture_f17_hall_interior.gd`, 1280x720) and 2 street-mid-right frames (`tests/capture_f17_visual_matrix.gd`, 1920x1080, real walk); all scaled to 1280x720 in `frames/`; all six on `sheet.jpg`.
- **Self-check:** I viewed every frame before handing over, as asked. Mean luminance, nave: day 83.7, night 36.4. Shrine: day 90.5, night 75.3 (round 2: day 90.5, night 103.0).

## Round-2 interior blockers
1. **Sealed arches:** lighter kit brick with its normal map inside the recessed fan, and a stone keystone at the crown. A warm light floor keeps them lit at night (never black).
2. **Floating labels:** arch name and state are on a wooden plaque on the arch surround, below the arch top, wrapped to the plaque. Pedestal names are carved on their stone plinths. "The Rise" was the HUD's region banner, set off inside the Hall; region announcements now wait outside declared interiors.
3. **Night:** the nave's window glass goes dark at night (the frontage keeps its lit glass). Lanterns burn at 0.35x by day and 0.5x at night with a 6.5 m reach, so they pool.
4. **Loose door / blue surface:** the locked door is widened into the arch, behind the trim, and the recess behind it is dark wood-brown, not blue.
5. **Raw cut:** the 6 m Shrine Room opening (x=7, z -3..3) gets two posts and a lintel. Presentation only, outside the walked clearance.
6. **Bench:** the companion settles at about (55.7, 17.3). The ranger bench is turned to face its door path at (59.0, 20.4); the logged gap is 4.52 m (round 2: 2.37 m).

## Still open (unchanged)
- Cobble scale.
- The nave end wall is dark at night beyond the lanterns' reach.
- The exterior later-notes: doorway grass, sign legibility, A-pose idle.
- The full-bar items.

**Checks:** affected unit tests pass (114 tests, 0 failed); parse checks clean.
