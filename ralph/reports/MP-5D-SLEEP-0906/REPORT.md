# MP-5D-SLEEP-0906 — sleep is a vote

Stage B Wave 5 lane **5.D**. Branch `claude/mp-5d-sleep`, off
`claude/tetherbound-roadmap-next-jrcjs8` (`b9c5f1e1`, main + Wave 3 verb conversion +
stable building uids). D105 is the contract; the host clock half of it was already
landed by lane 0.A/2.A and this lane **consumes** it rather than rebuilding it.

---

## Item by item

| # | Item | Verdict |
|---|---|---|
| 1 | The host tracks which peers are sleeping; `pass_the_night` runs on the host only when every connected, non-downed peer is in a bed | **DONE** — `night_rest.gd`, asserted by `smoke_net_sleep_vote` (both halves) |
| 2 | A player in bed sees who else is still up, one line, no panel | **DONE** — `_repaint()`, one `push_world_message` line, repainted off the replicated registry with no RPC of its own |
| 3 | The day and clock are host truth, replicated; a client never advances the day itself | **DONE (consumed, not rebuilt)** — `Game.advance_day()`'s existing refusal is relied on, and the host's day reaches a client through `Game.apply_host_clock()`, the same seam `session.gd::_rpc_clock` uses |
| 4 | Solo unchanged: one player, one bed, night falls, no vote and no waiting | **DONE** — `rest()` takes `_rest_alone()` when `is_multi_peer()` is false and `is_host()` is true; `smoke_home_sleep`, `smoke_clock_survives_a_reload` and `smoke_playground` all pass first try |
| 5 | A downed player does not block the vote | **DONE as a hook, wired both ways** — see F3. Lane 4.E has to set one already-replicated field and nothing here changes |
| 6 | A player who disconnects while asleep must not hold the night open | **DECIDED and implemented** — see F2 |
| 7 | Judgement on `creature_bed.gd`'s `static var _panel` vs lane 3.D's F4 | **AGREE with F4** — written into the file; see F5 |
| 8 | ONE new net smoke, registered in CI (count floor **and** named list) | **DONE** — `tests/smoke_net_sleep_vote.gd`, floor raised 8 → 9, name added |

---

## What was built

**`scripts/world/night_rest.gd`** is now a `Node` as well as the same static
definition of what a night costs. The statics (`rest`, `pass_the_night`) are unchanged
in signature and every existing caller — `rest_point.gd`, `grandpa_house.gd`,
`player_bed.gd`, `tools/gate_f/probe_daynight_after_rest.gd` — keeps calling them the
same way. `attach()` mounts one instance at `/root/Game/Session/SleepVote`, the same
idempotent pattern (and the same reason: identical node path in every process or the
RPCs do not resolve at all) `ledger_rpc.gd` uses. Nothing in `game_state.gd` or
`scripts/net/` was touched.

The flow:

- `rest()` asks the session — never `multiplayer.is_server()` — whether this is a
  multi-peer session **or** a client, at the moment of the press. Neither → today's
  solo path, byte for byte.
- Otherwise it registers a vote and returns, with **no fade**. The world stays playable
  while you wait, and pressing the bed again gets you back up.
- The host's tally is `peer_registry.gd`'s `sleeping` field — the one Wave 2 put on
  every row explicitly so this wave would add behaviour and not a new field on the
  wire. There is no second copy of it here.
- When nobody who could still vote is up, the host advances the day **first**, sends
  `_rpc_night_falls(day)`, clears the tally, and then runs its own night. Every peer
  runs `pass_the_night()` on **its own** process: its own trainer's vitals, its own
  creatures' bed rests, its own `player_slept_at_home`, its own sky. The host's day
  lands through `apply_host_clock()`, which is inert on the host.

**`scripts/build/player_bed.gd`** now routes through that one definition. It had been
carrying a *second, drifted copy* of the night — see F1.

**`scripts/build/creature_bed.gd`** — documentation only on the rest path (F5, F6).

---

## Commands run, and their counts

Godot **4.7-stable** (`v4.7.stable.official.5b4e0cb0f`) installed to `~/godot-bin/godot`;
`godot --headless --path . --import` run twice, both exit 0.

```
godot --headless --path . --check-only --script scripts/world/night_rest.gd      exit 0
godot --headless --path . --check-only --script scripts/build/player_bed.gd      exit 0
godot --headless --path . --check-only --script scripts/build/creature_bed.gd    exit 0
godot --headless --path . --check-only --script tools/net/peer_runner.gd         exit 0
godot --headless --path . --check-only --script tests/smoke_net_sleep_vote.gd    exit 0

godot --headless --path . --script tests/smoke_playground.gd                     exit 0, "smoke: OK"
godot --headless --path . --script tests/smoke_home_sleep.gd                     exit 0, "home sleep smoke test passed"
                                                                                 ("[rest] rested; day 2", "slept at home: day 1 -> 2")
godot --headless --path . --script tests/smoke_clock_survives_a_reload.gd        exit 0, "clock-survives-a-reload smoke passed"

tools/net/run_net_smoke.sh sleep_vote                                            exit 0, 23/23 PASS, ALL CHECKS PASSED
```

