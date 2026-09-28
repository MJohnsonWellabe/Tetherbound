# M2 earned spine: what blocks the continuous run (Cards lane, main 33afd91f)

The M2 run is `TB_WORLD_SEED=15 tests/smoke_four_biome_continuous.gd -- --reload-at-transitions --route-ledger --m4-finale --through-meadows`
from a new game. It stops at the first named fight the harness-piloted earned five loses; the harness has no heal-and-retry.

| Stage | Main settings (`trainer_ally_lateral_m` 2.4) | Local diagnostic (`trainer_ally_lateral_m` 0.0, not committed) |
|---|---|---|
| Opening through tournament | PASS 4/4 (M1 card) | PASS 3/3 |
| South Bridge guardian | **FAIL 0/3** (2 past the 9000-frame bound, 1 lost) | PASS 3/3 (`diag_lateral0_A1/A2_bridge_pass.txt`, `diag_lateral0_fresh_to_relay.txt`) |
| Warrens guardian and exit, reload | not reached | PASS 1/1 |
| Relay captain | PASS 1/1 once the harness reads the victory lines (`resume_relayhall.txt`) | FAIL 1/1 before that harness fix (world input held by the new victory lines) |
| Three Sigil captains | PASS 3/3 runs (Riverwatch, Field, Ridge 5/5 rounds each) | Riverwatch PASS 2/2, then **Captain Field lost 2/2** (`resume_hallL1/L2.txt`) |
| Hall patrol and courtyard | PASS 3/3 | not reached |
| Keeper Hald (Hall elite) | **FAIL 0/3, lost** (`resume_relayhall.txt`, `resume_hall1/2.txt`) | not reached |
| Warden, Veridian, Cloudreach | not reached | not reached |

Resumed runs start from the diagnostic's own earned checkpoints (`relay_disabled_and_mill_crossed`, a lateral-0.0 save), so they are debug only.

## Causes and owners
1. **South Bridge guardian regression**: `3f04ece8` (F04#2) `trainer_ally_lateral_m` 2.4 applies to every trainer fight. Owner: Meadows lane (`BRIDGE_GUARDIAN_REGRESSION.md`).
2. **Harder Meadows captains**: `b20d23ab` (F04#7, owner ruling 11/12) raised Hald's and the captains' power. Ruling 12 measures that a masher loses at least one named fight in 94-100% of playthroughs, and the earned-route pilot plays like one. With no heal-and-retry, one loss ends the run. Owner of the difficulty: Meadows lane / Balance (F04#7).
3. **Harness (fixed on `tb/cards`)**: the relay segment waited 120 frames for world input while the captain's new victory lines (d541cb04) held it; it now reads them at the Hall helper's pace.

## What M2 needs next
One of these, then one uninterrupted run to Cloudreach:
- (a) the route harness models a player's heal-and-rechallenge after a named-fight loss, disclosed as a relaxed-proof harness aid (Cards lane, harness only); or
- (b) a reader-policy pilot on the earned route (Meadows lane owns the pilot policies used by `smoke_meadows_named_c2c3.gd`).

Either way the bridge regression (1) must be fixed first, because it also times out rather than only losing. Fight feeders F04#1, #2, #6 and #7 remain the Meadows lane's.
