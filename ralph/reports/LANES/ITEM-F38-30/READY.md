STATUS: land
BRANCH: tb/item-f38-30  HEAD: a8449da9fcf6d1546afa498762e1e8cbecbebe2f (the gain commit; this READY commit follows it)

Lane LANE-MS (Meadows). Rows F38#30 (P2-012 Burrow Warrens hillside, board 5.10) and F38#24 (P2-014 distant mountains, board 4.42). They share the Warrens walk_02/walk_03 frames. Owner decision 7 Nov: re-seat the floating hillside shell into the terrain, keeping the entrance and the route. Art-row cap.

**Shipped (CPU, quick_judge `ralph/reports/LANES/LANE-MS/qj/F38-30_F38-24-354ca63271b5-11071915/`, three code-blind judges, calibration r 0.92, RMSE 0.46):**
- `data/config/burrow_warrens.json:bank.hill_shell.at` y changes from -0.8 to -5.8, with `_why_seat_on` recording the scores.
  - **F38#30: 2.95 -> 3.51 (+0.56).** All three judges preferred it or tied.
  - **F38#24: 3.28 -> 3.51 (+0.23).**
  - This batch maps low against the board's scale (board 5.10 / 4.42); compare within the batch only.
- Presentation only: no collider, route, save or entrance change. The mouth clip_box is in warrens space and unchanged, and the route frame still shows the shell arch framing the real doorway.
- Test: new `tests/test_warrens_shell_seat_f38_30.gd`. Ran test_warrens_shell_seat_f38_30 and test_warrens_hill_shell_r2: 3 tests, 11 assertions, 0 failed.
- Inert probe (not a test): `tests/probe_warrens_shell_seat.gd` prints the shell and Bank bounds in warrens space, the shell's lowest rim per 15 degrees against terrain, and the shell and Bank height over each walk stand.

**Diagnosis (probe numbers):**
- The warrens origin is at world y 3.80, and `_floor_y` is 5.39 (the floor is raised over the highest terrain under the footprint).
- The shell base was flat at warrens y -0.8 (world 3.0), but the meadow round the site falls to world 0-2. Its front lip therefore hung over the walk route with sky under it (walk_01 and walk_02). Sunk 5 m, the lip meets the grass.
- **walk_03 is not fixable by the shell.**
  - Its stand (-352.5, 2635.8) is local (21.4, 15.1), just outside the hall's +x wall, and it is inside both the shell (top 29.1 m over it) and the hidden procedural Bank (top 26.5 m).
  - The Bank's two-sided collision surface sits 19.25 m over the stand. The capture's terrain-height teleport puts the player in a cavity under the hill.
  - From there the camera looks up at the chamber shells (floor about world 9.2, roofs about 23), which float over the meadow. The legacy floor and wall box visuals are hidden by `organic_entry_finish.hide_legacy_box_visuals`.
  - All three judges named these "floating dark blocks" as the dominant defect on both rows.

**Not shipped / left OFF:**
- `bank.hill_shell.r2` (detail grain, hide MoundGrowth): captured over the seat and visually identical at these stands, so it was not judged and stays OFF.
- `capture_stands.json buried_stand_guard` with `window_m` 30: captured only, not judged, and not changed in the tree. The guard now fires ("solid geometry 19.25m overhead"), but both fallback offsets (18 m and 26 m) are also under the hill, so walk_03 is unchanged. It is a cross-cutting capture flag, so it is the coordinator's call.

**Judges' remaining asks:**
- Remove or ground the floating dark slabs (walk_03).
- No continuous mountain range or blue distance on the stronghold-approach horizon (F38#24 frame 3). A Team Tether keep reads as floating above the horizon there.
- Flat yellow grass decals.

**Next idea (needs a decision, so not done here):**
- The Bank and shell are built from the raised cave floor, not from terrain. Where the meadow dips, the hill's rim floats about 19 m over a walkable cavity beside the hall.
- The real re-seat is in `burrow_warrens.gd` `_bank_surfaces`: blend each bank vertex's height to the terrain over a rim band (y = lerp(terrain, plane + h, smoothstep(0, band, h))). The rim then meets the ground in both the visual and the collision mesh, closing the cavity, and a matching `fit_to: ["Bank"]` shell follows it.
- This changes Warrens collision outside the route notch, so it needs `tests/smoke_warrens.gd` and the walked-route probe re-run. That is a collision change, not a presentation flag, so I am handing it to the coordinator rather than taking it under this lane's art cap.
- With the cavity closed, enable the stand guard (window 30) so the capture stops seating the player inside the hill.
