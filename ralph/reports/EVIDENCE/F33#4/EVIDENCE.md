# F33#4 — trainer tool-pouch tiers extend Tether Commands; all gear persists and is personal in co-op

Criterion: Trainer tool pouch tiers extend Tether Commands; all gear persists and is personal in co-op.

- Branch/base: tb/ev-systems-b from origin/tb/ev-coordinator 00d4a639. No game-code or test change.
- Host: Linux, 4 cores, Godot 4.7-stable headless after a full `--import`. Runs Sun 11 Oct 2026, 10:41–10:55 AM CT.
- **Disclosed local shortcut (coordinator-approved 10:47 AM CT, not committed):** `data/config/multiplayer.json` `test_budgets` raised for this slow host only: `hello_budget_s` 180→900, `smoke_step_budget_s_2peer` 300→3600, `smoke_step_budget_s_wide` 1500→7200. These are wall-clock waits; no assertion changed. The first `harness_max_hp` attempt failed only on the 180 s hello wait.

## 1. Pouch tiers extend Tether Commands (unit)
`godot --headless --path . --script tests/run_tests.gd -- --only=test_creature_gear.gd,test_f24_host_commands.gd`
→ exit 0, 42 tests / 1860 assertions / 0 failed across both files (`unit_test_f24_host_commands.txt`).
- `test_equipped_authored_pouches_bind_each_upgrade_on_the_same_participant`: for tier 0..4 (none, Rootiron, Tidesteel, Skyglass, Stormglass command pouch) the host binds the equipped pouch's tier onto the participant's Tether Commands. The last slot of that tier's pouch is usable and the next slot is refused. `data/config/tether_commands.json` tiers: meter_rate 1.0→1.45, pouch_size 1→3, catch_bonus 0.10→0.16.
- `test_pouch_assignment_uses_original_character_journal_and_owner_save_without_moving_stacks`: the pouch assignment is journaled on the owner's character, survives a rejoin, and an old revision cannot edit again.

## 2. Gear is personal and persists in co-op (two real ENet peers)
- `GODOT_BIN=… tools/net/run_net_smoke.sh harness_max_hp` → exit 0, **ALL CHECKS PASSED**, 28 PASS / 0 FAIL (`net_harness_max_hp*.txt/md`). The guest's creature Harness (tidesteel +1) travels in the guest's own admitted record. The host applies it to the guest's creature only, and the guest's saved party row keeps its own base maximum (gear is never saved raised).
- `GODOT_BIN=… tools/net/run_net_smoke.sh reconnect_keeps_character` → exit 0, **ALL CHECKS PASSED**, 84 PASS / 0 FAIL (`net_reconnect_keeps_character*.txt/md`).
  - Host and client each equip distinct trainer gear through the production equip transaction.
  - After a link drop, an in-memory wipe and a rejoin, the client's worn equipment comes back from `user://characters/<id>/character.json`.
  - Neither peer ever receives the other's gear.
  - The worn item is never duplicated into the bag.
- Creature gear lives in the portable character record (`redesign_character.creatures[uid].gear`). `test_creature_gear.gd` (F33#0 run) proves the transaction: equip/upgrade refuse a creature that isn't the character's own (`ownership`), refuse replays, and refuse stale revisions.

## 3. Creature gear survives a production leave, wipe and rejoin (coordinator ruling 11:18 AM CT)
`tests/smoke_net_harness_max_hp.gd` extended at commits 36cfcc1c + 0bd43ae6. No existing check changed; a tail runs after them, with two read-only peer steps (`harness_record`, `harness_admitted`) in tests/helpers/harness_hp_net_peer.gd.
`GODOT_BIN=… tools/net/run_net_smoke.sh harness_max_hp` → exit 0, **ALL CHECKS PASSED**, 42 PASS / 0 FAIL, Sun 11 Oct 12:09–12:15 PM CT (`net_harness_max_hp_rejoin*.txt/md`). In order:
- the production leave writes tidesteel_harness_plus_1 on the guest's creature into the guest's own character file;
- `wipe_character` blanks memory (party 1 → 0, no gear) while the file still holds the Harness;
- the same saved guest rejoins through `production_join` (returning route);
- its creature wears the Harness again, restored from its own file;
- the bag and file count of the item is unchanged (0 → 0, no duplicate);
- the host's admitted record gives the guest's creature the Harness and the host rolls its hits with s = 1.2640 (authored);
- the host's own creature has no harness and s = 1.0.

Disclosed:
- Fixture: the smoke's existing `harness_unwear` isolation step erased the guest's in-memory gear, so `harness_wear` restores that same pre-join gear before the leave. Every write and read after that is production.
- First attempt (12:03 PM CT) failed only at the rejoin with "peer silent >15 s" while `production_join` rebuilt the world. Fix: the smoke now sets the standard `world_build_allowance_floor_s["production_join"] = 150.0`, as other production_join smokes do.
- The passing run had uncommitted, print-only `DIAG_TMP` lines in game scripts for the separate F48#3 diagnosis (no logic change), plus the local budget override.

## Disclosed limits
- No existing smoke does a single two-peer **Forge craft → creature-gear equip → reload → rejoin**. Persistence and personal ownership are proven by the pieces above: the unit transaction, the host-admitted guest gear in `harness_max_hp`, and trainer equipment restored from disk in `reconnect_keeps_character`. Trainer-equipment persistence is shown with armor (vest/helm), and the command pouch sits in the same `equipment` dictionary (`backpack` slot).
- `harness_max_hp` uses disclosed peer fixtures (tests/helpers/harness_hp_net_peer.gd): gear is written into the guest's record before it joins.
