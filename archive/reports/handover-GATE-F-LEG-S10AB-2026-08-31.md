# GATE-F-LEG-S10AB — S10a and S10b, driven in isolation from a hand-built entry

**Lane:** `ralph/GATE-F-LEG-S10AB`, branched from `main` and merged with
`ralph/GATE-F-FOUNDATION` once that branch appeared. **Date:** 2026-08-31.
**Run directory:** `ralph/reports/gate-f-run-S10AB-2026-08-31/`.

## The honesty rule, stated once and up front

**This is conditional, isolated evidence.** S10a and S10b were driven on their
own, from an entry save this lane HAND-AUTHORED rather than earned
(`tools/gate_f/seed_s09_exit.gd`, whose header states every assumption and its
source). Nothing here is evidence about the chapter. Every finding below is of
the form *"S10a/S10b, given a clean entry, does X"* — never *"the chapter does
X"*. Whether a real player arrives at the Hall threshold in the state this seed
describes is S01–S09's question and this lane did not ask it.

The seed had to be constructed because no completed Gate F run has ever produced
a real `S09-exit`. The only one in the repo,
`ralph/reports/gate-f-run-20260828T183531Z/S09/saves/S09-exit.json`, holds ONE
fainted level-4 creature, eight opening flags, and a player standing at z=1318 —
6.2 km short of the Hall.

Visual evidence is **absent, not negative**: both segments declare
`evidence_lane: logic` and delegate every prescribed frame to S10aC/S10bC, which
this lane did not run. A parallel lane (AUDIT-E) is doing a blind visual judge
pass on this same location and duplicating it here would have spent hours of
software rasterisation answering somebody else's question.

## Result

Both segments now run clean end to end, **zero FAIL verdicts in either**.

| segment | steps | verdict | handoff |
|---|---|---|---|
| S10a — Hall entry → gauntlet → recovery → elite | 62 | 0 FAIL | `S10a/saves/S10a-exit.json` |
| S10b — Warden → legendary → release ceremony | 66 | 0 FAIL | `S10b/saves/S10b-exit.json` |

Both runs above were taken on this branch's head **after** the merge with
`ralph/GATE-F-FOUNDATION`, so the evidence comes from the code that ships.

The handoff between them is a real save/load through the production Save tab and
the title-screen Load path, as §B requires — not an in-memory continuation. S10b
seeds from S10a's own written slot and boots fresh.

**Given a fair start, both fights complete cleanly.** The gauntlet:

- patrol (Trailpup L15, Burrowback L16) — 48 quick attacks, no handover needed;
- courtyard (Mosshell L16, Reedwing L17, Mudsnout L17) — 67 quick, 1 handover;
- elite (Galecrest L18, Burrowback L19, Duskhush L19) — 65 quick, 1 handover.

The Warden — five creatures, Burrowback L16 through a Tuskroot L20 ace — took
110 quick attacks and 2 handovers, and `defeated_warden` was set. Then the
machine was shut down, the legendary freed, the roster ceremony taken on a full
belt, and the tether machinery failed: §28's order, complete, in order.

The belt ended at **exactly five** — Dusk released, the Veridian Stag (L22) in
the freed holder — with all nine finale flags set.

## The seed

`tools/gate_f/seed_s09_exit.gd`, run against the booted world so it takes the
Hall's own `entrance` marker rather than a literal. Contents:

- **party of five, L20/19/19/19/19**, full HP, nobody fainted, satiety full.
  Grounded in `progression.json`'s `_comment_award_sh47`: the curve's own design
  target is that "the main line alone arrives level with the boss", where the
  boss is the Warden's **level-20** ace. The lead sits level with that ace, not
  above it; an over-levelled seed would have hidden the balance defects this
  lane was for. Species: Terrapup (ground), Ripplet (water), Galecrest (air),
  Tuskroot (ground), Duskhush (air).
- **32 flags** — every main-chain flag from the opening through
  `hall_approach_open` (the three-Sigil gate) plus S09's own outer-watch and
  checkpoint fights. Deliberately NOT the three `defeated_stronghold_*` flags:
  those are S10a's own work. The game's own quest log reads the tracked
  objective back as "Fight through the guard inside Meadows Hall. 0/3", which is
  exactly what S10a-11 asserts.
- **satchel**: 8 large potions, 12 small, 4 revives, 10 berries, 5 greater and 8
  basic orbs, the three Sigils, and the village tools. Never opened during
  either run — every fight below was won on levels, types and the belt alone.
