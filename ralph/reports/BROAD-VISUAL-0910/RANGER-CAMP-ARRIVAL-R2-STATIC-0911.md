# Abandoned Ranger Camp arrival R2 — static candidate

## Status

**Static candidate only.** No scatter bake or production capture has been run.
The location remains **POLISH** until the coordinator bakes once with the other
pending vegetation work and reviews a complete production day/night set.

## Root causes and bounded correction

- The existing order-2004 r9 lens was centered at `(-249.5,2251.5)` from a
  player-position estimate. The production evidence camera stands 5.2m behind
  the player; its two approach eyes resolve at approximately
  `(-241.1,2246.6)` and `(-241.1,2243.5)`, outside that old circle. The same
  r9 lens is shifted to `(-245,2247)`: both eyes now have more than 3m of
  clearing margin, and the lens overlaps the established camp r15 clearing by
  about 7.1m. Radius, surrounding ecology, grass, and flowers are unchanged.
- `camp_tent.glb` has imported local bounds y `[-0.6114,0.5973]`, z
  `[-0.9486,0.9481]`. At the authored 68-degree pitch and 8-degree roll, its
  lower edge is y `-1.1468` before scale. The old scale `0.92` / sink `-0.20`
  therefore buried roughly 0.86m of the canvas. Scale `1.08` / sink `-1.22`
  leaves the transformed lower edge about 0.019m into terrain and reveals the
  existing collapsed silhouette; model, position, yaw, pitch, and roll remain
  the same.
- The resulting conservative 1.34m footprint edge remains approximately
  7.26m from the rest centre, 6.81m from the craft point, and 8.97m from the
  spur reference point. No interaction or route is moved.
- The evidence harness now freezes both player processing loops and records
  actual camera XZ in its manifest, preventing locomotion drift and another
  player-position/camera-position mix-up.

## Exact owned paths

- `data/config/bands/band2_stone_and_root/vegetation.json`
- `data/config/bands/band2_stone_and_root/props.json`
- `tests/test_ranger_camp_approach_identity.gd`
- `tools/capture_ranger_camp_arrival_identity.gd`
- `ralph/reports/BROAD-VISUAL-0910/RANGER-CAMP-ARRIVAL-R2-STATIC-0911.md`

These paths were clean before the candidate and do not overlap the active Trail
Camp (Band 1), Quarry deadfall (base vegetation), Highfield (Band 4), or
Ironwood Grove (Band 4/spawns) lanes. Generated scatter is intentionally
untouched.

## Static validation

`Godot_v4.7-stable_win64_console.exe --headless --path . --script
tests/run_tests.gd -- --only=test_ranger_camp_approach_identity.gd,test_band_content.gd`
passed on the first attempt: **8 tests, 1,450 assertions, 0 failed**.
