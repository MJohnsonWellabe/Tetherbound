# MP-2B-JOINUI-0906 — a human can join a game

Lane 2.B of Stage B. Branch `claude/mp-2b-joinui`, based on `main` @ `a3df2546`.
Godot 4.7-stable installed at `~/godot-bin/godot`; `--import` run twice on a
fresh checkout, second run **0 errors**.

Before this lane, everything under multiplayer worked and thirteen two-process
CI smokes proved it — and no player could reach any of it. `title_screen.gd`
called `Session.host()` on Start and Load and that was the only door. The join
in every smoke went through `tools/net/peer_runner.gd`'s test-only `join` step.

---

## 1. A join path on the title screen — **DONE**

`Join a Game` now sits between Load and Quit on the title screen, controller
only, no keyboard required.

- **LAN list.** A `PacketPeerUDP` beacon (D95: direct IP plus a LAN beacon, no
  relay, no Steam). New `scripts/mp/lan_beacon.gd` holds BOTH ends of the one
  packet format — the host's `serve()` broadcast and the join screen's
  `listen()` — because a sender and a reader in two files drift silently. The
  host mounts it under `/root/Game` on the way into the world, so it outlives
  the title screen; the join screen mounts a listener that dies with the
  screen. Rows are rebuilt only when the advertised set changes (a focusable
  list rebuilt every frame is a cursor that cannot be moved), and focus is
  restored by which GAME it named, not by index.
- **Join by address.** Reuses the game's one on-screen keyboard rather than
  building a second: `name_prompt.gd` gained `open_entry(title, prefill, grid,
  cap, blank_hint, cancellable)` and `name_entry.gd` gained a second row set
  (`ADDRESS_ROWS`, digits and `. : -` first, then the alphabet for a hostname)
  and an instance `max_length`. `open()` delegates with the old arguments, so
  the naming panel is behaviourally unchanged. **B is backspace as it always
  was, and only backs OUT of a cancellable prompt when the buffer is empty** —
  one button, one meaning.
- **The two failures are two messages**, because they send the player to
  different fixes:
  - refused connect → *"No game answered at 10.0.0.5:27015. Check the address,
    and that the host has their world open."*
  - connected, no snapshot → *"Reached 10.0.0.5:27015, but their world never
    arrived. The host may not be ready — ask them to load their game, then try
    again."*
  They are told apart by ENet's own timing (`session.connect_timeout_s`), not by
  reading `session.gd`'s private state.

### Finding, and the design it forced

**A peer holding a live ENet connection does not survive building the Meadows.**
Measured, twice, on the first two runs of the new smoke: the joiner connected
from the title screen, applied the snapshot, changed scene, and spent ~85 s in
one blocking frame (spike S2's number) servicing nothing — ENet timed it out,
`session.gd::_on_server_disconnected` sent it back to the title, `--mp-join`
dialled again, and it looped at about ninety seconds a lap. `peer-1.log` from
run `net-20260906T071058Z` shows two complete world builds and three dials.

The fix is an inversion, and it is entirely in this lane's files: **the joiner
enters the world FIRST with no session at all, then dials from the far side.**
A session-less process is `is_host()` true with one peer and is exactly the
state every headless tool already runs in, and
`game_state.gd::apply_world_snapshot()` was already written for this arrival —
*"a joiner whose Meadows is already standing has to be told which one-shot
pickups are gone."* New `scripts/mp/join_driver.gd` is what does it: mounted
under `/root/Game` by the title screen (which is then freed by the scene
change), waits for the world scene, dials, polls, retries, and on final failure
closes the socket, returns to the title and leaves its reason where the title
screen reads it on the way up.

**Handover (lane 2.A):** the other half of this is ENet's peer timeout, which is
`scripts/net/session.gd`'s to set and this lane does not touch. Raising it would
make a mid-build disconnect survivable rather than merely avoided, and it is the
difference between a joiner and a player who is *already* in a session when a
realm change or a long load blocks their process.

**Cost of the inversion, stated plainly:** a mistyped address is now discovered
after the world build rather than before it. The player is returned to the join
screen with the exact reason, and the LAN list — where the address came off a
host that is demonstrably advertising — is the path that does not have the
problem.

## 2. A Players tab — **DONE**

`data/config/menu.json` gains one entry, `scripts/ui/tab_players.gd` is the
body, and **`scripts/ui/game_menu.gd` was not edited.** Eight tabs now; the
shell reached all eight with a physical RB in `smoke_menu`.

It is honest in all three states:

- **no session at all** (the port could not be bound, or nothing hosted):
  *"This world is not open to anyone else. The network port could not be opened,
  so nobody can join this game."* — not an error, not an empty void.
- **a solo session**, which is what every ordinary game is: *"You are playing
  alone. Up to 4 players can share this world."* plus the row for you (tagged
  `host, you`) and every IPv4 address on the machine with the port **actually
  hosted** — a host launched `--mp-host 27100` quotes 27100, not the config's
  27015. (That was a real defect the probe caught; the port comes from the
  beacon, since `Session` does not expose its bound port.)
