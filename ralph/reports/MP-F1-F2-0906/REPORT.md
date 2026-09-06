# MP-F1-F2-0906 — the two carried findings, fixed in the game

Lane scope: exactly two findings, F1 and F2 of
`ralph/reports/MP-ROWS-8-21-0906/REPORT.md` §3, carried in
`docs/acceptance/MULTIPLAYER_ACCEPTANCE.md`'s "Known-open" list. Nothing else.

Base: `claude/tetherbound-roadmap-next-jrcjs8` at `7f4aa57c`. Pushed to
`claude/mp-f1-f2`. No pull request.

## The verdict, up front

Both are fixed in the game, not in the harness, and both were **seen red first
on the tree they shipped on, at the values the assertion's own message
predicted.**

| | before | after |
|---|---|---|
| **F1** — §10's multiplier reaches a creature | `smoke_encounter_scaling`: **66 assertions, 18 failures** | **66 assertions, 0 failures** |
| **F2** — a fight staged outside the Warden Arena | `smoke_arena_contain`: **21 assertions (staging case), 8 failures** | **21 assertions, 0 failures** |

The design decision F1 required is recorded as
`docs/decisions/D112-participant-scaling-keeps-an-unscaled-base-on-the-director.md`.
(Filed by this lane as D100, RENUMBERED to D112 at merge: D100 was already taken by
the world/character save split, and D106 already holds the scaling decision this one
amends. Numbers are not reused.)
It is summarised in §2 below with the alternative and why it was rejected.

One thing the F2 write-up had the wrong way round is corrected in §3, with the
measurement: `place_on_ground` is not the defect. The fight was being **staged
outside the room**, and the floor claim then answered a floor with no collider
under it. The symptom the previous lane measured is real and is what is fixed;
the cause is one layer up.

Two things found and deliberately **not** fixed are in §7.

## 1. What shipped

| File | Change |
|---|---|
| `scripts/combat/encounter_director.gd` | F1. The scaling call moves out of `_send_out_next_creature()` to two places that run after the record is live (`_start_fight()`, `_host_after_encounter_change()`); an unscaled base is kept per opponent (`_scaling_base`, `_take_scaling_base`, `_forget_scaling_base`); the row is read through a new `_session_scaling_row()` that answers the identity rather than returning, so a leave puts the creature back; the scaled cooldown is pushed to the live body (`_push_scaling_to_opponent_body`). |
| `scripts/creatures/wild_creature.gd` | F1. New `refresh_combat_profile()` — re-reads `_enemy_config_for_this_body()` into `_combat_cfg` while engaged, which is the only way a mid-fight `combat_override` change reaches a swing. |
| `scripts/combat/combat_manager.gd` | F2. `_staging_spots()` / `_staging_reach()` scale the fight's staging back as one piece when `_arena_bounds()` says the room ends before it does; `_midpoint()` and `_place_fighters()` both read it, so the arena and the two fighters cannot disagree. |
| `tests/smoke_encounter_scaling.gd` | NEW. F1's proof: 66 assertions over three rounds, three participant counts, a join, eleven re-derivations and two leaves. |
| `tests/smoke_arena_contain.gd` | F2's proof: a Warden Arena staging case, 21 assertions, added to the file whose subject is already "fights stay inside a reachable arena". |
| `tests/smoke_net_shared_boss.gd` | Tightened: the §10 stat and cooldown numbers it deliberately only PRINTED are now asserted, against the config row it reads out of the data file itself. |
| `tools/net/peer_runner.gd` | The `boss` probe reports `live.body_attack_cooldown` — the number the swing timer reads — beside the instance's own override. |
| `.github/workflows/ci.yml` | One step registering the new smoke in `verify-combat-shard`. |
|  `docs/decisions/D112-...md` | NEW. The design decision F1 required. |
| `docs/acceptance/MULTIPLAYER_ACCEPTANCE.md` | The two "Known-open" bullets this lane closed, plus row 8's evidence cell. |

## 2. F1 — the design decision, and why

### What was wrong

`_scale_opponent_for_the_session()` was called from exactly one place —
`_send_out_next_creature()`, immediately after the creature was popped off the
trainer's queue and **before** `_start_fight()` opened or resumed the encounter
record it reads its multiplier off. The first creature of a roster found no
record; every later one found a participant list §9 empties at each round
boundary, re-stamped through `scaling_for(0)` — the identity. Rule 6 / §10 /
D-MP12 reached nothing, in any trainer or boss battle.

