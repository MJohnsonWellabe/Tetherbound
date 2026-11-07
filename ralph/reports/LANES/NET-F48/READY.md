# NET-F48 lane — READY

## HANDOFF 7 Nov

**State:** fix landed on `tb/net-f48-1107` (commits `25029ac7` fix + test, then the test's `.uid` and this file). Ready for the batch PR. Lane wound down at the coordinator's request; no timers or background jobs left.

**Cause (`tests/smoke_net_f48_cut_key.gd` intermittent, "registry reports 2 peer(s), wanted 1, after 12000 frames"):** the host's registry is cleared only from `peer_disconnected` (`session.gd::_on_peer_disconnected`). After a hard kill that signal waits for ENet's own timeout, and ENet does not honour `peer_timeout_max_ms` (180 s) for a dead peer. ENet re-checks timeouts only when `serviceTime >= peer->nextTimeout`. `nextTimeout` follows the HEAD of `sentReliableCommands`, the oldest in-flight reliable command, whose retransmit timer doubles on every resend (Godot 4.7 `thirdparty/enet/protocol.c`, `enet_protocol_check_timeouts` / `check_outgoing_commands`). #830's 1 s pings are fresh commands queued *behind* that head, so they never trigger a check. The drop lands on the doubling series rto·(2^k−1): with rto just under ~265 ms the 132 s point fails the 135 s minimum and the next check is ~264 s, past the smoke's budget, which explains the intermittency. Evidence:
- CI run 41956342047 host log (`net-smoke-runs-10`, `peer-0.log` `PEER_WAIT_TRANSPORT`): the dead guest was still `state 5` (CONNECTED) 200 s later, rtt 74 ± 46 ms (rto ≈ 258 ms), smoothed loss only 2%, so almost no timeout checks were running.
- Standalone loopback ENet reproduction at 1/10 scale (min 13.5 s, max 18 s, rto 22 ms): the dead peer dropped at ~23.0 s with 1 s pings, at 23.0 s with no pings and at ~24.0 s with 1 s pings plus 1 s reliable data (2/2 each). The maximum was overshot every time, matching 22·(2^10−1) ms.
- Not a re-add, a stale rejoin or a pending-join race: no registry add happens on this path between the cut and the wait.

**Fix (game code, `scripts/net/session.gd` + `data/config/multiplayer.json`):**
- Each guest sends a reliable `_rpc_transport_alive` to the host every `peer_liveness_ping_s` (1 s).
- The host tracks when it last heard from each physical ENet peer (`_transport_heard_ms`, starting at `peer_connected`). In `_tick_transport_liveness`, a peer silent for `peer_timeout_max_ms` has its link ended with `ENetPacketPeer.peer_disconnect_now()` (`drop_transport_peer`). `ENetMultiplayerPeer`'s next poll then emits the ordinary `peer_disconnected`, so the registry row removal, 120 s held seat and realm reconcile all run through the existing `_on_peer_disconnected`. Crash semantics are unchanged (MULTIPLAYER: a dropped admitted character keeps a reserved seat).
- Guard: if the host's own tick is late by more than `peer_liveness_host_stall_s` (5 s, new config key), every peer's silence clock restarts, so a host stall is never blamed on a guest.
- ENet transport only (`transport_uses_enet_timeouts`); Steam and offline are unaffected. Pure helper `silent_transport_peers()` for tests. No test was loosened and no timeout was raised; no save, schema or transaction change.

**Tests:**
- New `tests/test_session_transport_watchdog.gd`: real ENet loopback with ENet timeouts pushed out of reach (60 s), so only the watchdog can drop. A dead guest is dropped through `peer_disconnected` at ceiling (600 ms) + one tick (3/3 trials); a heartbeating guest is never dropped over 4 ceilings; the silence rules hold (first sight, host and relayed ids skipped, pruning, ceiling 0 disables).
- `run_tests.gd --only=test_session_transport_watchdog.gd,test_session_transport_liveness.gd`: 6 tests, 62 assertions, 0 failed.
- `tools/net/run_net_smoke.sh f48_cut_key` locally (4 cores, Godot 4.7 headless), every other run with an extra busy-loop CPU burner: **7/7 PASS** (rc 0, 0 FAIL lines, ~327 s each; host count reached 1 after ~120–121 s of the wait). Coordinator cut the planned 20 runs short.
- Shard 10 net smokes after the fix: running at commit time (stormwood_realms, catch_race, shared_building); see the next commit of this file.

**Uncertain / open:**
- In all 7 local runs ENet's own timeout dropped the guest first. Locally rto ≈ 22 ms puts ENet's check near ~180 s, the same time as the watchdog, so the watchdog's drop in the full game is proven by the unit test (real ENet, production helpers) but not yet seen in a local smoke log. A confirming run: temporarily set `peer_timeout_max_ms` 150000 locally (do not commit) and look for `[session] peer N silent for` in `peer-0.log`. CI load (rto ≈ 258 ms) is where the watchdog decides the outcome; the next full-CI shard-10 runs are the real confirmation.
- Client side is symmetric but not changed: a client still relies on ENet to notice a dead host (`host_gone`). Out of scope for this flake.
- Local environment note: a disk-full event mid-import truncated tracked `.import` files and some `.ctex` caches. Restored from git and re-imported; nothing from that was committed.

**Runbook:** Godot 4.7 from the GitHub release zip; `godot --headless --path . --import`, then check `.godot/imported/*.ctex` headers are `GST2` (corrupt caches make the smoke's pre-restart log check fail with "ERROR:"). Loop: `tools/net/run_net_smoke.sh f48_cut_key --out=<dir>`, one Godot process at a time; drop lines are in `<run>/peer-0.log` (`left;` = ENet or watchdog, `silent for` = watchdog).