- **company**: one row per peer with realm and `down`/`asleep` tags, and a
  Remove button beside every guest **when this peer is the host** — never
  beside the host's own row, never on a client, because `Session.kick()`
  refuses both and a button that is refused when pressed is worse than no
  button.

Authority is asked of the session every poll, never cached and never asked of
`multiplayer.is_server()` — with no session that is `true` and `get_unique_id()`
is `1`, which is exactly what would have made this tab lie.

## 3. Command-line entry — **DONE**

Parsed in `scripts/ui/title_screen.gd`, documented in that file's header (the
file that parses them), routed through the same `Session.host()` /
`Session.join()` the buttons call. **These are the exact flags for
`tools/owner/`:**

```
--mp-host [port]            Start a NEW game, host it, go straight in.
                            Port optional; defaults to multiplayer.json's
                            session.port (27015). Hosting a SAVED world has no
                            flag — the Load button already hosts.

--mp-join <address[:port]>  Load this machine's autosave (or mint a fresh
                            character when there is none), enter the world,
                            dial that host, and play. Port defaults to 27015.
```

- Both forms accepted: `--mp-host 27100` and `--mp-host=27100`.
- Read from **both** `OS.get_cmdline_args()` and `OS.get_cmdline_user_args()`
  (the tokens after a bare `--`), the `operator_harness.gd` precedent.
- The first multiplayer flag on the line wins; a malformed address is refused
  with a warning rather than half-applied.
- `--mp-join` is **patient**: it re-dials both failure kinds for 180 s
  (`CMDLINE_JOIN_RETRY_S`), 2 s apart. The kit launches a host and three clients
  in the same second and every one of them is inside its own ~85 s world build;
  a client that gave up on the first refusal could never join a host started
  beside it. A player who typed an address gets the answer immediately instead.

Examples:

```
Tetherbound.exe --mp-host 27015
Tetherbound.exe --mp-join 192.168.1.24
Tetherbound.exe --mp-join=192.168.1.24:27015
godot --headless --path . --script tools/net/peer_runner.gd -- \
    --role=host --peer=0 --control-port=27901 --enet-port=27801 \
    --scene=title --mp-host=27801
```

---

## Commands run, and their counts

Every one of these was run on this branch. First-attempt results; nothing below
needed a retry, and nothing below was re-run to make it green.

| What | Command | Result |
|---|---|---|
| Import (fresh) | `godot --headless --path . --import` ×2 | exit 0, **0 errors** |
| Parse | `--check-only` on all 12 changed/new `.gd` files | **12/12 clean** |
| Menu data | `run_tests.gd -- --only=menu` | **12 tests, 167 assertions, 0 failed** |
| Name entry (touched) | `run_tests.gd -- --only=name_entry` | **15 tests, 236 assertions, 0 failed** |
| Solo | `tests/smoke_menu.gd` | `menu smoke test passed`; **RB reached all 8 tabs** |
| Solo | `tests/smoke_title_new_game.gd` | `title new game: OK` |
| Solo | `tests/smoke_title_load_game.gd` | `title load game: OK` |
| Solo | `tests/smoke_playground.gd` | `smoke: OK` |
| Naming panel (touched) | `smoke_name_prompt_controller.gd` | `OK` |
| Naming panel (touched) | `smoke_name_prompt_keyboard.gd` | `OK` |
| Naming panel (touched) | `smoke_rename_pad_trigger.gd` | `OK` |
| **New net smoke** | `tools/net/run_net_smoke.sh join_by_address` | **17 assertions, 0 failed, ALL CHECKS PASSED** |
| Existing net smoke (harness changed) | `tools/net/run_net_smoke.sh host_join_leave` | **21 checks, ALL CHECKS PASSED** |
| Beacon listener | `tools/_probe_lan_beacon.gd` | **17 assertions, 0 failed** |
| Flag parser | `tools/_probe_join_flags.gd` | **17 assertions, 0 failed** |
| Players tab | `tools/_probe_players_tab.gd` | **14 assertions, 0 failed** |

Assertion counts are reported rather than pass/fail alone, and the new smoke
prints its own (`assertions run: 17`) so a future run that quietly asserts less
is visible in the log rather than inferred from a green tick.

### `tests/smoke_net_join_by_address.gd`

Two peers, both booting `--scene=title` — the real front door — and reaching the
session **only** through the command-line flags. It deliberately does not use
`peer_runner.gd`'s `host` or `join` steps; the coordinator issues nothing until
both peers are already up, so everything asserted at that point was done by the
flags alone.

