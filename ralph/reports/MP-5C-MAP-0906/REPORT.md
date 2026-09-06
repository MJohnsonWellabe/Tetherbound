# MP-5C — personal map, fog, alpha pins and quest scopes

**Lane:** Stage B Wave 5, lane 5.C · **Branch:** `claude/mp-5c-map` · **Base:** `main` @ `61518f6b`
**Date:** 2026-09-06 · **Godot:** 4.7-stable (installed into `~/godot-bin/godot`; `--import` run twice, clean)

The one sentence the lane is judged on: **a player who joins a host who has explored the whole
Meadows sees their own fog, not the host's — while an alpha somebody has already beaten is gone
for everyone.** Both halves are now asserted in one run, on one pair of peers, in one session.

---

## Verdicts, one line per item

| # | Item | Verdict |
|---|---|---|
| 1 | Fog of war is per player; judge what stays static | **PASS — already landed by lane 1.B, verified, and nothing stateful stays static** |
| 2 | Alpha pin discovery personal, a cleared alpha world, through the ledger | **PASS with one handover** (the shipping writer is `encounter_director.gd`, another lane's file) |
| 3 | Quest log scopes, D99, declared never defaulted | **PASS** — every row now reports `scope`; 21 Cloudreach entries gained a declared one |
| 4 | `tab_map.gd` draws whichever is which; joining reveals nothing of the host's map | **PASS — verified, documented; no behavioural change was needed** |
| — | Fog survives a save and reload as personal state | **PARTIAL, and the gap is 1.C's** — see Finding 2 |
| — | Solo behaves exactly as today | **PASS** — `smoke_alpha_pins`, `smoke_gate_a_map_cycle`, `smoke_playground` all green first attempt |

---

## 1. Fog of war is per player

**The brief contradicts the code, so I followed the code and say so here.** The brief says
`autoload/map_state.gd` "currently also caches the world extent in `static var`s — process-global."
It does not: lane 1.B removed `static var _grid_x/_grid_z/_origin` when it built
`PlayerState.maps`, and `map_state.gd:59` is a *comment about* the statics that used to be there.
There is no `static var` anywhere in `map_state.gd`, `alpha_pins.gd`, `tab_map.gd` or
`quest_log.gd` today (`grep -n "static var"` over the four returns only two prose lines).

So item 1 was verification rather than a move, and what I verified is:

- Fog cells, `_visited_count`, discovered landmarks, discovered regions, dynamic markers and
  pinned alphas are all **instance** fields on `MapState`.
- The instances hang off `PlayerState.maps[realm]` (`player_state.gd::map_for`), and `Game.map`
  forwards to the local player's (`game_state.gd::bind_realm_map`).
- Every consumer goes through `Game.map`: `tab_map.gd`, `minimap.gd`, `playground_hud.gd`,
  `player_death.gd`, `save_game.gd`, `alpha_pins.gd`. There is no second route.
- The only writer of fog is `game_state.gd:986` (`map.mark_visited(here)`), driven off
  `_find_player()` — **the local player**. `remote_trainer.gd` never reveals anything, so a
  remote body walking past does not lift another player's fog.
- The join snapshot is `WorldState.save_data()` (`session.gd:338` → `_rpc_snapshot`) and carries
  **no map payload at all**. That is the structural reason a joiner cannot inherit the host's
  fog: there is no wire it could arrive on.

**What legitimately stays static: nothing that holds state.** The extent *is* a property of the
world rather than of a player — but it is DERIVED, from `world_extent.gd` (or `set_extent()` for
Cloudreach), so every peer computes the identical grid from the identical config. A shared static
cache would buy nothing except the hazard it already caused once: two realm maps in one process
overwriting each other's shape. The only `static func` left in the file is `alpha_marker_id()`,
which is pure string arithmetic over its argument and holds nothing.

I wrote that conclusion into `map_state.gd`'s header so the next lane does not re-derive it.

## 2. Alpha pins — personal discovery, world clear

`scripts/world/alpha_pins.gd`:

- **`_once_cleared()` now reads the WORLD store explicitly** (`Game.world.flags`) instead of the
  merged view, falling back to the merged view only when there is no `Game` (a unit test standing
  the node up alone). Both answer identically in solo, because `wild_once_` routes to the world
  store either way — the explicit read changes no solo behaviour and removes the possibility of a
  client's own player store answering for the world's.
- **`clear_alpha(order)` is new**: it submits `{"kind": "set_world_flag", "realm": …, "id":
  "wild_once_<order>"}` through `Game.ledger`. That is the only way a world fact may be written
  (D103). Solo and the host commit in-process; a client gets `pending` and the flag arrives as a
  committed delta.
- The pin itself is untouched and stays personal: `pin_alpha`/`unpin_alpha` are `MapState` calls,
  and `_map()` resolves the local player's map.
- `INTRO_FLAG` (`alpha_pin_intro_seen`) stays on the merged view deliberately. It is a
  `player`-scope id, so `scope_of()` routes it to the joining player's own store and their first
  pin still announces itself once — which is the behaviour we want and did not need code to get.

**Handover (see Findings).** `clear_alpha()` has no caller inside this file, because the shipping
writer today is `encounter_director.gd::_mark_once_cleared()` — another lane's file, in the
`scripts/combat/*` set I was told not to touch.

## 3. Quest log scopes (D99)

`scripts/world/quest_log.gd` now reports `scope` on **every** row it builds, in both lists and
both realms, and the scope is declared rather than defaulted:

- `_scope_of(entry)` takes the entry's own `scope` key when it has one, otherwise asks
  `progression_state.scope_of()` — the same table the runtime writer routes by, so the row's label
  and the flag's actual store cannot disagree.
- An id neither can answer is a `push_error` naming the objective and the flag, and a `""` scope.
  Never a guess. The row is still listed: an undeclared scope is a data bug for the test to catch,
  not a reason to hide an objective from a player mid-chapter.
- `_scoped_side_entries()` stamps the scope onto Cloudreach's side-chain rows, which come back
  from `realm_chapter_progression.gd::side_entries()` (not my file) and carry no scope of their
  own. Matched by `id` against the chain record, so that file learns no second vocabulary.

`data/config/cloudreach_chapter.json` gained **21 declared `scope` keys** — 17 act objectives and
4 side chains, all `world` — inserted line-by-line beside the existing `flag_id`/`completion_flag`
so the rest of the file is byte-identical. Every one of them was already classified in
`data/progression/flag_scopes.json`, so the declarations agree with the table by construction and
`test_a_declared_scope_never_contradicts_the_table` asserts it rather than assuming it.
`objectives.json` already carried a `scope` on all 33 entries (lane 1.A) and was not touched.

Four tests added to `tests/test_quest_log.gd`, each sweeping the authored data rather than a
fixture: every Meadows row declares world-or-player, every Cloudreach row does, no declared scope
contradicts the table, and the Meadows chain genuinely carries **both** scopes — that last one
exists because a sweep that only ever saw one scope would pass while `_scope_of()` was hard-wired
to return it.

## 4. `tab_map.gd`

Verified and documented; no behavioural change was needed and I made none. `_map_state()` reads
`Game.map`, which is `PlayerState.map_for(realm)` for the local player, so the fog texture, the
landmarks, the regions, the alpha pins and the objective marker are all what *this* trainer has
found. What is shared arrives as world state and is drawn only through it (a landmark gated on a
world flag; a pin that clears because somebody beat that alpha). The comment I added on
`_map_state()` says so, and names the snapshot as the reason a joiner cannot inherit a map — so a
later lane that adds a map payload to the snapshot has been told, in the file, what it is breaking.

The minimap (`scripts/ui/minimap.gd`) reads the same `Game.map` and needed no change either.

---

## Findings

**Finding 1 — the brief contradicts the code on the `static var`s, and the code is right.**
`map_state.gd` has held its extent in instance fields since lane 1.B; the `static var` the brief
describes is a prose reference to what used to be there (`map_state.gd:59`). Nothing was moved for
item 1; it was verified, and the conclusion about what stays static is written into the file.

**Finding 2 — a client's fog is not persisted at all today, and that is 1.C's to close.**
Asked to check how the save split treats fog, here is what is actually there:

- Fog *does* round-trip for solo and for a host. `save_game.gd` (v22) writes `realm_maps` from
  `Game.save_realm_maps()` → `PlayerState.map_payloads()` → each `MapState.save_data()`, and
  restores it through `restore_realm_maps()`. `test_realm_map_persistence.gd` (6 tests, in the
  101-test `--only=map` sweep) pins that, including the two-realm case.
- The character half of the split is **not writable yet**, exactly as the brief suspected.
  `save_game.gd` still writes one v22 file; `character.json` is 1.C's and has not landed.
- The consequence is sharper than "not yet split": `Game.autosave_here()` writes the save only
  `if is_host()`, and a client falls through to `session.gd::_save_character_here()`, which on a
  client prints *"client leave: no character file to write yet (D100 split is a later lane)"* and
  writes nothing. **So a joining player's fog, party, satchel and hotbar are discarded when the
  session ends.** That is not a regression from this lane and not something this lane may fix (I
  do not own `game_state.gd`, `session.gd` or `save_game.gd`), but it is the concrete thing that
  makes "fog survives a save and reload as personal state" only half true right now, and it is the
  player-facing cost of 1.C being outstanding.

**Finding 3 — the first run of the new net smoke failed on its own bar, not on the code.**
The host walked with the stick for 300 frames and revealed **zero** new cells: 4428 before, 4428
after. That is the farmhouse wall `smoke_net_movement_two_peers.gd` already measured — a fresh
boot starts inside Grandpa's house, forward is a wall about three metres away, and 2.71 m of
travel stays entirely inside the 45 m circle the map reveals at boot. Every other assertion in
that first run passed, the world half included. The smoke was wrong about how to make the host
explore, not the map. It now stands the host out at the authored alpha cluster (−490, 555) through
a new `explore_at` arm and lets `game_state.gd`'s own discovery tick do the revealing.

**This is a change to the test between runs, not a smoke that passed on retry.** I am flagging the
distinction because the process rules treat those very differently: nothing about the code under
test changed, and the second run is the first run of the corrected smoke.

**Finding 4 — `tests/smoke_net_deploy_two_creatures.gd.uid` is missing from `main`.**
Every other `tests/smoke_net_*.gd` has its `.uid` committed; lane 4.B's does not, so a fresh
`--import` generates it as an untracked file. Included in this push alongside my own smoke's
`.uid`, since leaving it out means every future fresh checkout produces the same stray file.

---

## Handovers

**Handover 1 — `encounter_director.gd` still writes the beaten-alpha flag directly.**
`scripts/combat/encounter_director.gd::_mark_once_cleared()` (called from `:2418` on a win and
`:2425` on a catch) does `progression.call("set_flag", id)` on the merged view. In solo that is
correct and unchanged; on a **client** it writes `wild_once_<order>` into that client's own world
replica and the host never learns, so the alpha stays alive for everyone else and comes back for
the client on the next snapshot. `scripts/combat/*` is another lane's, so I did not touch it.

The fix is one call: point that line at `AlphaPins.clear_alpha(order)`, which already exists,
already routes through the ledger, and is already exercised end-to-end by
`smoke_net_fog_is_personal`. Nothing else has to move — the pin-pruning, the flag id and the
scope table are all unchanged.

**Handover 2 — the net harness starts every peer boxed in the opening beat.**
Finding 3's root cause is not mine to fix and is already assigned: the movement smoke's header
gives "teaching the net harness to seed a post-opening save" to whichever lane takes it up. Until
then, any net smoke that needs a peer to travel more than ~3 m has to supply the position, as
`explore_at` now does. Worth doing once, in the harness, rather than once per smoke.

**Handover 3 — `realm_chapter_progression.gd` does not know about D99.**
`side_entries()` builds Cloudreach's side-chain rows and returns no `scope`; `quest_log.gd` stamps
it on afterwards by matching the row's `id` against the chain record. That is deliberate — one
vocabulary, in one file — but if a later lane gives that file more row shapes, the stamp is the
thing to keep in step.

---

## What changed

| File | Change |
|---|---|
| `autoload/map_state.gd` | Header only. Records that everything here is one player's, that nothing stateful stays static, and why the extent is derived per instance rather than cached process-wide. No behavioural change. |
| `scripts/world/alpha_pins.gd` | `_once_cleared()` reads the world store explicitly; new `clear_alpha(order)` submits `set_world_flag` through `Game.ledger`; new `_world_flags()`, `_ledger()`, `_realm()` helpers; header documents which half is personal and which is the world's. |
| `scripts/world/quest_log.gd` | Every row now carries `scope`; new `_scope_of()` (declared, never defaulted, `push_error` on an unclassifiable id) and `_scoped_side_entries()` for Cloudreach's side chains. |
| `data/config/cloudreach_chapter.json` | 21 declared `scope` keys added (17 act objectives, 4 side chains), all `world`, inserted beside the existing flag keys so the rest of the file is untouched. |
| `scripts/ui/tab_map.gd` | Comment on `_map_state()` only: names `Game.map` as the local player's and the snapshot as the reason a joiner cannot inherit one. No behavioural change. |
| `tools/net/peer_runner.gd` | Three harness arms and one probe: `map_fog` probe, `alpha_pin`, `alpha_clear`, `explore_at`. All go through shipping code. |
| `tests/smoke_net_fog_is_personal.gd` | New. The lane's experience test. |
| `tests/test_quest_log.gd` | Four D99 scope tests. |
| `.github/workflows/ci.yml` | `verify-multiplayer-shard`: count floor 6 → 7, and `tests/smoke_net_fog_is_personal.gd` added to the named-registration list. |

**Files I did not touch,** as instructed: `autoload/game_state.gd`, `scripts/net/*`,
`autoload/world_state.gd`, `autoload/player_state.gd` (all read), `scripts/combat/*`, and the
Wave 3 consumer set. `tools/net/peer_runner.gd` and `.github/workflows/ci.yml` are shared
additively with the other lanes; my CI edit is one number and one list line, so a concurrent
lane's edit to the same two spots is a trivial conflict with my own line correct on either side.

## Commands run, and what they returned

Godot was not installed in this container. Installed 4.7-stable per `CLAUDE.md`'s lock, from the
same URL `ci.yml` uses, to `~/godot-bin/godot`; `godot --headless --path . --import` run **twice**,
clean both times.

```
~/godot-bin/godot --version                    -> 4.7.stable.official.5b4e0cb0f
~/godot-bin/godot --headless --path . --import (x2)  -> clean
```

**Parse check — every changed `.gd`, all clean:**

```
godot --headless --path . --check-only --script autoload/map_state.gd
godot --headless --path . --check-only --script scripts/world/alpha_pins.gd
godot --headless --path . --check-only --script scripts/ui/tab_map.gd
godot --headless --path . --check-only --script scripts/world/quest_log.gd
godot --headless --path . --check-only --script tools/net/peer_runner.gd
godot --headless --path . --check-only --script tests/test_quest_log.gd
godot --headless --path . --check-only --script tests/smoke_net_fog_is_personal.gd
```

**Unit, by name:**

| Command | Result |
|---|---|
| `godot --headless --path . --script tests/run_tests.gd -- --only=map` | **101 tests, 701 assertions, 0 failed** |
| `... -- --only=quest_log.gd` | **42 tests, 812 assertions, 0 failed** (38 before this lane + 4 new; all 4 confirmed present in the run list by name) |
| `... -- --only=alpha_pins.gd` | **24 tests, 154 assertions, 0 failed** |
| `... -- --only=flag_scopes.gd` | **11 tests, 235 assertions, 0 failed** |

**Smoke — the solo regression bar, all green on first attempt, none re-run:**

| Command | Printed verdict |
|---|---|
| `godot --headless --path . --script tests/smoke_playground.gd` | `smoke: OK` |
| `godot --headless --path . --script tests/smoke_alpha_pins.gd` | `alpha pins: OK — a body walking in pins the Band 2 alpha inside 300 m, the pin is in the marker list both screens draw, it survives a real save/load, and beating it clears it and keeps it cleared.` |
| `godot --headless --path . --script tests/smoke_gate_a_map_cycle.gd` | `Gate A map/cycle: OK -- real pad cycling, movement-up minimap, full-map zoom/pan, recovery.` |

I did not run a full sweep, did not re-run any pass to confirm it, and did not chase the exit-time
`ObjectDB instances were leaked` / `resources still in use` notices — engine noise at exit.

**The new net smoke:**

```
tools/net/run_net_smoke.sh fog_is_personal
```

`ALL CHECKS PASSED` — **34 assertions, 0 failures, exit 0**
(run `net-20260906T052351Z-3991`; both peers exited cleanly, `unexpected_exit=false` on each).

Three runs were needed and none of them was a flaky pass; the code under test never changed
between them, only the smoke did:

| Run | Result | What it found |
|---|---|---|
| `net-20260906T051836Z-3462` | 2 FAIL / 20 PASS | The smoke's own reveal method. The host's stick walk revealed 0 new cells (4428 → 4428), so "the host revealed new ground" and "the joiner has less than the host" both failed. **Every fog-separation and world-sharing assertion in that run passed.** See Finding 3. |
| `net-20260906T052124Z-3720` | 1 FAIL / 33 PASS | `explore_at` fixed the reveal (4428 → 5678). The remaining failure was the `alpha_pin` arm reporting FAIL because `pin_alpha()` returns true only on a NEW pin — the shipping `AlphaPins` node had already pinned it off its own proximity tick, which is the feature working. |
| `net-20260906T052351Z-3991` | **34 PASS / 0 FAIL** | Green. |

The numbers that carry the lane, from the green run:

- The joiner boots with **4428** of its own cells revealed, holds **4428** after applying the
  host's snapshot, holds **4428** after the host explores, and holds **4428** at the end of the
  run. Its fog never moved.
- The host reaches **5678** cells. `4428 < 5678` is asserted, so "unchanged" is not being
  satisfied by a fog system that stopped working on both peers.
- The host holds **1** alpha pin, put there by the shipping `AlphaPins` proximity tick rather than
  by the harness. The joiner holds **0**, before and after.
- `wild_once_1900` is absent from **both** peers' world stores before the clear (the negative
  control), and present on **both** within **0 frames** after the host submits it through the
  ledger — the client received it as a committed delta, having never written it itself.
