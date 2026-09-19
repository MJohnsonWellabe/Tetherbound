# MP net harness — contract

**Status:** Stage B lane 0.A output, 2026-09-05. This is the contract lane 0.F builds to and every
`tests/smoke_net_*.gd` is written against. It is deliberately written before the harness exists,
for the same reason `tools/gate_f/SEGMENT_SCHEMA.md` was: a vocabulary invented one step at a time
ends with three ways to press a button and no way to prove two peers agree. Where this document
and the harness disagree, fix the harness or amend this document in the same commit — never both
silently.

Plan: `docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` (Wave 0 row 0.F, §7 Verification).
Spike evidence it rests on: `ralph/reports/MP-0C-SPIKE-ENET-0905/`, `MP-0D-SPIKE-HOSTCOST-0905/`.

---

## 1. What it is, and what it is not

The harness drives **N real, isolated, headless Godot processes** — one host, up to three
clients — through a scripted scenario, from one coordinator, and returns one verdict. It exists so
that a claim like "two players cannot both collect one pickup" is a smoke that fails on the
previous wave's head and passes on this one, rather than a sentence in a report.

It is **not** a second input harness: inside a peer, every press is a real `InputEvent` through
`Input.parse_input_event` against the live InputMap, walking is `tests/helpers/stick_navigator.gd`,
and state is read through `scripts/debug/gate_f_probe.gd` — the same seams Gate F uses. The
harness adds exactly two things Gate F lacks: **more than one process**, and **a way to prove
their world state agrees**.

It is also **not** a test of the game until Wave 2 gives it a session to join. In Wave 0 it boots
two Meadows worlds and exchanges one message over its own control channel; that proves the
instrument, nothing else, and the Wave 0 report says so.

---

## 2. Processes and roles

```
coordinator  (tests/smoke_net_<name>.gd, extends tests/helpers/net_harness.gd, headless SceneTree)
   │  launches with OS.create_process, one per peer, each with its own XDG_DATA_HOME
   ├── peer 0  role=host    (tools/net/peer_runner.gd, headless SceneTree)
   ├── peer 1  role=client
   ├── peer 2  role=client        ← 3/4-peer runs are nightly / owner-kit only, never PR CI
   └── peer 3  role=client
```

- **Coordinator** — a Godot script so a net smoke is a normal `tests/smoke_*.gd` file: same
  invocation, same `failures` array, same exit-code convention, discoverable by
  `tools/run_all_smokes.sh`. It owns the run directory, launches and reaps peers, serves the
  control channel, sequences steps, collects verdicts, runs the desync detector, and writes
  `NET_RUN.json`. It never loads a world scene itself.
- **Peer runner** — one script for every role. Boots the requested scene exactly as the existing
  smokes do (`load → instantiate → root.add_child → await physics_frame × settle`), connects to
  the coordinator, then executes steps as they arrive. From Wave 2 it hosts or joins through the
  game's own `Session` API; until then it runs the Wave 0 loopback scene from spike S1.
- **Launcher** — `tools/net/run_net_smoke.sh <smoke> [--peers=N] [--out=dir]` for CI and for
  humans: sets the run id, calls the coordinator, tails the summary, and **kills orphans by run
  id** on any exit path (`pgrep -f "TB_NET_RUN_ID=<id>"`), the way `tools/gate_f/run_segment.sh`
  does for Gate F. Spike S1 decides whether the coordinator can launch peers itself with
  `OS.create_process`; if it cannot inherit `XDG_DATA_HOME`, the launcher starts the peers and
  passes the coordinator their control ports.

Isolation, non-negotiable: every peer gets `XDG_DATA_HOME=<run>/home-<i>` (the `flake_rate.sh`
rule — one machine, many runs, no shared `user://`), its own log file, its own ENet port
(`base + i`) and control port (`control_base + i`), and the environment variable
`TB_NET_RUN_ID=<run id>` so nothing outside this run is ever killed.

Run directory: `<out>/net-<smoke>-<UTC stamp>/` containing `peer-<i>.log`, `home-<i>/`,
`NET_RUN.json`, and `SUMMARY.md`. Under `ralph/reports/` only when a lane commits a verdict; the
default is the scratch/`/tmp` location so payload never lands in the tree (AGENT_WORKFLOW §8).

