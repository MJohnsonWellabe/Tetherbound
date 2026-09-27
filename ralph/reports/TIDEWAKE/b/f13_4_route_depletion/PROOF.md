# F13#4: four-character route depletion run

Criterion: ACCEPTANCE §6.1 **F13#4**, "... leave four-character supplies solvent without a new catch or
repeated wild." This run closes the ledger's gap 6 ("data only, no runtime or co-op depletion run") by spending
the supplies in the production Water scene. The data ledger is `../f13_4_four_character_ledger/`.

## Command
```
XDG_DATA_HOME=$(mktemp -d) $HOME/godot-bin/godot --headless --path . --script tests/smoke_tidewake_b_route_depletion.gd
```
Result: exit 0, `590 checks, 0 failures`, about 4.5 minutes (Godot 4.7, headless, Linux).
The log is `route_depletion.log`, with repeated missing-mesh import noise filtered out.

## What the run does
- It loads `scenes/world/water_archipelago.tscn` with the production pickup streamer, interaction arbiter and host
  ledger.
- Four characters (A-D) with distinct `character_id`s share that one world. For every base-material harvest row
  (reed fiber, driftwood, reef stone, tide bloom) on the no-saddle route (gate stages 0-7, First Shore to Veilfall,
  140 rows), in gate order:
  - the claiming character equips the right tool with a hotbar press;
  - left-stick input approaches the node until the production arbiter offers that node's prompt;
  - one **Interact** press gathers it through `harvest_node.gd`, which calls `WorldLedger._harvest`.
- The run asserts the exact yield landed in that character's satchel and that `harvest_node:order:<id>` was set.
- **Depletion:** after every claim, the next character submits the same harvest intent to the host ledger. It must be
  refused `already_taken` with no item granted, and the body must no longer be resident. 137 of 137 claims passed.
  Nothing regrows.
- **Split:** claim *i* of an item goes to character *i* mod 4. This is the ledger's even-split model, enacted with
  real claims. The Cradle seam is forced to A (see gap 3).
- **Debits**, each paid at the stage it falls due and only from supply gathered by then:

| stage | debit | scope | path | result |
|---|---|---|---|---|
| 1 | `reedhaven_repair` 6 reed + 4 driftwood | world-once | A, real dock prompt + Interact (escrow, ledger `water_dock_action`) | OK |
| 5 | Swim Saddle 8 reed + 6 driftwood + 4 reef stone | personal ×4 | each character, production `Game.craft("water_swim_saddle")` | 4/4 OK |
| 6 | 2 Small Potions each (PROGRESSION §6 emergency reserve before Veilfall) | personal ×4 | `Game.craft("water_small_potion")` | 8/8 OK |
| 7 | `lastlight_shelter_supply` 4 driftwood + 4 reed | world-once | B, real site prompt + Interact (ledger `item_take`) | OK |

## Result per character (after every debit)
| char | claims | gathered reed/drift/reef/bloom | remaining reed/drift/reef/bloom | saddle | potions |
|---|---|---|---|---|---|
| A | 36 | 33 / 30 / 20 (incl. Cradle 4) / 12 | 17 / 20 / 16 (**12 without Cradle**) / 10 | 1 | 2 |
| B | 35 | 33 / 30 / 16 / 12 | 19 / 20 / 12 / 10 | 1 | 2 |
| C | 34 | 33 / 27 / 16 / 12 | 23 / 21 / 12 / 10 | 1 | 2 |
| D | 32 | 30 / 27 / 16 / 10 | 20 / 21 / 12 / 8 | 1 | 2 |

The run depleted the whole route: 129 reed, 114 driftwood, 68 of 74 reef stone and 46 tide bloom. These equal the
ledger's reachable supply, less the 3 unreachable seams below.
- Fights started: **0**. Catches: **0**.
- Every party is still exactly the retained five: terrapup, bramblebun, mudsnout, pipwing, trailpup.
- Trainer landing damage: 0.

