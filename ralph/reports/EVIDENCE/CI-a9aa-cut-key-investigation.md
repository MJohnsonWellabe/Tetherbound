# CI a9aa cut-key investigation

Run38506342641 / job115664974349 / artifact11868511697. Failure is retained; no rerun, timeout increase, diagnostic exemption, or assertion change.

Exact shard archive SHA256 `4fa97966c47c616c4ba47fb789b2b11dfa82191c8987bae923e02d0de160f0ea` (4,885,358B). Job excerpt, archive, extracted top-level cut-key logs and NET_RUN.json are at `D:/tetherbound/.artifacts/codex-takeover-systems/ci-cut-key-a9aa/`. CI checkout reported merge `d4a5e3eefac6`; source head is `a9aa64e45da5738869aa52f77bb529217b210446`.

## Observed failure boundary

Original guest PID2309 died at the real portal-key owner-write-before-ACK edge. Replacement PID2525 announced on the same original home, stayed at title with no session peers, and had not attempted rejoin. Host PID2308 retained registry IDs1 and1633756353 throughout the failed12000-frame/201.2s expectation. Its final heartbeat was in world at323.75s with physics_frame16620; there was no harness fatal or unexpected process exit. The host log never printed the disconnect/seat-reservation path. All subsequent shard smokes passed.

Thus this is neither a guest-key assertion failure nor evidence that the replacement silently rejoined. The retained data does not distinguish a still-connected ENet link from an already-disconnected transport whose registry cleanup failed: ENet state/RTT was not recorded.

The passing a941 and failing a9aa sources have identical cut-key script, F18 restart helper, peer runner, ledger RPC, registry and multiplayer timeout config. Session's intervening change is the feast-only personal-view refresh; it returns for host or any action other than feast_cook/feast_feed. No causal path from that change to this key wait was found.

## Latent timing contract issue

The config describes180000ms as a hard ceiling, but the locked engine's [ENet implementation](https://github.com/godotengine/godot/blob/5b4e0cb0f/thirdparty/enet/protocol.c#L1351) checks timeoutMaximum only after a command's current roundTripTimeout expires, then doubles that interval. This can overshoot the configured maximum. A source-equation model of one continuously unacknowledged command with immediate retries and min135000/max180000/limit32 yields262143ms at initial RTO1ms,196605ms at3ms, and163835ms at5ms. These are examples, not recovered packet timings from the failed run. They show why a passing predecessor run does not establish a deterministic201s bound.

## Changes and next evidence

The existing expect_peers failure path now retains start/end read-only observations: registry IDs, SceneMultiplayer polling/paused status, connection status, physical peer states, mean/last RTT, variance and packet loss. It avoids get_peer on nonphysical or no-longer-exposed IDs. No poll, ping, registry mutation, disconnect, timeout or PASS decision was added. Static diff checks pass; GDScript/native validation is pending root service.

This does not fix disconnect behavior. An unchanged retry is not justified as an infrastructure-only recovery. A root-approved instrumented reproduction at the same budget would be diagnostic evidence only, even if it happens to pass. If ENet remains connected, the substantive product fix needs a wall-clock liveness contract independent of retry backoff, while preserving the120s procedural-loading allowance and authentic reconnect/owner-save semantics. If ENet has disconnected, fix registry cleanup instead. Public ENetPacketPeer statistics expose RTT/state but not last-receive or earliest-timeout clocks, so a product watchdog cannot safely be invented from RTT alone. Do not force-remove a peer in the test or raise its wait to turn this red run green.
