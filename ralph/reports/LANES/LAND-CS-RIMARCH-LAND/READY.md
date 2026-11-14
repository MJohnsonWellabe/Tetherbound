STATUS: land

# tb/land-cs-rimarch-land: RIMSEAT (F40#17) and the ARCHSTAND capture stand (F40#3)

One branch for both, as the coordinator asked, cut from current main 8abc4ad70.

## Verdicts (GPU High, LANE-JUDGE)
- `ralph/reports/GPU-PASS/1108/G-lcs-rimseat.md` (tb/judge d0e475d15): **SHIP.** F40#17 6.05 -> 6.68 (+0.63, 3/3); the tan cluster sits on the lawn, floating defect FIXED 3/3. Crown court no-loss +0.31 (3/3). The arrival +0.58 is creature staging, not counted.
- `ralph/reports/GPU-PASS/1108/G-lcs-archstand.md` (tb/judge d0e475d15): **RE-BASELINE.** F40#3 6.37 on the new arch stand against 5.74 on the old (+0.63, 3/3); adopt the stand as F40#3's fixed camera. The board's F40#3 is 6.37.

## What lands
- `data/config/cloudreach_physical_runtime.json rim_pickup_seat_1114` ON with `_why_on`: the stamina (tan) rim find 1.2 m back from the lip; speed and wild keep their spots. Same ids, items, counts and claims.
- `scripts/world/cloudreach_physical_runtime.gd`: the seat flag is read first in `_pickup_override` (the only change to this file).
- `data/config/mushroom_pickup_variants.json rim_glow_1113.scale` 0.45 -> 0.3, as judged with RIMSEAT (with `_why_scale_0_3`). The finds still glow.
- `data/config/capture_stands.json approach_overrides.candidates_1113` ON with `_why_on`: both arch frames stand on the island's south rim facing the arch. Capture tooling only.
- Tests: `tests/test_rim_pickup_seat_flag.gd` (ON pin, verdict and score; only the stamina find moves, closer to the crown centre; read first) and `tests/test_arch_stand_candidate.gd` (ON pin; both arch identities resolve to the arch centre, heading 0).

## Tests run (14 Nov, on this branch)
- 12 files in one run: 56 tests, 8,851 assertions, 0 failed (`test_rim_pickup_seat_flag`, `test_arch_stand_candidate`, `test_rim_glow_flag`, `test_below6_perch_rim_landed`, `test_cloudreach_physical_runtime`, `test_capture_approach_overrides`, `test_capture_stand_heading_override`, `test_warrens_walk03_stand`, `test_mushroom_natural_cluster`, `test_item_cache_pickup`, `test_pickup_glow`, `test_cloudreach_pickup_density`).
- 3 more files that read the physical runtime config: 54 tests, 388 assertions, 0 failed (`test_cloudreach_counterweight_seal`, `test_cloudreach_no_legendary_offer`, `test_cloudreach_old_wind_observatory_presentation`).

## Not in this landing
The griffin clipping the tower (BEINGS-PERCH-CLEARANCE); contact shadows under the clusters (a ride-along candidate); the observatory architecture (new art); the arch's road deck and rubble and the beacon's stone drum (next F40#3 asks).