## New finding: three reef-stone seams cannot be stood beside
- `water:brine_steps:harvest:008`, `water:shellwatch:harvest:005` and `water:shellwatch:harvest:012` each yield 2 reef
  stone.
- They sit on baked ground of 60-63° all round. The authored `sampled_slope_deg` values are 28°, 11° and 21°, but those
  were measured on the analytic field.
- Earlier attempts placed the trainer beside them. The trainer slid 10-20 m down the bank, and one fall was fatal and
  dropped a death satchel.
- The run now records them as `UNREACHABLE` and never counts them as supply. Solvency holds without them, with a
  reef-stone margin of 68 / 16 = 4.25×.
- This is a data-placement defect for the WORLD/pickups owner to re-seat. This run did not change it.

## Shortcuts (disclosed; the owner ruling allows them because they are listed)
1. **Four characters in one process.** Switching character assigns `Game.local` and re-points the merged flag view
   and progression feed at it, which is what `Game._ensure_containers` binds, minus its satchel rebuild. This stands
   in for four co-op peers on one host world. The ledger arbitration is the same code for host and remote intents
   (`ledger_rpc._commit_here`), but **no network transport was exercised.**
2. **Position writes.** The trainer is placed on a dry stance 1.6-2.3 m from each node or prompt: ≤40° and within
   1.2 m of the node's ground on the way in. There is no walking between the 137 nodes. The final approach and the
   gather are real stick and Interact input.
3. **Carried tools.** Each character carries an axe, pickaxe and knife on hotbar slots 1-3. This is the ledger's
   carried-tool assumption. The tools were not re-earned.
4. **Retained five placed in each party at level 43.** They are used only for party identity. This fixture is shared
   with `smoke_water_pocket_walk_claim.gd`.
5. **`EncounterDirector` processing is disabled.** No wild can start, so no wild can pay. `CombatManager.entered` and
   `catch_resolved` are counted, and both must be 0.
6. **Flags stand in for story steps that are not replayed:**
   - world: `water_swim_lesson_complete`, which is the dock precondition;
   - world: `water_chapter_started`;
   - world: `water_claim:local:lastlight_shelter:lead`, which is Halen's lead;
   - personal: `water_swim_stone_earned` and `water_swim_saddle_recipe_learned` on every character.
7. **Trainer health is topped up at each position write if below max.** The final run used 0 top-ups.
8. **Crafting uses `Game.craft()` directly**, not the station UI. The station is presentation only
   (`existing_campfire_or_workbench`).

## Coordinator gaps
1. **"Data-only four-character ledger; no route depletion run": closed within the shortcuts above.** Real claims,
   real depletion refusals, real dock and site debits and real crafts all pass. The co-op transport remains
   unexercised (shortcut 1).
2. **"Garden/Deep Watch chains need an owned swimmer": solvency is closed, and reachability stays an owner
   question.**
   - Neither chain has a material cost. `garden_records_*` has none, and `deep_watch_chart` has `cost {}`.
   - Their islands' harvest is excluded from all supply, both here and in the ledger.
   - The swimmer is therefore not part of any chain cost. It is only the dock precondition
     (`requires_compatible_active_swim_mount` + `swim_saddle`).
   - The Swim Saddle is still paid ×4 here, conservatively.
   - The retained five has no compatible swimmer. The earned route's swimmer
     (`water_earned_swimmer_segment.gd`) is a **new wild catch** that replaces a duplicate within five. The ledger and
     this run never count it.
   - So visiting Garden and Deep Watch personally still needs a new catch. This is **not closed**. Two of the six
     chains conflict with "without a new catch" for personal visitation.
3. **"Cradle pays first gatherer only": closed for solvency, and the payout inequality remains.**
   - The seam gave A 4 reef stone.
   - B, C and D never received it and each finished with 12 reef stone after their saddle.
   - A's balance without the seam is also 12.
   - All four are solvent without it. The payout itself is still world-once; a per-character grant needs the runtime
     change in `water_local_chain_rules.gd` that the ledger's PROOF names.
