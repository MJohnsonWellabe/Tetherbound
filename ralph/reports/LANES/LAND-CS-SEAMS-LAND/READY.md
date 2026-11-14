STATUS: land

# tb/land-cs-seams-land: Stormward Overlook buried approach pavers not built (F40#15)

**Verdict:** GPU High, `ralph/reports/GPU-PASS/1108/G-land-cs-overlook-seams.md` on tb/judge fd20f845 (confirming batch, r 0.910, RMSE 0.58): F40#15 walk_02/walk_03 5.10 -> 5.41 (+0.31, 3/3); the overlook's other views (route_day, vista_dusk, walk_01) 5.10 -> 5.41 (+0.31, 3/3). The base's green slab, walk_03 slab and cobble strip are gone.

**Disclosed, not counted by LANE-JUDGE:** the High Perches no-loss set read 6.68 -> 6.38 (−0.30, 0/3). All three judges put it on creature staging (a wyvern centred on base, cropped on the arm); the arm changes only the Stormward Overlook (piece 12), the court is described identically, and the 64 Perches frames differ by a mean of 1.9 (rain and spawns). LANE-JUDGE offers a fixed-seed re-capture if you want it proven before merging.

**Flag:** `data/config/cloudreach_stormward_overlook_visual.json paver_strips_1113`, ON with `_why_on`.

**Files (5):**
- `scripts/world/cloudreach_stormward_overlook.gd`: `build_pavers(cfg)`; the paver loop runs only when it is true (the only change to this file).
- `data/config/cloudreach_stormward_overlook_visual.json`: the flag ON.
- `tests/test_overlook_paver_strips_flag.gd` (new): the ON pin (verdict file and score), OFF still builds the pavers.
- `tests/test_cloudreach_stormward_overlook.gd`: the approach-paver count goes 4 -> 0 with a comment citing the verdict.
- this READY.md.

**Scope:** presentation only. The pavers had no collision; the trail is a separate surface.

**Tests run (14 Nov, on this branch):**
- Unit, one run of eight files: 18 tests, 100 assertions, 0 failed (`test_overlook_paver_strips_flag`, `test_cloudreach_stormward_overlook`, `test_overlook_ridge_join_flag`, `test_overlook_ruin_collision_flag`, `test_overlook_pane_fix`, `test_below6_overlook_pane_landed`, `test_cloudreach_environment`, `test_earned_stormward_handoff`).
- Route smoke: `tests/smoke_cloudreach_waterward_overlook_join.gd`, headless, exit 0, "CLOUDREACH WATERWARD OVERLOOK PASS", 386.2 m.

**Not a close.** Remaining (judges): the dark wedge strip at route_day and vista_dusk and the walk_02 strip at the trainer's feet (the overlook ledge's side face; parked after four attempts, see LAND-CS NOTE), the rampart and tower over the void at walk_03, the blurry dirt-path decal and flat green plane, and pale stratified stone terrace with a carved arch (new art).
