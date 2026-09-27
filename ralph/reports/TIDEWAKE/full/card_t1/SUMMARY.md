# Card T1 "Tidewake retained-five water route", with the Garden and Deep Watch rest points

**Result:** CARD T1 PASS. All 17/17 suite steps exit 0 at one checkout: `tb/tidewake-full`
dbe43195e978bab39f9f4b2ab62a2d8a68cd2150, 0 dirty tracked files (`SHA.txt`). The full table is
in `results.tsv`, with one log per step.

Command: `tests/card_t1_tidewake_retained_five.sh --stage=all --out=ralph/reports/TIDEWAKE/full/card_t1`

## What changed from Tidewake-B's T1 run (b514938e, `../../b/card_t1/`)
- **Rest points.** The owner's 13:33 Garden and Deep Watch rest points are on this branch: a
  cherry-pick of Tidewake's 29dc85e9, the same commit the clean F15#2 head carries.
  - Rebaking on this branch gave byte-identical tiles; only the manifest config hash changed.
  - `salt_crown_to_drowned_garden_sheltered` (7 shoals) and
    `sluice_isle_to_deep_watch_sheltered` (3 shoals) are now `human_level_0`, optional and
    need no mount.
- **Phase C** swims both crossings **out and back** from Salt Crown and Sluice Isle, with the
  same 15% zigzag and level-0 pin as the mandatory chain.
- **B3** counts the 5 remaining mount-only routes. A new **B4** asserts that both
  Garden/Deep Watch sheltered routes are `human_level_0`, optional and mount-free (the
  coordinator's "check B3's Garden routes").
- **Two-peer rider-identity proof.** It raced once, at fa287aa4: the host read the returning
  mount's swim mode as 0 before its state arrived. The scenario now waits for
  `remote_mounts.<peer>.applied_aquatic.mode == 2` before the identity check (3b9c9721).

## The card (card_integrated.log)
CARD T1 PASS: 13 items, 0 failed, 982 assertions.

| Route | Per-hop minimum stamina % |
|---|---|
| first_shore → reedhaven | 31.21 |
| reedhaven → brine_steps | 75.83 / 75.55 |
| brine_steps → shellwatch | 82.03 / 81.85 |
| shellwatch → tidal_cradle | 73.31 / 73.07 |
| tidal_cradle → salt_crown | 38.49 / 57.21 / 57.95 / 57.21 / 38.63 |
| **salt_crown → drowned_garden** (rest points) | 46.01 / 65.14 / 65.14 / 65.14 / 65.09 / 65.09 / 65.09 / 46.05 |
| **drowned_garden → salt_crown** | 52.17 / 67.99 / 67.94 / 67.94 / 67.94 / 67.99 / 67.94 / 52.03 |
| salt_crown → sluice_isle | 44.09 / 63.09 / 63.88 / 63.04 / 44.09 |
| **sluice_isle → deep_watch** (rest points) | 50.30 / 69.76 / 69.76 / 50.30 |
| **deep_watch → sluice_isle** | 56.93 / 72.84 / 72.84 / 56.83 |
| sluice_isle → veilfall | 30.19 / 49.27 / 49.32 / 50.02 / 49.27 / 49.23 / 30.23 |

- C1 covers 48 hops (24 mandatory + 24 side-trip) with the original five, no swimmer and a
  mount refused.
  - The worst hop is 30.19%, against the ≥20% bar.
  - Commanded steering is 1.155× path length (15% deviation).
  - There are 0 position writes and 0 stamina writes during the chain.
  - Every hop ends on the authored safe landing.
- The other items:
  - A1/A2: arrival with the original five.
  - B1–B4: mount/no-swimmer checks.
  - D1/D2: mid-swim combat pause and resume.
  - E1/E2: drowning, then safe shore and recovery.
  - F1/F2: mid-water save, rebuild and reload, then continue.
- The item lines in the log carry EXPECTED and OBSERVED for each item.

## The rest of the suite (all exit 0 at dbe43195)
- `chain_direct_0_3`: worst 33.17%.
- F12#1–#6 smokes: swimming, original five, death, combat pause, mounted swimming,
  dismount state, reconnect saves, closed-gate seal, sealed-anchor reload.
- `f12_units`: 33 tests, 0 failed.
- Net smokes `net_water_swimming` and `net_water_mounted_swimming`.
- **Two-peer proofs** `proof_f12_combat_pause_two_peer` and
  `proof_f12_remote_rider_identity_reconnect` (host and guest state agree).

## Repeats (the flake rule)
- `smoke_water_combat_pause`, reported intermittent earlier: **5/5 green**. Two runs were in
  the suites at fa287aa4 and dbe43195, plus `repeats/combat_pause_repeat_{1,2,3}.log`
  at dbe43195.
- `proof_f12_remote_rider_identity_reconnect` after the fix: **6/6 green**. Five runs at
  3b9c9721 (`repeats/rider_identity_repeat_*_tail.log`) plus the suite run at dbe43195.

## Shortcuts disclosed
- Declared Water-arrival start from the dry fixture
  (`tests/helpers/tidewake_b_water_arrival_dry_fixture.gd`): Stormwood completion flags set
  through the ledger, the realm key treated as spent. No earned S3 save exists.
- The original five at L41–44 are granted (`smoke_water_swimming.gd` ORIGINAL_FIVE).
- Every chained route's `required_departure_flag` is set up front. This includes the Salt
  Crown charted flag: its closed-gate tide race also covers the start of the Garden crossing,
  so a Garden trip needs Salt Crown charted, as a story gate. Every dock `unlock_flag` is set
  before phase D.
- Swimming XP is cleared every chain frame (level-0 pin).
- There is one position write after the chain: onto the dry rest shoal
  `tidal_cradle_to_salt_crown_rest_03`, for the fight.
- The wild's HP is capped at 12 once engaged.
- The stamina=0 exhaustion fixture is used in phases E and F.
- The two-peer proofs use loopback ENet and fixture-scenario teleports, as filed for F12.
- The runs are headless, single host except the two-peer proofs. There is no four-peer run.
- **Shared helper.** A diagnostic `print` was added to
  `tests/helpers/earned_roster_replacement_segment.gd` in Tidewake-B's b6ca3408. It comes in
  through the tidewake-b merge. It is diagnostic only and T1 does not use it.