### The decision: keep an unscaled base, on the director

Moving the call is not enough, and that is exactly why the previous lane refused
to make it. §10 re-derives its row every time `participants` changes, so the
scaler is asked about the same live creature **more than once**: on a mid-fight
join, on a leave, on the host's re-derivation after every landed strike, and
again for each creature of a roster. The old code multiplied in place; the second
call squares the multiplier.

Every write is now `base × row`, never `live × row`.

**The alternative — re-deriving from the species curve at each re-stamp — was
rejected**, for three reasons:

1. **A trainer's creature is not a pure function of species and level.**
   `trainers.json` authors `level_bonus`, `stat_bonus`, `body_scale`, a title, a
   per-member `combat` block and a shiny roll, and the world adds alpha/elder
   treatment on top. Re-deriving would silently discard every one of them the
   first time somebody joined a fight — a scaling change that quietly retunes an
   authored encounter is a worse bug than the one it fixes.
2. **It would couple §10 to the progression curve**, so a species retune would
   change what a mid-fight join does to a creature already on the field.
3. **The base is exact and free** — three floats and a dictionary, taken once,
   off the numbers the fight was authored with.

**The base lives on the director, not on `creature_instance.gd`**, because that
class is saved (`character_save.gd`, `save_game.gd`) and a multiplayer scaling
scratch field has no business in the format every solo save is written in. The
opponent of a networked fight lives and dies inside one battle, which is this
node's own lifetime.

### Two consequences that are part of the fix

- **The identity is an answer, not a return.** `_session_scaling_row()` answers
  1.0/1.0 whenever this process is not the host of a multi-peer session or holds
  no live record. That is what puts a creature back when the last other
  participant leaves: `_is_multi_peer()` goes false the moment a two-person
  session is one person again, and a scaler that merely returned there would
  leave the boss carrying a multiplier for a fight nobody else is in. *This was
  found by the test, not by reading* — the first version of the fix returned, and
  the smoke's final leave went red with the creature still at ×1.1.
- **The cooldown has to be pushed to the body.**
  `wild_creature.gd::set_engaged()` snapshots `_enemy_config_for_this_body()`
  into `_combat_cfg` when the fight opens, which is **before** the record exists,
  so a `combat_override` written afterwards would sit on the instance and never
  reach a swing. `refresh_combat_profile()` re-reads it. Only the config: the
  swing already in flight (`_cooldown`, `_beat_left`, `_intent`) is left alone,
  so a shorter cooldown takes effect from the next swing rather than cutting
  short a telegraph the player is reading.

**HP is never multiplied by players.** The function does not read or write `hp`
or `max_hp`, `multiplayer.json` still carries no key a future edit could use as
one, and the rule is now asserted at every row *including the identity*, on every
creature, in both smokes.

### Scope, stated

Lane 4.D scoped this to **trainer-owned opponents** (its own header says so) and
this lane did not widen it. A shared WILD fight still scales nothing. That is
recorded as open in §7 rather than answered here.

## 3. F2 — the finding was right about the symptom and wrong about the cause

The write-up said `place_on_ground` "asks the world for a height … inside the
stronghold that height is the *terrain* under the building, not the arena floor".
Measured, that is not what happens. `place_on_ground` inside the Warden Arena
answers **6.172, the arena's own floor**, correctly, through
`built_floor.gd::resolve()`:

```
warden_arena centre = (8.00, 6.172, 7650.20)
stronghold.built_floor_height_at = 6.172      world.ground_height_at (terrain) = -0.874
place_on_ground(10.00, 7652.20) ok=true -> y=6.172;  after 60 frames of settle: y=6.172
```

The defect is one layer up: **the fight is staged outside the room.**
`_place_fighters()` forms the whole fight `deploy_offset + separation` (~7.6 m)
in front of wherever the player engaged, and the Warden stands 5 m from his
arena's back wall. A z sweep out of that wall at x 16.85:

```
       z      claim    terrain    arena_r  ray from y=20
  7663.0      6.172     -1.568       0.50  collider '@StaticBody3D@65433' top y=18.172
  7664.0      6.172     -1.605      -1.00  collider '@StaticBody3D@65464' top y=18.572
  7666.0      6.172     -1.664      -1.00  NO COLLIDER within 60 m below y=20.0
  7668.0      6.172     -1.767      -1.00  NO COLLIDER within 60 m below y=20.0
```

