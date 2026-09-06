# MP-OWED-SMOKES-0906 — the two owed rows, closed

**Branch:** `claude/mp-owed-smokes`, from `claude/tetherbound-roadmap-next-jrcjs8` at
`6c5189fb3df75d575df65843ba0dbe6d94c9e6a2` ("6.A's two smokes never opened the road to
Cloudreach"). Not rebased during the run.

**Lane:** `docs/acceptance/MULTIPLAYER_ACCEPTANCE.md` §17 items **16** (menus without freezing
others) and **6** (the first-successful-catch rule). Both had shipping code recorded as *owed*
rather than borrowing a neighbour's evidence.

**Godot:** installed 4.7-stable at `~/godot-bin/godot`
(`4.7.stable.official.5b4e0cb0f`); `--headless --path . --import` run twice, both exit 0.

---

## Verdicts

| Item | Verdict | Needed a code fix? |
|---|---|---|
| **16 — a menu does not freeze other players** | **PASS.** `tests/smoke_net_menu_does_not_freeze_peer.gd`, green locally, **61 assertions**, 0 failures. | **Yes.** D102 had never been implemented: `Session.pause_local()` did not exist and all six panels still set `get_tree().paused = true` unconditionally. |
| **6 — the first-successful-catch rule, over the wire** | **PASS.** `tests/smoke_net_catch_race.gd`, green locally, **45 assertions**, 0 failures. The race really forms and the arbitration is correct over the wire. | **No.** `catch_arbiter.gd`, `encounter_director.gd` and `combat_manager.gd` were already right; the lane added the two-process proof and two harness arms. |

Neither verdict rests on a retry: each smoke's final form was run twice from a clean tree and
was green both times. See **Runs** below, including the reds that came first and what each of
them actually meant.

---

## Item 16 — what the current state turned out to be

The brief said item 16 "has shipping code". **It did not.** Verified before writing anything:

```
$ grep -rn "pause_local" --include=*.gd .            # nothing outside docs/
$ grep -rn "get_tree().paused = true" --include=*.gd scripts/ autoload/
scripts/ui/craft_panel.gd:128        scripts/ui/storage_panel.gd:79
scripts/ui/swap_panel.gd:90          scripts/ui/game_menu.gd:349
scripts/ui/creature_bed_panel.gd:71  scripts/ui/shop_panel.gd:97
```

All six named panels paused the tree unconditionally, and `Session` had no `pause_local`.
`docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` §2.D (the lane that was to build it) had
not landed on this base. **A smoke asserting a thing nobody implemented is as useless as no
smoke**, so this is the finding, and the brief's own instruction applied: fix it if it is small
and local.

### The fix, and the one deliberate deviation from D102

`scripts/ui/local_pause.gd` (new) — `hold(tree)` pauses only when
`Game.is_multi_peer()` is false; `release(tree)` is unconditional, byte-for-byte the panels'
existing RG1 behaviour. The six panels call it instead of touching `paused` directly. Nine
lines changed per panel, comments included.

**Deviation:** D102 names the entry point `Session.pause_local(bool)`. `scripts/net/session.gd`
is on this lane's do-not-touch list (another lane owns it), and two lanes editing one file
concurrently is how a merge silently drops one of them. The contract is D102's exactly; only
the address changed, and `pause_local(tree, want)` exists under D102's own name so a reader
who greps for the decision finds the code. Moving it onto `Session` later is a pure rename:
the file asks `Game.is_multi_peer()`, which is `session.gd::is_multi_peer()` with a null guard.

`Game.is_multi_peer()` — never `multiplayer.is_server()`. Under `OfflineMultiplayerPeer` a
process with no session reports `is_server() == true` and `get_unique_id() == 1`, so that API
cannot tell solo from host.

### What the smoke proves, on one run

Solo half first, deliberately — a run whose multi-peer half passed because somebody deleted
the pause outright rather than making it conditional fails here:

```
PASS: SOLO KEEPS TRUE PAUSE: peer 0's tree is paused with no session (paused=true)
```

Then, with the panel open on the **host** and again on the **client**:

```
PASS: D102: peer 0's panel did NOT pause the tree in a session (paused=false)
PASS: peer 1 KEPT MOVING while peer 0 held a panel open: 2.71 m (bar 2.0 m)
PASS: peer 1 KEPT GATHERING: its satchel went 0 -> 1 berries with peer 0's panel open
PASS: peer 1 KEPT ACTING: it built with peer 0's panel open (ghost_ok=true; records 0 -> 1)
PASS: peer 0's own world verbs are stood down while its panel is open: 0.00 m on a full
      stick hold (bar 1.5 m, and under half of the 14.61 m it walks free)
PASS: and peer 0 got the world back: 2.56 m on the same hold that moved it 0.00 m a moment ago

PASS: D102: peer 1's panel did NOT pause the tree in a session (paused=false)
PASS: peer 0 KEPT MOVING while peer 1 held a panel open: 2.56 m (bar 2.0 m)
PASS: peer 0 KEPT GATHERING: its satchel went 0 -> 1 berries with peer 1's panel open
PASS: peer 0 KEPT ACTING: it built with peer 1's panel open (records 1 -> 2)
PASS: peer 1's own world verbs are stood down while its panel is open: 0.00 m
```

The recovery walk is the control for the suppression walk: same peer, same home, same stick
hold, 0.00 m with the panel up and 2.56 m with it down.

**What this does not prove, stated so nobody reads it as more:** `Session` and `LedgerRpc` are
`PROCESS_MODE_ALWAYS`, so a peer whose tree was wrongly paused would still answer some network
traffic. A gather that succeeded through a frozen host is not proof the host was not frozen.
`paused`, read off `SceneTree.paused` at the source, is the mechanism assertion; the walk, the
gather and the build are what item 16 is in the player's hands. Both, not either.

---

## Item 6 — the race forms, and the arbitration is right over the wire

`tests/test_catch_arbitration.gd` proves `catch_arbiter.gd` pure and deterministic. It cannot
prove the intent leaves a client, that the host arbitrates a remote throw against its own, or
that the loser is told over the wire. This smoke is that half.

**Lane 3.B's pattern reused, not reinvented.** The coordinator awaits each verdict before
sending the next, so two "throw now" messages are always a round trip apart. `catch_throw` with
`at_unix_ms` arms the throw and answers immediately, exactly as `pickup_take` does, so both
peers throw at one shared wall-clock instant with both intents in flight before either is
decided. It works: the race really formed on both runs.

```
PASS: the client's throw went out and waited for the host -- 'pending', which is not a refusal
PASS: the granted throw HELD the fight while its orb shook (§8): the record went to 'catching'
PASS: EXACTLY ONE peer's throw was granted: peer 0 ok=true, peer 1 ok=false
PASS: peer 1 (the loser) was refused with `already_resolving`
PASS: and it reads like something a player can act on: 'Somebody else's orb got there first.'
PASS: peer 1 (the loser) never played a catch resolution
PASS: and the refusal reached the player through `catch_refused`, not only the log
PASS: exactly 0 creature(s) entered the world: 0 owned before, 0 after
PASS: peer 0/1 still owns at most five creatures -- there is no sixth slot and no storage
```

**The host won all three observed runs**, which is not surprising and is written into the
smoke's header rather than left to be inferred: the host arbitrates its own throw inside its own
`submit_encounter_intent` call while the client's is still on the wire, so it is a round trip
ahead by construction. What this smoke is evidence for is that the SECOND throw to arrive is
refused, told why, and pays nothing. "The host's own throw loses it like anybody else's" is
proven in `test_catch_arbitration.gd`, which can prove it because it is pure.

The winner's decision on every run was a **breakout** (`caught: false, shakes: 2`), which is
expected: `catching.json` puts `hp_factor_full` at 0.10 and the host rolls with its own `_rng`.
Every assertion is written to hold either way — conservation is stated against the winner's own
`caught` bit, not against a hoped-for catch — and which branch a run took is printed.

**Not asserted, and why:** the record's *final* phase. The first run went red on it with
`phase ''`, and that was correct behaviour, not a defect: after the settle the fight has often
ended on its own (the opponent is a live AI). What §8 step 4 actually promises the loser is
asserted instead, in both directions.

---

## Findings

### F1 — `verify-multiplayer-shard` was a bash syntax error and had never run a net smoke

The "Discover peers:2 net smokes" step carried **two nested count-floor `if`s with a single
`fi` between them**. The outer `if` was never closed, so the whole `run:` block failed to
parse and the job died at discovery, before launching a single peer.

Reproduction, on the base commit:

```
$ # extract the step's run: block to a file, then
$ bash -n /tmp/discover.sh
/tmp/discover.sh: line 97: syntax error: unexpected end of file
```

Exactly the accident the block's own comment predicts ("four lanes resolving this same
conflict in turn, each restating the lanes before them"). Fixed here, because the registration
edit this lane owes lands in those same lines. After the fix the step parses, discovers 22
files and passes its own roster check:

```
$ bash /tmp/discover2.sh
found (22): tests/smoke_net_behind_character_joins_ahead_world.gd ... two_peers_boot.gd
(then: GITHUB_OUTPUT unbound — expected outside Actions)
```

**Consequence for the acceptance ledger:** every automated cell in
`MULTIPLAYER_ACCEPTANCE.md` naming a `smoke_net_*` is evidence from a local run, not from a
shard run — no shard run has ever happened. Recorded in that file's known-open section.

### F2 — an injected `jump` never leaves the floor, with no session and no panel

Not a D102 regression and not this lane's to fix, but it is real and it has a reproduction.
A one-peer probe (`launch(1, "world")`, no session, nothing open):

```
context: world      on_floor at boot: true      pos: [-25.40, 4.950, -15.70]
jump with confirm: FAIL / never left the floor within 120 physics frames of the press
attempt 0: y0=4.950 then ["4.950/true", "4.950/true", "4.950/true", "4.950/true", ...]
attempt 1: y0=4.950 then [...same...]
attempt 2: y0=4.950 then [...same...]
```

`y` never moves and `is_on_floor()` never goes false, across three presses. The same
`press` arm moves the body 14.61 m on a stick hold in the same run, so the peer is alive and
its input reaches the world — it is `jump` specifically. Two candidates, and this lane did not
pick between them: `peer_runner.gd::_inject()`'s header says its physics-frame-first ordering
was measured **against `jump`** when it was written, so either that ordering has drifted, or
`player_controller.gd::_try_jump()` has. `confirm: left_floor` had no other user in the tree,
so nothing would have caught it.

Two attempts (`within_frames` 40, then 120 plus a teleport onto known-good ground) yielded
nothing, so per the anti-grind rule the lane stopped, classified it with the probe above, and
switched the smoke's third verb to `build_place`. The probe smoke was deleted; the transcript
above is the record.

### F3 — `deploy_creature` leaves the party empty

Both peers report `party_size: 0` throughout `smoke_net_catch_race` even after
`deploy_creature` passed ("deployed AllyCreature"). A body stands in the world; `Game.party`
gains no row. Not investigated — outside this lane's files — but it is why the
five-creature assertions in that smoke hold **vacuously**, and it is stated in the smoke's own
header rather than left for a reader to infer from a zero.

---

## Handovers

**H1 — the full-belt catch is still owed.** A catch landing while the winner already owns five
must go to `Game.pending_catch` (`encounter_director.gd::_resolve_catch()`), exactly one, never
a sixth slot and never storage. `smoke_net_catch_race` asserts it as an invariant that a
breakout satisfies vacuously, and cannot do better: the host rolls with its own `_rng`, the
same generator serves the opponent's swings, and no seed set from outside survives to the
throw. Closing it properly needs a seam that pins the host's roll over the wire, which does not
exist. Recorded in `MULTIPLAYER_ACCEPTANCE.md` row 6 rather than implied.

**H2 — F2's jump.** Whoever owns `peer_runner.gd::_inject()` or `player_controller.gd` next
should take the reproduction above. It is cheap to re-run: a one-peer net smoke, ~90 s.

**H3 — F1's shard has still never gone green.** The 52-minute timeout in `ci.yml` is now an
estimate built on two measured smokes plus lane 6.A's estimate, on a job that has never
completed. The first real green run should correct it in whichever direction it wants.

**H4 — `Session.pause_local()`.** When `scripts/net/session.gd` is free, moving
`scripts/ui/local_pause.gd`'s three statics onto it is a pure rename and closes D102 to the
letter. Nothing depends on the current address.

---

## Exact commands and results

**Godot**

```
~/godot-bin/godot --version                                  4.7.stable.official.5b4e0cb0f
~/godot-bin/godot --headless --path . --import               exit 0  (twice)
```

**`--check-only` on every changed or added script — all exit 0, no output**

```
scripts/ui/local_pause.gd            scripts/ui/craft_panel.gd
scripts/ui/storage_panel.gd          scripts/ui/swap_panel.gd
scripts/ui/creature_bed_panel.gd     scripts/ui/shop_panel.gd
scripts/ui/game_menu.gd              tools/net/peer_runner.gd
tests/smoke_net_menu_does_not_freeze_peer.gd
tests/smoke_net_catch_race.gd
```

**The two new smokes, locally**

| Run | Command | Result |
|---|---|---|
| 1 | `tools/net/run_net_smoke.sh menu_does_not_freeze_peer` | RED — 55 assertions, 10 failures, **all fixture**: `MOVE_FRAMES` was 90 and both peers reported 0.00 m *with nothing open*. `smoke_net_movement_two_peers` uses 300 for a 2 m bar. |
| 2 | same | RED — 63 assertions, 3 failures: F2's jump ×2, and one over-strict relative movement bar measuring the *previous round's floor* rather than the feature. |
| 3 | same | **GREEN — 61 assertions, 0 failures.** 2 min 45 s. |
| 4 | same | **GREEN — 61 assertions, 0 failures.** |
| 1 | `tools/net/run_net_smoke.sh catch_race` | RED — 44 assertions, 2 failures, **both reader bugs in the smoke**: a client's `code: "pending"` read as a refusal code, and an assertion on the record's final phase. The race itself formed and arbitrated correctly on this run. |
| 2 | same | **GREEN — 45 assertions, 0 failures.** 2 min 23 s. |
| 3 | same | **GREEN — 45 assertions, 0 failures.** |

Assertion counts were identical across repeats (61 and 45), so no branch was silently skipped.

State hashes agreed across both peers on every green run (`hashes: [468786767 ×3]` on both),
so the desync detector was quiet throughout.

**Reference run, to classify the movement reds rather than guess at them**

```
tools/net/run_net_smoke.sh movement_two_peers    exit 0
  peer 0 walked 14.61 m / peer 1 walked 2.42 m on 300 frames of full stick
```

That is why `MOVED_M` is 2 m and not more: a fresh boot starts inside Grandpa's farmhouse and
forward from the spawn is a wall about three metres away. `smoke_net_movement_two_peers.gd`'s
own header carries the same measurement.

**Solo regression bar — the three the brief names, plus four that touch the six panels**

| Smoke | Result | Wall |
|---|---|---|
| `smoke_menu` | PASS | 146 s |
| `smoke_post_modal_control` | PASS (3 mixed real-joypad cycles) | 146 s |
| `smoke_modal_stacking` | PASS | 2 s |
| `smoke_craft_panel_controller` | PASS | 3 s |
| `smoke_station_panels_hide_world_hud` | PASS | 2 s |
| `smoke_menu_focus` | PASS | 114 s |
| `smoke_satchel_owns_hotbar` | PASS | 2 s |

**CI registration** — `.github/workflows/ci.yml`, `verify-multiplayer-shard`:

* the unclosed `if` collapsed into one correct count-floor test (F1);
* the floor **regenerated from the files on disk**, not incremented —
  `for f in tests/smoke_net_*.gd; do head -5 "$f" | grep -qE '^#[[:space:]]*peers:[[:space:]]*2$' && echo "$f"; done | wc -l` → **22**;
* both smokes added to the named `for required in` roster (now 22 entries, matching disk
  exactly in both directions);
* `timeout-minutes` 45 → 52, from the measured 2:45 + 2:23 plus margin (H3).

---

## Files

**Added**

* `tests/smoke_net_menu_does_not_freeze_peer.gd` — item 16.
* `tests/smoke_net_catch_race.gd` — item 6.
* `scripts/ui/local_pause.gd` — D102's conditional pause. The deviation from D102's named
  address is above.

**Changed**

* `scripts/ui/{craft,storage,swap,creature_bed,shop}_panel.gd`, `scripts/ui/game_menu.gd` —
  the unconditional `get_tree().paused = true` routed through `LOCAL_PAUSE`. Nine lines each.
* `tools/net/peer_runner.gd` — two arms (`menu_toggle`, `catch_throw`) and two probes
  (`local_pause`, `catch`). `menu_toggle` presses with an idle frame FIRST, which is the gate
  `_inject()`'s own header asks for when a `_process`-polled control needs driving
  (`game_menu.gd::_read_actions()` is called from `_process`), and presses the back button more
  than once when closing, because B backs out of a tab before it reaches the shell.
* `.github/workflows/ci.yml` — F1's fix plus the registration.
* `docs/acceptance/MULTIPLAYER_ACCEPTANCE.md` — rows 6 and 16, and F1 and H1 in known-open.

**Not touched**, as instructed: `autoload/game_state.gd`, `autoload/world_state.gd`,
`scripts/net/world_ledger.gd`, `scripts/net/ledger_rpc.gd`, `scripts/net/session.gd`,
`scripts/save/*`, `riding_controller.gd`, `fly_controller.gd`,
`tests/helpers/net_harness.gd`.
