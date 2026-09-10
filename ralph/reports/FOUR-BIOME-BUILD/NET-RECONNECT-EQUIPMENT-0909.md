# Reconnect smoke: worn equipment persistence — 2026-09-09

## Scope

This verification-only change extends the existing real two-peer reconnect smoke. It does not change production code, PR103, PR104, imports, or world content.

Owned source files:

- `tests/smoke_net_reconnect_keeps_character.gd`
- `tools/net/peer_runner.gd`

The runner addition is one uniquely scoped `equipment_equip_from_satchel` action. It calls the live `PlayerState.equipment.equip_from_inventory(item_id, Game.inventory)` transaction after the test grants the item to the real satchel. The existing `character_restore` probe now reports `equipment.save_data()` from memory and the `equipment` dictionary from `CharacterSave.state()` on disk.

## Assertions added

The host first carries and equips `insulated_helm`; the client first carries and equips `insulated_vest`. Their distinct identities make cross-peer contamination visible.

The preserved reconnect sequence now also proves:

- before save, the client wears `insulated_vest` in `upper_body`, the vest is absent from its bag, and it has no host helmet;
- the host wears `insulated_helm` in `helmet` and has no client vest;
- the actual character file contains the same equipment identity and no duplicate vest inventory stack;
- `PlayerState.load_data({})` clears the client's live equipment while leaving the disk equipment intact;
- rejoining the same character restores the vest from disk, still absent from the bag;
- the host still has only its own distinct helmet after the reconnect;
- the missing-character negative control rejoins with every equipment slot empty.

All pre-existing party, satchel, player flag, ENet identity, registry, disconnect, world catch-up, world equality, and missing-file checks remain.

## One authorized real-peer run

Command:

```text
C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe --headless --path C:/Projects/Tetherbound --script res://tests/smoke_net_reconnect_keeps_character.gd --log-file C:/Projects/Tetherbound/.artifacts/net-reconnect-equipment-20260909/engine.log
```

The coordinator used `TB_NET_RUN_ID=reconnect-equipment-20260909`, `TB_NET_OUT_DIR=.artifacts/net-reconnect-equipment-20260909/net`, an isolated coordinator `APPDATA`/`LOCALAPPDATA`, and the mature harness's separate peer homes. Both peers loaded the production `world` scene and communicated over real loopback ENet sockets. Persistence was read from the client's isolated `user://characters/reconnect-smoke-character/character.json`.

Result:

- started: `2026-09-09T18:04:19.5946632Z`
- ended: `2026-09-09T18:05:54.0502716Z`
- elapsed: `94.456 s`
- exit: `0`
- checks: `71 PASS`, `0 FAIL`, final `ALL CHECKS PASSED`
- peer 0 host: PID `8828`, exited normally
- peer 1 client: PID `13828`, exited normally
- all owned PIDs: `8224, 8828, 13828, 14284, 17732`
- held coordinator process handle: `2000`; wrapper called `WaitForExit()`
- initial system commit/process count: `57.40% / 252`
- maxima across 38 samples: `77.13% commit / 260 processes / 5 owned processes`
- stop reason: empty
- terminal census: Godot `0`

The saved character file directly records:

```json
"equipment": {
  "backpack": "",
  "boots": "",
  "helmet": "",
  "lower_body": "",
  "upper_body": "insulated_vest"
}
```

Its inventory rows are `potion_small x3` and `orb_basic x2`; there is no `insulated_vest` stack.

## Retained raw evidence

- `.artifacts/net-reconnect-equipment-20260909/console.log` — complete coordinator assertions and peer identity lines
- `.artifacts/net-reconnect-equipment-20260909/engine.log`
- `.artifacts/net-reconnect-equipment-20260909/stderr.log`
- `.artifacts/net-reconnect-equipment-20260909/result.json` — exact command, UTC interval, exit, limits, handle, and owned PID set
- `.artifacts/net-reconnect-equipment-20260909/pid-ancestry.json` — command lines and parent IDs
- `.artifacts/net-reconnect-equipment-20260909/resources.csv` — all 38 guard samples
- `.artifacts/net-reconnect-equipment-20260909/net/NET_RUN.json`
- `.artifacts/net-reconnect-equipment-20260909/net/SUMMARY.md`
- `.artifacts/net-reconnect-equipment-20260909/net/peer-0.log`
- `.artifacts/net-reconnect-equipment-20260909/net/peer-1.log`
- `.artifacts/net-reconnect-equipment-20260909/net/home-1/Godot/app_userdata/Tetherbound/characters/reconnect-smoke-character/character.json` — real disk state
- `.artifacts/net-reconnect-equipment-20260909/hashes.sha256` — SHA-256 manifest for every retained run artifact

The raw client log retains 24 Godot diagnostics during the two deliberate transport teardown/rejoin transitions: 10 inactive multiplayer-instance reads, 2 missing `TrainerSpawner` paths, 2 null-node path simplifications, 4 missing cache-ID reads, 4 null spawner reads, and 2 invalid synchronizer deltas. They did not produce a harness failure or unexpected peer exit. This change does not classify or suppress them.

Key SHA-256 values:

- `console.log`: `84f75f8c52a917005d13c313a15fffc78b36bf93a7015d0460365b3b3066b54e`
- client character file: `3b07d83ee167fec3d4fde85ed793ee8e7c63385aabe294f3d90afae3afa8447a`
- `NET_RUN.json`: `aefb6d026a9aeff5d3947736fe7b14e2111b299663efceca95a56827b08784cc`
- `peer-0.log`: `994830e5f1502c398fa1194a0a1423b0d04ab900d2603a2306b0dfbcdfe72a`
- `peer-1.log`: `0c8081ba7e52815fe87abd8abead87b91b9498b322cfcfa4779c026db08d69f5`
- `result.json`: `7ca37d408a92f3babd7ce08b43389a0db435a14aae3fb13d29560117fa784d25`