---

## 3. Control channel

TCP on localhost; the **coordinator is the server** (`TCPServer`), each peer connects
(`StreamPeerTCP`) on boot and identifies itself. Newline-delimited JSON, one object per line,
both directions. Peers process one step at a time; the coordinator may address several peers
in one frame (that is how a race is issued — see §6).

Coordinator → peer:

| Message | Fields | Meaning |
|---|---|---|
| `step` | `id`, `action`, `args` | Execute one step (§4), reply with a `verdict`. |
| `probe` | `id`, `what`, `args` | Read something (§5), reply with a `value`. |
| `quit` | `code` | Save nothing, exit with `code`. |

Peer → coordinator:

| Message | Fields | Meaning |
|---|---|---|
| `hello` | `peer`, `role`, `pid`, `godot_version`, `main_sha` | Sent once, after the scene settles. |
| `verdict` | `id`, `verdict` (`PASS`/`FAIL`/`ERROR`), `detail`, `frames_used` | One per `step`. `ERROR` is a harness fault (unknown action, missing control), never a game fault. |
| `value` | `id`, `value` | One per `probe`. |
| `heartbeat` | `frame`, `physics_frame`, `t`, `pos`, `context`, `state_hash`, `session_peers` | Every `heartbeat_frames` (default 60 physics frames). The desync detector reads `state_hash`. |
| `log` | `level`, `text` | Forwarded `push_error`/`push_warning` lines and the peer's own notes, so the coordinator log is readable alone. |

Timeouts: a `step` that produces no `verdict` within its `budget_frames` (plus 5 s of wall clock)
is a `FAIL` recorded by the coordinator with `detail: "no verdict"`. A peer whose heartbeat
stops for 15 s wall clock is `ERROR: peer silent` and the run is aborted (exit 2). A peer that
exits is `ERROR: peer exited <code>` unless the coordinator sent `quit`.

---

## 4. Step vocabulary

Every step carries `id`, `action`, `args`, `budget_frames` (default 3000) and, like Gate F,
`expected` — the human sentence a reader compares against; it is not machine-checked.

Reused from Gate F with identical semantics (0.F ports the implementation from
`tools/gate_f/operator_harness.gd` rather than re-inventing it; it may `preload` that file's helpers
where they are pure):

| Action | Args | Notes |
|---|---|---|
| `boot` | `scene` (`title`/`world`/`cloudreach`), `settle_frames` | Same 240-frame settle as `smoke_playground.gd`. |
| `wait` | `frames` or `seconds` | Play time. |
| `press` | `action`, `times` (1), `gap_frames` (18) | Real `InputEventJoypadButton`/key through the live InputMap. |
| `hold` / `release` | `action`, `frames` | |
| `stick` | `x`, `y`, `frames` | Left stick. |
| `move_to` | `x`, `z`, `close_enough` (0.8) | `stick_navigator.walk_to`. A leg that stops short is FAIL with the shortfall in metres. |
| `interact_with` | `name` | Walk to and press `interact` on the named `Interactable`. |
| `advance_dialogue_until_closed` | as Gate F | |
| `fight_until_resolved` | as Gate F | |
| `assert` | `check`, args | Every Gate F `check` (`flag_set`, `party_size`, `inventory_count`, `near`, `input_context`, `combat_running`, `enemy_hp_fraction`, `placed_buildings`, `clock_hour`, `satiety`, `mouse_captured`, …). |

New, net-specific:

| Action | Args | Passes when |
|---|---|---|
| `host` | `port`, `max_peers` | `Session.host()` returned OK and `multiplayer.is_server()`. |
| `join` | `host`, `port`, `character` | `Session.join()` connected and the handshake completed (world snapshot applied). |
| `leave` | — | Clean disconnect; the peer keeps running for probes. |
| `expect_peers` | `count`, `budget_frames` | The session registry reports exactly `count` peers. |
| `wait_flag` | `flag`, `budget_frames` | The (world or player, by scope) flag becomes set. |
| `wait_until` | `check`, args, `budget_frames` | Any `assert` check, polled until true. |
| `state_hash` | — | Returns the hash (§7); also an `assert` form `state_hash_equals: <hash>`. |
| `save` | — | The peer saves what its role may save (host: world + own character; client: own character only). |
| `sleep_in_bed` | — | Walks to the nearest own bedroll and rests (Wave 5). |