The floor CLAIM runs 10 m past the room (deliberately —
`stronghold.gd::FLOOR_CLAIM_MARGIN_M`, so a fight that has drifted past a wall is
not told its floor is the meadow far below), but there is no collider out there
at all. So `place_on_ground` seats a body at 6.172 and
`creature_body._physics_process()` — which grounds on `is_on_floor()`, not on
anybody's claim — drops it ~8 m. Staging the Warden fight the way
`peer_runner.gd::_step_trainer_battle()` does, on the unfixed tree:

```
--- at open ---
  player    (10.49, 6.173, 7661.31)  arena_r  0.89  INSIDE the room
  ally      (11.84, 6.172, 7662.04)  arena_r  0.50  INSIDE the room
  opponent  (13.85, -1.241, 7665.02) arena_r -1.00  OUTSIDE the room
--- after 120 frames ---
  player    ( 8.49, -0.363, 7667.24) arena_r -1.00  OUTSIDE the room
  ally      (11.62, 6.173, 7661.71)  arena_r  0.50  INSIDE the room
  opponent  (13.25, -1.124, 7665.10) arena_r -1.00  OUTSIDE the room
```

The **player** goes through the wall too — `_stand_the_trainer_aside()` puts them
6.5 m under the floor their own creature is standing on. That is worse than the
finding described and it is the same cause.

### The fix, and why there

The stronghold's own comment names the owner outright: *"This function only
answers 'whose floor is this' … containing that drift is `combat_manager.gd`'s
own arena-bounds job and stays there."* So the claim margin is **not** narrowed
and `place_on_ground` is **not** changed. `combat_manager.gd` now scales its
staging back as one piece when `_arena_bounds()` — already the "is this spot
inside a room, and how much room is there" query, and already answering −1.0 for
every square metre of open meadow — says the room ends before the staging does.
Both fighters keep their order, their facing and their separation ratio.

**A fight started outdoors, or in a passage between two chambers, walks none of
it**: `_arena_bounds(from)` is −1.0 there and `_staging_reach()` returns the
caller's number on its first line.

With the fix, the same probe:

```
  player    (10.49, 6.173, 7661.31)  arena_r 0.89  INSIDE the room
  ally      (11.85, 6.172, 7661.65)  arena_r 0.55  INSIDE the room
  opponent  (12.41, 6.173, 7662.33)  arena_r 0.50  INSIDE the room
```

The harness's `exact: true` placement argument is **untouched and still works** —
other smokes now use it, and a caller whose Y is host truth off the encounter
record still wants the literal coordinates.

## 4. Every assertion was seen red first, for the right reason

The assertion COUNT is reported on every line. A break that made a run assert
FEWER times would be a function aborting, not a test failing.

### F1 — `tests/smoke_encounter_scaling.gd`

| revision | assertions | failures | what the failures said |
|---|---|---|---|
| **base tree** (`encounter_director.gd` + `wild_creature.gd` reverted) | 66 | **18** | every scaled read at exactly its authored number: `attack is the authored 40.250 x 1.1000 = 44.275 … (got 40.250)`, `the BODY swings on the authored 0.700 x 0.8500 = 0.595 … (got 0.700)`, on the join, on the 11 re-derivations, on the third-peer arm, and on creatures 2 and 3 |
| **BREAK C** — scale the LIVE value instead of the base | 66 | **6** | the compounding, at the values compounding produces: `authored 40.250 x 1.1500 = 46.287 … (got 50.916)` — which is 44.275 × 1.15 — then `(got 56.008)` = 50.916 × 1.1 on the way back down, and the final restore off by exactly one multiplier |
| **BREAK D** — `refresh_combat_profile()` made a no-op | 66 | **6** | every BODY cooldown read, and only those: `the BODY swings on the authored 0.700 x 0.8500 = 0.595 … (got 0.700)`. Attack and defence stayed green, which is the point — they reach the fight through the instance and the cooldown does not |
| **shipped** | 66 | **0** | — |

An earlier revision of the smoke ran 51 assertions and BREAK C produced only 2
failures, both at the final restore. That is honest and it is why the test grew:
with only one non-identity row in play, `_scaling_applied`'s unchanged-row guard
short-circuits the eleven re-derivations, so "authored × row" and "the previous
answer × row" are the same number on a creature that is only ever scaled once.
The **third-peer arm** (the row MOVES from 1.1 to 1.15 on the same creature, and
back) is what makes the compounding claim provable, and the file asserts up front
that the two rows are different numbers.

### F2 — `tests/smoke_arena_contain.gd`

