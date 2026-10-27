# r47: Ashfoot storm-driven room light (CPU, code-blind, 26 Oct): +0.33, under the bar, no arm

**Arms:** the Ashfoot inside stand, all four phases, on the lane with storm_view ON (GPU SW16).
- **OFF:** the current room.
- **ON:** `cottage_interior_finish.json storm_finish.storm_room`:
  - a 62-degree spot from the east window, with per-phase colour and energy (calm 1.6, building 4.0, break 6.5, fading 2.6) and a surge-flash gain of 2.5;
  - the hearth scaled per phase (1.0, 0.75, 0.6, 0.9);
  - the warm overhead RoomLight scaled per phase (0.9, 0.55, 0.45, 0.75).

**Result:** mapped **5.44 -> 5.77 (+0.33)**. 3/3 judges prefer ON: 5.5/5.8, 5.2/5.7, 5.2/5.4.
- **Calibration:** offset fallback (least-squares slope 2.14, outside 0.5-2.0) and anchor RMSE 0.77, so read with that caveat.
- **"The room stays warm orange":** PARTIAL on both arms for two judges; for the third, PRESENT on OFF and PARTIAL on ON. The judges see building cool and break go violet, but calm and fading are "nearly identical warm" and there is "no lightning shaped on the walls".
- **Measured:** the left half of the frame in break goes from RGB 131/91/77 to 156/123/118. The orange wood albedo keeps the overall read warm.
- **First try:** spot at 0.9-2.6 with the room lamp untouched, no visible change. It was retuned before judging and is not counted as a round.

**Decision:** under the 0.5 rule, so no arm. `storm_room` stays OFF and rides along with the second ask that all three judges repeat: Stormwood dressing inside (moss, copper fittings, glass floats or lanterns, storm gear), plus a lightning shape on the walls (a window-shaped flash) rather than a whole-frame tint.
