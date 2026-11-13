# READY: BEINGS-WMONITOR-GROUND landing (F36#92)

STATUS: land

- **Branch:** `tb/beings-wmonitor-ground-land`, cut from `origin/main` 4f9ae9e2.
- **Verdict:** SHIP. LANE-JUDGE `G-beings-wmonitor-ground.md` (tb/judge 83d0819f), GPU High, base and arm: F36#92 6.68 -> 7.03 (+0.35), 3/3 prefer the arm, no loss. Only faint-050 changes; the other three tiles are identical.
- **Change:** `data/config/creature_pose_settle.json`, `faint.per_species.water_mangrove_monitor.crumple.limb_sink_frac` 0.15 -> 0.5, with `_why_limb_sink`. One species, faint only, presentation only.
- **Pin test:** `tests/test_beings_wmonitor_ground_landed.gd`.
- **Tests run:** that file plus `test_things_faint_ground.gd`, `test_cause_poses_settle.gd`, `test_things_hit_per_species.gd`, `test_fulgocobra_faint_end_pose_flag.gd`: 16 tests, 122 assertions, 0 failed.
- **Not closed:** High is 7.03 on a batch that ran about 0.6 strict (the same base read 7.47 on the earlier panel). The row stays open. Next asks (3/3): lighter dorsal and flank value with rim light; limbs slump and head rests in faint-100; a readable teal stripe.
- **Files:** the config value, the pin test, `ralph/reports/LANES/BEINGS-WMONITOR-GROUND/` (arm) and this folder.