- **position**: the Hall threshold, from the live `entrance` marker.
- day 6.

One correction to the brief: the lane was told the stronghold gauntlet "runs up
to level 22". The data says the highest enemy in the building is the Warden's
**L20** Tuskroot; 22 is the freed legendary's own level
(`stronghold_climax.json`), not an enemy's.

## What was fixed

### 1. The load path never restored a creature's species base stats — SHIP

The one defect the finale could not be played around, and it is not confined to
the finale. **This lane found and fixed it independently; the coordinator's
`ralph/GATE-F-FOUNDATION` landed a fix for the same bug (GAME-F4) while this
lane was running, and GAME-F4's mechanism is the one that ships.** This
branch's duplicate was removed in the merge. What follows is the measurement,
which is this lane's own contribution to it.

`creature_instance.gd::_apply_level_stats()` recomputes max_hp, attack and
defence from `base_hp`/`base_attack`/`base_defence`, deliberately — its own
comment explains why it must never scale `max_hp` from `max_hp`.
`save_game.gd` **never wrote those three fields to a slot and never read them
back**. A creature rebuilt by `_array_to_party()` therefore carried the class
defaults of 1.0, while its `max_hp` came back from the file looking perfectly
healthy.

Nothing showed until the creature LEVELLED. Measured in the Hall on the frame
the elite's first creature fell and the victory XP landed:

```
Ripple  L19 218.4/218.4  ->  L20   2.14/2.14
Tup     L20 155.7/256.8  ->  L21   1.33/2.20
Gale    L19  68.4/218.4  ->  L20   0.67/2.14
```

Three party members, one tick, each then a single hit from fainting. Since
`encounter_director.gd::_on_trainer_round_ended()` ends the whole battle the
moment the PILOTED creature falls, the chapter's climax became unwinnable — and
only ever in a session that had loaded a save, which is every session after the
first. The same fingerprint is sitting unrecognised in the 2026-08-28 run's own
`S09-exit.json`: a level-4 creature with `max_hp` 1.18.

GAME-F4 writes the three fields going forward and falls back to `species.json`
for any save that lacks them. One regression test from this lane is kept beside
GAME-F4's own: that one proves the fields make the round trip, this one drives
the production `gain_xp` path the fights actually call, from a loaded creature.

### 2. The Hall's front door had a 0.34 m riser in it — SHIP

`stronghold.gd::_build_approach_ramp()` built the causeway to reach floor height
at `_mouth_outer_z()` — which is the mouth wall's INNER face, one wall thickness
too far in. The interior floor slab begins at the OUTER face, so it stood proud
of the ramp for that whole 1.2 m: measured on the built world, ramp surface
y=5.83 against a floor slab edge at y=6.17. This function's own header explains
what that costs ("Godot's character body does no stair-stepping of its own",
which is why the apron is an incline and not steps).

S10a's first walk spent its entire 9,000-frame budget oscillating between x=6.07
and x=9.92 at z≈7546.4 — inside the doorway's own 4 m gap, at the right height
for the ramp, scrabbling at the lip — and failed 13.7 m short. The player got in
about two seconds later on the next step's walk, by the capsule rolling over the
riser, which is the tell that it was marginal rather than sealed. Marginal is
worse: the chapter's climax had a front door that took roughly a minute and a
half of luck to enter.

The slab's 3 m overlap also ran UPHILL past the top, laying a 0.38 m ridge
across the inside of the doorway that the player has to climb on the way back
OUT. It now runs downhill into the meadow, where burying a slab end belongs.

**Why nothing caught it:** `smoke_gate_e_finale.gd` walks in from the entrance
and failed only past 14 m from the Outer Works' centre. The measured stuck
position is 13.6 m from that point. The tolerance was 0.4 m wider than the
failure, and the baseline run of that test on `origin/main` prints
`walked in from the entrance; 13.6m from the Outer Works' centre` — passing,
with the player pinned outside the door. The bar is now 6 m, and the walker's
frame budget was raised so the budget is no longer what decides the result
(700 frames at 4 m/s is 46.7 m against a 53.2 m causeway). After the fix the
same test walks to **3.8 m**.

### 3. The tether machine's control could never be reached — SHIP

`stronghold.json`'s `machine_foot` mark sat at the Legendary Chamber's centre,
which is the machine's own AXIS. `stronghold_climax.gd::_place_machine_prompt()`
hangs the "Shut down the tether machine" interactable on that mark;
`stronghold_climax.json`'s `site.prompt_radius` is **4.2 m**; and
`stronghold.json`'s own `machine.base_radius` is **5.6 m**.