## Diagnostic classification against retained reconnect baselines

This section classifies the 24 client-log errors; the passing state assertions do not make them harmless by themselves.

### Baseline evidence and its limit

The immediate baseline is PR103 commit `a76c50bd64a352a35b3a030e03ba457490a401b7`, CI run `34384910163`, net shard job `102580482368`. Its reconnect group is retained in `.artifacts/pr103-a76c50bd-ci/job-102580482368.log` at lines 3696–3773 and passed its one attempt. SHA-256: `24a664a40cf6f5d2905654e9e8cfbeeb227959d826b3de4aa55a864828600d12`.

That CI terminal log names `/tmp/net-ci/net-reconnect_keeps_character-20260909T180013Z/peer-1.log` but does not print the peer log. The downloaded PR103 evidence in this workspace contains only the job log, so its zero visible `ERROR:` lines cannot establish a clean peer process. It is a valid immediate coordinator/result baseline, not a diagnostic-count baseline.

The nearest retained same-smoke peer raw is PR91's `.artifacts/ci-pr91-b5dd34b4/net-smoke-runs-6/net-reconnect_keeps_character-20260909T033135Z/peer-1.log`, run `net-20260909T033135Z-3095`, peer `main_sha=df4c9e5b7a4f`. It passed and contains 20 errors. SHA-256: `9b8c4607d9ada25851ace8167a0c1583d9f6eaf8c93283b75159a3274c846def`.

Every error class in the equipment run is already present in that retained same-smoke raw:

| Error class | PR91 | Equipment run | Lifecycle point |
| --- | ---: | ---: | --- |
| `The multiplayer instance isn't currently active` | 6 | 10 | After the first forced link loss and character write, before the restored-character dial |
| missing `MeadowsPlayground/Spawned/TrainerSpawner` | 2 | 2 | Once during each direct rejoin, before snapshot application |
| null node in `process_simplify_path` | 2 | 2 | Paired with each missing spawner path |
| `ID 2 not found in cache of peer 1` | 4 | 4 | Before and after snapshot on each direct rejoin |
| null spawner in `on_spawn_receive` | 4 | 4 | Paired with each missing cache object |
| invalid/non-authority synchronizer delta | 2 | 2 | Once before snapshot on each direct rejoin |

The two seven-error rejoin clusters are identical in class, count, and ordering between PR91 and this run. The only count difference is four more inactive-multiplayer reads during the first scene transition. In PR91, two of the six have no GDScript backtrace and four come from `remote_trainer.gd::_apply_ownership -> _physics_process`; here, four of ten have no GDScript backtrace and six come from that same call chain. This is variable transition-frame exposure within an existing class, not a new equipment-specific signature.

The committed files that control these paths—`remote_trainer.gd`, `session.gd`, `trainer_spawn.gd`, `join_driver.gd`, and `meadows_playground.tscn`—have no diff from PR103 `a76c50bd...` to the current `7d5c6a25...` HEAD, and none is dirty. The equipment verification delta changes only the test and peer-runner command/probe. There is therefore no source or raw-log evidence that worn-equipment persistence introduced these diagnostics.

### Lifecycle cause and disposition

The inactive-multiplayer reads expose a plausible production cleanup defect. On a real host loss, `session.gd::_on_server_disconnected()` saves the character, `_teardown()` replaces the ENet peer with the offline peer, emits `session_ended`, and requests the title scene. Existing `RemoteTrainer` nodes can still receive physics frames before the scene replacement finishes. Their `_physics_process()` calls `_apply_ownership()`, whose `is_multiplayer_authority()` reaches `get_unique_id()` on the closed multiplayer instance. The backtraces directly establish that path for six occurrences here and four in PR91. The no-backtrace occurrences happen in the same interval but cannot be assigned more narrowly from retained raw. This appears pre-existing and does not corrupt the proven portable data, but it is real player-path error logging during disconnect and merits a separate cleanup fix or focused regression test.

The spawner/cache/synchronizer errors have a different cause and a more serious implication for what this smoke proves. The production disconnect path calls `_return_to_title()`, which queues `title_screen.tscn`. A normal player reconnects through `title_screen.gd::_begin_join()` and `join_driver.gd`: it changes to the configured world, waits for that world and its authored `Spawned/TrainerSpawner` to exist, settles 30 frames, and only then calls `Session.join()`.

This smoke bypasses that production re-entry lifecycle. After `drop_link` triggers the real return-to-title path, it calls `Session.join()` directly in the same peer process without loading and settling the world again. The host then sends spawner packets addressed to `/root/MeadowsPlayground/Spawned/TrainerSpawner` while the client is on, or transitioning to, the title scene. Godot cannot resolve the spawner, then cannot resolve cache ID 2, and rejects the dependent synchronizer delta. The absence of any new `[trainers] built Trainer_*` lines after either rejoin confirms that the rejoined client did not regain the replicated trainer world representation.

Disposition: the errors do not indicate a newly introduced equipment persistence regression. They do show that this run proves only portable character state restoration over a real socket and real disk. It does **not** prove that the client returned to a playable world with replicated trainer bodies after reconnect. The missing-spawner sequence is established fixture misuse relative to the production UI's world-first join order; whether a normal UI-driven reconnect is fully playable remains unproven by this fixture and needs a separately authorized test that follows `title_screen`/`JoinDriver`, rather than another retry of this command.