| revision | staging assertions | failures | what the failures said |
|---|---|---|---|
| **base tree** (`combat_manager.gd` reverted) | 21 | **8** | `the player is 6.535 m off the Warden Arena's floor as the fight opened (body y -0.363, floor y 6.172)`; `the Warden's creature is 7.413 m off … (body y -1.241)`; each paired with an OUTSIDE-the-room failure, at both sample points |
| **shipped** | 21 | **0** | — |

The case asserts its own precondition before measuring anything: *"the full
7.60 m staging span reaches (15.51, …, 7664.33), which the room does NOT claim
(radius -1.00)"*. Without it, a room that happened to be large enough would pass
the floor checks while proving nothing about containment, and the failure names
`combat.json`'s own numbers so a future retune reads as a retune.

## 5. Commands, and every attempt

Godot 4.7-stable installed at `~/godot-bin/godot`; `--headless --path . --import`
run twice before anything below.

```
~/godot-bin/godot --headless --path . --script tests/smoke_encounter_scaling.gd
~/godot-bin/godot --headless --path . --script tests/smoke_arena_contain.gd
~/godot-bin/godot --headless --path . --script tests/run_tests.gd -- --only=test_encounter_rewards.gd
~/godot-bin/godot --headless --path . --script tests/smoke_combat.gd
~/godot-bin/godot --headless --path . --script tests/smoke_trainer_battle.gd
~/godot-bin/godot --headless --path . --script tests/smoke_boss.gd
~/godot-bin/godot --headless --path . --script tests/smoke_tournament_bracket.gd
~/godot-bin/godot --headless --path . --script tests/smoke_gate_e_finale.gd
~/godot-bin/godot --headless --path . --script tests/smoke_playground.gd
tools/net/run_net_smoke.sh shared_boss --out=/tmp/net-f1f2
```

### The required suite, all on the shipped tree, all FIRST attempt

| run | result |
|---|---|
| `smoke_encounter_scaling` (new) | **66 assertions, 0 failures** — `OK -- §10's multiplier reaches the creature, exactly once, at every row.` 74 s |
| `smoke_arena_contain` | **21 staging assertions, 0 failures**, plus its two existing OP21-25 cases — `OK -- Warrens and Stronghold fights FORM inside a reachable, legal room and hold participants inside it.` ~110 s |
| `test_encounter_rewards` | **29 tests, 97 assertions, 0 failed** |
| `smoke_combat` | `OK — a fight can be entered, piloted, won and left.` |
| `smoke_trainer_battle` | `OK — a trainer can be challenged, fought through their team, beaten once, and not again.` |
| `smoke_boss` | `boss smoke test passed` |
| `smoke_tournament_bracket` | `OK — the tournament can be entered, lost, retried, fought through all three rounds and won, once.` |
| `smoke_gate_e_finale` | `gate E finale smoke test passed` |
| `smoke_playground` | `smoke: OK` |
| `smoke_net_shared_boss` | **85 PASS, 0 FAIL, `ALL CHECKS PASSED`** — 81 before this lane, plus the four assertions that replace the printed numbers. Two real processes over ENet. |

The four new net assertions, on the exact creature finding F1 measured as
unscaled:

```
live:     { "attack": 56.98, "attack_cooldown": 0.765, "body_attack_cooldown": 0.765,
            "defence": 30.525, "hp": 212.1, "max_hp": 212.1, "species_id": "galecrest" }
authored: { "attack": 51.8,  "attack_cooldown": 0.9,   "defence": 27.75, "max_hp": 212.1 }

PASS: §10: at 2 participants his creature's attack is the authored 51.800 x 1.1000 = 56.980 (live 56.980)
PASS: and its defence is the authored 27.750 x 1.1000 = 30.525 (live 30.525)
PASS: his second creature authors a real attack_cooldown (0.900) -- without one this comparison
      is 0.0 against 0.0 and proves nothing (finding F3)
PASS: and the BODY swings on the authored 0.900 x 0.8500 = 0.765 (live 0.765) -- read off its own
      combat config, which is the number the swing timer uses
```

F1's own measurement was "galecrest 51.800 / 27.750, exactly its authored number,
while the record beside it said 1.1". It now reads 56.980 / 30.525 / 0.765, and
`max_hp` is still 212.1.

