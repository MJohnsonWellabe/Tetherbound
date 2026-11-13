# READY: tb/beings-poses-land (F36#92 and F39#8)

STATUS: land (one test change to look at, in the Aquaryn READY)

One branch, as the coordinator asked, cut from `origin/main`. It holds two shipped arms, each with its own READY:

| Arm | Row | Verdict (GPU High, tb/judge 83d0819f) | READY |
|---|---|---|---|
| BEINGS-WMONITOR-GROUND | F36#92 | 6.68 -> 7.03 (+0.35, 3/3), G-beings-wmonitor-ground.md | `../BEINGS-WMONITOR-GROUND-LAND/READY.md` |
| BELOW6-AQUARYN-RIDE | F39#8 | 5.97 -> 6.32 (+0.35, 3/3), G-below6-aquaryn-ride-c673.md | `../BEINGS-AQUARYN-RIDE-LAND/READY.md` |

- **Tests run on this branch:** the two pin tests and the related settle and water-mount tests 24 tests, 153 assertions, 0 failed.
- **Look at:** `tests/smoke_water_mounted_swimming.gd` (Aquaryn READY). CI should run that smoke on the PR; it did not finish all five mounts on CPU here.
- The single-arm branches `tb/beings-wmonitor-ground-land` and `tb/beings-aquaryn-ride-land` carry the same commits and are not needed.
