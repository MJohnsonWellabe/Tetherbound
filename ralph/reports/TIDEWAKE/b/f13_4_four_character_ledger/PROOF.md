# F13#4: four-character supply ledger, six Tidewake local chains

Criterion: ACCEPTANCE §6.1 **F13#4**, "Six selected local chains ... leave four-character supplies solvent
without a new catch or repeated wild", checked with the PROGRESSION §6 method: a ledger built from reachable
source rows, four characters sharing permanent nodes, four personal kits plus shared structures counted once,
supply at least 150%, and an emergency reserve before the gauntlet.

Test: `tests/test_tidewake_b_four_character_ledger.gd`. It is pure data and reads only shipping Tidewake configs.
Data changes: **none**. The ledger is solvent as shipped, so no pickup, harvest or rest-shoal row was added.

## Command
```
XDG_DATA_HOME=$(mktemp -d) $HOME/godot-bin/godot --headless --path . --script tests/run_tests.gd -- --only=tidewake_b_four_character_ledger
```
Result: `5 tests, 66 assertions, 0 failed` (Godot 4.7, headless, Linux). The full output is in `unit_ledger.log`.

## Model (read from data, not invented)
- **Gate stages** come from `water_world.json` docks. The mandatory chain is First Shore 0, Reedhaven 1,
  Brine Steps 2, Shellwatch 3, Tidal Cradle 4, Salt Crown 5, Sluice Isle 6, Veilfall 7. Lantern Cove and Gull Rest
  take their parent's stage. Drowned Garden and Deep Watch sit behind docks that need `swim_saddle` plus an active
  compatible swim mount. Those two islands are **excluded from all supply**, which is conservative.
- **Supply:** harvest rows in `water_pickups.json`. At runtime each one is world-once through
  `harvest_node:order:<id>`, and the first gatherer keeps the yield. Basic heals are `potion_small` and
  `potion_large` pickups under `existing_world_pickup_policy`, which is also world-once. No trainer payout, wild
  encounter, enemy drop or catch is counted.
- **Debits:**
  - Dock action costs. `reedhaven_repair` (6 reed, 4 driftwood) is world-once and due by stage 1.
  - Local chain step costs. `lastlight_shelter_supply` (4 driftwood, 4 reed) is world-once and due by stage 7.
  - The Swim Saddle recipe (8 reed, 6 driftwood, 4 reef stone) is a **personal kit ×4**, due by stage 5, the first
    saddle-gated dock (Salt Crown to Garden). It matches `water_swimming.json::saddle_recipe`.
- **Check:** for every item and every due stage `s`, all debits due by `s` must be covered by supply from
  stages ≤ `s`. The test asserts three things: supply ≥ need, supply ≥ 150% of need, and an even four-way
  split of what remains after the world debits covers one personal kit.

## Ledger (four characters)
| item | by stage | world-once | personal (×4) | required | reachable supply | margin | per-character even split |
|---|---|---|---|---|---|---|---|
| reed_fiber | 1 (Reedhaven repair) | 6 | 0 | 6 | 60 | 10.00× | 13 |
| reed_fiber | 5 (saddle) | 6 | 8 | 38 | 117 | 3.08× | 27 |
| reed_fiber | 7 (Lastlight) | 10 | 8 | 42 | 129 | 3.07× | 29 |
| driftwood | 1 | 4 | 0 | 4 | 42 | 10.50× | 9 |
| driftwood | 5 | 4 | 6 | 28 | 99 | 3.54× | 23 |
| driftwood | 7 | 8 | 6 | 32 | 114 | 3.56× | 26 |
| reef_stone | 5 | 0 | 4 | 16 | 64 | 4.00× | 16 |
| reef_stone | 7 | 0 | 4 | 16 | 74 | 4.62× | 18 |

**Emergency reserve before Veilfall** (stage ≤ 6, no swim mount):
- Heals: 35 world-once basic-heal pickups, plus 42 Small Potions craftable from what remains after all debits
  (tide_bloom 42, reed 88). The requirement is 8 (4 characters × 2), and an even split gives each character 19.
