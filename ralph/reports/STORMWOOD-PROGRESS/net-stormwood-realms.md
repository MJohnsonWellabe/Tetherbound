# Stormwood two-peer realm-router smoke

## Scope

Added the Stormwood production-root registration to
`tools/net/peer_runner.gd` and the bounded
`tests/smoke_net_stormwood_realms.gd` coordinator. The smoke uses the real
`Game.enter_realm()` route after a host-led replicated key, then checks:

- client `Stormwood` / host Meadows registry separation;
- host-owned, ready Stormwood shell with one remote body;
- the shell's existing `STORMWOOD READY ... terrain_regions=108` production
  log line;
- remote visibility of `realm_gate_stormwood_unlocked`;
- a fresh Stormwood fog-cell discovery while the host's Meadows fog remains
  unchanged;
- client return to Meadows with both session members still active.

It deliberately leaves gate-refusal/unlock UX and late join to their dedicated
lanes. This smoke/report lane changes no runtime or shared production code.

## Windows harness portability and validation

The initial Windows run exposed a harness issue: it used `/bin/sh` for worker
redirection and defaulted its output directory to `/tmp`. Those paths do not
exist on this host.

`tests/helpers/net_harness.gd` now keeps the POSIX `/bin/sh` and `exec` path
unchanged, while Windows:

- sets a unique per-peer `APPDATA` root before launching Godot, which Godot
  resolves into a distinct `user://` directory;
- launches the Godot executable directly with `OS.create_process`; and
- uses Godot's `--log-file` for peer and UDP-proxy logs.

This makes the tracked PID the actual Godot process, so normal harness cleanup
can kill the process it launched rather than a console or shell wrapper.

The harness does not use the nonexistent Godot 4.7 `--user-data-dir` option.
Instead it sets Windows `APPDATA` for each child before `OS.create_process`.
A direct two-process probe established that this Godot build resolves
`OS.get_user_data_dir()` below the supplied `APPDATA` root. The peer runner
also includes its resolved `user_data_dir` in `hello`, so the smoke verifies
the actual child paths rather than relying on the coordinator's intent.

The actual Windows coordinator was run with:

```powershell
& 'D:\CodexWork\godot-4.7\Godot_v4.7-stable_win64_console.exe' --headless --path . --script tests/smoke_net_stormwood_realms.gd
```

It launched actual Godot peer PIDs 25068 and 19892. Their `hello` messages
proved distinct user-data directories:

```
.../net-run-local-2020643/home-0/Godot/app_userdata/Tetherbound
.../net-run-local-2020643/home-1/Godot/app_userdata/Tetherbound
```

That first post-portability run passed. Both peers reached `hello`, formed a
two-member session, and passed the then-configured shared-flag checks; the
client entered Stormwood, the host stayed in Meadows, and the host's shell
reported a remote body and its 108-region Terrain3D footprint. Its fog check
only proved that the host map did not change: the old assertion accepted an
unchanged client cell count, so it was not evidence of positive client
exploration.

The instrumented client log records the completed world build:

```
STORMWOOD BUILD shell=false elapsed_ms=252 terrain attached
STORMWOOD BUILD shell=false elapsed_ms=2696 terrain assets assigned
STORMWOOD BUILD shell=false elapsed_ms=3980 terrain physics settled
STORMWOOD READY realm=stormwood shell=false terrain_regions=108
```

## Strengthened run

The smoke now uses the real `realm_gate_stormwood_unlocked` world flag, checks
that the two actual `hello.user_data_dir` values differ, and moves the client
to a fresh `[-350, 450]` Stormwood point. It requires the local fog-cell count
to increase strictly, while still requiring the host's Meadows fog payload to
remain byte-identical.

The one targeted rerun (`net-run-local-1977417`) passed every assertion. Its
`NET_RUN.json` has `failures: []`, an empty `fatal` value, and both peers
exited cleanly. The two reported paths end in distinct `home-0` and `home-1`
directories. The host log reached `STORMWOOD READY ... shell=true
terrain_regions=108` after a 10.1-second build; the client reached the same
108-region ready marker after 8.2 seconds. The strict fresh-cell assertion and
the unchanged-host-payload assertion both passed.

Both peer logs also contain Godot multiplayer replication cache errors during
the transition (for example `Node not found` under `Stormwood/Spawned/Trainers`
and `Ignoring delta for non-authority or invalid synchronizer`). They did not
cause a smoke assertion, disconnect, or failed `NET_RUN`, but remain a
production concern outside this smoke-only lane.