Every one passed **on its first attempt**. No retries were used and no run was retried
to turn a failure green. The net smoke was run a second time only because
`night_rest.gd` was edited after the first run began, so the first run had not
exercised the tree being shipped. Both runs are recorded: run
`net-20260906T053131Z-3316` (23/23, exit 0) and, on the delivered tree,
`/tmp/net-5d-b/net-sleep_vote-.../` (23/23, exit 0, peer id `231371296`). Neither run
needed a retry; a smoke that only passed on retry would be a finding, and neither is.

`ObjectDB instances were leaked` / `resources still in use` appear at exit in the solo
smokes. Engine noise at exit, not findings, and not chased.

### The net smoke's 23 assertions

Run `net-20260906T053131Z-3316`, `/tmp/net-5d/net-sleep_vote-20260906T053131Z/`.
The two that carry the lane:

```
PASS: the day did NOT advance while only one of two players was in bed (host: 1, was 1)
PASS: the day did NOT advance on the other peer either (client: 1, was 1)
...
PASS: the night fell once BOTH players were in bed (host: day 2, was 1)
PASS: both peers agree on the new day (host 2, client 2)
```

and the ones that prove the vote is *visible* and *replicated*:

```
PASS: peer 0 can name exactly 1 player still up (named 1: ["Trainer"])
PASS: peer 1's replicated registry shows exactly 1 player asleep (shows 1: { "1": true, "1622972089": false })
PASS: the host's tally is cleared after the night (still marked: { "1": false, "1622972089": false })
```

The negative half is asserted explicitly and it is the assertion that matters: a smoke
that only checked "the day advanced once both slept" would go green on a build where
the vote did nothing at all, because the first sleeper would have advanced the day the
pre-5.D way and the number would still read 2 at the end. Note also the peer id in that
dictionary — `1622972089`, not `1` — which is the ENet spike's finding 2 showing up in
real data.

**Assertion hygiene.** `_sleeping_count()` returns **-1**, not 0, when the probe comes
back without its key, so a payload that lost `registry_sleeping` fails the count checks
instead of quietly satisfying "cleared afterwards" with a zero. The probe itself skips
any registry row with no `peer_id` rather than reading `int(null) == 0` and inventing a
vote nobody cast, and `night_rest.gd::_rows()` does the same on the game side.

---

## Findings

**F1 — `player_bed.gd` was carrying a second, drifted copy of the night. Now routed.**
Not a multiplayer defect, found while wiring one. `night_rest.gd` exists precisely so
that "what a night costs and pays" is defined once, and `rest_point.gd` and
`grandpa_house.gd` both call it — but the bedroll, the buildable the tutorial ends on,
still had its own `_pass_the_night()` copied out of the old `camp.gd`. The copy had
drifted in two ways that matter now:

- it wrote `player_slept_at_home` through the **merged** progression view rather than
  the sleeper's own store (`Game.player_flags()`), which MP_STATE_SEAM.md §3 and the
  shared definition both already do;
- it called `save_game(autosave_slot())` **directly** rather than through D100's
  `Game.autosave_here()` routing — so on a client the bedroll would have written the
  host's world.

Both are fixed by routing, and `smoke_gateb_flags.gd`'s direct-call seam
(`bed.call("_pass_the_night")`) is preserved as a delegating wrapper rather than
deleted.

**F2 — a peer that disconnects while asleep. Decided: it neither blocks nor counts.**
`session.gd::_on_peer_disconnected` already removes the row and emits `peer_left`.
`SleepVote` listens to that signal (and to `peer_joined`) and re-tallies. Consequences,
stated so nobody has to re-derive them:

- a **sleeper** drops → its row is gone, so it is neither asleep nor awake; if everyone
  remaining is in a bed the night falls **immediately**, which is the desired
  behaviour and not a special case;
- an **awake** player drops → same re-tally, same immediate fall;
- the **last** sleeper drops while others are awake → `sleeping == 0` and nothing
  happens, which is correct: nobody is in a bed.

A dropped peer can therefore never hold the night open. This is not asserted by the net
smoke (that would be a second smoke; the instruction was one), so it is a reasoned
implementation, not a measured one — recorded as such.

