# MP-5A-STORY-0906 — story triggers and dialogue in a session

**Lane:** Stage B Wave 5, lane 5.A.
**Branch:** `claude/mp-5a-story`, from `main` at `a3df2546`.
**Godot:** 4.7-stable installed at `~/godot-bin/godot` (4.7.stable.official.5b4e0cb0f);
`--headless --path . --import` run before anything else.

## The bar, and what it turned out to be

> **The main story advances once for the world, and a character who is behind is
> never locked out.**

Rule 3 is a player experience, not a data-model claim, and the first thing worth
recording is what the experience actually was before this lane. A character with
no opening progress joining a world whose Warden is dead:

- wakes lying in Grandpa's bed behind a fade-to-black they cannot dismiss until
  they find the bed prompt;
- finds the farmhouse's front door a **solid collision box** — `grandpa_house.gd`'s
  physical stop, held shut by `sequence_director.gd::_refresh_door_gate()` until
  the `walk_out` beat — an invisible wall around a farmhouse in a chapter whose
  boss is already dead;
- has **no creature at all**, because `_ready()` calls
  `encounter_director.suspend_default_starter()` on frame one and the thing that
  replaces it is a tutorial they are being walked through;
- and, if they get outside, meets trainers the host already beat whose prompts
  answer the button with silence.

Each of those is right for the player the opening is *for*. Every one of them is
a soft-lock for somebody who walked in late. The fix is not to make the opening's
flags world-scoped — that would hand a friend's tutorial history to a stranger,
which is the collapse D99 exists to prevent — it is to make the opening's
**gates** stand down while its **beats** stay personal.

## What changed

### 1. Dialogue is local; its effects commit through the ledger

`scripts/ui/dialogue_panel.gd` is unchanged in behaviour and now says why: the
box, the portrait, the button and the camera push-in are one player's screen.
Only what a line *changes* crosses the wire.

`sequence_director.gd::_set_progression_flag()` — the `flag:` effect drain — is
now an intent submission. `scripts/story/story_ledger.gd` (new) is where D99's
classification becomes an intent kind:

| scope (`progression_state.scope_of`) | intent | addressed to |
|---|---|---|
| `world` | `set_world_flag` | everybody, once |
| `player` | `grant_player_flag` | the speaker's peer (the ledger's own default) |
| `player`, and in D99's residual table | `grant_player_flag` | **every peer in the session** |

Nothing is written locally on the way past: the committed delta writes the flag,
on the host inside `commit()` and on every client inside `apply()`, so two peers
cannot disagree about whether a line fired. The one exception is a process with
no transport at all (a bare fixture, a capture tool) — there the old local write
still happens, because the alternative is a conversation that plays and changes
nothing, which is the exact failure `_drain_effects`' own header was written
about.

### 2. `_refresh_lockout` locks only the local rig (directive rule 16)

The function was already local in effect. It is now local *by construction and
by assertion*: every handle it touches is checked against the `remote_trainer`
group before it is written, and a rig that fails that check is a loud
`push_error` (once) rather than a silent freeze of somebody else's body. The
header now states the rule and names each of the four handles and why each one
is this process's own.

### 3. World deltas re-run `restore_progression_from_game` on every peer

This is the lane's real defect, and it is not where the brief expected it.
`ledger_rpc.gd::_rpc_delta` sweeps the `progression_restore` group — but
`_commit_here()`, which is the **host's** path *and solo's*, does not sweep it at
all. So a client's opened gate re-posed on every peer except the one that
committed it, and the host's own commit re-posed nothing.

`scripts/net/*` is out of this lane's scope, so the fix is on the consumer side
and is the same three lines in each: join `progression_restore` **and** listen
for `delta_applied`, and make `restore_progression_from_game()` idempotent. On a
client the restore therefore runs twice per delta; that is deliberate and
documented (`story_ledger.gd::listen()`), because a restore path has to be
idempotent anyway — a save reload calls it too.

