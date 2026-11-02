# CREATURES-RALPH GPU queue

Each entry gives the species, the commit and the capture. All entries use `capture_f36_poses.gd -- --species=<list> --whole-body --context`, Forward+ 1920x1080, High first, against the shipped arm on main.

- **r9 Duskhush** (r12, CPU 4.61 → 6.30). Commit: see `git log --oneline -1 -- ralph/reports/LANES/CREATURES-RALPH/r12`. Arms:
  - B is `remake_owner1101_duskhush` pointing at `candidate_r9/models/creature_duskhush_r9.glb`;
  - A is main, which points at the owner1101 remake.
- **r9 Aquaryn** (r13, CPU 4.44 → 6.54) and **r9 Mangrove Monitor** (r13, CPU 5.02 → 5.69). The flags point at `candidate_r9`. The Monitor's red-brown dorsal stripe needs a red check (see `r13/VERDICT.md`).
- **r10 Staticub** (r16, CPU 5.34 → 8.55), **r10 Sirenseal** (4.35 → 6.95) and **r10 Skyrill** (4.79 → 7.34). Each remake flag points at `candidate_r10/models/creature_<species>_r10.glb`; A is main, which points at owner1101.
- **Thundertunnel** (r17, CPU 2.93 → 5.36): the GLB carries the hit and faint fixes, and `creatures_ralph_thundertunnel_velvet` is ON. A is main.
- **One GPU job for all seven:** `--species=aquaryn,duskhush,mangrove_monitor,staticub,sirenseal,skyrill,thundertunnel`.

## Ready for GPU (r19 keeps; A is main)

- **Staticub r10:** the faint is settled; the GLB is CPU 7.09 → 7.22.
- **Skyrill r10:** `creatures_ralph_skyrill_r10_lift` is ON, CPU 6.15 → 6.37.
- **Torrentoad:** `creatures_ralph_torrentoad_toad` is ON (already in cr1102b).
- **Job:** `--species=staticub,skyrill`.
- **Not kept in r19:** Aquaryn matte scales (−0.05) and the Mangrove Monitor faint settle (tie). Both need new art: Aquaryn a value ramp and a natural finish; Mangrove Monitor a lying faint and its dorsal stripe moved off red.

## READY next fixes (coordinator 2 Nov ~12:40 UTC); the first job after the origin/main merge needs a fresh main control (main1102c)

1. **Mangrove Monitor r9:** a faint that lies down (r19's settle tied: it still crouches on folded legs), and the red-brown dorsal stripe moved off red.
2. **Aquaryn r9:** a natural finish with a back-to-belly value ramp. r19's matte scales scored −0.05, because the scale detail does not read at the stage camera.
3. **Duskhush r9:** one clear elemental trait and a cleaner faint.
4. **Torrentoad:** a grounded, squat toad pose and a less glossy skin.
5. **Tuskroot:** keep main's value, add rim light and a slightly larger read against the ruler. Don't lighten the hide.
