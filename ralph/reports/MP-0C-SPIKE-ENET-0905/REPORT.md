# MP-0C-SPIKE-ENET — report

**Lane:** 0.C Spike S1, ENet in this repo (Sonnet) · **Branch:** `claude/tetherbound-roadmap-next-jrcjs8`
from `main` `55c64aaa` · **Kind:** spike, reference scripts only · **Brief:**
`docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` Wave 0 row 0.C. The lane could not write this
file itself; Fable wrote it from the lane's completion report after reproducing the two-peer run
(median RTT 6.9 ms, spawn seen after 2 frames, authority correct on both sides — matching the
lane's numbers).

## One line per item, up front

| Item | Verdict |
|---|---|
| 1 Host/client connect over `ENetMultiplayerPeer`, bounded wait | **done** — timeout path exits 2 |
| 2 `@rpc("any_peer","call_remote","reliable")` ping/pong × 50 | **done** — loopback RTT min 4.2 / median 6.9 / max 40 ms |
| 3 `MultiplayerSpawner` + `spawn_function`, authority set before tree entry | **done** — two gotchas below |
| 4 `MultiplayerSynchronizer` replicating `position` | **done** — host sees the move in 2–3 frames |
| 5 Launcher with 1 host + 3 clients, isolated `XDG_DATA_HOME`, orphan sweep | **done** — 4.09 s wall clock, ~143 MB RSS per process, all three clients saw the spawn (after 17 / 2 / 34 frames) |
| 6 `OS.create_process` env inheritance, `OS.set_environment` | **done** — both work; child reaped by polling `OS.is_process_running` |

## Files

`tools/net/_spike_enet.gd` (driver, `extends SceneTree`, roles `host|client|spawntest|envcheck`),
`tools/net/_spike_enet_peer.gd` (RPC hub and spawn function, `extends Node`),
`tools/net/_spike_enet.sh` (launcher). Reference only; the real harness is lane 0.F's.

## Invocations

```
GODOT_BIN=~/godot-bin/godot SPIKE_OUT=<dir> tools/net/_spike_enet.sh 1 9944   # 1 host + 1 client
GODOT_BIN=~/godot-bin/godot SPIKE_OUT=<dir> tools/net/_spike_enet.sh 3 9966   # 1 host + 3 clients
godot --headless --path . --script tools/net/_spike_enet.gd -- --role=spawntest --outdir=<dir>
```

Raw form: `XDG_DATA_HOME=<home> godot --headless --path . --script tools/net/_spike_enet.gd -- --role=host --port=9944 --peers=1`, and the same with `--role=client`.

## Errors hit, verbatim, and what they were

1. `SCRIPT ERROR: Parse Error: Identifier "multiplayer" not declared in the current scope.` —
   `SceneTree` has no bare `multiplayer` property; use `get_multiplayer()` in a `SceneTree` script.
2. **The real finding.** The client sat at its 600-frame timeout while its ENet peer was already
   `CONNECTION_CONNECTED`. A GDScript lambda captures an outer local `bool`/`int` **by value**;
   `var connected := false; sig.connect(func(): connected = true)` never flips the variable the
   loop reads. No error, no warning. Fixed with a `Dictionary` state box. The host's equivalent
   worked only because `Array.append()` mutates a reference type.
3. `ERROR: Can't use get_node() with absolute paths from outside the active scene tree.` —
   setting `spawn_path` before `add_child(spawner)`. Non-fatal but noisy; order is add first.
4. `String formatting error: a number is required.` — a `%` format one argument short.

**Authority set after the node is in the tree** raises nothing: it silently changes on the calling
peer only, because authority is not a replicated property. `MultiplayerSpawner` gets it right only
because `spawn_function` runs identically on every peer before the node is added.

## Advice carried into lane 0.F's brief

1. Never let a signal callback set a bare local a polling loop reads; use a state box everywhere,
   including `wait_flag`/`assert`.
2. ENet peer ids are large random 32-bit numbers (`2098775056`, `1519229912`); the registry maps
   id → role/character explicitly and logs the real ids.
3. `add_child()` before wiring `spawn_path`/`spawn_function`; set authority inside
   `spawn_function`, never after — the failure is silent divergence, which is exactly what the
   desync detector must cover.
