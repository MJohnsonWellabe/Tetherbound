# MP-4C — encounter core and catch arbitration

**Lane:** Stage B 4.C · **Date:** 2026-09-06 · **Branch:** `claude/mp-4c-encounter`
**Base:** `main` @ `61518f6b` (session 2.A, per-peer rig 2.C, world ledger 3.A, storage 3.D,
creature ownership 4.B)
**Godot:** 4.7.stable.official.5b4e0cb0f, installed at `~/godot-bin/godot`, project imported
twice before any other command (both imports exit 0).

The one-line verdict: **two players fight one opponent together, the host decides every
outcome, and exactly one player can win a catch. Friendly fire is a refusal with a reason,
not a damage number of zero. Solo combat is unchanged.**

---

## 1. Per item

| # | Item (from the brief) | Verdict |
|---|---|---|
| 1 | A host-simulated opponent with authoritative HP; clients render the record | **DONE** |
| 2 | Validated strikes (§5): host positions, host move profile, host `_rng` | **DONE** |
| 3 | Friendly fire is a refusal (`friendly_target`), before any roll | **DONE** |
| 4 | Join in progress (§6): no reset, no re-intro camera | **DONE, host-opened only** — F1 |
| 5 | Catch arbitration (§8): first commit owns it, `already_resolving` for the second | **DONE (pure + unit-proven); no net catch-race smoke** — F5 |
| 6 | Numbers in `multiplayer.json`'s `encounter` block, fixed before implementing | **DONE** |
| 7 | One net smoke, registered in `verify-multiplayer-shard` (count floor + named list) | **DONE** |

### 1. The record is the hit points

`scripts/net/encounter_host.gd` (new, pure `RefCounted`) holds protocol §3's record and is
the only thing that writes its `hp`. `combat_manager.gd` in a session never calls
`_enemy.take_damage()` — the host's number is **written** to `_enemy.hp` by
`apply_encounter_record()`, and a record arriving with an older `seq` is dropped rather than
applied backwards, which is what stops a late packet from un-dropping the bar.

The net smoke asserts the consequence directly: after every landed blow, host and client read
the same float to within 0.001.

### 2. Strikes

`strike_intent` carries `slot`, `move_id`, `origin`, `facing` and nothing about what happened.
The host:

* takes **its own** position for the striking creature — 4.B's `deployed_body_for(peer_id)`,
  never a node name, never the payload;
* **rebuilds the move** from its own `combat.json` and its own two body radii
  (`combat_manager.host_move_profile()`), so a peer cannot post itself a longer reach by
  describing its own move. This is one static function that the instance path also delegates
  to, so there is not a second copy of "what a quick attack reaches";
* runs `MATH.move_connects` exactly as `_resolve_player_strike()` did, then, if that misses,
  against each sample the host took inside `strike_latency_tolerance_ms`;
* rolls damage with the **host's** `_rng` (the manager's own — deliberately not a second
  generator, or "the host rolled it" would be ambiguous).

The intent's `origin` reaches exactly one line, `_retro_window_applies()`, and decides only
whether this peer gets the retro window. A lying origin can therefore only ever **lose** a
striker its latency tolerance; it can never win a hit, because both branches test from the
host's origin. That is §2 reduced to one function, and
`test_the_host_position_decides_the_hit_not_the_one_in_the_intent` plus
`test_a_lying_origin_loses_the_latency_tolerance_it_would_have_had` are the two assertions.

The opponent's own swing is host-decided too. On a client `_on_enemy_strike()` now returns
immediately: per 4.B's H1 a client's wild bodies are its own drifted simulation, and letting
one decide that a player just took eleven damage is a peer authoring an outcome from a
position no other process holds. On the host the swing picks a target **among the
participants** (`host_pick_struck_participant`) and the blow is addressed to that peer.

### 3. Friendly fire

