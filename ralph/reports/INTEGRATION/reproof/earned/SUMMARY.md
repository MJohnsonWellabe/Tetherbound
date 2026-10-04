# Re-proof: earned scripted runs. Summary

Code under test: **826d273c3dbdcb1002034812041b1dfb59d84120** (origin/tb/integration; main is now fe7a611ab = 826d273c3 plus three test-only net-smoke fixes). Godot 4.7.stable.official.5b4e0cb0f, Linux, 4-core container; engine runs were one process at a time.

Two facts about this commit shape every row:
1. **F49 default path.** `smoke_four_biome_continuous.gd` now runs the F49 portal campaign by default, and that path refuses to start while `session.redesign_portal_runtime_enabled=false`. The `--through-*` prefixes need `--legacy-order-diagnostic` ("never F49 campaign proof"), which every F02/F17 row used.
2. **v27 fixtures are refused.** Every committed earned fixture (`c1_arrival`, `checkpoints/seed4_hall`, `checkpoints/c1_flight_trained`, the Stormwood `full_run/checkpoints/*.tgz`, and `f03_lure_saves`) is save v27. RD-35 refuses those by design (`RESET_MAX_VERSION := 27`). Those rows are ERROR, blocked on fixture regeneration (coordinator ruling, 17:49Z), not product FAILs.

| Item | Verdict | Evidence |
|---|---|---|
| F02#0 | FAIL | `F02-0.md` (seed 15 through-bridge: 4th practice-fight loss after potions ran out) |
| F02#1 | FAIL | `F02-1.md` (through-warrens reload, rolled seed: team router "no current open gate route") |
| F02#2 | FAIL | `F02-2.md` (through-relay reload, rolled seed: walker "contact observation cap") |
| F02#3 | FAIL | `F02-3.md` (seed 15 through-hall reload: walker "lost grounded floor" toward TrailGate) |
| F02#4 | FAIL | `F02-4.md` (no reload transition reached on any chain run) |
| F02#6 | FAIL | `F02-6.md` (seed 15 died before team_ready; seed 1 lost a training fight, a solvency finding; seed 26 hit the walker contact cap; extra seed 4 `repeated_wilds []`) |
| F02#7 | FAIL | `F02-7.md` (ledger stopped at the village; A7 [] and no windows over 679 m only) |
| F03#0 | ERROR | `F03-0.md` (seed4_hall v27 refused by Game.load_game; no frames, no judge) |
| F03#1 | ERROR | `F03-1.md` (same) |
| F06#1 | ERROR | `F06-1.md` (c1_arrival v27: incompatible_old_version) |
| F06#2 | ERROR | `F06-2.md` (same) |
| F06#3 | ERROR | `F06-3.md` (same) |
| F06#5 | FAIL | `F06-5.md` (unit PASS 6/13/0; solo v27 ERROR; two-peer step #9 enter_realm "no verdict", route order: scenario lacks the legacy_physical_crossings_fixture step) |
| F08#0 | ERROR | `F08-0.md` (c1_arrival v27) |
| F09#0 | FAIL | `F09-0.md` (fixture-start continuous run: first charged Stormglass node did not set first_stormglass_gathered) |
| F09#3 | ERROR | `F09-3.md` (swcp 3_rootgate/4_core v27 refused at title Load) |
| F11#0 | FAIL | `F11-0.md` (marrow press PASS; earned Dynamo segment not reached because of the F09#0 failure) |
| F17#4 | FAIL | `F17-4.md` (seed 4 through-tournament: camp "hammer hotbar input did not equip the earned tool") |
| CH-Cloudreach#C1 | ERROR | `CH-Cloudreach-C1.md` (c1_arrival v27, shared with the F06 runs) |

**Totals:** 19 items: **PASS 0, FAIL 11, ERROR 8.**

Trimmed logs (each under 200 KB) are in `logs/`.
