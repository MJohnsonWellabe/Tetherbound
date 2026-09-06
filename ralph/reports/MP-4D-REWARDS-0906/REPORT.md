# MP-4D — trainers, bosses, tournament and per-participant rewards

**Lane:** Stage B 4.D · **Date:** 2026-09-06 · **Branch:** `claude/mp-4d-rewards`
**Base:** `main` @ `a3df2546` (session 2.A, per-peer rig 2.C, world ledger 3.A, storage 3.D,
creature ownership 4.B, encounter core 4.C, shared combat / trading / fog / revive / sleep-vote)
**Godot:** 4.7.stable.official.5b4e0cb0f, installed at `~/godot-bin/godot`, project imported
twice before any other command (both imports exit 0).

The one-line verdict: **a trainer beaten by two people is beaten once for the world, and pays
both of them the authored amount in full. Solo is unchanged — all four named solo regressions
pass on first attempt.**

---

## 1. Per item

| # | Item (from the brief) | Verdict |
|---|---|---|
| 1 | The world fact happens once: ONE commit for the `defeat_flag` | **DONE** |
| 2 | The personal reward happens per participant, guarded by `reward_flag(source, peer)` | **DONE** |
| 3 | XP is NOT divided by participant count | **DONE** — unit-proven at 1, 2 and 4 participants |
| 4 | A multi-pilot Warden: boss and tournament through the same record, differing by data | **DONE** — and it needed one real fix, see §4 F1 |
| 5 | Scaling by composition (§10, D-MP12), numbers in `multiplayer.json`, fixed before implementing | **PARTIAL, deliberately** — targeting spread and the modest multiplier ship; "extra opponents" does not, and §4 F2 says why |
| 6 | One new pure unit file, every assertion seen red first | **DONE** — 29 tests, 97 assertions, 34 breaks |
| 7 | ONE new net smoke, registered in `verify-multiplayer-shard` (count floor + named list) | **DONE** — floor regenerated from disk (14), not incremented |

### 1. The world fact happens once

`_record_trainer_defeat()` grew one line — `if _record_trainer_defeat_for_the_session(spec):
return` — and everything else about it is untouched. Solo returns `false` on the first line of
that function (`_is_multi_peer()`), so **not one line of the new path runs in a solo game** and
the old body is byte-for-byte the payout it was.

In a session the defeat flag stops being a local `progression.set_flag()` and becomes a
`set_world_flag` intent through `Game.ledger` — D103's rule that a world fact may only change
as an intent, with `alpha_pins.gd::clear_alpha()` as the shipped precedent. The host commits it
once and every peer receives the delta. `world_ledger.gd` answers a re-commit with
`code: "noop"`, which is §7's second sentence working: a second peer arriving later finds the
trainer already beaten because that is what the world says.

The net smoke asserts the player-facing consequence rather than the mechanism: after the fight,
**both** peers are offered a greeting instead of a second battle (`can_challenge` false), and
peer 1 — which never ran a trainer battle of its own, asserted mid-fight — holds the flag.

`reward.flags` are routed by `data/progression/flag_scopes.json`, not by assumption: the three
in the shipped table (`recipe_saddle`, `realm_key_cloudreach`, `realm_heart_meadows_earned`) are
all world-scoped, so they travel with the world fact and are committed once. A player-scoped one
would be paid per participant instead. Both directions are separate assertions.

### 2. The personal reward happens per participant

`scripts/net/encounter_rewards.gd` (new, pure `RefCounted`) turns a trainer spec plus a
participant list into plain intents. It holds no state, touches no node, and is the file the
"nothing is divided" claim is provable in.

One `reward_grant` per **component** — `trainer:<id>:coins`, `trainer:<id>:item:<item>`,
`trainer:<id>:flag:<flag>`, `trainer:<id>:xp` — each addressed to every participant. Distinct
sources because `world_ledger.gd::reward_flag()` guards one receipt per participant per source:
with a single source for a whole payout, a satchel that was full when the coins landed has burnt
the receipt for the potion too and nothing can ever pay it.

