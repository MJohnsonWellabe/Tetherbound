# F48#0 evidence: two-peer co-op loop

**Criterion (ACCEPTANCE §6.2, F48 (0)):** a two-peer session runs hub → homestead
crafting → portal → Master → feast → boss → relic hang, with each player's
receipts separate.

**Result: PASS.** `ALL CHECKS PASSED`, 500 passing checks, 0 failures, exit 0.

| | |
|---|---|
| Command | `GODOT_BIN=/opt/godot/Godot_v4.7-stable_linux.x86_64 tools/net/run_net_smoke.sh f48_coop_loop` |
| Smoke | `tests/smoke_net_f48_coop_loop.gd` (`# peers: 2`), peer `tests/helpers/f48_coop_loop_net_peer.gd` |
| Source | branch `tb/ev-coop-loop`, from `origin/tb/ev-coordinator` at `f37db59a`. The run used the working tree committed as `69703470`; the next commit, `9ff3ed9d`, adds only the two `.uid` files |
| Engine | Godot 4.7-stable, Linux headless, two real ENet processes on loopback |
| When | 2026-10-11, 1:19:21–1:35:38 PM CT (16 min 17 s) |
| Files | `SUMMARY.md`: harness verdict. `F48_COOP_LOOP.json`: each player's own record and the host's admitted record of the guest after every leg. `run_checks.txt`: every check line and every leg's new receipts |

## The loop

Each leg calls a step that an existing net smoke already runs, all in one session:

1. **Hub:** each player uses its Satchel Home Key to reach the Crossing Hall (`craft_home_key_trip` → `f49_portal_travel.home_key`).
2. **Homestead crafting:** the host plants a Kitchen and Spice rack through the paid build press (`craft_place_kitchen`). The guest crafts a Small Potion there (`craft_at_host_kitchen`). The guest pays berries 4 and fiber 1 and keeps the potion. The host's stock does not change.
3. **Portal:** each player uses its Home Key again, then leaves through the Hall's home arch prompt to Meadows (`loop_home_key`, `loop_arch_enter`). Each `portal_enter` reply belongs to that player.
4. **Master:** each player challenges Orin Stonewake (`master_t1`) with its chosen Bramblebun, wins (`win_trainer_battle`), then opens the chest (`f28_chest`). Each player ends with one win receipt, one `master_recipe:master_t1:<own id>` receipt and the `feast_t1` recipe once.
5. **Feast:** each player cooks Ascension Feast 1 (ground) at the host's Kitchen (`f28_cook`) and feeds its own Pup (`f28_feed`). Each player pays exactly berries 4, rootstone 2 and attuned_ground 1, gets one station craft receipt and one `feast_feed:` receipt, and its Pup's cap goes from 10 to 20.
6. **Boss:** both players fight the Warden (`trainer_battle`, `join_encounter`, `win_trainer_battle`). Each holds exactly one Tidewake portal key and the Meadows relic once.
7. **Relic hang:** each player uses its Home Key, then hangs its own relic on the Shrine Room pedestal (`f49_portal_travel.hang_relic`, which closes the relic-power chooser by default). Each player has `relics_hung` = meadows once and exactly one `relic_hang:meadows:<own id>` receipt.
8. **Save and reload, once:** the guest saves. The host does a production save and reload (`save_reload_here`). The guest leaves and rejoins on the returning route as its saved character. Afterwards, for both players, the satchel items, caps, wins, recipes, relics held and hung, and the full receipt list are identical to their state before the reload.

These checks run after every leg:

- Each player's new receipts name only that player's own character or creatures.
- No new receipt appears in the other player's record.
- Neither receipt list holds a duplicate.
- Where a leg pays someone, that player gets exactly one receipt of that kind, and anyone it does not pay gets none.
- The host's admitted record of the guest matches the guest's own record (items, recipes, relics, receipts).

## Disclosed setup and shortcuts

Everything below happens before the first admission, as in the leg smokes:

- Both peers boot straight into the world.
- `party_grant` gives each player a Lv 10 Terrapup "Pup" (the feast target, at cap 10) and a Lv 40 Bramblebun (the Master duellist).
- `seed_opening_complete` marks the opening as played.
- `f28_feast_seed` gives each player one Home Key and one cook's ingredients, and gives the guest the potion's ingredients. It seeds no recipe: each player earns `feast_t1` from the Master.
- Each player is saved with `save_character_here`, then the session starts with `host`/`join`.

During the run, these are fixture moves or settings:

- Teleports: the host's Kitchen stance (`craft_place_kitchen`), the guest's craft stance (`craft_at_host_kitchen`), the Master and Kitchen stances (`f28_stand`) and the Warden arena (`explore_at`).
- The feast stance is the craft step's own spot at Kitchen + (1.6, 1.6). An earlier run walked there instead, stopped about 3 m short behind the Spice rack (outside the station's radius), and the host refused the cook as `source_or_revision_changed`.
- The Warden fight uses `win_trainer_battle`'s `enemy_hp_ceiling` 6 with no self-HP top-ups, as `smoke_net_veridian_relic_key` does.
- A feast panel press that the host refuses because the record moved is pressed again, at most twice, as the Masters smoke does for its chest. The guest's chest is pressed again if the first press is refused while duel checkpoints settle. That is the known open F28#4 gap, and its delivery is still held to exactly once.
- `craft_home_key_trip` sets `home_key_given`.

**Local only, not committed:** `data/config/multiplayer.json` `test_budgets` was raised for this slow host (`hello_budget_s` 180→900, `smoke_step_budget_s_2peer` 300→3600, `smoke_step_budget_s_wide` 1500→7200). The smoke's own step deadline is the larger of 2400 s and that budget, so it ran under 3600 s here. The run took 16 min.

## CI registration

- `tools/ci/net_shards.py`: `f48_coop_loop` is added to `ROSTER`. `DISCOVERY_FLOOR` is now 74, the real count of files with the `# peers: 2` header.
- `MEASURED_SECONDS["f48_coop_loop"] = 1100` is an **estimate**. Refresh it from the first full CI run.
- `SHARD_COUNT` goes from 13 to 14, and the `ci.yml` `shard:` matrix from `[1..13]` to `[1..14]`: the gate plan no longer fit the 1110 s lane budget.
- `python3 tests/test_ci_net_shards.py` passes (15 tests).
- **Risk:** a CI net smoke is ended at `NET_SMOKE_TIMEOUT_SECONDS` = 1200 s. This smoke took 977 s on this slow host. The leg smokes it composes take 200–600 s each on CI.

## Not covered here

- The host's own station craft. The host's Kitchen use is covered by its feast cook.
- Disconnects mid-transaction (F48#1), four peers (F48#2) and the behind friend (F48#3).