5.6 > 4.2. The prompt sat at the centre of a solid cylinder the player can never
come within 5.6 m of, so the interaction could not be offered from anywhere in
the room, by construction. Measured in S10b: the walk stopped 7.2 m short
against the machine's face, `legendary_freed` was never set, and objective 25/27
— freeing the legendary, the chapter's second-to-last beat — was unreachable.

**Fixed** by moving the mark to +7.0 in local x: 1.4 m clear of the base
cylinder, on the side the player walks in from, which is where a control at the
FOOT of a machine belongs and what the mark is named for.

**Why nothing caught it:** the one test that covers the beat,
`smoke_gate_e_finale.gd::_pull_the_lever`, checked the prompt's `enabled` flag
and then called `interaction_activate()` on it **directly** — a call no player
can make, because it skips the distance entirely. That test now asks the prompt
for a real offer from where the player is standing, and prints the distance:
`machine control offered at 4.0 m: 'Shut down the tether machine'`.

### 4. The elite's fight formed under the building — SHIP

`tether_approach` is the narrowest room on the route (16 m against the outer
works' 20 and the courtyard's 22), and the elite's offset put him at world
x=12.5 — 3.5 m from its east wall, facing straight into it. `combat.json`'s
`arena.separation` is 5.0, so a fight staged on his own front had nowhere to put
the second body and pushed it through the wall: measured, both combatants formed
at world (18.4, 0.68), outside the building and 5.5 m BELOW the floor they were
standing on.

**Fixed** in data: offset x 4.5 → 2.0 (six metres off either wall) and
`facing_deg` 90 → 180, turning him down the room's own 18 m depth to face the
passage the player walks in through — which is what the Warden's own facing
already does in his arena. He keeps his z, so he still stands in front of the
Tether blast shutter, and stays 7 m clear of the recovery bed's prompt. The
other two gauntlet trainers keep `facing_deg` 90; their rooms are wide enough
that it costs nothing there.

### 5. The in-fight switch could pull a sleeping creature out of its bed — QUALITY

`combat_manager.gd`'s switch paths checked only `fainted`, while `begin()`
refuses to start a fight on a RESTING creature and `party.gd::cycle_active()` —
whose own comment is "skips anything that cannot take the field" — skips both.
Only the in-fight switch disagreed.

That disagreement is reachable in exactly one place in the chapter, and it is
inside this lane's own segment: the Hall's recovery point is the only creature
bed standing within metres of a fight. Park a creature in it, walk nine metres
to the elite, and LB would pull the sleeping creature straight into the boss
gauntlet — still flagged `resting`, so `_tick_creature_bed_recovery()` keeps
healing it every frame WHILE it fights, and the bed still lists it as its
occupant. Fixed with one shared predicate, `_can_take_the_field()`, used by
`switchable_indices()`, `cycle_active()` (which now steps OVER a resting
member rather than stopping on it) and `request_switch()`.

## What was fixed in the segments' own step-scripts

These are defects in S10a/S10b as instruments. Each would have produced a
confident PASS over a beat that never happened.

**Every finale walk was aimed at the wrong place.** The `at` coordinates were
transcribed from `band5_stronghold_approach/trainers.json`'s `position` rows —
which that file labels, in its own `_position_note`, *"FALLBACK ONLY … 
`stronghold.gd` places this row from `stronghold.json`'s `gauntlet` block"* —
and those fallbacks are still written in the pre-OW5D frame where the Hall's
chambers ran along +x. Measured against the booted world by
`tools/gate_f/probe_hall_geometry.gd` (committed): the courtyard walk was 45 m
out, the elite walk 92 m, the Warden walk 120 m. The ambiguity S10b's own header
recorded rather than resolved — CB-06 and trainers.json both saying
(90.2, 7569.4) while stronghold.json implies (8, 7658.2), "the same pair
transposed" — is resolved by that measurement, in favour of the building.

**The recovery beat had no walk to the bed and no close afterwards.** S10a-37's
note said "the steps below use it" and the step below it was a bare
`press interact`, 32 m from the bed. Added the walk; added the `menu_cancel` that
closes the panel (which pauses the tree and owns input until dismissed — its
absence is what made S10a-30w fail and S10a-42's walk burn its whole budget
without the player moving). The bed is now spent on the creature that actually
needs it rather than on whichever row focus defaults to, which is a gameplay
choice and is commented as one.

