STATUS: land

# tb/land-cs-overlook-join-land: Stormward Overlook ridge join (F40#15)

**Verdict:** GPU High, `ralph/reports/GPU-PASS/1108/G-below6-overlook-join-c673.md` on tb/judge ae67d0a5 (confirming batch, r 0.945, RMSE 0.45): overlook route_day, vista_dusk and walk_01 4.86 -> 5.28 (+0.42, 3/3 prefer; defect PRESENT -> PARTIAL 3/3). The long thin black line across the grass at the trainer's feet is gone. No-loss: sky shrine 6.71 -> 6.76, high perch court 5.49 -> 5.60.

**Flag:** `data/config/cloudreach_visual.json landmass.overlook_ridge_join_1113`, ON with `_why_on`. Arm built by LANE-BELOW6 (`BELOW6-OVERLOOK-JOIN/ARM.md`); the code is already on main.

**Files (3):** `data/config/cloudreach_visual.json`, `tests/test_overlook_ridge_join_flag.gd` (now the ON pin), this READY.md.

**Scope:** world geometry: the approach ridge rows lift to meet the overlook ledge (a max, never lowers), and the collider follows.

**Tests run (13 Nov, on this branch):**
- Unit, one run of six files: 43 tests, 235 assertions, 0 failed (`test_overlook_ridge_join_flag`, `test_cloudreach_environment`, `test_vis_cloudreach_landed`, `test_cloudreach_cause`, `test_near6_cr_judged_on`, `test_below6_knifeedge_landed`).
- Route smoke with the flag on: `tests/smoke_cloudreach_waterward_overlook_join.gd`, headless, exit 0, "CLOUDREACH WATERWARD OVERLOOK PASS", 386.3 m walked.

**Not a close:** the F40#15 job frame walk_03 does not change with this flag. Remaining (3/3): a dark wedge slab beside the path, open-backed wall slabs, no pale-stone terrace paving.