- Beds: `water_camp_veilfall` has a free creature bed, and no authored camp carries a cost.
- One viable creature: this is the retained five and is not a Tidewake debit.

## Payouts: who is paid (disclosed, not a solvency failure)
- `side_water_cradle_care`: the 4 Reef Stone come from seam `water:tidal_cradle:harvest:007`. That seam is
  world-once, so **only the first gatherer** gets them. Otto's `grant {berries: 3}` goes to the reporting character
  only, because the step record is world-scoped.
- The six chain reward-pocket Skill Candies (Lantern I, Gull II, Garden II, Deep Watch III, plus Brine and Salt
  Bell I) are `character_once`, so **each character** gets their own.
- The ledger never counts the Cradle stone or the berries as supply that a second character receives.

## Verdict
**Met for the supply ledger:**
- The mandatory route plus the six chains is solvent for four characters.
- Every item clears PROGRESSION's 150% target, with a margin of at least 3.07×.
- The result holds without a catch, a repeated wild, a trainer payout or any saddle-gated island's resources.
- The mandatory docks and sheltered routes require no saddle and no owned swimmer, and the test asserts this.

## Assumptions and remaining gaps (stated plainly)
1. **Tools:** driftwood needs an axe and reef stone needs a pickaxe. The test assumes each character carries
   these from earlier chapters and does not re-derive tool ownership or durability.
2. **First-come contention:** harvest is world-once with no enforced fair share. The per-character column is an
   even-split model. One gatherer can legally take everything, but the margins mean 4 saddles still fit twice over.
3. **Swimmer precondition (owner question):** the Garden and Deep Watch chains (two of the six) need an owned
   compatible swim mount (Cannonback, Aquaryn, Riverdrake, Sirenseal or Mosshell). WORLD designs these as optional
   mounted routes. The only pre-Tidewake wild source is Mosshell (Meadows spawn tables, rare). A character whose
   retained five has no swimmer cannot reach those islands without a **new catch**. In co-op, one swimmer-owner
   completes the world-scoped chain record, but the others cannot follow. So "without a new catch" is met for
   supplies and the mandatory route, but not for personally visiting Garden and Deep Watch.
4. **Per-character payouts (board gap):** turning the Cradle seam or berries into per-participant rewards needs a
   runtime change in `scripts/world/water_local_chain_rules.gd` and the harvest runtime. It is not a data-only
   fix, so it was not implemented. **SHARED-FILE REQUEST** if the owner wants equivalence: add a per-character
   `grant` path (character receipt) for chain report steps.
5. **Rest-shoal harvest proposal:** not needed for solvency, so no rest-shoal rows were added.
6. **Data only:** no runtime or co-op depletion run. Harvest rows are spawned by `water_scene_pickups.gd`, but this
   test does not gather them.

## Independent review (read-only subagent): APPROVE on 22af7276

- **Debits are complete.** Only `reedhaven_repair` (dock actions) and `lastlight_shelter_supply` (local chains) carry costs. The Veilfall controls, the other chain steps, camps and objectives have no item costs. No recipe is required on the main path; the saddle is counted conservatively as ×4.
- **No coin costs.** Tidewake has no shops or fees; coins appear only as payouts.
- **The stage mapping matches** the 7 mandatory docks. The supply rows are world-once through the order ledger, and no regrowth is assumed.
- **The tool assumption is fair.** Axe and pickaxe are base recipes, and repair is free.
- **Assertions are not vacuous.**
- **Non-blocking notes:**
  - Island inference by nearest centre (`test:88`).
  - A whole-file text search of `spawn_tables.json` (`test:279`).
  - A stale `runtime_proven:false` comment in `water_pickups.json`.
  - A sheltered-route loop that could pass on zero routes. **Fixed in the follow-up commit:** it now asserts that at least one sheltered route was checked, giving 5 tests, 67 assertions, 0 failed (`unit_ledger.log`).