**The ordering trap** (lane 3.B's finding, restated): the group sweep runs
*before* `delta_applied` is emitted, so a "have I already handled this" guard
written the obvious way skips the winner's own feedback **on clients only**.
`sequence_director.gd::_on_ledger_delta()` therefore orders its `seq` guard
after the work that must run on every delta, not before it.

### 4. Gate, bridge, relay and shrine restore paths read world scope

| file | reads | writes |
|---|---|---|
| `gated_crossing.gd` (South Bridge, Mill Crossing) | `WorldState.flags` | `set_world_flag` |
| `road_gate.gd` (village boundary gates, sigil gates) | `WorldState.flags` | `set_world_flag` |
| `tether_relay.gd` | `WorldState.flags`, incl. the `relay_captain_defeated` prerequisite | `set_world_flag` |
| `realm_gate.gd` (the realm keys / unlocks) | `WorldState.flags` | `set_world_flag` |
| `cart_repair.gd`, `river_nest_clear.gd` | `WorldState.flags` | `set_world_flag` |

The merged view answers "does *either* store hold this", which is right for an
objective line and wrong for a gate: it cannot tell "the world opened this" from
"my own store happens to hold that id".

`item_gate.gd` gained `can_open()` and `spend()` — the two halves `try_open()`
always had, told apart so a **commit can sit between them**. A client cannot
write the flag locally and then wait for the host's answer, so the sequence is
now: check the satchel → submit → on `ok` or `pending`, spend the key → on `ok`,
pose the leaf; on `pending`, the delta poses it. `try_open()` itself is untouched
and is still what every solo caller and every existing test uses.

**The reward stays personal.** `river_nest_clear.gd` hands its coins and potion
to the satchel of the player who brought the materials, not to everybody in the
world. Only the cleared nest is shared.

### 5. Home and creature-bed flags reach every peer

`home_progress.gd::_grant()` called `Game.grant_player_flag()`, which fans a flag
out to every `PlayerState` **this process holds** — solo the whole world, in a
session one machine's view of it. The friend across the meadow has their own
process and their own store, and nothing was crossing the wire. It now submits a
`grant_player_flag` intent addressed to every peer in the session, with the old
call as the no-transport fallback.

The other half: `maybe_set_home_built()` is only *called* from a build placement,
which happens in one process — so the peer who was elsewhere never evaluated it.
`sequence_director.gd::_share_the_camp()` re-evaluates on every delta, which is
exactly what a `place_building` delta is.

### 6. Rule 3 itself: the catch-up

`sequence_director.gd::_catch_up_a_behind_character()`. When the WORLD holds any
of `WORLD_MOVED_ON_FLAGS` (seven world-scope ids; a unit test pins that every one
of them is `world` in `flag_scopes.json`), the opening stands down for this
character: the beat is carried to the end — persisted as their **own**
`opening:beat:` history, so it survives their next login — the fade and the bed
pose clear, the door opens, and they are handed the companion
`encounter_director.gd` would have given them if this node had never run.

Three calls made deliberately rather than defaulted, all recorded in the code:

- **A companion, not a ceremony.** The starter picker is a modal panel; opening
  it here would answer "can they act at once" with "first read this menu". The
  late arrival gets the sandbox `default_starter` (captured before
  `suspend_default_starter()` erases it), keeping its species name.
- **It never runs backwards.** A character *ahead* of the world is untouched.
- **It is per-character, not per-session.** A host loading a solo save into a
  world they themselves finished takes the same path, and should.

`_refresh_door_gate` also states the answer at the gate itself
(`or world_has_moved_on()`), so the frame between the world flag landing and the
catch-up running never shows a shut door.

### 7. `trainer_npc.gd` prompt / relabel

The relabel poll needed **no ledger wiring** and the reasoning is now written
down: a `defeat_flag` is a world flag, a committed delta applies it through
`WorldState.apply_delta()`, and `merged_progression.revision` is the *sum* of
both stores' counters — so the world's store moving is indistinguishable from
this player's own moving, which is exactly right, because the label is about the
world. Verified rather than assumed in `test_story_world_catchup.gd`.

What *was* broken: `_on_challenged` fell through to a bare `return` — silence,
no line, no fight — when a trainer was already beaten and their spec named no
`defeated` conversation. Solo that is nearly unreachable (you only see a beaten
trainer because you beat them). With a second player it is the ordinary case,
because `defeat_flag` is a world flag: the trainer your friend beat is beaten for
you, and walking up got a prompt that answered with nothing.
`data/dialogue/trainers.json` gained a generic `trainer_already_beaten`, wearing
that trainer's own name and plate through the existing `speaker_identity`
overlay. `interactable.gd`'s own rule — "a visible prompt the button refuses is
worse than no prompt" — is what this closes.

## Testing

Minimal, as instructed. CI is the gate.

### `--check-only`, every changed script — clean

`story_ledger.gd`, `sequence_director.gd`, `dialogue_panel.gd`, `trainer_npc.gd`,
`gated_crossing.gd`, `road_gate.gd`, `item_gate.gd`, `realm_gate.gd`,
`tether_relay.gd`, `cart_repair.gd`, `river_nest_clear.gd`, `home_progress.gd`,
`peer_runner.gd`, and both new smokes.

### Unit

| suite | result |
|---|---|
| `test_story_world_catchup.gd` (**new**) | 13 tests, **70 assertions**, 0 failed |
| `test_flag_scopes.gd` (D99's own) | 11 tests, 239 assertions, 0 failed |
| `--only=world_ledger` | 24 tests, 136 assertions, 0 failed |
| `test_item_gate.gd` | 13 tests, 33 assertions, 0 failed |
| `test_home_progress.gd` | 10 tests, 14 assertions, 0 failed |
| `test_merged_progression.gd` | 17 tests, 51 assertions, 0 failed |
| `test_progression_state.gd` | 24 tests, 78 assertions, 0 failed |
| `test_trainer_rules.gd` | 15 tests, 214 assertions, 0 failed |
| `test_trainers_data.gd` | 50 tests, 1386 assertions, 0 failed |
| `test_gateb_objective_chain.gd` | 4 tests, 54 assertions, 0 failed |
| `test_quest_log.gd` | 42 tests, 812 assertions, 0 failed |
| `test_realm_chapter_progression.gd` | 8 tests, 115 assertions, 0 failed |
| `test_dialogue_runner.gd` | 67 tests, 1168 assertions, 0 failed |

Assertion counts are reported because a test can pass while running *fewer*
assertions than it should: `int(null)` is 0 in GDScript and a missing key aborts
a statement rather than failing it. Every `get()` in the new test and in both new
smokes is preceded by a `has()` check for exactly that reason, and both smokes'
readers return `null` rather than `false` for a key the probe did not report, so
"the peer never answered" cannot satisfy a negative assertion.

### Solo regression

<!-- SOLO_REGRESSION -->

### Net smokes (both **new**, both registered in CI)

<!-- NET_SMOKES -->

Both are registered in `.github/workflows/ci.yml`'s `verify-multiplayer-shard`,
by name in the `for required in ...` list **and** in the discovery floor. The
floor was **regenerated from the files on disk**, not incremented:

```sh
for f in tests/smoke_net_*.gd; do
  head -5 "$f" | grep -qE '^#[[:space:]]*peers:[[:space:]]*2$' && echo "$f"
done | wc -l
```

13 before this lane, **15** with its two. The command is written into the
workflow comment so a lane landing beside this one reconciles against the merged
directory rather than incrementing whichever number its own branch saw.

### Harness additions (`tools/net/peer_runner.gd`)

One arm and one probe, both narrow:

- **step `story_flag`** — submits the *same* intent the shipping trigger submits
  (`story_ledger.gd::write_flag()`, which is what `_set_progression_flag`,
  `road_gate.gd` and `tether_relay.gd` all call), so what a smoke drives is the
  game's own path to the ledger rather than a test-only poke into a flag store.
- **probe `story`** — what the WORLD says, what THIS character personally holds,
  the beat, whether the opening is still gating them, locomotion, input context,
  party size, and the gate **nodes** and their poses. Node state is reported
  beside flag state on purpose: a flag that crossed with no node change is a
  delta that reached `WorldState` and never reached the scene — a player walking
  into an invisible wall over an open bridge — and that failure is invisible from
  the flag alone. Same split lane 3.C draws between `placed_building_rows` and
  `placed_building_nodes`.

## Findings and residuals

1. **`ledger_rpc.gd::_commit_here()` runs no `progression_restore` sweep.** Only
   `_rpc_delta` does. This is a real gap in `scripts/net/`, worked around on the
   consumer side here because that directory is another lane's. The cleaner fix
   is one call in `_commit_here()`, ordered *after* `delta_applied.emit()` so the
   guard trap above does not reappear on the host. Flagged for whoever owns
   `scripts/net/` next; every consumer this lane touched is idempotent, so
   adding it there is safe and would let the `delta_applied` listeners go.

2. **`smoke_net_gate_opens_for_both` asserts the two facts that make passage
   possible, not a walk across the bridge.** The South Bridge is ~1.4 km south of
   the farmhouse spawn and `smoke_net_movement_two_peers.gd`'s own comment
   records that a fresh boot walks 2.71 m before it meets a wall. Upgrading this
   to a real crossing belongs to whichever lane teaches the net harness to seed a
   post-opening save; the assertions as written are the ones that would go red
   first if replication broke.

3. **The late arrival is handed a creature, not a choice.** See §6. If the owner
   wants a late joiner to pick their starter, the mechanism is already there
   (`starter_picker.gd`) and the change is small — but it costs "act immediately",
   which is the bar rule 3 actually states.

4. **`scripts/world/cloudreach_chapter.gd` has a second `drain_effects()` site**
   that still routes through its own `consume_dialogue_effect` path rather than
   the ledger. Left alone: Cloudreach is a separate chapter on its own branch
   scope (`docs/00_START_HERE.md`), and touching it here would be this lane
   widening itself.

5. **`scripts/net/*`, `autoload/game_state.gd`, `autoload/world_state.gd`,
   `scripts/combat/*`, `tab_map.gd`/`alpha_pins.gd`/`quest_log.gd`,
   `night_rest.gd`, `realm_heart_shrine.gd` and the Wave 3 consumers were not
   touched**, per the lane's file fence. The "shrine restore path" in the brief
   is `realm_heart_shrine.gd`, which is on the forbidden list; `realm_gate.gd` —
   the realm key/unlock gate, which is the reachable half of that pair — was
   taken instead, and the brief's contradiction is recorded here rather than
   resolved in either direction.