The payout is deliberately **not** gated on the defeat flag. Solo uses that flag as its anti-farm
guard because solo there is only ever one player; here the guard is the per-participant receipt,
and reading the world flag instead would refuse to pay a second player for a trainer their friend
had beaten earlier — who is exactly the person §7 exists to pay.

**XP cannot be a ledger op**, and that is a consequence of D100 rather than a shortcut: a peer's
party is its own and the host has never seen it, so the host cannot add a level to somebody
else's creature and must not pretend to. The ledger holds the *receipt*; the host then TELLS each
newly-paid participant (`_rpc_trainer_reward`, using the ledger's returned `paid` list), and that
peer applies the bonus to its own party and shows its own line. The guard is durable, the payment
is a message.

### 3. XP is not divided

`xp_bonus()` takes no participant count, so there is no argument it *could* be divided by — the
structural half. The behavioural half is `test_xp_is_not_divided_by_participant_count`, which
runs the grant list at 1, 2 and 4 participants and asserts the same receipt names every one of
them; `test_items_are_not_divided_by_participant_count_either` does the same for the authored 150
coin and 2 revives. `data/config/multiplayer.json` carries
`encounter.reward.divide_by_participants: false` as the contract written where a future edit has
to argue with it.

The net smoke proves the item half against two real processes: **peer 1 gained Bryn's authored 20
coin and 1 potion, and so did peer 0.** Measured as a before/after delta, never an absolute — the
opening hands out a starting satchel.

### 4. One record, several creatures, one code path

Every trainer, tournament round, stronghold gauntlet fight and Cloudreach captain already funnels
through `begin_trainer_battle()` → `_finish_trainer_battle()` → `_record_trainer_defeat()`
(`cloudreach_encounter_director.gd` overrides it and calls `super`). So `tournament.gd`,
`stronghold_climax.gd` and the Cloudreach controllers needed **no change at all** to be paid
correctly — a boss really is data and not a code path, and `smoke_tournament_bracket` and
`smoke_gate_e_finale` passing unchanged is the evidence.

What *was* wrong is F1 below: the record was being minted per ROUND. It is now one record per
battle, and both peers are still in it when the last creature falls.

`kind` is `"boss"` when `trainers.json`'s new `boss_ranks` (`["warden"]`) matches the spec's
`rank`, `"trainer"` otherwise. Data, so promoting a captain is a data edit and not a branch.

### 5. Scaling — two thirds of §10, and the third stated rather than faked

Implemented, all from `data/config/multiplayer.json`'s `encounter.scaling`, all fixed in this
report's brief before a line was written:

* **targeting spread** (4.C's handover H6) — `encounter_host.gd::pick_struck()` prefers whoever
  has been hit least, distance only breaking a tie. Nearest-only is precisely §10's named
  failure: two players fighting one creature meant whoever stepped closest absorbed the whole
  fight while the other watched.
* **a modest stat multiplier** — 1.10 at two players, applied to the opponent's `attack` and
  `defence` only, plus an `attack_cooldown_multiplier` of 0.85 so one body facing two people
  swings more often. Never a level (spec §11 / D30) and **never HP**: there is no `hp_multiplier`
  key, and `test_there_is_no_hp_multiplier_to_reach_for` asserts its ABSENCE at five participant
  counts, because a key present and set to 1.0 is a key somebody eventually tries at 1.5.

Not implemented, and stated at the config, at the code and here: **`opponents_extra`**. See F2.

---

## 2. Commands run, and their counts

No full sweep. Nothing re-run to confirm a pass. No exit-time `ObjectDB instances were leaked` or
`Parameter "material" is null` notice chased — both are engine noise at exit and both appear on
the untouched base.

### Parse checks — 7 files, `--check-only`, all clean

```
godot --headless --path . --check-only --script scripts/net/encounter_rewards.gd
godot --headless --path . --check-only --script scripts/net/encounter_host.gd
godot --headless --path . --check-only --script scripts/combat/encounter_director.gd
godot --headless --path . --check-only --script scripts/world/trainer_npc.gd
godot --headless --path . --check-only --script tools/net/peer_runner.gd
godot --headless --path . --check-only --script tests/test_encounter_rewards.gd
godot --headless --path . --check-only --script tests/smoke_net_boss_rewards_each_participant.gd
```

7 invocations, 7 clean (no output beyond the engine banner).

### The new unit file

```
godot --headless --path . --script tests/run_tests.gd -- --only=test_encounter_rewards.gd
  -> 29 tests, 97 assertions, 0 failed
```

Discovered automatically by `tests/run_tests.gd`'s sharding, so no CI registration was needed.
(The baseline was 29/95 before the F3 fix below added two assertions.)

### Solo regression — the bar that matters most

Run after every game-code change was in place. All four **PASS on the first attempt**; no retries,
no reruns.

| Smoke | Result |
|---|---|
| `tests/smoke_trainer_battle.gd` | **PASS** — `a trainer can be challenged, fought through their team, beaten once, and not again.` (`2 of the trainer's 2 creatures felled`, `reward paid: 20 coin`, `reward paid: 1 potion_small`, `Terrapup: level 3 xp 0 -> 140`, `re-challenge granted nothing; the reward paid exactly once`) |
| `tests/smoke_boss.gd` | **PASS** — `boss smoke test passed` |
| `tests/smoke_tournament_bracket.gd` | **PASS** — `the tournament can be entered, lost, retried, fought through all three rounds and won, once.` |
| `tests/smoke_gate_e_finale.gd` | **PASS** — `gate E finale smoke test passed` |

That the trainer/tournament/boss/finale smokes all pass **unchanged** is also the evidence for
item 4: those three systems share one payout path and did not need one line each.

### The net smoke

`tools/net/run_net_smoke.sh boss_rewards_each_participant`

| Attempt | Result |
|---|---|
| 1 | **FAIL** ×1 — `no verdict`. Harness defect, mine: F4 |
| 2 | **FAIL** ×1 — `the battle never resolved in 2164 frames (108 swings, 1 of their creatures met)`. Real finding: F5 |
| 3 | **PASS**, 30 checks, `ALL CHECKS PASSED`, exit 0, both peers `unexpected_exit=false` |

Attempts 1 and 2 are reported as failures of this lane's own harness arm, not of the base: both
were in `tools/net/peer_runner.gd`'s new `win_trainer_battle` arm, which did not exist before this
lane, and neither touched game code.

---

## 3. Break / fail / revert — every assertion seen red first

34 deliberate defects in **production** code (never a weakened test), each reverted immediately
after. The assertion count is reported for every run, because a break that makes a test run FEWER
assertions is aborting the function rather than failing it. **The count held at 95 in 32 of the 34
runs**; the two that moved are called out and are findings in their own right.

Baseline at the time of the sweep: 29 tests, **95 assertions**, 0 failed.

### `scripts/net/encounter_rewards.gd`

| Break | What was broken | Assertions | Went red |
|---|---|---|---|
| A | world-scoped reward flags never join the world facts | 95 | `..._world_scoped_reward_flag_travels_with_the_world_fact...` |
| B | world-scoped reward flags are ALSO paid per participant | **99** | same test — see note below |
| C | reward flags are never paid to anybody | 95 | `..._player_scoped_reward_flag_is_paid_to_each_participant...` |
| D | the defeat flag is committed twice | 95 | 3 tests, incl. `..._defeat_flag_is_one_world_intent...` |
| E | coins divided by participant count | 95 | `..._items_are_not_divided_by_participant_count_either` |
| F | the xp receipt only exists for a solo winner | **91** | 3 tests, incl. `..._xp_is_not_divided_by_participant_count` |
| G | every component shares one source | 95 | 4 tests, incl. `..._one_full_satchel_cannot_burn_the_rest` |
| H | `unique_peers` does not de-duplicate | 95 | `..._same_peer_listed_twice_is_paid_once` |
| I | peer 0 counts as a peer | 95 | `..._payout_with_nobody_in_the_fight_is_not_made` |
| J | `peers` handed over without `duplicate()` | 95 | **stayed green — F3** |
| J2 | the same break, against the corrected test | 97 | `..._no_two_grants_share_one_participant_list` |
| K | a spec with no id is still paid | 95 | `..._spec_with_no_id_is_refused...` |
| L | `world_facts` ignores a missing realm | 95 | `..._intent_with_no_realm_is_refused...` |
| M | an item row with count 0 is granted | 95 | `..._zero_count_item_row_is_skipped...` |
| N | a trainer with no defeat flag still writes one | 95 | `..._trainer_with_no_defeat_flag_asks_the_world_for_nothing` |
| O | a coins grant is emitted at 0 coins | 95 | `..._trainer_who_pays_nothing_produces_no_grants_but_still_falls` |
| AD | only the first participant is addressed | 95 | 4 tests, incl. `..._every_participant_is_addressed_by_every_component...` |

Break **B** ran FOUR MORE assertions (99), not fewer, and that is the benign direction: paying the
world flag per participant adds a grant, and
`test_each_component_is_its_own_source_so_one_full_satchel_cannot_burn_the_rest` loops over the
grant list. Break **F** ran four fewer (91) for the mirror reason — it deletes a grant that the
same loop would have asserted on — and it still failed on three tests including the one it was
aimed at, so no assertion was silently skipped past.

### `scripts/net/encounter_host.gd`

| Break | What was broken | Assertions | Went red |
|---|---|---|---|
| P | `scaling_for` always returns the identity row | 95 | `..._more_people_make_the_opponent_modestly_stronger...`, `..._mid_fight_join_re_derives_the_scaling` |
| Q | a count above the table is not clamped down | 95 | `..._group_bigger_than_the_table_clamps_to_the_hardest_row` |
| R | an `hp_multiplier` key is added | 95 | `..._there_is_no_hp_multiplier_to_reach_for` |
| S | the `maxi(1, ...)` count clamp removed | 95 | **stayed green — F6, and the line is gone** |
| S2 | the missing-row guard removed | **96** | stayed green, ran one assertion fewer — F6 |
| T | `pick_struck` picks the nearest, ignoring hit counts | 95 | `..._opponent_prefers_whoever_it_has_hit_least` |
| U | distance never breaks a tie | 95 | `..._distance_still_breaks_a_tie` |
| V | `note_struck` does nothing | 95 | `..._opponent_prefers...`, `..._leaver_stops_being_a_target...` |
| W | a leaver's hit count survives them | 95 | `..._leaver_stops_being_a_target_and_stops_being_counted` |
| X | `open` does not stamp the scaling row | 95 | `..._record_is_stamped_with_its_own_scaling_row` |
| Y | `join` does not re-derive it | 95 | `..._mid_fight_join_re_derives_the_scaling` |
| Z | joining refills the opponent to full | 95 | `..._opponents_hit_points_are_never_touched_by_a_join` |
| AA | the next creature clears the participants | 95 | `..._trainers_next_creature_is_the_same_fight_and_the_same_participants` |
| AB | a finished fight accepts another creature | 95 | `..._finished_fight_does_not_get_another_creature` |
| AC | a swing that reached one person hits nobody | 95 | `..._swing_that_reached_one_person_lands_on_that_person` |
| AE | the stat multiplier doubled | 95 | 4 tests, incl. the MODEST bound in `..._more_people_make...` |
| AF | the cooldown multiplier pinned at 1.0 | 95 | `..._more_people_make_the_opponent_modestly_stronger_and_faster` |
| AG | the table is read one row too hard | 95 | 3 tests, incl. `..._solo_is_the_identity_row` |

Every one of the 29 tests in the file is covered by at least one break.

---

## 4. Findings

### F1 — a trainer battle was minting a NEW encounter record per creature, and it would have paid the joiner for none of a boss they fought two thirds of

Found by reading, before the net smoke could catch it. `_start_fight()` runs once per SEND-OUT,
so `_open_encounter_if_networked()` was minting a fresh record for each of the trainer's
creatures. A peer that joined round one's record was simply not in round three's, and round three
is the one the victory is recorded against.

Worse, and this is the part that would not have been obvious from a code read alone:
`combat_manager.gd::_finish()` submits `disengage` at the end of **every** round — correct for a
wild fight, and also what a trainer's creature fainting looks like from inside the manager. So by
the time the next creature steps up, §9 has already emptied the record's participant list and
marked it `done`. "Who is in the record right now", asked at the moment the last creature falls,
is very nearly nobody: the winner has just left it.

Fixed in two halves, both in this lane's own files:

* `encounter_host.gd::set_opponent()` — the trainer's next creature is the SAME record with a new
  opponent row and a cleared position history. The id, the participants and their `joined_seq`
  all survive. `_resume_trainer_encounter()` brings the record back to `active` and re-seats
  everybody the session still holds, using `join()`'s documented idempotence (it does not
  re-stamp `joined_seq`, so a re-seat cannot make anybody look like a later arrival than they
  were).
* `_trainer_battle_participants` — the union of everybody who has been in this battle's record at
  any point, sampled while a round is LIVE (from `_tick_encounter`). That accumulated set, not
  the record's live list, is who gets paid. It is also §6's "arriving late costs nothing" for
  free: a peer that joined for the ace alone is in it exactly like the one who was there from the
  first send-out.

`_close_trainer_encounter()` ends the record when the BATTLE ends, and not one creature earlier.

### F2 — `opponents_extra` is not implemented, and shipping the knob would have been worse than not shipping it

The brief and §10 both ask for "extra opponents or roles **where the encounter defines them**".
Following the code and saying so, per the anti-grind rule:

* `combat_manager.gd` holds ONE opponent body (`_enemy`). Two creatures cannot stand on the field
  at once without restructuring 4.C's file, which this lane does not own.
* A trainer's roster is authored and finite. The only two ways to field more were to **invent**
  creatures for them — `CLAUDE.md` forbids new creatures for the Meadows, and inventing roster
  entries is a design decision no lane may make alone — or to **re-send a creature that has
  already fainted**, which is worse than not doing it and is exactly the "four times as long, not
  four times as interesting" failure §10 names, wearing a different hat.

So the key is **absent from `multiplayer.json`** rather than present and ignored, and the reason
is written at the config, at `scaling_for()`, and here. What §10 asks for that this tree CAN
express honestly — targeting spread and a modest multiplier — is implemented and unit-proven.
Handover H1.

An earlier draft of the config did carry `opponents_extra` (0/1/1/2 by count). It was removed
before any code read it, so no number here was discovered by running until something passed.

### F3 — a `duplicate()` that no test could turn red, because it was guarding the wrong thing

Break J removed `_grant()`'s `peers.duplicate()` and every assertion stayed green. The test was
asserting that a grant does not alias the CALLER's array — and `unique_peers()` already returns a
fresh array, so the caller was never at risk and the line was not what protected them.

What that line actually prevents is one array shared by all four grants: correcting one
component's recipients would silently correct every component's, which is how a payout ends up
owed to somebody nothing recorded a receipt for. The test was rewritten to assert THAT
(`test_no_two_grants_share_one_participant_list`), and break J2 turns it red. Two assertions
added, 95 → 97.

### F4 — the net smoke's first failure was my own harness arm counting the wrong unit

Attempt 1 returned `no verdict`, which says nothing about the game. `win_trainer_battle`'s ceiling
counted LOOP ITERATIONS and each iteration burned ~24 physics frames, so a "2400" ceiling was
really 57,600 frames and the coordinator's own wall-clock deadline expired first. Rewritten to
count physics frames and to bound itself by the budget the coordinator actually sent, minus a
margin, so it answers with a real verdict instead of being cut off. Recorded because a smoke that
reports `no verdict` is a smoke nobody can debug.

### F5 — submitting a `strike_intent` directly lands the damage but never performs the KILL

Attempt 2's failure, and it is worth stating because the next person to write a net smoke will
reach for the same arm. 108 direct `submit_encounter_intent` submissions drove Bryn's first
creature's bar to the floor and the battle kept running.

The host's arbitration and the record broadcast both work — the hit points drop and both peers
draw the same bar — but the FAINT is performed by `combat_manager.gd::apply_host_strike_verdict()`,
and only `_submit_strike_intent()` calls it. `_step_strike` (4.C's arm) never notices, because it
exists to say what a MODIFIED client could say (a swing aimed at a teammate), which no button can
produce, and its smoke does not need anything to die.

This lane's arm needs a fight to actually finish, so it presses `combat_quick` — the button a
player presses — and the whole production path runs: manager, host arbitration, verdict, faint.
Not a game defect; a statement about which harness arm proves which thing. Battle then won in
1337 frames / 27 swings against both of Bryn's creatures.

### F6 — two guards, one dead and one only unfalsifiable, handled differently

4.C's F7 set the precedent and both cases were tested against it.

**Break S** removed `scaling_for()`'s `maxi(1, participant_count)` clamp and every assertion
stayed green — because a count of 0 looks up a row the table does not have and falls through to
the identity anyway, which is the answer the clamp existed to produce. A line no test can turn red
is a line that is not enforcing anything, so **it is gone**, with the reasoning left at the site.
The behaviour is still pinned by `test_a_count_of_zero_or_less_is_read_as_one_player`, which
breaks AE and AG both turn red.

**Break S2** removed the `by_count.has(wanted)` guard instead. It stayed green *and ran one
assertion fewer (96)* — the signature the brief warns about, an aborted function rather than a
failed one: indexing a missing Dictionary key is an engine error, not a value. That guard's job is
to keep a missing row from being an engine error rather than to change the answer, and the answer
below it (`row is Dictionary` → identity) is the same either way. It is KEPT, and this is recorded
rather than left as a green tick, because "green" and "ran fewer assertions" together are the
thing that is supposed to be reported, not resolved.

### F7 — a pre-existing script error on both peers, not this lane's

Every net smoke run prints, on both peers, during the handshake:

```
SCRIPT ERROR: Invalid call. Nonexistent 'bool' constructor.
   at: _apply_nameplate (res://scripts/net/remote_trainer.gd:137)
```

`remote_trainer.gd` is lane 2.C's file, is in this lane's do-not-touch set, and the error fires
from `_ready()` during peer spawn — before anything this lane touches exists. It does not fail any
smoke. Reported rather than fixed; handover H5.

### F8 — `cloudreach_finale_controller.gd` still writes a world fact locally

`strike_relay()` at :244 does `_progression.set_flag(relay["flag_id"])`. Those relay flags are
world facts, and under D103 the only way a world fact may change is an intent — the same defect
`alpha_pins.gd`'s own handover describes for `_mark_once_cleared()`. The file is named in this
lane's ownership, so this is a deliberate scope call rather than an oversight: it is not a trainer
defeat, no test in this lane's set covers it, and changing Cloudreach behaviour with nothing to
prove it either way is how a lane lands a regression it cannot see. One-line fix, same shape as
`_record_trainer_defeat_for_the_session()`'s world half. Handover H3.

### F9 — `tests/smoke_net_sleep_vote.gd.uid` was missing from the tree

Lane 5.D's net smoke landed without its `.uid`, so a fresh `--import` generates one and leaves
every subsequent contributor with a dirty tree. Committed here with this lane's own three, because
the alternative is every future lane rediscovering it.

---

## 5. What this lane deliberately did not do

* No change to `autoload/game_state.gd`, `autoload/world_state.gd`, `scripts/net/world_ledger.gd`,
  `scripts/net/ledger_rpc.gd`, `scripts/net/session.gd`, `scripts/ui/tab_map.gd`,
  `alpha_pins.gd`, `night_rest.gd`, or any Wave 3 world consumer.
* No change to `tournament.gd`, `stronghold_climax.gd` or the Cloudreach controllers — they were
  already correct through the shared path (item 4), and editing them to prove ownership would
  have been change for its own sake.
* No `opponents_extra` (F2). No HP scaling, ever. No level scaling (spec §11 / D30).
* No second net smoke, no full sweep, no confirmation re-runs, no creature meshes, no change to
  the five-creature limit, no storage, no sixth slot.
* No fix for `smoke_combat_camera`'s known flake (4.C's H9) — not run here and not this lane's.

---

## 6. Handovers

* **H1 — §10's "extra opponents or roles" is unbuilt, and needs a decision before it is built.**
  F2. It needs either a second opponent body in `combat_manager.gd` (4.C's file) or authored
  reserve rosters in `trainers.json` (a design decision, and under `CLAUDE.md` an owner one).
  Neither is a lane's to take alone. The config key is absent rather than ignored, so whoever
  builds it adds a key and a reader together.
* **H2 — 4.F measures the result at 1, 2 and 4 participants.** `encounter.scaling.by_participants`
  is the table to tune and `encounter_host.gd::scaling_for()` the one reader. The numbers there
  are a first pass fixed before implementation, not a measured result: 1.10 / 0.85 at two players
  is chosen to be modest, and W23's method is what should decide whether it is right.
* **H3 — `cloudreach_finale_controller.gd::strike_relay()` writes a world fact locally.** F8.
  One-line fix, same shape as this lane's world half; wants a Cloudreach-side test to land with
  it.
* **H4 — a joiner's trainer battle is still local and unarbitrated.** 4.C's F1/H1 unchanged: the
  host opens encounters, a client joins them. A CLIENT that beats a trainer on its own submits the
  world fact through the ledger (this lane added that) but pays only itself, because its fight was
  its own. When wild replication and D96's Terrain3D FULL_GAME collision land, that branch
  disappears into `_open_encounter_if_networked()` with nothing else to change.
* **H5 — `remote_trainer.gd::_apply_nameplate()` errors on every peer spawn.** F7. Lane 2.C's
  file, in this lane's do-not-touch set, fails nothing today.
* **H6 — a losing thrower's HUD still has no banner.** 4.C's H7 is untouched: `encounter_refused`
  and `caught_by_other` exist, nothing draws them. This lane adds one more event in the same
  state — `_rpc_trainer_reward` carries a `line` that reaches `Game.push_world_message()`, which
  `playground_hud.gd` polls, so the reward toast DOES appear; the refusal banner still does not.
* **H7 — the reward line names the AUTHORED payout, not what landed.** The solo path reads back
  `inventory.add()`'s leftover and can say "the satchel was full"; the ledger's `item_grant` op
  does not carry a leftover back to the host, and inventing one would mean the host describing the
  contents of somebody else's satchel, which it has never seen (D100). Whoever gives `item_grant`
  a receipt can close this.

---

## 7. Files

| File | Change |
|---|---|
| `scripts/net/encounter_rewards.gd` | **new** — §7's two halves as plain intents, pure |
| `scripts/net/encounter_host.gd` | §10's `scaling_for`/`scaling`, the record's scaling stamp, `pick_struck`/`note_struck`, `set_opponent` |
| `scripts/combat/encounter_director.gd` | the §7 payout section, one record per BATTLE (F1), `_encounter_kind`, opponent scaling, spread targeting wired in |
| `scripts/world/trainer_npc.gd` | `is_boss()` — §3's `kind`, read off data |
| `data/config/multiplayer.json` | `encounter.scaling` and `encounter.reward` (§11) |
| `data/config/trainers.json` | `boss_ranks` |
| `tools/net/peer_runner.gd` | `trainer_battle`, `win_trainer_battle`; the `trainer_reward` probe |
| `tests/test_encounter_rewards.gd` | **new** — 29 tests, 97 assertions |
| `tests/smoke_net_boss_rewards_each_participant.gd` | **new** — the lane's net assertion |
| `.github/workflows/ci.yml` | `verify-multiplayer-shard`: floor 13 → **14, regenerated from the files on disk**, and the named registration |

---

## 8. The net smoke's own output, in full

Attempt 3, the green one. Peer ids as the engine handed them out: the listen server is **1**, the
joiner is a large random 32-bit number, and nothing in this lane indexes by peer id or assumes an
ordering.

```
PASS: coordinator tracked 2 peers
PASS: peer 0 input_context is 'world' (got 'world')
PASS: peer 1 input_context is 'world' (got 'world')
PASS: a Session exists to host/join (lane 2.A)
PASS: peer 0 hosted a world (hosting udp/28741 as peer 1)
PASS: peer 1 joined peer 0's world on port 28741
PASS: peer 0's registry holds both players
PASS: peer 1's registry holds both players
PASS: peer 0 deployed its own creature (deployed AllyCreature)
PASS: peer 1 deployed its own creature (deployed AllyCreature)
PASS: both peers answered the reward probe before the fight
PASS: peer 0 has not beaten Bryn yet
PASS: peer 0 could challenge Bryn right now
PASS: peer 1 has not beaten Bryn yet
PASS: peer 1 could challenge Bryn right now
PASS: peer 0 challenged Bryn (challenged practice_trainer; bound to encounter '1:1')
PASS: the host minted an encounter record for the battle
PASS: and it is a TRAINER encounter, not a wild one (got 'trainer')
PASS: stamped with an explicit realm (D97), got 'meadows'
PASS: peer 1 travelled to the fight (trainer stands at (22.11, -1.58, 18.88))
PASS: peer 1 joined the trainer battle already in progress (joined 1:1 beside a local 'bramblebun')
PASS: the host's record now holds 2 participants (got 2)
PASS: joining did not change the phase (got 'active')
PASS: peer 1 is in the FIGHT but is not running a trainer battle of its own --
      so any defeat flag it ends up holding can only have come from the host
PASS: peer 0 beat Bryn's whole team (battle won in 1337 frames / 27 swings against 2 of their creatures)
PASS: peer 0's world says Bryn has been beaten ('trainer_defeated_practice')
PASS: and peer 0 is offered a greeting rather than a second battle
PASS: peer 1's world says Bryn has been beaten ('trainer_defeated_practice')
PASS: and peer 1 is offered a greeting rather than a second battle
PASS: the host knows about 2 peers to pay (got 2)
PASS: the ledger holds a 'trainer:practice_trainer:coins' receipt slot for each peer (got 2)
PASS: 'trainer:practice_trainer:coins' was paid to BOTH participants, once each (got 2 of 2):
      { "1": true, "708349876": true }
PASS: the ledger holds a 'trainer:practice_trainer:item:potion_small' receipt slot for each peer (got 2)
PASS: 'trainer:practice_trainer:item:potion_small' was paid to BOTH participants, once each (got 2 of 2):
      { "1": true, "708349876": true }
PASS: peer 0 gained Bryn's authored 20 coin, not a share of it (got 20)
PASS: peer 0 gained the authored 1 potion, not a share of it (got 1)
PASS: peer 1 gained Bryn's authored 20 coin, not a share of it (got 20)
PASS: peer 1 gained the authored 1 potion, not a share of it (got 1)

ALL CHECKS PASSED
```

The three groups are asserted separately on purpose, and that is the point of asserting all three:
a payout that reached only the winner passes the world group; a world flag written twice, once per
peer, passes the receipt group; a payout that halved every amount passes both. Only together are
they §7.
