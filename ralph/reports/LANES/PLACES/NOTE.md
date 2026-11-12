# LANE-PLACES NOTE (branch `tb/places`)

## Status, 11 Nov 2026
- **Sent to GPU (arm 1 of 2):** `PLACES-STORMLIGHT/ARM.md` + `CAPTURE.json` + `overlay.json`. P1 Stormwood storm light: `storm_phase_1111` (layered storm sky, held white-violet bolts with a bolt key light, far bolts in Building, mist banks, shafts un-culled) with `distinct_bodies_1111` riding for F41#8. Rows F41#2, #4, #5, #12, #19, #8; riders #6, #13. All code is flag-off on the branch.
- **Sent to GPU (arm 2 of 2):** `PLACES-RAINTIME/ARM.md` + `CAPTURE.json` + `overlay.json`. P2 Cloudreach `rain_time_grade`: rain sky, cloud and fog follow the clock (night rain is night), golden hour keeps warm light, streaks fine and translucent. Rows F40#0, F40#19. CPU: 23:00 and 18:00 rain at the Realm Gate, clear change on both.
- **Two arms are waiting on the GPU, so no third is sent until one is judged.** Building next arms flag-off meanwhile.
- **Next:** P4 dark dawn and night foregrounds, P5 Tidewake dunes, P3, P6, P7 (grass-clear radius).

## Findings worth keeping
- **Stormwood light shafts never drew away from the world origin.** `stormwood_storm_shafts.gd` sets a custom AABB centred on a node that stays at the origin, so the MultiMesh is culled along most of the route (it draws round Cinder Verge only). Judges kept saying "no shafts" after `storm_sky_1101` shipped them. The fix (`shafts.follow_camera`) is inside `storm_phase_1111`.
- **Stormwood Break already shows crawler veins and bolts on main at Cinder Verge** (CPU). The phases differ in the sky but not on the ground, which is what the bolt key light addresses.
- **The "black pools" in F41#8 frames are the dark wet path** filling the lower half of the settlement stands, not the zone pools. Lighter wet earth lost on GPU (swing-1), so this arm leaves it.
- **Cloudreach weather presets are absolute colours** (`world_look.gd _layer_weather`): any weather sky replaces the night or golden sky outright. That is the cause of "night rain reads as day".

## Runbook additions
- Stormwood matrix screening: `.artifacts/places/cap_matrix.sh` pattern (flip the flag, run `capture_stormwood_f10_matrix.gd --stands=… --phases=calm,building,break --no-aftermath`, restore the config). Break frames wait up to 150 fine frames for a bolt; under giant trees on CPU that is about 10 minutes a frame, so screen Break at the open stands.
- `quick_judge.py capture <row> --overlay <file>` gives base and arm frames for a row under `.artifacts/qj/cache/<tree>/{base,<overlay>}/`; untracked new files do not change the cache key, tracked edits do.
- Write scratch frames under `.artifacts/`, not `ralph/reports/VISUAL/` (that path is not ignored).