**The fights were driven by counted presses.** Replaced with
`fight_until_resolved`, a new predicate-driven step documented in
`SEGMENT_SCHEMA.md`. The schema already makes this exact argument twice — 
`advance_dialogue_until_closed` exists because "press confirm N times" is right
for one conversation, `focus_item` because "press right N times" is right for
one arrangement of the bag — and a fight is the same class of problem and a
worse one: its length is a function of both levels, the type chart and a ±10%
roll per hit. Measured across three runs, the counted form came apart three
different ways: a water pilot against a water defender spent every press
budgeted for a trainer's THREE creatures on the first one (46.8 s for 247 HP);
the switch presses then landed mid-round and were swallowed by the commitment
guard; and each fight was finally lost to a single faint with three untouched
creatures on the belt. Every one of those steps reported PASS, because a press
step only asserts that input was injected — the same defect shape RIG-26 found
on engage steps.

The action presses only the quick attack and LB, only while the action machine
reads READY, and never opens the satchel. It stops when `is_fighting()` AND
`trainer_battle_active()` have both been quiet — both, because a trainer battle
goes quiet BETWEEN its creatures and a driver that stopped on the first gap
would abandon a five-creature Warden after his first one fell.

**The release ceremony's step sequence never released anything.** Read off the
shipped UI: the ceremony opens ITSELF (`_watch_pending_catch`), there is no
prompt to press; focus lands on the newcomer's row, which `_fence_choose_focus`
fences so left/right are no-ops; `_begin_farewell` focuses "Keep them", wired to
`_back_to_choosing`. The shipped steps pressed `interact` (nothing answers it),
moved focus `right` (fenced to nothing), accepted on the still-focused newcomer
row (asking "let the legendary go?" rather than choosing any of the five), and
then pressed the focused button, which is "Keep them". Driven faithfully it
walks in a circle: nothing is released, `pending_catch` is never cleared, and
`legendary_settled` is never set. The sequence now steps onto the belt, walks
the five past the detail column, asks the question of one of them, takes the one
deliberate press down from the safe answer, releases, and closes the shell — 
and the tree has to be un-paused before the two flags can be asserted, because
`stronghold_climax.gd::_advance()` runs in `_process`.

**S10b-87's comparator had been inverted.** The step's own `expected` says a
sixth creature "would be the single hardest rule in the project broken", and it
was checking `min: 5`, which passes a party of six without comment. RIG-15 moved
every `party_size` check from `equals` to `min` because catching is
probabilistic — sound reasoning that does not reach this assert, where nothing
probabilistic happens and both endings leave exactly five. Restored to
`equals: 5`, which RIG-15's own note reserves for "a caller that genuinely wants
exact equality".

**The two interior doorways were walked past rather than lined up with.**
`stronghold.json`'s passages give the tether_approach → warden_arena door a
width of **3.4 m** — the narrowest opening in the building, and it is the one
into the boss arena — centred on world x 8, while the elite fight can leave the
player anywhere in a 16 m-wide room. Measured across two runs from two different
S10a exits: from x=5.0 the walk to the Warden went straight through; from x=4.5
it did not, and the player spent all 3,000 frames sliding along the inside of
the north wall between x=0.4 and x=3.3, twenty-six metres short, taking the
whole segment down with it. The protocol's walker steers straight at its target
and does not route around interior geometry, so a doorway narrower than the
room's own spread has to be lined up with. Both interior passages now get a
waypoint on their own centreline first — which is what a player does on sight of
a door, and it makes the segment deliberate instead of dependent on where the
last fight happened to end. Recorded as an observation as well: a 3.4 m door is
the tightest thing between the player and the Warden.

**The segment walked into its own save handoff with a conversation open.** §28's
last beat — the tether machinery failing — starts the moment the roster settles,
and nothing played it out, so `open_menu` reported "map did not open the pause
shell: context narrative_modal -> narrative_modal" and `save_out` correctly
refused to copy a slot still byte-identical to what `seed_save` had written.
Added an `advance_dialogue_until_closed`; the beat now runs and closes.

## The freeze record, and a trap worth a coordinator's attention