`smoke_net_shared_wild_fight` was **not** run as a regression: it is measured
flaky on both sides (5 of 7 against 6 of 7 on an untouched base), so a single run
of it is neither evidence nor a finding. Nothing in this lane touches the wild
path — `_scale_opponent_for_the_session()` is called only for `opponent_owned`
fights (see N1), and `combat_manager.gd`'s staging change is inert outside a
building.

Every red run above is a deliberate break or a deliberate reversion, listed in
§4. **No test in this lane was retried into green**: there is no run where a
first attempt failed and a second passed.

## 6. Parse and subclass checks

`--check-only` over every changed script, and over every subclass of a changed
script, because a lane last week broke a test file whose subclass carried an old
override and lost all 18 of its tests silently:

```
grep -rn 'extends "res://scripts/combat/combat_manager.gd"'      -> scripts/combat/cloudreach_combat_manager.gd
grep -rn 'extends "res://scripts/combat/encounter_director.gd"'  -> scripts/combat/cloudreach_encounter_director.gd
                                                                    tests/smoke_meadows_realm_handoff.gd (inline class)
grep -rn 'extends "res://scripts/creatures/wild_creature.gd"'    -> scripts/combat/cloudreach_encounter_director.gd (inner class)
grep -rn 'extends "res://scripts/creatures/creature_body.gd"'    -> wild_creature.gd, follower_creature.gd, remote_creature.gd
```

All parse clean. **No public signature changed** in this lane — every production
edit is either a new function or a change to a function body.
`cloudreach_encounter_director.gd` overrides `_start_fight()` and calls
`super._start_fight()`, so it inherits the fix; `cloudreach_combat_manager.gd`
overrides none of `_midpoint` / `_place_fighters` / `_arena_bounds`.

`ci.yml`: one step added. Every `run:` block extracted and `bash -n`'d — 67
blocks, 0 syntax failures — and the file re-parsed as YAML. The net-smoke count
floor was not touched: this lane adds no `smoke_net_*` file.

## 7. Found, and deliberately NOT fixed

Recorded here rather than widened into, per the lane's scope.

### N1 — §10 scales a trainer's creature and nothing else. A shared WILD fight scales nothing.

`_scale_opponent_for_the_session()` is called only for `opponent_owned` fights,
which is the scope lane 4.D shipped and its header states. §10's own words are
about "an encounter", and `encounter_host.gd::scaling_for()` is not
trainer-specific — so two players ganging up on a wild creature fight it at its
authored numbers today. Whether that should change is a design question (a wild
creature is also catchable, and a scaled one is a harder catch at the same
`hp_fraction`), and answering it is not this lane's to make.

### N2 — WRONG, corrected at merge. `smoke_arena_contain` IS registered in CI.

> **Correction (merge review, 2026-09-06).** This finding is factually wrong and
> its recommended follow-up must not be actioned. `smoke_arena_contain` is
> registered in `verify-owner-regressions-shard` at `ci.yml:1476` as
> `env: { SMOKE: arena_contain, RETRIES: 1 }`, and it ran and passed in CI run
> 4471 ("Verify arena_contain", 13:34:48–13:35:57). The F2 regression DOES gate.
>
> The mistake is instructive: that shard passes the BARE smoke name through a
> `SMOKE` env var, so `grep smoke_arena_contain ci.yml` returns nothing while
> `grep arena_contain ci.yml` finds it. Acting on the recommendation would have
> registered the smoke a second time and run it twice per CI run for no reason.
>
> The original text follows, kept because the reasoning about scheduling cost is
> still sound if anyone ever does move it into a different shard.

### N2 (original, superseded) — `tests/smoke_arena_contain.gd` was not registered in CI at all.

It is named in no `ci.yml` step, so the OP21-25 containment proof — and, until
this lane's edit, nothing else — gated nothing. This lane registered its own new
smoke (`smoke_encounter_scaling`, measured at 74 s, in `verify-combat-shard`) but
did **not** register `smoke_arena_contain`: its three cases run ~110 s and adding
a previously-ungated file to a shard is a scheduling decision with its own
history in that file's timeout comments. The F2 regression therefore exists and
passes but does not yet gate. Recommended as a one-step follow-up.

### N3 — the previous lane's report is not in the tree at `7f4aa57c`.

`ralph/reports/MP-ROWS-8-21-0906/REPORT.md` was added by `08d4c4ed` and is
present at `origin/claude/tetherbound-roadmap-next-jrcjs8`. A stale local branch
ref pointing at an older commit is what briefly hid it; noted only because a
later lane reading `git branch` rather than `git ls-remote` can lose an hour to
the same thing.