**F3 — the downed hook, and what lane 4.E has to do (nothing here).** `peer_registry.gd`
already carries a `downed` field on every row, already replicated. `_evaluate()` counts
a downed peer as **neither** awake nor blocking, so lane 4.E closes rule 5 by calling
`registry.set_flag(peer_id, "downed", true)` on the host and letting the existing
registry broadcast carry it — no change to `night_rest.gd` at all. As of this commit
4.E had not landed, so the hook is **wired and unexercised**: nothing sets `downed`
yet, and the net smoke does not cover it. One consequence worth naming: a downed peer
is not counted as *sleeping* either, so if every peer is downed the night does not fall.
That is correct — nobody is in a bed — but it is a decision, not an accident.

**F4 — the mount race, and the retry that closes it.** `SleepVote` is mounted lazily
(`attach()`), because this lane may not touch `game_state.gd`, which is where
`LedgerRpc` gets its guaranteed mount. So a client can send its vote to a host that has
not mounted its own copy yet, and an RPC to a node that does not exist on the receiver
is **dropped in silence**. A sleeping client therefore re-sends once a second until the
host answers (either broadcast is an answer), and gives up after ten tries with "Nobody
answered. You get up again." rather than waiting on a night that is never coming. In
practice the host mounts the moment anything in its own tree beds down, and in the net
smoke the first send lands. **Handover:** the honest fix is one line in
`game_state.gd::_mount_session()` beside `ledger = LEDGER_RPC.attach(self)` —
`NIGHT_REST.attach(self)` — whenever the lane that owns that file is free. The retry
becomes redundant, not wrong.

**F5 — `static var _panel` in `creature_bed.gd`: AGREE with lane 3.D's F4.** The same
process-global pattern, reached independently and reaching the same conclusion for the
same reason: `static` is process-global, and Stage B gives one process exactly one
local player with one screen, so a second peer is a second *process* with its own
static. Two players opening two different creature beds never share this panel. It
becomes a real hazard the day one process drives two local players (split-screen),
where it would have to become per-player. Left as it is, with that reasoning written
into the file rather than only into a report.

**F6 — a shared creature bed has no replicated occupancy. Cosmetic today.**
`creature_bed.gd::occupant_index()` asks `Game.party`, which is this peer's own five,
so in a co-op session two players can each bed a creature down in the **same** shared
bed and each see only their own lying in it. Nobody's rest is stolen —
`complete_creature_bed_rests()` now runs on each peer's own process over its own party
— so the consequence is a wrong picture, not a lost overnight recovery. Closing it
needs replicated bed occupancy: a ledger intent that claims a bed by identity the way
lane 3.D claims a chest, refused when somebody already holds it. That is creature
ownership (4.B) plus a ledger op, not a rest-path change. Recorded in the file.

---

## Handovers

1. **Mount `SleepVote` eagerly** (F4). One line in `game_state.gd::_mount_session()`,
   beside the `LedgerRpc` mount, for whichever lane owns that file next. The retry in
   `night_rest.gd::_process` can then be deleted.
2. **Lane 4.E**: set `sleeping`'s sibling `downed` on the host's registry row and
   broadcast; rule 5 closes with no change to this lane's files (F3). Worth one
   assertion in 4.E's own smoke that a downed peer does not hold the night.
3. **Replicated creature-bed occupancy** (F6), for the lane that owns creature
   ownership plus a ledger op.
4. **The disconnect path is reasoned, not measured** (F2). If a later wave adds a
   second sleep smoke, "a peer that drops while asleep does not hold the night open" is
   the assertion to write.
5. `tests/smoke_cloudreach_act_one.gd` holds `const NIGHT := preload(".../night_rest.gd")`
   and never uses it. Dead const, not this lane's file, not touched.

---

## Files

Changed:

- `scripts/world/night_rest.gd` — the vote (owned)
- `scripts/build/player_bed.gd` — routed onto the one definition (owned)
- `scripts/build/creature_bed.gd` — rest-path documentation only (owned)
- `tools/net/peer_runner.gd` — two arms (`sleep_stand`, `sleep_press`) and two probes
  (`day`, `sleep_vote`); additive, expect a trivial conflict with other lanes
- `.github/workflows/ci.yml` — `verify-multiplayer-shard`: floor 8 → 9 and
  `tests/smoke_net_sleep_vote.gd` in the named list; additive, expect a trivial conflict

Added:

- `tests/smoke_net_sleep_vote.gd`

Not touched, as instructed: `autoload/game_state.gd`, `scripts/net/*`,
`autoload/world_state.gd`, `scripts/combat/*`, `scripts/player/*`,
`scripts/world/player_death.gd`, `map_state.gd`, `alpha_pins.gd`, `tab_map.gd`,
`quest_log.gd`, `tab_backpack.gd`, and the Wave 3 consumer files.