- The host's pin then clears itself, because the alpha is gone. The joiner's stays at 0, because
  it never found it and now never will.

### On the `int(null)` hazard

Every read of a probe result in the smoke checks `has()` before `int()`, and `_fog()` turns a null
probe into `{}` rather than into zeros, so a peer with no map shows up as a **failed assertion**
naming the missing key rather than as a function that aborted mid-run. The assertion count is
reported above for the same reason: 34 is the full complement, and a run that aborted early would
show fewer. The `_fog()` helper carries that reasoning in its own doc comment.

The two negative controls are there for the matching hazard on the other side: `4428 == 4428`
would also be true if fog never worked at all, so the run asserts the joiner booted with a
non-zero count and that the host's count really moved.

---

## The rules the lane was given

- **Solo behaves exactly as it does today.** `smoke_alpha_pins` and `smoke_gate_a_map_cycle` both
  green on first attempt, plus `smoke_playground`. The only solo-reachable behaviour change is
  `_once_cleared()` reading `Game.world.flags` instead of the merged view, and in solo those are
  the same answer — `wild_once_` is a world-scope prefix, so the merged view was reading the world
  store anyway.
- **Every world-scope change goes through the ledger.** `clear_alpha()` is the only new world
  write in this lane and it is a `set_world_flag` intent. No direct `set_flag` on a world id was
  added anywhere. (The one that already existed, in `encounter_director.gd`, is Handover 1.)
- **Fog survives a save and reload as personal state.** True for solo and host; not yet true for
  a client, because the character save does not exist. Finding 2, stated plainly rather than
  claimed as round-tripping.
