# CREATURES-RALPH GPU queue

Each entry gives the species, the commit and the capture. All entries use `capture_f36_poses.gd -- --species=<list> --whole-body --context`, Forward+ 1920x1080, High first, against the shipped arm on main.

- **r9 Duskhush** (r12, CPU 4.61 → 6.30). Commit: see `git log --oneline -1 -- ralph/reports/LANES/CREATURES-RALPH/r12`. Arms:
  - B is `remake_owner1101_duskhush` pointing at `candidate_r9/models/creature_duskhush_r9.glb`;
  - A is main, which points at the owner1101 remake.
- **r9 Aquaryn** (r13, CPU 4.44 → 6.54) and **r9 Mangrove Monitor** (r13, CPU 5.02 → 5.69). The flags point at `candidate_r9`. The Monitor's red-brown dorsal stripe needs a red check (see `r13/VERDICT.md`).
- **One GPU job for all three:** `--species=aquaryn,duskhush,mangrove_monitor`.