```
PASS: derived the host's ENet port before launch (33681)
PASS: --mp-host bound a live listen server with no step telling it to (mode 'host')
PASS: --mp-host left the title screen and entered the world (context 'world')
PASS: the host's registry reached 2 peers with only --mp-join driving the joiner
PASS: --mp-join carried the joiner off the title screen into the world
PASS: peer 1 applied the host's world snapshot -- the handshake finished, not just the socket
PASS: peer 1 holds a real assigned ENet id, not the session-less 1 (got 406180608)
PASS: the registries agree across peers: host [1, 406180608] vs client [1, 406180608]
assertions run: 17
ALL CHECKS PASSED
```

Negative control: on `main` (no flags, no parser) the joiner boots to a title
screen and stays there — `expect_peers` fails as `registry reports 1 peer(s),
wanted 2`, which is precisely the state this lane found the game in.

Registered in `.github/workflows/ci.yml`'s `verify-multiplayer-shard`, in the
named `for required in` roster and in the count floor. **The floor was
regenerated from the files actually on disk (14), not incremented**: the comment
around it had already accumulated four duplicated fragments from four lanes
resolving the same conflict in turn, and those are now replaced with one
statement that the `for required in` list is the authority.

## Harness changes, and why each was needed

Three, all additive; every smoke written before them is unchanged.

1. **`tests/helpers/net_harness.gd` — `launch(..., per_peer_args)`.** A
   command-line flag is fixed at process start, so a joiner reaching the session
   through `--mp-join <host>:<port>` must carry the host's port in the argv it
   boots with. `extra_args` goes to every peer; this goes to one.
2. **`net_harness.gd` — `run_id()` / `enet_port_for(i)`.** The same derivation
   `launch()` already used, called instead of restated, so a smoke can know a
   peer's port *before* launch. A second formula would be a smoke dialling a
   port nothing listens on and reporting a join failure that is really
   arithmetic.
3. **`net_harness.gd` — `heartbeat_silence_tolerance_s`, and
   `tools/net/peer_runner.gd` — a `wait_context` step.** Contract §3's 15 s
   "peer silent" rule is right for a peer that only walks and presses things,
   and wrong for one that changes scene *after* hello: building the Meadows is
   one blocking frame of ~85 s and the detector cannot tell that from a hang.
   This is the only smoke in the directory whose peer changes scene after hello
   and the only one that raises the tolerance (to 240 s). `wait_context` is
   `assert input_context` that can WAIT — the existing assert answers on the
   frame it arrives, and a peer mid-build answers nothing at all.

## Findings

1. **A live ENet peer does not survive a blocking scene build.** Section 1
   above. Fixed here by ordering; the durable fix (ENet peer timeouts) is a
   handover to lane 2.A.
2. **The Players tab quoted the configured port, not the hosted one.** Caught by
   `_probe_players_tab.gd`, not by any smoke: `Session` does not expose its bound
   port, so `--mp-host 27100` would have told a friend to type `:27015`. Fixed —
   the beacon carries the served port and the tab reads it.
3. **`JSON.parse_string` pushes an engine ERROR per malformed packet.** The
   beacon listens on a port anyone on the LAN can send anything to, so one
   stray broadcaster would have filled the log with parse errors about somebody
   else's protocol. Switched to a `JSON` instance, which returns the failure.
4. **No smoke retried.** Nothing here is 1-fail-then-green. The two red runs of
   the new smoke were the disconnect defect above, reproduced twice with the
   same cause, and were red on the *product*, not on the instrument.

## Handovers

- **Lane 2.A / `session.gd`:** ENet peer timeouts (finding 1). Also
  `session.gd::_save_character_here()` prints *"client leave: no character file
  to write yet"* from `game_state.autosave_here()` as well as from an actual
  leave — it cost real time reading a log, since it makes an ordinary autosave
  look like a disconnect.
- **D100 / character split:** `_begin_join()` continues this machine's autosave
  if there is one and mints a fresh character otherwise. That is the honest
  answer available today (a client writes no world file, so neither choice can
  damage the save it started from); when the per-character file lands it should
  become a character picker.
- **One machine, one LAN listener.** Godot's `PacketPeerUDP` exposes no
  SO_REUSEPORT, so only one process per box can bind the beacon port. Correct
  for several machines on a LAN, which is what it is for; the second copy gets a
  sentence rather than an empty list, and the owner kit's four-on-one-box case
  uses `--mp-join` rather than the list. Noted so it is not rediscovered.
- **`tests/smoke_net_sleep_vote.gd.uid` is missing from the tree** (lane 5.D
  shipped the script without it). Left untracked here rather than committed, to
  keep a generated file out of a five-lane merge.
- **Not covered by a test:** the LAN list's own drawing and focus behaviour, and
  the address prompt's grid, are exercised only by hand-reading. Their inputs
  (the beacon's parse/TTL and the flag parser) are probe-covered; the Controls
  above them would need a UI smoke this lane's "minimal, and that is an
  instruction" budget does not stretch to.