Rules carried over from Gate F: an unknown action is a harness `ERROR` and stops the run; a
press is never a proof — every engage/fight/gather step is followed by an `assert` that reads
state; `move_to` never teleports (a `teleport` exists only behind `diag: true`, exactly as Gate
F, and a smoke that uses it cannot be acceptance evidence).

---

## 5. Probes

`probe` reads, never acts. `what` is one of: `position`, `input_context`, `party` (the Gate F
`party_state()` shape), `inventory_count` (`item`), `flag` (`id`), `placed_buildings`,
`session` (`{is_server, peer_id, peers: [...], realm}`), `state_hash`, `save_dict`
(the full world save dictionary — large, for diffing a late joiner against the host in 7.A),
`custom` (`expr` — a `gate_f_probe.gd` accessor name and args; nothing else is evaluated).

---

## 6. Coordinator API (what a smoke author writes)

`tests/helpers/net_harness.gd` (`extends SceneTree`) exposes, all awaitable:

```gdscript
launch(peers: int, scene: String, extra_args: Array = [])    # starts peers, waits for every hello
step(peer: int, action: String, args := {}, budget := 3000) -> Dictionary   # one verdict
steps(peer: int, list: Array) -> Array                                       # sequential
race(list: Array) -> Array         # [{peer, action, args}...] issued in ONE coordinator frame
probe(peer: int, what: String, args := {}) -> Variant
assert_all_hashes_equal(budget_frames := 300) -> bool
expect_desync_free(seconds: float) -> bool      # detector saw no divergence in the window
check(condition: bool, message: String)         # appends to failures, like every smoke
finish() -> int                                  # writes NET_RUN.json, quits peers, returns exit code
```

A `race` is the harness's honest limit: two processes cannot be frame-locked, so a race step
proves "no duplication **regardless of order**", not simultaneity. True simultaneity is proven
deterministically by the pure ledger/arbiter unit tests (`test_world_ledger_races.gd`,
`test_catch_arbitration.gd`) with explicit interleavings. Every net race smoke names the unit test
that covers the interleaving it cannot.

Exit codes mirror Gate F and the unit runner: `0` all checks passed; `1` a check failed;
`2` harness error (a peer died, a control timeout, an unknown action). CI treats 2 as red.

---

## 7. Desync detector

Every heartbeat each peer sends `state_hash`: the FNV/`hash()` of
`JSON.stringify(<world save dictionary>, "", true)` with the fast-changing keys removed
(`clock_elapsed_seconds`, `player_pose`, `satiety`, and every per-player key — the detector
compares **world** state, which every peer must agree on; player state is by construction
different per peer, and `satiety` drains with wall time like the clock does). Concretely, against
today's v22 keys: **hashed** — `progression`, `placed_buildings`, `farm_plots`, `death_satchels`,
`harvested_vegetation`, `felled_vegetation`, `day`; **excluded** — `party`, `inventory`, `hotbar`,
`satiety`, `map`, `realm_maps`, `alpha_pins`, `player_pose`, `clock_elapsed_seconds`,
`current_realm`, `pending_realm_entry`, `realm_hearts`, `version`; `world_seed` is erased from the
hashed dictionary and asserted separately against the pin. From Wave 1 the hashed set is
exactly `WorldState.save_data()` and the list above retires. **`world_seed` is
pinned**: `spawn_tables.json`'s `roll_new_worlds` gives every independent boot a random seed, so
the coordinator sets one `TB_WORLD_SEED` for every peer in a run (default `"0"`) and the peer
normalises the saved field to it for hashing only. Both amendments come from lane 0.F's real
runs (`ralph/reports/MP-0F-NET-HARNESS-0905/`); from Wave 2 the seed is the host's and arrives
in the handshake, and the pin becomes a harness convenience rather than a correctness patch. Before Wave 1 lands the dictionary is `Game.save_system.save()`'s; from Wave 1 it is
`WorldState.save_data()`; the key exclusion list lives in one place in the harness and is
printed in `NET_RUN.json`.

