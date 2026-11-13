STATUS: land

# tb/land-cs-overlook-solid-land: Stormward Overlook solid ruin and reviewed walk stands (F40#15)

**Verdict:** GPU High, `ralph/reports/GPU-PASS/1108/G-below6-overlook-solid-c673.md` on tb/judge ae67d0a5 (confirming batch, r 0.945, RMSE 0.45): F40#15 walk_02 and walk_03 4.23 -> 5.60 (+1.37, 3/3 prefer). route_day, vista_dusk and walk_01 level (4.86 = 4.86). F40#15 row read with this change: 5.60 High (walk pair only).

**Flag:** `data/config/cloudreach_stormward_overlook_visual.json ruin_collision_1113`, ON with `_why_on`: the overlook's piers and ruined wings are solid, so nobody (and no capture stand) can stand inside the masonry and see it as translucent planes. Arm built by LANE-BELOW6 (`BELOW6-OVERLOOK-SOLID/ARM.md`); the code is already on main.

**Capture stands:** two reviewed `heading_overrides` rows in `data/config/capture_stands.json` (walk_02_day, walk_03_day), as judged. Capture tooling only.

**Files (4):** the two configs, `tests/test_overlook_ruin_collision_flag.gd` (now the ON pin, plus a stand check), this READY.md.

**Read the gain honestly:** most of the +1.37 is the new stands, which face the arch instead of a wall. They now show dark slab and plank strips on the grass that the old stands looked away from (defect PARTIAL 2/3, PRESENT 1/3). Those strips are the next job on this row.

**Tests run (13 Nov, on this branch):**
- Unit, one run of six files: 24 tests, 92 assertions, 0 failed (`test_overlook_ruin_collision_flag`, `test_capture_stand_heading_override`, `test_warrens_walk03_stand`, `test_cloudreach_environment`, `test_vis_cloudreach_landed`, `test_below6_overlook_pane_landed`). The run prints one "Parse JSON failed" line; main prints the same line without this change.
- Route smoke with the flag on: `tests/smoke_cloudreach_waterward_overlook_join.gd`, headless, exit 0, "CLOUDREACH WATERWARD OVERLOOK PASS", 386.0 m walked.

**Lands independently of** `tb/land-cs-overlook-join-land` (different config blocks; `cloudreach_visual.json` is not touched here).

**Not a close.** Next asks from the judges: clear the dark slab and plank strips at walk_02 and walk_03 and the grey ramp wedge, cap the open-backed wall slabs, pale-stone terrace paving, and capture the windscar aerie vista_dusk (the row's second job frame).
