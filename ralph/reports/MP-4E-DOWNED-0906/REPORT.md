# MP-4E — downed, revive and death

Stage B multiplayer conversion, Wave 4 lane 4.E.
Branch `claude/mp-4e-downed`, based on `claude/tetherbound-roadmap-next-jrcjs8`
(`b9c5f1e1`, main + Wave 3 verb conversion + stable building uids).

**A player who goes down is a problem their friend can solve, not the end of the fight.**

---

## 1. Verdicts, one line per brief item

| # | Item | Verdict |
|---|---|---|
| 1 | `died` becomes `downed` for a configurable window in a multi-peer session | **DONE** — `data/config/multiplayer.json` → new top-level `downed` block, `window_s: 45.0`, fixed before implementing (derivation below and in the config comment). |
| 2 | A teammate's `interact` revives them | **DONE** — stand within `revive_radius_m` of the downed body and hold `interact` for `revive_hold_s`. Real polled action, real distance; the prompt on the body is display only. |
| 3 | On timeout, the existing satchel-drop and respawn runs unchanged | **DONE** — `player_death.gd::_die_now()` is the original `_on_died` body, moved and not edited. Both the solo death and the timeout death call it. |
| 4 | Solo has no window at all | **DONE and measured** — `request_down()` answers false unless `Game.is_multi_peer()`. `tests/smoke_realm_world_records.gd` (the repo's real solo-death regression) passes 35/35 unchanged. |
| 5 | One player going down never touches the encounter or the world | **DONE by construction** — the downed path reads `Game.is_multi_peer()`, `Game.local_player()` and `Game.push_world_message()`, and writes only the local player's vitals and locomotion. No ledger intent, no world record, no encounter call, no pause, no satchel. Asserted in the smoke as "no satchel record and no satchel body on either peer". |

**Deviation from the brief's file list, stated rather than hidden:** the brief
gave me `scripts/player/player_controller.gd` ("the death signal path only").
**I did not touch it.** The code says the smaller change is elsewhere: `died`
has exactly two emitters in the whole repo —
`player_controller.gd::_resolve_landing` (a lethal fall) and
`water.gd::_apply_hazard_damage` (a lethal drowning) — and both funnel into the
single listener `player_death.gd::_on_died`. Intercepting at the listener
catches every death with one guard; intercepting at the emitter would have
needed two, one of them in a file this lane does not own. `_resolve_landing`
already fires only on a floor-contact transition, so a downed player lying
still cannot re-fire it, and `water.gd` already returns early on
`vitals.is_dead()`, so a downed player in water cannot either. Nothing in
`player_controller.gd` needed to change; the brief's grant was permission, not
an obligation, and the codebase outranks the prompt.

---

## 2. What was built

### `data/config/multiplayer.json` — a new top-level `downed` block

A new block rather than keys inside `session`, deliberately: `session` is lane
2.A's and is read by `session.gd::config()`, `test_budgets` is lane 0.F's and is
read by `net_harness.gd::_init_budgets()`. A third owner gets a third block, so
three lanes editing this file conflict trivially rather than semantically.

Numbers fixed **before** implementing, from the movement tuning rather than
discovered by running until something passed:

| Key | Value | Why that number |
|---|---|---|
| `window_s` | `45.0` | `movement.json` sprints at 8.6 m/s. A teammate needs ~10 s to break off the fight they are still in (rule 19 — the encounter does not stop), ~20 s to cross the hundred-odd metres a Meadows engagement spreads over, and `revive_hold_s` on top. 45 s carries that with margin. Not 30 (too tight for a friend who is mid-fight, which is the case this feature exists for); not 90 (a minute and a half face-down is a worse game than dying). |
| `revive_hold_s` | `3.0` | Long enough to be a commitment made under pressure — the reviver is stationary and exposed for all three seconds — and short enough never to be a chore. A tap makes the revive free; five seconds makes it a chore. |
| `revive_radius_m` | `2.5` | Tighter than `interactable.gd`'s 3.6 m default on purpose. A berry bush may offer itself from across a clearing; kneeling over a friend is arm's reach plus a step, and the tightness is what makes the reviver's own position a real exposure. |
| `revive_health_fraction` | `0.35` | Going down has to cost something or it is free; being revived straight into a second knockdown is the worse game. 0.35 is enough to walk out and eat. |
| `revive_stamina_fraction` | `0.35` | Up and able to move, not able to sprint away for free. |

Satiety is deliberately untouched by a revive. A revive is not a meal, and
CLAUDE.md's light-satiety rule means satiety was never a way to die.

### `scripts/player/downed_state.gd` — new, the whole state machine

Mounted **once**, lazily, at `/root/Game/DownedState` by
`player_death.gd::build()`. A child of the one autoload rather than a second
autoload (the one-autoload rule) and for the same reason `session.gd` is one:
the node path must be **identical in every process** or the RPCs do not resolve.
`PlayerDeath` itself is a per-world component, rebuilt on every scene change, so
it cannot be the RPC endpoint.

Three RPCs, all `any_peer`/`call_remote`/`reliable` on D95's `CHANNEL_LEDGER`:
`_rpc_downed(display_name)` broadcast by the player who went down,
`_rpc_up()` broadcast when their window closes either way, and
`_rpc_revive()` addressed by `rpc_id` to the one peer being revived. The sender
id from `multiplayer.get_remote_sender_id()` is the truth about *who*; an
argument naming a peer would be a second, forgeable answer to a question the
transport already answers.

### `scripts/player/player_vitals.gd` — `revive(health_fraction, stamina_fraction)`

Not `rest()`. Fractions rather than absolutes so a Heart-raised capacity scales
with them. Health is clamped to a floor **above zero**: a revive landing on
exactly 0.0 would leave `is_dead()` true, so the next landing would re-fire
`died` and the player would be revived straight back onto the floor — which
reads as a revive that did not work, not as a rounding error.

### `scripts/world/player_death.gd` — the intercept

`_on_died()` is now four lines: ask `downed_state.request_down()`, and return if
it took the death. `_die_now()` is the file's original `_on_died` body, moved and
not edited. Solo, a headless test, a capture tool and the editor all get `false`
from `request_down()` and run `_die_now()` on the same frame they always did.

### `tools/net/peer_runner.gd` — two arms and one probe

- `go_down` — sets `vitals.health` to 0 and emits the player's own `died`
  signal. Byte for byte what `water.gd::_apply_hazard_damage` does when a
  drowning turns fatal; a reproducible lethal *fall* would need terrain the
  harness cannot promise it has.
- `stand_by_downed` — places the local rig `offset` metres from the downed
  teammate's body. **Setup, not the thing under test**, exactly as lane 3.B's
  `pickup_stand` stands its prop rather than making the smoke walk to one.
  `move_to` would measure the stick navigator, which this repo has open stall
  findings against (FENCE-CORNER-0903) and which is not what this smoke is about.
  The revive itself gets no help: it is a real held `interact`.
- probe `downed` — the local window, the peers this process knows to be downed,
  health, stamina, locomotion, and both satchel counts (records and live nodes).

### `tests/smoke_net_revive.gd` + `.github/workflows/ci.yml`

Registered in `verify-multiplayer-shard` in **both** places the brief names: the
count floor is raised 8 → 9, and `tests/smoke_net_revive.gd` is added to the
named-registration list. Expect a trivial additive conflict with the other lanes
adding smokes; both of my lines are correct on their own.

---

## 3. The traps, and what was done about each

**The `OfflineMultiplayerPeer` trap.** Nothing in `downed_state.gd` asks the
multiplayer API whether there is a session. Every decision runs through
`Game.is_multi_peer()` → `Session.is_multi_peer()` → `peer_count() > 1`, which is
the one question that is honestly *false* in a process with no session — where
`multiplayer.is_server()` is true and `get_unique_id()` is 1. It is re-read on
the frame it is needed and never cached at `_ready()`: `_tick_window()` asks it
again every frame precisely because `join()` swaps the peer under the node's
feet.

**A player who disconnects while downed.** Decided in both directions, not left
to chance:

- *They drop while down.* Their process is gone and their window with it. On
  every remaining peer, `Session.peer_left` frees their `remote_trainer` body
  (`trainer_spawn.gd::_despawn_for`) and `_forget_peer()` frees the revive prompt
  bolted to it — so there is no body nobody can revive and no prompt nobody can
  clear. `_prune()` is the belt to that braces: `session.gd::_on_peer_disconnected`
  returns early off the host, so a **client** watching another **client** leave
  never hears `peer_left`; `_prune()` reconciles `_downed_peers` against the
  replicated registry every frame instead, which is authoritative on both ends.
- *The session collapses under them.* If the local player is downed and the
  session drops below two peers — the host left, everyone quit, the socket died —
  the window closes **immediately as an ordinary death**. Rule 4 says solo has no
  window, and a player left face-down forever in a game that has become solo is
  the worst of the three outcomes. Same for a world/scene change under a downed
  player (`attach_local` closes the window as a death).

**A satchel already carries its owner (lane 3.C).** Not regressed and not
touched: `_die_now()` is the unedited original, `_drop_satchel` still stamps the
dying player's character id, and `death_satchel.gd::can_open` is untouched. The
smoke asserts the stronger thing on top — going down writes **no** satchel at
all, so there is no bag whose ownership could be wrong.

**A missing key read through `get()`.** `downed_state.gd::_load_config()` asks
`has()` before every `get()` and says why in the file: `window_s` absent would
read back as null, `float(null)` is 0.0, and a zero-second window expires on the
frame it opens — the feature silently not existing while every test still passed.
The smoke does the same with `_has(row, "satchels")` before it trusts a count.

---

## 4. Commands run, and their counts

Godot 4.7-stable is not installed in a fresh container. Installed
`Godot_v4.7-stable_linux.x86_64` (`4.7.stable.official.5b4e0cb0f`) to
`~/godot-bin/godot` and ran `godot --headless --path . --import` twice before
anything else, as instructed. Both imports exited 0.

### `--check-only` on every changed `.gd`

```
godot --headless --path . --check-only --script scripts/player/downed_state.gd     exit 0
godot --headless --path . --check-only --script scripts/player/player_vitals.gd    exit 0
godot --headless --path . --check-only --script scripts/world/player_death.gd      exit 0
godot --headless --path . --check-only --script tools/net/peer_runner.gd           exit 0
godot --headless --path . --check-only --script tests/smoke_net_revive.gd          exit 0
```

### Solo — the bar that matters most

```
godot --headless --path . --script tests/smoke_playground.gd
  -> smoke: OK                                            exit 0

godot --headless --path . --script tests/smoke_unstick.gd
  -> unstick smoke test passed                            exit 0

godot --headless --path . --script tests/smoke_realm_world_records.gd
  -> REALM WORLD RECORDS SMOKE: PASS (35 checks)          exit 0

godot --headless --path . --script tests/run_tests.gd -- --only=test_player_death.gd
  -> 7 tests, 11 assertions, 0 failed

godot --headless --path . --script tests/run_tests.gd -- --only=test_player_vitals.gd
  -> 30 tests, 57 assertions, 0 failed
```

`tests/smoke_realm_world_records.gd` is this repo's real solo fall/death
regression — it drives the production `Player.died` signal and asserts the drain,
the fresh bag, the preserved older bags and the timed respawn. Its 35 checks are
the evidence that **solo death is unchanged**. There is no separate
`smoke_fall_death.gd` or `smoke_vitals.gd` in the tree; `test_player_vitals.gd`
is the vitals suite and it is run above by name.

### The new net smoke

```
tools/net/run_net_smoke.sh revive        # GODOT_BIN=~/godot-bin/godot
```

**Run 1 — `net-revive-20260906T052916Z` — 36 checks, 35 PASS, 1 FAIL, exit 1.**
One real defect, found and fixed (finding F1 below). Not a flake and not a
budget: the same check failed for the same reason it would fail on a player's
machine.

**Run 2 — `net-revive-20260906T053333Z` — 36 checks, 36 PASS, 0 FAIL, exit 0.**
`ALL CHECKS PASSED`. Both peers exited clean (`unexpected_exit=false`).

This is a **1-fail-then-fix-then-green**, not a 1-fail-then-retry: the two runs
are of different code. Nothing was re-run to see whether it would pass the
second time.

The 36 checks of run 2, in the order they ran:

```
PASS: coordinator tracked 2 peers
PASS: peer 0 / peer 1 input_context is 'world'                          (x2)
PASS: a Session exists to host/join (lane 2.A)
PASS: peer 0 hosted a world (hosting udp/28281 as peer 1)
PASS: peer 1 joined on port 28281 as peer 46521028 after 8 frames; snapshot applied
PASS: peer 0 / peer 1 registry holds both players                       (x2)
PASS: peer 0 / peer 1 mounted /root/Game/DownedState                    (x2)
PASS: peer 0 / peer 1 downed probe reports a satchel count              (x2)
PASS: peer 0 / peer 1 is not downed before anything happens             (x2)
PASS: peer 1's downed window is a real number of seconds (45.0)
PASS: peer 1 took a lethal hit through the shipping `died` path
PASS: peer 1 is DOWN, not dead (local_downed)
PASS: peer 1 has 44.0 s left of its 45.0 s window
PASS: a downed peer 1 cannot walk away
PASS: peer 1's health really is at zero while it is down (0.0)
PASS: going down dropped NO satchel record on peer 1 (0, was 0)
PASS: going down stood NO satchel body on peer 1 (0, was 0)
PASS: the HOST's world gained no satchel record either (0, was 0)
PASS: peer 0 knows exactly one teammate is down (knows 1)
PASS: peer 0 stood over peer 1's body (standing 1.80 m from peer 46521028's body)
PASS: peer 0 held interact for 300 frames (still down at the end)
PASS: peer 1's window is closed
PASS: peer 1 was revived exactly once (1)
PASS: peer 1's window never expired -- the friend got there first (0 expiries)
PASS: peer 1 stood up with health above zero (35.0)
PASS: peer 1's locomotion is back on
PASS: a revived peer 1 still has its bag: no satchel record was ever written (0, was 0)
PASS: no satchel body ever stood for peer 1 (0, was 0)
PASS: peer 0's revive prompt is gone
PASS: peer 1 held the stick forward after being revived
PASS: peer 1 is PLAYING AGAIN: it walked 8.55 m after the revive (needed 0.5 m)
```

Peer-side evidence for the same run, from the peers' own logs rather than the
coordinator's:

```
peer-1.log: [downed] local player is down; 45.0 s to be revived
peer-1.log: [downed] revived by peer 1                 <- peer id 1 = the host
peer-0.log: [downed] peer 46521028 is down ('')
peer-0.log: [downed] reviving peer 46521028
```

**Assertion counts, all runs together.** Net smoke 36 (36 pass);
`smoke_realm_world_records` 35 checks; `test_player_vitals` 30 tests / 57
assertions; `test_player_death` 7 tests / 11 assertions; `smoke_playground` and
`smoke_unstick` are pass/fail smokes without a printed count. No run was
re-run to confirm a pass, and no full sweep was run.

---

## 5. Findings

### F1 — a single write to `set_locomotion_enabled` does not hold. FIXED.

**What.** Run 1's one failing check was `a downed peer 1 cannot walk away`:
locomotion was still enabled 60 frames after the window opened, even though
`request_down()` had written `set_locomotion_enabled(false)`.

**Why.** `scripts/story/sequence_director.gd:800` (`_refresh_lockout()`, called
from its `_process`) writes `set_locomotion_enabled(not modal)` on **every
frame** in which no fight is running. Four other files write the same channel
(`encounter_director.gd:2909`, `throw_aim.gd:390`, `cloudreach_chapter.gd:115`,
`cloudreach_world_runtime.gd:201/246`). And the ordering is against you twice
over: this node is a child of the `Game` autoload, autoloads are added to the
root before the current scene, so by default it runs *before* the sequence
director in the idle frame and *after* `player_controller.gd::_physics_process`
in the physics tick — i.e. it loses both races.

**Fix.** `downed_state.gd` holds the latch instead of setting it:
`_hold_still()` is re-asserted from `_process` (`process_priority = 100`, last
in the idle frame) and from `_physics_process`
(`process_physics_priority = -100`, ahead of the reader). Run 2 passes that
check.

**Worth knowing beyond this lane.** `player_death.gd::_fade_and_respawn` has
written this channel the same single-write way since it was written, and is
subject to the same stomp during the opening — the fade is short enough that
nothing has noticed. Not this lane's to change (it is the unedited death path
and changing it would change solo behaviour), recorded here so the next person
to touch locomotion knows the channel has six writers and no owner.

