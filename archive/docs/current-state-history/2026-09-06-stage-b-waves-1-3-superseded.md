# CURRENT_STATE history — moved 2026-09-07

Moved verbatim from `docs/CURRENT_STATE.md` when that file was slimmed to the live
status. History only; nothing here routes current work. See `docs/CURRENT_STATE.md`.

## Stage B (multiplayer) Waves 1–3 — 2026-09-06 — SUPERSEDED by the entry above

> Kept as the log entry it was. Its "not yet done" paragraph is stale: lanes 3.B–3.D, the save
> split 1.C, and the realm refusal it describes as held all landed later the same day. Read the
> entry above for the state, and `docs/acceptance/MULTIPLAYER_ACCEPTANCE.md` for the evidence.

**Two people can walk around one Meadows and see each other.** That is Wave 2's deliverable and it
is measured, not asserted: `tests/smoke_net_movement_two_peers.gd` runs two isolated Godot
processes that really host, join, exchange a world snapshot and walk, and each asks the other
where it is drawing its body. On the merged tree, both directions read **0.55 m in motion and
0.00 m at rest** against budgets of 4.0 m and 1.5 m, with zero peer errors. The
`verify-multiplayer-shard` CI job runs it and the three other net smokes on every pull request,
and passed on run 34006612393.

Landed on the branch since Wave 0:

- **Wave 1 lane 1.B — the world/player state split.** `autoload/world_state.gd` and
  `autoload/player_state.gd` behind forwarding properties on `Game`, so `Game.party` still means
  "the local player's party" and no existing call site moved (D98). Flag scope is declared per id
  in `data/progression/flag_scopes.json`, never defaulted (D99).
- **Wave 2 lane 2.A — the session.** `scripts/net/session.gd` and `peer_registry.gd`: host, join,
  leave, kick, a host-authoritative registry, and a handshake that sends the world snapshot on its
  own channel before the registry. Solo is a one-peer session through the same funnel, so there is
  no second implementation to rot. `enter_realm()` is refused in a multi-peer session until Wave 6
  (D97). The day and clock are host truth (D105).
- **Wave 2 lane 2.C — the per-peer rig.** `scenes/player/local_rig.tscn` and `remote_trainer.tscn`;
  the host spawns a trainer body per peer with authority set before it enters the tree, and remotes
  interpolate.
- **Wave 3 lane 3.A — the world ledger.** `scripts/net/world_ledger.gd`, a pure `RefCounted` the
  host commits every consequential world mutation through, answering each intent with either a
  delta or a refusal code a player can be shown (D103). `commit()` applies its own delta through
  the same `WorldState.apply_delta()` a client runs, so the two sides cannot drift by running
  different code over the same ops. Race safety is proven in
  `tests/test_world_ledger_races.gd` — 19 tests, 87 assertions, each of the five required
  interleavings seen red against a deliberate break in production code. `scripts/net/ledger_rpc.gd`
  is mounted beside the session at an identical path in every process, which is the only reason its
  remote calls resolve.

**The authority defect Wave 2 found, because it is the kind that hides.** Godot installs an
`OfflineMultiplayerPeer` by default, under which `multiplayer.is_server()` is **true** and
`get_unique_id()` is **1** with no session at all. Both processes therefore spawned a phantom
`Trainer_1` while the world was still booting, and on the client that phantom held the name the
host's real body needed. Any guard of the shape "am I the server, if a peer exists" is unsound in
this engine; the fix asks the session instead, and `scripts/net/trainer_spawn.gd::_is_host()`
carries the account.

Not yet done in Wave 3: pickups, harvest, building, satchels and storage still write their own
world state rather than submitting intents (lanes 3.B–3.D, in flight). The save split (lane 1.C)
is deferred, so a client still writes no character file — `session.gd::_save_character_here()`
and the two D100 probes in `smoke_net_host_join_leave` are the three places that lane re-points.
`smoke_progression_feedback` fails identically on the Wave 0 base, is in no CI shard, and is
routed rather than fixed.
