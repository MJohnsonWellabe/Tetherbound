# Lane 2.A — Session: host/join/leave, registry, handshake, snapshot, reconnect, host exit (Opus)

**Base:** the Wave 2 branch tip after Wave 1 has landed on `main` (sha named at provisioning).
**Contracts:** decisions D95 (transport, two channels), D100 (autosave ownership), D105 (clock is
host truth), D97's interim rule (`enter_realm` refused in a multi-peer session); plan row 2.A;
`docs/specs/MP_NET_HARNESS_CONTRACT.md` §4's net-specific steps (`host`, `join`, `leave`,
`expect_peers`, `wait_flag`) which you make real in `tools/net/peer_runner.gd`; the ENet spike
report `ralph/reports/MP-0C-SPIKE-ENET-0905/` (peer ids are random 32-bit; state boxes for
signal flags; spawn wiring order). Read `ralph/briefs/MP-W1/COMMON.md` for the operating rules.

**Player-visible outcome.** One player hosts a world (solo is a one-peer session — Start/Load
World calls `Session.host()`), up to three join by IP, everyone sees the registry agree, a
joiner receives the world snapshot before it can act, a rejoin by character id resumes, and
when the host quits the world saves and every client returns to the title screen cleanly.

**Files you own:** new `scripts/net/session.gd` (a `Node` child of `Game`, mounted in
`Game._ready()` — the one-autoload rule stands), `scripts/net/peer_registry.gd` (pure,
`RefCounted`), `data/config/multiplayer.json` (add the session keys beside 0.F's
`test_budgets`), the autosave call sites in `autoload/game_state.gd` and
`scripts/world/night_rest.gd` (route through `Session.is_host()`, replacing 1.C's stub), the
`enter_realm()` guard in `game_state.gd`, host-clock replication (`Game.day`,
`clock_elapsed_seconds` → `world_look.gd::resume_at_elapsed` on clients), the net-specific
step arms in `tools/net/peer_runner.gd`, `tests/test_peer_registry.gd`,
`tests/smoke_net_host_join_leave.gd`, `tests/smoke_net_host_exit_saves.gd`, an `is_server()`
assertion added to `tests/smoke_playground.gd`, and your report.

**Deliverables.**
1. `Session.host(port)`, `join(ip, port, character_summary)`, `leave()`, `kick(peer)`;
   `is_host()`, `peer_count()`, `peers()`; signals `peer_joined(peer_id, character_id)`,
   `peer_left`, `snapshot_applied`, `session_ended(reason)`. Two ENet channels (D95).
2. Registry: peer id ↔ character id ↔ display name ↔ realm ↔ `sleeping`/`downed` flags
   (placeholders for Waves 4–5). Host-authoritative; replicated as a whole on change.
3. Handshake: client sends its character summary; host replies with the world snapshot
   (`WorldState.save_data()`) on the snapshot channel, then the registry; the client applies the
   snapshot through `WorldState.load_data()` and re-runs `restore_progression_from_game` on its
   world. A joiner cannot send intents until `snapshot_applied`.
4. Reconnect: a client reconnecting with the same character id within `reconnect_window_s`
   resumes its registry row; otherwise it joins fresh.
5. Host exit: `Session.end()` saves the world (host only), broadcasts `session_ended`, waits
   one round trip, disconnects; clients save their character and `change_scene_to_file` to the
   title with a message. A client never writes `user://worlds/`.
6. `enter_realm()` in a multi-peer session pushes a world message and returns false (D97).
7. Solo unchanged: `Session.host()` with no peers; `smoke_playground` asserts
   `multiplayer.is_server()`.

**Proof.** `test_peer_registry.gd` (pure interleavings: join/leave/rejoin/kick, seen red);
`smoke_net_host_join_leave.gd` (# peers: 2 — host, join, `expect_peers 2`, leave, `expect_peers
1`, rejoin by character id, registry rows compared across peers, hashes equal);
`smoke_net_host_exit_saves.gd` (host writes `worlds/<id>/world.json`, client's `user://worlds/`
is empty, client lands on the title); both run against the previous wave head first and must
fail there (negative control); solo smokes `smoke_playground`, `smoke_title_new_game`,
`smoke_title_load_game`, `smoke_save_persistence`, `smoke_menu` green first attempt.