This run directory carries its own `RUN_METADATA.json` with a `lanes` block. It
has to: the harness's capture pre-flight reads a freeze record's display-server
claim and BLOCKs a process that contradicts it, and with no record in the run
directory it falls through to `ralph/reports/gate-f-candidate/RUN_METADATA.json`
— the **2026-08-27** freeze, for a different candidate SHA and a different run
directory, carrying a flat `"display_server": "X11 under xvfb-run"` and no
`lanes` block. Per the harness's own rule a flat claim binds every segment, so
that stale record refused this lane's headless logic run before step 1. The
documented remedy is exactly what was done. Recorded rather than worked around:
**a stale candidate freeze silently binding an unrelated later run** is worth
fixing at the coordinator level.

## Observations, not fixed

- **GAME-F4 does not repair a save that the bug already corrupted.** It restores
  the BASE stats and leaves the derived ones as the file has them, so a save
  written by a build carrying the bug — the 2026-08-28 run's own `S09-exit.json`
  holds a level-4 creature with `max_hp` 1.18 — comes back at its collapsed
  maximum and stays there until the next level-up recomputes it, which at 2 HP
  it may never reach. This lane's own version recomputed the derived stats on
  load, which repairs those saves and is a no-op for healthy ones; it was
  dropped in favour of one mechanism rather than two. Whether that residual is
  worth closing is the foundation lane's call, and it is stated here so the
  choice is a choice.
- **The legendary is enormous relative to the team it joins.** Veridian's
  authored `base_hp` is 420 against a roster of 96–130, so the freed Stag lands
  on the belt at L22 with **949 max HP** beside party members at 231–286. That
  is a deliberate authoring choice, not a defect, and it is out of this lane's
  scope to change — but it is the state the S10c–S10e walk-back inherits, and
  whoever owns that lane should know the reward arrives roughly four times
  stronger than anything that earned it.
- **Damage does not scale with level; only HP does.** `combat_math.gd`'s
  `power * scale * attack / (attack + defence)` is a ratio, so a quick hit lands
  for about `player_quick.power` (9.0) against a comparable defender at any
  level, while max HP climbs. Measured: a L20 Terrapup hit a L15 Trailpup for
  8.9–10.7 a time against 193 HP. Fights therefore get LONGER as the chapter
  goes on — 20–28 quick hits per enemy in the Hall. That is a property of the
  shipped design rather than a defect, and it is what makes the belt, not the
  pilot, the thing that wins the gauntlet.
- **A player who never stops attacking cannot change creature.**
  `can_switch()` refuses while `player_is_committed()`, and
  `combat_hud.gd::_handle_switch_input()` answers "locked in — a moment" rather
  than queueing the press. Correct as designed, and worth knowing: measured with
  presses 0.5 s apart against a ~0.4 s action cycle, both of a fight's switch
  presses were swallowed.
- **`test_save_format.gd::test_the_board_reads_the_same_bracket_after_a_reload`
  swallows a script error.** It calls `save_game` on a `save_game.gd` RefCounted,
  which has no such method (it is `save`), prints
  `Invalid call. Nonexistent function 'save_game'` and still reports `ok`.
  Pre-existing, unrelated to this lane, and not touched.

## Artefacts

```
ralph/reports/gate-f-run-S10AB-2026-08-31/
  RUN_METADATA.json           this lane's own freeze record, with its `lanes` block
  saves/S09-exit.json         the HAND-AUTHORED entry state
  S10a/                       0 FAIL; saves/S10a-exit.json
  S10b/                       0 FAIL; saves/S10b-exit.json
  S10a-superseded-1..7/       every earlier attempt, kept
  S10b-superseded-1..2/
```

New tools, all committed with their reasoning:
`tools/gate_f/seed_s09_exit.gd`, `tools/gate_f/probe_hall_geometry.gd`,
`tools/gate_f/probe_hall_threshold.gd`.

## Verification

- Godot 4.7-stable (`4.7.stable.official.5b4e0cb0f`), CI's pin. Two import
  passes before any run.
- Unit suite on the shipped head: **1606 tests, 290,740 assertions, 0 failed**
  (`--skip=test_veg_corridor.gd,test_scatter_rules.gd,test_harvest.gd`, CI's own
  split).
- `smoke_gate_e_finale.gd` green, with the tightened walk-in bar and the new
  reachability check on the machine control. A baseline run of the same test on
  `origin/main` is what established that the walk-in check had been passing a
  player stuck outside the door.
- `smoke_stronghold`, `smoke_boss`, `smoke_release`, `smoke_combat`,
  `smoke_stronghold_reload`, `smoke_stronghold_battle_camera`,
  `smoke_gate_f_probe`, `smoke_gate_a_rest_torch`: all green.