The coordinator keeps the last three hashes per peer. **Divergence** = no common hash among the
peers' last-three windows. A divergence that persists for `desync_frames` (default 240) is a FAIL
with the two offending peers' `save_dict` probes written to the run directory as
`desync-<peer>.json` so the diff is in the evidence, not re-derived. `assert_all_hashes_equal`
is the explicit form used at the end of every net smoke and after every ledger-mutating step
sequence.

---

## 8. Budgets and real-time rules

- Peers run **real-time physics**: `Engine.physics_ticks_per_second` untouched, no
  `max_physics_steps_per_frame` fast-forward (which dilates differently per process and made
  tolerances meaningless in review). A heartbeat carries `physics_frame` so the coordinator can
  report each peer's achieved tick rate; a peer below 80 % of nominal for 10 s is a `log`
  warning and the run's `SUMMARY.md` says so.
- Default per-step budget 3,000 physics frames; per-smoke wall clock **300 s of steps after both
  peers report `hello` for a 2-peer smoke on PR CI** (a cold Meadows boot is ~85 s per peer and
  is budgeted separately at 180 s), 1,500 s for 3/4-peer runs off-CI — spike S2's numbers
  (`ralph/reports/MP-0D-SPIKE-HOSTCOST-0905/`: four full boots need 12.85 GB, so 3/4-peer runs
  never share a 16 GB runner with PR CI); the harness reads them from `data/config/multiplayer.json` `test_budgets` so a
  change is data, not a rewrite.
- Position tolerances (used by `near` and by movement smokes): **1.5 m at rest, 4.0 m in
  motion**, provisional until 2.C measures interpolation lag; recorded in the same config block.
- Ports: ENet `base_port` 27801 + peer index; control `control_port` 27901 + peer index; both
  overridable by argument so two runs can coexist on one box.

---

## 9. Latency, jitter and loss

`tools/net/udp_proxy.gd` — a headless script that forwards UDP between a listen port and the
host's ENet port with `--delay-ms`, `--jitter-ms`, `--loss-pct`. Clients join the proxy port
instead of the host's. The coordinator starts it when a smoke passes `net_conditions`. 7.A runs
`smoke_net_shared_wild_fight` and `smoke_net_catch_race` at `delay 150 / jitter 30 / loss 1`
and records the verdict beside the clean one. Not a substitute for the owner's real LAN run; a
way to make a latency-sensitive regression reproducible in a container.

---

## 10. CI shape

`verify-multiplayer-shard` in `.github/workflows/ci.yml`: conditioned on
`needs.changes.outputs.code == 'true'`, runs `tools/net/run_net_smoke.sh` for every
`tests/smoke_net_*.gd` **whose header declares `# peers: 2`**, `RETRIES: 1` (a net smoke that
passes on retry is a finding), uploads the run directory as an artifact, and fails on any
non-zero exit. Smokes declaring `# peers: 3` or `# peers: 4` run only from the
`workflow_dispatch` job `verify-multiplayer-wide` and from the owner kit. Timeout 25 min.

---

## 11. The negative-control rule

A net smoke is not evidence until it has been run against the head of the previous wave and
**failed there for the right reason**. The lane report records the command, the failing
verdict and the assertion it named. A harness that only ever saw green is a harness whose
checks are unproven — the same rule the unit tests already live under.

---

## 12. What 0.F delivers, in order

1. `tools/net/peer_runner.gd` booting the spike-S1 loopback scene, connecting to the control
   channel, answering `boot`, `wait`, `press`, `assert input_context`, `probe position`, `quit`.
2. `tests/helpers/net_harness.gd` with `launch`, `step`, `probe`, `finish`, the heartbeat
   reader and the desync detector (against `Game.save_system.save()` for now).
3. `tools/net/run_net_smoke.sh` with isolation and orphan kill.
4. `tests/smoke_net_two_peers_boot.gd` (`# peers: 2`): both peers boot the Meadows world, both
   heartbeat, both hashes equal, one `press` on each is reflected in `input_context`, exit 0.
   Then the negative control: kill one peer mid-run and show exit 2 with `peer exited`.
5. The CI job, with the run directory uploaded.
6. `tools/net/udp_proxy.gd` may slip to Wave 7 if time runs out; say so in the report.

Opus reviews the control protocol implementation against §3–§7 before the wave lands; the
review's findings are fixed in the same wave.
