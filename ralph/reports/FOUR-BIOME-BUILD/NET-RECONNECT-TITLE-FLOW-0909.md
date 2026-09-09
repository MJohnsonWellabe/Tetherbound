# Production title-flow reconnect — 2026-09-09

## Result

The two-peer reconnect smoke now returns through the real title-screen join
entry, lets the production `JoinDriver` build the Meadows before opening its
socket, restores the returning guest's portable character, and reaches a
playable replicated world.

Final native result: **81 PASS, 0 FAIL, exit 0, `ALL CHECKS PASSED`**.

The restored client recovered `bramblebun@3`, `potion_small x3`,
`orb_basic x2`, the player-scoped `player_slept_at_home` flag, and
`insulated_vest` in `upper_body`. The vest remained absent from the satchel.
The host retained only `insulated_helm`; neither peer received the other's
equipment and the returning character appeared exactly once in the host
registry.

Both peers held two replicated trainer proxy nodes and drew exactly one other
trainer in their current world. The restored client then moved **12.02 m**
through normal stick input and the host's remote body converged to **0.15 m**
of the client's reported position. The missing-character control joined
through the fresh title entry with an empty party, satchel, equipment, and
player flag.

## Production defects fixed

`title_screen.gd::_join_via()` previously treated only slot-0 world autosaves
as returning players. A disconnected client writes its portable character but
never a world autosave, so the title showed the new-character route and
`_begin_join()` reset local state. `JoinDriver` then intentionally called
`Session.join()` without a character summary because the title was expected to
have loaded the returning state already. The portable file therefore remained
on disk while the rejoined player arrived blank.

The title now keeps the existing priority:

1. continue slot-0 autosave when present;
2. otherwise, if the live character ID addresses a readable, parseable
   portable character file, bypass the picker and apply it;
3. otherwise keep the existing new-character picker/reset path.

This is deliberately a **same-process reconnect** proof. The live character ID
survives the server-disconnect return to title and identifies the portable
file. This change does not add a cold-start character browser or claim that a
fresh process can discover an arbitrary portable character.

`remote_trainer.gd` also avoids authority reads while its MultiplayerAPI has no
peer or its ENet peer reports `CONNECTION_DISCONNECTED`. This removes the
previous backtraced `remote_trainer.gd::_apply_ownership()` calls during the
scene-transition window. It does not make the whole engine teardown clean; the
remaining diagnostics are recorded below.

## Harness boundary

The first production-flow attempt reached 48 passing assertions, then the
coordinator declared the client silent while the Meadows was building in one
blocking frame. That was a harness failure before `JoinDriver` dialled.

The harness now suspends the 15-second heartbeat guard only for an in-flight
`production_join`, for at most 90 seconds. The step's command deadline and the
smoke-wide deadline remain in force. The allowance is cleared on a matching
verdict, fatal error, peer exit, or command deadline. Every other action keeps
the ordinary 15-second silence rule.

The final successful native run included three pure guard assertions:

- an ordinary peer with no allowance is silent after 15 seconds;
- an in-window production build is not called silent;
- a production join still silent after the 90-second allowance is called
  silent.

## Native command and isolation

Final command:

```text
C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe --headless --path C:/Projects/Tetherbound --script res://tests/smoke_net_reconnect_keeps_character.gd --log-file C:/Projects/Tetherbound/.artifacts/net-reconnect-production-20260909-d/engine.log
```

Environment:

```text
TB_NET_RUN_ID=reconnect-production-20260909-d
TB_NET_OUT_DIR=.artifacts/net-reconnect-production-20260909-d/net
APPDATA=.artifacts/net-reconnect-production-20260909-d/coordinator-profile
LOCALAPPDATA=.artifacts/net-reconnect-production-20260909-d/coordinator-profile
```

Peer 0 PID `17704` and peer 1 PID `692` both terminated. The terminal Godot
process census was zero.

## Diagnostics and limits

The earlier equipment run retained **24** client errors: ten inactive
multiplayer reads plus fourteen missing-spawner/cache/synchronizer errors. The
missing-spawner/cache/synchronizer cluster was caused by direct `Session.join()`
while the client was on the title transition.

The final title-flow run has none of those spawner, cache, null-spawner, or
synchronizer errors. It retains exactly **8** client errors, four at each
forced teardown:

```text
ERROR: The multiplayer instance isn't currently active.
  at: get_unique_id (modules/enet/enet_multiplayer_peer.cpp:438)
```

These eight entries have no GDScript backtrace. The host log has zero `ERROR:`
lines. The functional reconnect passes, but teardown is not claimed
diagnostically clean and the remaining engine-level transition calls are not
assigned to a production caller without a backtrace.

The harness does not write the returning identity before entering the title.
It asserts that the live same-process ID already equals the expected returning
ID; only the missing-character negative control receives the identity that its
simulated character-card choice would have supplied. `production_join` also
uses the same optional UDP proxy rewrite as the lower-level `join` action when
`TB_NET_CONDITIONS` is configured. The non-mutating returning-ID assertion was
exercised by the final native run. No latency condition was configured, so the
UDP proxy rewrite is source-reviewed rather than claimed as native latency
evidence.

The final run did not perform a cold process restart, LAN/outside-network
session, latency campaign, long reconnect stress run, or rendered visual
inspection.

## Files changed

- `scripts/ui/title_screen.gd`
- `scripts/net/remote_trainer.gd`
- `tests/helpers/net_harness.gd`
- `tests/smoke_net_reconnect_keeps_character.gd`
- `tools/net/peer_runner.gd`

Focused `git diff --check` passed for all five files.

## Retained raw evidence

Successful actual-title run:

- `.artifacts/net-reconnect-production-20260909-d/console.log`
- `.artifacts/net-reconnect-production-20260909-d/engine.log`
- `.artifacts/net-reconnect-production-20260909-d/net/NET_RUN.json`
- `.artifacts/net-reconnect-production-20260909-d/net/SUMMARY.md`
- `.artifacts/net-reconnect-production-20260909-d/net/peer-0.log`
- `.artifacts/net-reconnect-production-20260909-d/net/peer-1.log`
- `.artifacts/net-reconnect-production-20260909-d/net/home-1/Godot/app_userdata/Tetherbound/characters/reconnect-smoke-character/character.json`

Preserved failed attempts:

- `.artifacts/net-reconnect-production-20260909/` — 48 assertions passed before
  the unscoped 15-second heartbeat guard killed the world-building client.
- `.artifacts/net-reconnect-production-20260909-b/` — the first bounded
  `JoinDriver` attempt reached a playable replicated world but demonstrated
  that bypassing the title's character preparation left portable state blank.
