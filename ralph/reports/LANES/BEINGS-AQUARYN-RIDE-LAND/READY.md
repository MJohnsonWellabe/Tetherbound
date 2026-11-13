# READY: BELOW6-AQUARYN-RIDE landing (F39#8)

STATUS: land, with one test change the coordinator should look at (below)

- **Branch:** `tb/beings-aquaryn-ride-land`, cut from `origin/main` 4f9ae9e2.
- **Verdict:** SHIP. LANE-JUDGE `G-below6-aquaryn-ride-c673.md` (tb/judge 83d0819f), GPU High, base and arm: F39#8 5.97 -> 6.32 (+0.35), 3/3 prefer the arm, no loss; defect PRESENT -> PARTIAL 3/3.
- **Change:** `data/config/water_mount_presentation.json` `mounts.water_aquaryn.deep_swim_1113.enabled` true, with `_why_on`. The ridden Aquaryn sits 1.6 m deeper (was 1.0); the rider is waist-deep.
- **Pin test:** `tests/test_uiposes_water_mount.gd::test_f39_8_deep_swim_pin` now asserts ON, the `_why_on` citation, the resolved 1.6 m sink, chest above the sea and seat below it.

## The test change to look at
`tests/smoke_water_mounted_swimming.gd` had a second copy of the old rule: "rider art origin remains above sea". With the flag ON it fails for `water_aquaryn` (the rider's origin is below the surface by design). The arm's decision record (`BELOW6-AQUARYN-RIDE/QUESTION.md`, option A, chosen by the coordinator on 13 Nov) replaces that rule with "the rider's head and chest stay above the sea"; the earlier lane changed the unit pin but missed this smoke.

What I changed: for a mount whose row has `deep_swim_1113` on, the smoke checks the rider's chest stays above the sea (`rider_chest_above_art_m`, 0.75 m, above 0.15 m). Every other mount keeps the dry-rider check unchanged. This applies the decided rule; it does not remove a check. If the dry-rider rule should stand instead, do not land this branch: option B (raise the seat) is the alternative and is a larger change.

## Tests run
- `test_uiposes_water_mount.gd`, `test_water_mount_dismount_replication.gd`, `test_water_mounted_replication.gd`: 8 tests, 31 assertions, 0 failed.
- `smoke_water_mounted_swimming.gd`: before the change it failed at `water_aquaryn rider art origin remains above sea` with the flag ON. After the change `water_aquaryn` passes every check and the smoke moves on to `water_mosshell`. The full five-mount run had not finished on this CPU machine when this was written (about 8 minutes a mount under Mesa); the other four mounts take the unchanged branch of the check. **Please let CI run this smoke on the landing PR.**

## Not closed
F39#8 is 6.32. Next asks (3/3): a stroke and bob so the frames differ; a trailing V-wake and bow spray instead of the foam disc; a side-offset ride camera so the mount's head reads.

## Files
The config flag, the unit pin, the smoke change and this folder.
