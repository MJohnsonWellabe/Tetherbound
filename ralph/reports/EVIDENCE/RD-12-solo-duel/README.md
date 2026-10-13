# RD-12: solo ordinary trainer duels fill the Tether Command meter and the Ultimate (tb/ev-systems-a)
Bug: a solo ordinary duel (e.g. Captain Riverwatch/Oreth) minted no host encounter record. The command meter and the Ultimate live on that record, so they never filled.

## Fix
Commits cde2aaed6..c7fc4b95d (final head c7fc4b95d).
- `encounter_director._solo_duel_record` is decided once at begin_trainer_battle. It applies when the battle is not a Master, rematch or tournament round, `_is_host()` is true (the one-peer hosted session that every solo world runs in), it is not multi-peer, and Tether Commands and actor vitals are on.
- `_open_encounter_if_networked` mints the record for that duel.
- Preflight: if the creature's admitted vitals don't bind (`_ordinary_actor_binding`), the record is closed and the duel fights unbound exactly as before. It is never 'fled'.
- `Session.ordinary_combat_reward_owner` answers "not applicable" for that battle (the same branch chapter bosses use), so rewards and vitals stay on the solo path. A guest joining mid-battle cannot switch it.
- The offline fallback after a failed port bind keeps the unbound duel, because its strikes have no host to commit.

## Proof
`tests/smoke_solo_duel_meter.gd -- --profile=relay --trainer=captain_riverwatch [--to-victory]`: real Meadows world from a generated boundary profile. Disclosed: one-peer session hosted as the title screen does; player placed beside the trainer; `begin_trainer_battle` called directly; route-pilot controller presses.

| Run | Record | Hits | Command meter max | Ultimate max | Rally spend | Rewards |
|---|---|---|---|---|---|---|
| Control: same commit with the fix reverted (local b99ccdc14) | none | 96 | 0 | 0 | not offered | +50 coins, defeat flag, legacy XP |
| Fix, c7fc4b95d | 1:1 | 81 | 100 | 1.0 | 55 → 13 | +50 coins, defeat flag, legacy XP; durable owners 0 |

- XP totals differ between runs only by fight variance: the legacy award goes to the active creature and shares to non-fainted members.
- Unit suites, encounter/combat/director/F24/rematch/boss-handoff/trainer/named-fight (57 files): 451 tests, 1 failed.
  - The failure, test_cloudreach_encounters "Maela's creature trial…", is pre-existing: it fails identically on the control commit and comes from the recent Cloudreach aviary merges.
- Co-op: `run_net_smoke.sh client_trainer_rewards` and `boss_rewards_each_participant` both pass. The first attempt failed only at peer hello under CPU load.

EV RD-12 PASS c7fc4b95d solo ordinary duel binds the host record: landed hits fill the command meter (100) and the Ultimate (full), Rally spends (55→13), rewards unchanged, co-op smokes pass