### F2 — a fixed spot in the farmhouse entombs a walking player. NOT this lane's.

Reproduced identically in **both** runs, at the same world coordinate, after
the revive: peer 1 walks ~8.5 m, `player_controller.gd`'s unstick reports
`entombed at -25.40, 6.42, -15.70 -- recovering to -25.40, 12.02, -15.70`, and
shortly afterwards goes down a second time. The coordinate did not move when
the reviver's placement offset changed from 1.0 m to 1.8 m between runs, so it
is a property of the world, not of the harness placement.

I did not chase the last step (whether the killer is the 5.6 m unstick drop or
the pond beyond it). Arithmetic says the drop alone is not enough: gravity 26.0
x fall multiplier 1.35 gives ~19.8 m/s at 5.6 m, which is 12.6 damage against
the 35 HP a revive leaves — survivable. Two attempts is the anti-grind bar and
this is worth zero of them: it is outside this lane and it does not affect any
assertion (every check runs before it). Handed over below.

What it *does* show, incidentally, is the feature working a second time
unprompted: the second lethal hit opened a second window rather than killing,
and peer 0 re-hung its revive prompt (`[downed] peer 46521028 is down` appears
twice in `peer-0.log`).

### F3 — the harness has no display name, so the prompt uses its fallback.

`[downed] peer 46521028 is down ('')` — `Game.local.display_name` is empty in a
peer process that never ran character creation, so the broadcast carries "".
Handled rather than left to render as an empty prompt: `_attach_prompt()` falls
back to `Revive your teammate` and the world message to `Your teammate is
down.` Cosmetic, correct, and noted so nobody reads the empty string in the log
as a bug.