Refused with `friendly_target` before any roll, decided from bodies the host holds, by
`owner_peer_id` (4.B's H5). "Resolved target" is the **nearest** body the swing connects with,
not "anything in the cone": a strike at the opponent with a teammate somewhere behind it is a
legal strike, and refusing it would teach two players to fight from opposite sides of the
field to stay out of each other's arcs. A teammate's **trainer** is as protected as their
creature; a wild body and a non-participant's creature are not friendly targets. All four
cases are separate unit assertions.

### 4. Joining

`engage` naming a live id adds the peer to `participants` and touches nothing else — the
function has no line that could reset a fight even by accident. Asserted twice: a unit case
that a join does not refill the opponent or change the phase, and the net smoke asserting the
same against a real second process.

### 5. Catch arbitration

`scripts/net/catch_arbiter.gd` (new, pure). One entry point, `attempt()`, which claims **and**
decides in the same call — a `claim()` a caller could forget to pair with a `decide()`, or two
claims interleaved between a check and a set, is exactly the race the file exists to close.
The host re-derives the closest approach with `orb.gd::closest_approach_ahead(launch_point,
direction, host_target_position)` using its **own** position for the creature, rolls
`CATCH.resolve` with the host's die, and prices the orb the thrower actually **spent**
(carried in the intent — R4.9's reason, restated across the wire).
`throw_aim.gd::last_launch()` is the new hand-off: `_release()` is the one place the launch
point and direction exist, after `_spawn_forward` and the launch assist, and a caller
re-deriving either would describe a different throw.

`catch_attempt` on a non-wild encounter is refused with `not_catchable` at the host, not by
hiding a button.

---

## 2. Commands run, and their counts

Nothing was re-run to confirm a pass. No full sweep. No exit-time `ObjectDB instances were
leaked` / `resources still in use` notice was chased — engine noise at exit, and both appear
identically on the untouched base.

### Parse checks — 9 files, `--check-only`, all clean

```
godot --headless --path . --check-only --script scripts/combat/combat_manager.gd
godot --headless --path . --check-only --script scripts/combat/encounter_director.gd
godot --headless --path . --check-only --script scripts/combat/throw_aim.gd
godot --headless --path . --check-only --script scripts/net/encounter_host.gd
godot --headless --path . --check-only --script scripts/net/catch_arbiter.gd
godot --headless --path . --check-only --script tools/net/peer_runner.gd
godot --headless --path . --check-only --script tests/test_catch_arbitration.gd
godot --headless --path . --check-only --script tests/test_encounter_host_rejects_friendly_strike.gd
godot --headless --path . --check-only --script tests/smoke_net_shared_wild_fight.gd
```

9 invocations, 9 clean (no parser output beyond the engine banner).

### The two new unit files

```
godot --headless --path . --script tests/run_tests.gd -- --only=test_catch_arbitration.gd
  -> 13 tests, 48 assertions, 0 failed
godot --headless --path . --script tests/run_tests.gd -- --only=test_encounter_host_rejects_friendly_strike.gd
  -> 16 tests, 42 assertions, 0 failed
```

Both are discovered automatically by `tests/run_tests.gd`'s sharding, so no CI registration was
needed for them.

### Solo regression — the bar that matters most

Run after every change to `combat_manager.gd` and `encounter_director.gd` was in place. (The
only game-code edits after this run were a rename — `_nearest_live_wild` → `nearest_live_wild`
— and two host-only branches that solo cannot reach; every solo-reachable line is unchanged
from the run below.)

| Smoke | Result |
|---|---|
| `tests/smoke_combat.gd` | **PASS** — `combat: OK — a fight can be entered, piloted, won and left.` (`5 blows landed for 115.7 damage`) |
| `tests/smoke_catching.gd` | **PASS** — `catching: OK — a throw can be aimed, missed, and landed.` |
| `tests/smoke_arena_contain.gd` | **PASS** — `arena containment: OK -- Warrens and Stronghold fights hold participants inside a reachable, legal room.` |
| `tests/smoke_combat_camera.gd` | **1 fail, then 3 green. Recorded as a finding, not as a pass — see F4.** |

### The net smoke

`tools/net/run_net_smoke.sh shared_wild_fight --out=/tmp/net-local`

| Attempt | Result |
|---|---|
| 1 | **FAIL** ×2 — the joiner's creature was held in its own arena 40 m from the host's opponent (F2) |
| 2 | **FAIL** ×1 — the joiner's swing missed a creature that had run out of reach (F3) |
| 3 | **FAIL** ×1 — the two creatures settled 3.28 m apart against a 3.0 m guard I had set too tight |
| 4 | **PASS**, 46 checks, `ALL CHECKS PASSED`, exit 0, both peers `unexpected_exit=false` |
| 5 | **PASS**, 43 checks, after the F6 fix below. First attempt after that change. |

The check count varies between 43 and 46 because phase 1 gives each player a **swing budget**
against a creature that is actively running away (see the smoke's own comment and F3). The
terminal assertion — "peer N landed a blow on the shared opponent within K swings" — is always
present and always evaluated, so a shorter run is a run where fewer swings were needed, never
a run where an assertion was skipped.

---

## 3. Break / fail / revert — every assertion seen red first

Each break below is a deliberate defect in **production** code (never a weakened test),
reverted immediately after. The assertion count is reported alongside the failures, because a
break that makes a test run FEWER assertions is aborting the function rather than failing it.
**The count never moved in any of the 24 breaks**: 42 for the encounter-host file, 48 for the
arbiter, in every single run.

### `scripts/net/encounter_host.gd` (baseline: 16 tests, 42 assertions, 0 failed)

| Break | What was broken | Went red |
|---|---|---|
| A | `_friendly_body_struck` returns `{}` unconditionally | `..._teammates_creature_is_refused_not_zeroed`, `..._teammates_trainer_is_as_protected...` (2) |
| B | `_retro_window_applies` returns true unconditionally | `..._lying_origin_loses_the_latency_tolerance...` (1) |
| C | the strike is resolved from the INTENT's origin | `..._host_position_decides_the_hit...` (1) |
| D | the friendly test ignores distance (any participant body in the cone refuses) | `..._opponent_standing_nearer_than_the_teammate_is_an_ordinary_hit` (1) |
| E | a body with `owner_peer_id` 0 counts as friendly | **stayed green — see F7** |
| F2 | any owned body counts, participant or not | `..._creature_belonging_to_somebody_outside_the_fight...`, `..._wild_body_in_the_arc...` (2) |
| G | no retro test at all, present tick only | `..._honestly_late_peer_gets_the_latency_tolerance` (1) |
| H2 | opponent position samples are never pruned on the way in | `..._sample_older_than_the_tolerance_is_gone_rather_than_stale` (1) |
| H3b | the retro scan reads samples older than the tolerance | `..._history_that_stopped_being_written_still_cannot_be_read` (1) |
| I | any peer may strike into any fight | `..._peer_that_is_not_in_the_fight_cannot_strike_into_it` (1) |
| J | the phase never gates a strike | `..._strike_into_a_fight_that_is_resolving_is_refused` (1) |
| K | required fields read through `get()` instead of checked with `has()` | `..._intent_missing_its_move_is_malformed...` (1) |
| L | joining a live fight refills the opponent | `..._joining_a_live_fight_changes_nothing_but_who_is_in_it` (1) |
| M | one participant leaving ends the fight for everyone | `..._last_participant_leaving_ends_the_fight_with_the_hp_it_has` (1) |
| N | an unknown encounter is accepted | `..._strike_naming_no_live_encounter_is_refused` (1) |

All 16 tests in the file are covered by at least one break.

### `scripts/net/catch_arbiter.gd` (baseline: 13 tests, 48 assertions, 0 failed)

| Break | What was broken | Went red |
|---|---|---|
| O | no race check at all — every attempt resolves | 4 tests |
| P | the same peer may re-throw inside its own claim | `..._same_peer_throwing_twice_gets_no_second_roll` (1) |
| Q | `release` ignores who owns the claim | `..._releasing_the_claim_frees_the_fight...` (1) |
| R | the arbitration window never lapses | `..._claim_left_hanging_lapses_after_the_window` (1) |
| S | `claims["*"]` alongside the per-fight key | **stayed green — a badly built break, see below** |
| S2 | `owner_of` answers from any live claim, whichever fight | `..._two_fights_arbitrate_independently` (1) |
| T | a trainer's creature is catchable | `..._trainers_creature_can_never_be_caught...` (1) |
| U | the phase never refuses a throw | `..._orb_that_lands_on_a_creature_already_going_into_somebody_elses_orb` (1) |
| V | a fainted creature is still catchable | `..._orb_landing_on_a_fainted_creature_catches_nothing` (1) |
| W | required fields read through `get()` instead of `has()` | `..._missing_field_is_malformed_rather_than_a_catch_at_chance_zero` (1) |
| X | the offset is measured against the thrower's own line | `..._offset_is_measured_against_the_hosts_own_creature_position` (1) |
| Y | the orb is re-queried as basic instead of the one spent | `..._orb_the_thrower_actually_spent_is_the_orb_that_is_priced` (1) |

Break S was my error, not a test gap: I wrote both `claims["*"]` **and** `claims[encounter_id]`,
so per-fight lookups still worked. S2 is the same defect built correctly and it goes red. All
13 tests in the file are covered.

---

## 4. Findings

### F1 — a CLIENT cannot OPEN an encounter, and that is 4.B's H1, not an omission

The protocol's §4 says `engage` absent an `encounter_id` mints one. It cannot, from a client,
on this tree: Terrain3D FULL_GAME collision is unimplemented and wild creatures are not
replicated (4.B's H1), so **the host has never heard of the creature a client is standing in
front of** and there is nothing for it to mint a record about.

So: the host opens encounters and announces them; a client **joins** one. A client's own fight
against its own local wild is left exactly as it was before this lane — local, unarbitrated,
unchanged. That is the honest state of the tree and it is stated at the one function
(`_open_encounter_if_networked`) rather than only in this report. When wild replication lands
it is one more branch there. Handover H1 below.

Consequence worth stating plainly: **a joiner's opponent BODY is a stand-in.** Its own nearest
wild, drawn from the same seeded spawn table, so in practice the same creature a couple of
metres adrift — the net smoke's run log shows the host engaging a `mudsnout` and the joiner
standing beside its own local `mudsnout`. Everything that decides an outcome comes off the
record and off the host: the hit points its HUD draws, whether its swings connect, whether its
orb catches. Nothing reads the stand-in's transform to decide anything.

### F2 — the joiner's arena held its creature 40 m from the fight (net smoke attempt 1)

`combat_arena.hold_inside()` corrects a fighter with a raw position write, so a joiner whose
stand-in body was 40 m away had its creature yanked back every frame and could never stand
beside the host's opponent. Fixed in the SMOKE, not in the game: a joining player walks to the
fight, and the harness teleports there first (`teleport` step) for the reason
`smoke_aggression.gd`'s own header documents — a scripted walk across the Meadows dies against
a Terrain3D snag, and a smoke that fails there is reporting on terrain.

### F3 — a swing at a creature that is running away legitimately misses

Net smoke attempt 2 failed because the opponent chases whichever creature it is engaged with
at `chase_speed` 4.6 m/s, so it had left reach between the frame the smoke read its position
and the frame the host resolved the swing. That is `D07` working ("attacks are aimed and can
miss"), not a defect.

Phase 1 therefore gives each player a **swing budget** of 5, each swing a fresh read, a step
back into reach, and a real `strike_intent`. This is deliberately not a retry loop around a
flaky assertion: the claim under test is that a peer CAN land a blow on the shared opponent
and that both peers then read the same bar. A peer whose strikes never reached the host, were
refused, or landed only on its own copy fails it on every swing. The smoke carries this
reasoning in its own comment so the next reader does not have to take it on trust.

### F4 — `smoke_combat_camera` failed once on this branch, then passed three times

Reported as 1-fail-then-3-green rather than as "green", by rule.

| Tree | Runs | Result |
|---|---|---|
| this branch | 1 | **FAIL** — `the second production encounter would not start` |
| this branch | 3 | **PASS**, 0 failures each |
| base `61518f6b`, untouched | see below | — |

What the failure is: the smoke's second entry/exit cycle did not start a fight. What is
NOT plausible as a cause, stated as reasoning rather than assertion: every line this lane adds
to a solo path is gated on `_encounter_link != null` (null solo, because
`bind_encounter()` is only called from `_open_encounter_if_networked()`, which returns
immediately unless `_is_multi_peer()`) or on `_is_host()` (false with no session — and asked
through the session, never `multiplayer.is_server()`). `_perform_player_strike()` is the old
`_resolve_player_strike()` body with the connect test hoisted into its caller and the same
arithmetic; `floor_reach_for_bodies()` is the old three lines moved to a static that the old
call site now delegates to. The smoke's own printed `look vector` values already differ
run-to-run between base and branch at identical steps, which is timing jitter in the orbit
sample rather than anything this lane touches.

**Base flake rate: recorded in `BASE_CAMERA_RUNS.md` beside this report.** It was measured
specifically to answer "did this lane break it", before writing this verdict.

### F5 — no `smoke_net_catch_race`, and that is scope, not an oversight

The protocol's §12 names both `test_catch_arbitration` (which this lane ships, 13 tests / 48
assertions, every one seen red) and `smoke_net_catch_race`. The brief told this lane to run
**exactly one** new net smoke and named it `shared_wild_fight`. The race itself is proven
deterministically where a race is actually provable — `world_ledger.gd`'s own header makes the
same argument about `test_world_ledger_races.gd` versus its net smokes: a net smoke only ever
proves "no duplication in the order the packets happened to arrive in this run". Handover H4.

### F6 — the host's own strike landed silently, found by reading, fixed before the commit

`_submit_strike_intent()` originally only acted on a verdict that was `not ok and not pending`.
On a CLIENT that is right — the real answer arrives later on `apply_host_strike_verdict()`. On
the HOST the answer is already there, returned synchronously from its own arbitration, and it
was being dropped: the health bar still moved (the record broadcast did that), so the bug was
the subtle one — the host's own blows landing with no spark, no projectile, no `hit_landed`
and no energy gain, while a client's looked normal. Same defect on the catch path, where the
host would have won a race and never seen the wobble.

Fixed by acting on any non-`pending` verdict, and by adding a `quiet` flag to
`apply_encounter_record()` so the author's body does not flinch twice for one blow. Net smoke
re-run after the fix: **PASS on the first attempt**, 43 checks.

### F7 — a guard clause no test could turn red, so it is gone

Break E (`owner_peer_id == 0` treated as friendly) left every assertion green, because peer id
0 is never a participant and the `participants.has(owner)` check one line below had already
caught it. A line no test can turn red is a line that is not enforcing anything, so it was
removed rather than left standing as if it were protection; the reasoning is in the code at
the surviving guard. Its mirror, break H2/H3, turned out to be genuinely two guards with two
different jobs (prune at the write, cutoff at the read) — the second was only unfalsifiable
because the test did not cover the case where sampling STOPS, so a case was added
(`test_a_history_that_stopped_being_written_still_cannot_be_read`) and both are now pinned.

### F8 — where the host gets the striker's attack stat: the protocol does not say

§5 step 4 says the host rolls damage and is silent on where the host gets the STRIKER's attack
stat. It cannot come from the intent — a peer authoring half of its own damage is the same
class of thing §2 forbids for positions — and it cannot be read off the creature, because a
peer's party is its own (D100) and the host has never seen it.

The answer is 4.B's deployment announcement, extended: a peer announces what it has out
**once**, when it deploys, and a combat card (level, effective attack, effective defence,
types, move ids, hp) rides along with the species. Announced once at deploy rather than quoted
per swing is what makes it un-tunable mid-fight. This is a deviation from the brief's silence
rather than from its text, and it follows the code — `_host_set_deployed()` is already the one
door for "what this peer has out" (4.B's H4), and this is one more field through it.

---

## 5. What this lane deliberately did not do

* No change to `autoload/game_state.gd`, `autoload/world_state.gd`, `scripts/net/world_ledger.gd`,
  `scripts/net/ledger_rpc.gd`, `scripts/net/session.gd`, or any Wave 3 consumer file
  (`item_cache_pickup.gd`, `harvest_node.gd`, `vegetation.gd`, `build_placer.gd`,
  `death_satchel.gd`, `player_death.gd`, `storage_*.gd`).
* No `reward_grant` plumbing (§7). XP is still awarded by the killing peer's own
  `_award_victory()`, exactly as it was. Per-participant rewards are 4.D's — handover H2.
* No §10 scaling. `participants` changing re-derives nothing yet — handover H3.
* No second net smoke, no full sweep, no confirmation re-runs, no creature meshes, no change
  to the five-creature limit, no storage, no sixth slot.
* `catch_math.apply_failure_bound` (the opening's "cannot fail twice" beat) is not applied on
  the networked catch path. It is a solo, authored, opening-sequence policy and the opening is
  not a session; noted rather than silently skipped.

---

## 6. Handovers to lane 4.D

* **H1 — a client still cannot open an encounter.** F1. When wild replication and D96's
  Terrain3D FULL_GAME collision land, `_open_encounter_if_networked()` gains the mint branch
  and `join_encounter()`'s stand-in stops being a stand-in. Nothing else has to change: no
  outcome anywhere reads the stand-in's transform today.
* **H2 — rewards (§7) are unbuilt.** The world fact happens once and the personal reward
  happens per participant. `world_ledger.gd::reward_flag(source, peer_id)` and the
  `reward_grant` intent already exist for the replay guard; what does not exist is anything
  that emits one. `_finish_trainer_battle(won)` is still the single-peer path it was.
  `encounter_host.gd` records each participant's `joined_seq` **for 4.D to read, not to gate
  on** — §6 is explicit that arriving late costs nothing.
* **H3 — scaling (§10) is unbuilt.** `EncounterHost.join()`/`leave()` are the two places
  `participants` changes and are the natural hook. Composition first, health second, and never
  HP × players.
* **H4 — `smoke_net_catch_race`.** F5. The arbiter it would exercise is done and unit-proven;
  what is missing is a second peer throwing an orb in a net smoke, which needs a `throw` arm
  in `tools/net/peer_runner.gd` (the `strike` arm is the template — the launch parameters come
  from `throw_aim.gd::last_launch()`, which this lane added for exactly this).
* **H5 — `smoke_net_death_does_not_reset_encounter`.** §9's behaviour is implemented and
  unit-asserted (`test_the_last_participant_leaving_ends_the_fight_with_the_hp_it_has`), and
  4.E's downed/revive work is where the net assertion belongs.
* **H6 — the opponent's targeting is nearest-participant, not spread.** §5 says targeting is
  spread across participants "rather than one player tanking by standing still", and §10 says
  that is scaling. `host_pick_struck_participant()` currently picks the nearest body in the
  arc, which is the honest one-opponent behaviour and is where a spread policy plugs in.
* **H7 — the intent vocabulary a HUD needs.** `combat_manager.gd` emits two new signals,
  `encounter_refused(code, reason)` and `caught_by_other(peer_id, species_id)`, and holds
  `last_encounter_refusal`. Nothing draws either yet. §8 step 4's requirement is that a losing
  thrower's HUD says WHO got it rather than their fight silently ending; the event exists, the
  banner does not.
* **H8 — `build_placer.gd`'s `AllyCreature` name lookup** (4.B's H2) is still open. It is in
  this lane's do-not-touch list too, so the legacy alias still stands.

---

## 7. Files

| File | Change |
|---|---|
| `scripts/net/encounter_host.gd` | **new** — the record, the participants, §5's strike validation |
| `scripts/net/catch_arbiter.gd` | **new** — §8's race and roll, one atomic entry point |
| `scripts/combat/combat_manager.gd` | the encounter link, submit/render split for strikes and catches, the host's damage rolls, the client gate on the opponent's swing |
| `scripts/combat/encounter_director.gd` | the transport: one door, four RPCs, host arbitration, `join_encounter()`, the position sampler, the combat card |
| `scripts/combat/throw_aim.gd` | `last_launch()` — the launch parameters §8 needs |
| `data/config/multiplayer.json` | the `encounter` block (§11) |
| `tools/net/peer_runner.gd` | `engage_wild`, `join_encounter`, `teleport`, `place_creature`, `strike`; the `encounter` probe |
| `tests/test_encounter_host_rejects_friendly_strike.gd` | **new** — 16 tests, 42 assertions |
| `tests/test_catch_arbitration.gd` | **new** — 13 tests, 48 assertions |
| `tests/smoke_net_shared_wild_fight.gd` | **new** — the lane's net assertion |
| `.github/workflows/ci.yml` | `verify-multiplayer-shard`: floor 6 → 7, and the named registration |

## 8. The net smoke's own output, in full

Run of attempt 4 (`net-shared_wild_fight-…`), the first green one, before F6's fix; attempt 5
after it is identical minus one swing. Peer ids as the engine handed them out: the listen
server is **1**, the joiner is a large random 32-bit number, and nothing in this lane indexes
by peer id or assumes an ordering.

```
PASS: coordinator tracked 2 peers
PASS: peer 0 input_context is 'world' (got 'world')
PASS: peer 1 input_context is 'world' (got 'world')
PASS: a Session exists to host/join (lane 2.A)
PASS: peer 0 hosted a world (hosting udp/29301 as peer 1)
PASS: peer 1 joined peer 0's world on port 29301
PASS: peer 0's registry holds both players
PASS: peer 1's registry holds both players
PASS: peer 0 deployed its own creature (deployed AllyCreature)
PASS: peer 1 deployed its own creature (deployed AllyCreature)
PASS: peer 0 engaged a wild creature (engaged mudsnout as encounter 1:1)
PASS: the host minted an encounter record for that fight
PASS: and it is a wild encounter (got 'wild')
PASS: stamped with an explicit realm (D97), got 'meadows'
PASS: the record carries the opponent's hit points (112.7)
PASS: peer 1 was told the fight exists and can be joined (announced ids: ["1:1"])
PASS: the announcement says where the fight is happening
PASS: peer 1 travelled to the fight (trainer stands at (27.66, 0.38, -37.47))
PASS: peer 1 joined the fight already in progress (joined 1:1 beside a local 'mudsnout')
PASS: the host's record now holds 2 participants (got 2)
PASS: joining did not change the phase (got 'active')
PASS: and it did not refill the opponent -- no reset for the player already fighting
PASS: peer 1's fight is bound to the SAME record (got '1:1')
PASS: peer 0 landed a blow on the shared opponent within 1 swings: 112.7 -> 103.7 on the host
PASS: both peers draw the same health bar after it (host 103.750, guest 103.750)
PASS: peer 1 landed a blow on the shared opponent within 1 swings: 103.7 -> 95.3 on the host
PASS: both peers draw the same health bar after it (host 95.279, guest 95.279)
PASS: peer 0's creature stepped clear of the opponent
PASS: peer 1's creature stood next to it
PASS: peer 0's creature is alive to be swung at (120.9 hp)
PASS: both creatures report where they are standing
PASS: the two creatures are within one swing of each other
PASS: peer 1's swing at its teammate reached the host
PASS: the host refused it with `friendly_target`
      (got code 'friendly_target', reason 'You can't attack your own side.')
PASS: and gave the striker a sentence a player can be shown
PASS: peer 0's creature took nothing from it (120.888 before, 120.888 after)
PASS: and the opponent took nothing from it either (95.279 before, 95.279 after)

ALL CHECKS PASSED
```

Both halves of the friendly-fire assertion are there, and that is the point of the pair: a
silent no-op — a targeting bug that resolved onto the teammate and then rolled zero — passes
the "took nothing" line while leaving the player unable to tell "I swung at my friend" from
"the game dropped my input".