---

## 6. Handovers

**H1 — there is no HUD for any of this.** `downed_state.gd` emits
`downed_began()` and `downed_ended(revived)` and exposes `remaining_s()`,
`hold_s()` and `status()`, and *nothing reads them*. A downed player is told
once, in a world message, that they have 45 seconds; they get no countdown, and
the reviver gets no filling hold ring — just the `Revive <name>` prompt, which
appears and then simply does not respond for three seconds. The seams are
deliberately already there; the HUD belongs to whichever lane owns
`scripts/ui/playground_hud.gd`, which this lane does not.

**H2 — a downed player can still open menus.** Locomotion is latched off;
the satchel, the map and the pause shell are not. Today this is harmless
*because of a fact that is not guaranteed to stay true*: healing consumables in
`tab_backpack.gd` target a creature, and food calls `vitals.eat()`, which moves
satiety only — so nothing in the game can raise a downed player's health and
there is no self-revive. **The day a player-healing item is added, that becomes
a self-revive.** Gate the backpack on `DownedState.is_downed()` at that point,
not before.

**H3 — F2's entombment spot** (`-25.40, 6.42, -15.70` in the Meadows
playground), reproducible in both net runs, worth ten minutes from whoever owns
the farmhouse collision.

**H4 — a downed player's deployed creature is untouched, and that is by
design here but unverified against lane 4.C.** Rule 19 says the encounter
continues, so this lane deliberately does not recall, freeze or despawn the
downed player's creature. Lane 4.C owns `scripts/combat/*` and was running
concurrently; the two have not been run together. Worth one combined run once
both have landed: down a player who is mid-fight and confirm the fight, and
their creature, carry on.

**H5 — the CI shard registration will conflict trivially.** Both the count
floor (8 -> 9) and the named list in `verify-multiplayer-shard` are edited, and
other lanes are adding their own smokes to the same two places. Take every
lane's line; the floor is `8 + (number of smokes actually added)`.
