# FINDING — CAP-1 is a GAME defect. Fixed. (Not a capstone-harness flaw.)

**Verdict: GAME, confirmed live in the engine.** The capstone operator's aim
affects how OFTEN the tutorial fight is lost. It has nothing to do with what
happens next, and what happens next was the defect: **nothing in the chapter
could put the starter back up, and nothing anywhere reacted to a wiped party.**

Source finding: `ralph/reports/gate-f-capstone-1/CAP-1-FINDING.md` on
`ralph/GATE-F-CAPSTONE-1` (commit `6ddab6bd`) — four fresh runs, two ending
unrecoverable. Fix branch: `ralph/CAP1-TUTORIAL-CATCH-FAINT`.

## What the capstone got right, and the one thing it could not settle

The write-up's §5 hypothesis is correct and its §6 open question — *"the
trainer promises 'a bed will do it'. Does it?"* — has an answer, and the
answer is **no, not at that point in the chapter**. That is the whole defect.
At the encounter beat, with the starter fainted, every route out is closed:

| route | why it was closed | read at |
|---|---|---|
| a potion | D40 made `heal()` refuse a fainted creature **outright** | `creature_instance.gd::heal()` |
| a Revive | **the player has none** — see the regression below | the capstone's own `S02-exit.json`: `orb_basic x11` and nothing else |
| a creature bed | a *buildable*: 8 fiber, and gathering fiber needs Tam's knife, which is past the road gate, which is past this catch | `data/items/buildables.json`, `objectives.json`'s `village_tools` rung |
| sleeping | a night heals only creatures **physically put to bed** — a party member that is merely fainted is skipped | `night_rest.gd` → `game_state.complete_creature_bed_rests()` |

And with no creature able to fight, `encounter_director.gd::_engageable()`
correctly offers nothing, anywhere, ever again. That is the capstone's ten
consecutive no-prompt engage attempts in S03: not a missing prompt, the
designed refusal, reached from a state the game had no exit from.

`autoload/party.gd::all_fainted()` — *"Every creature down means there is no
fight to be had"* — existed the whole time. **Nothing in `scripts/` or
`autoload/` called it. Only tests did.** The game had the predicate for its own
worst state and no owner for it.

## The regression underneath it

`docs/decisions/D40-fainting-needs-a-revive.md` (owner, 2026-08-15:
*"Grandpa should give you revives at the beginning too"*) added
`give:revive:2` to Grandpa's opening gifts specifically **so a new game starts
with the tool D40's own rule requires**, since the same decision stopped
potions from reviving.

`66eb47ec` (*"First-hour: sequence opening through tournament signup"*,
2026-08-28) reflowed `data/dialogue/opening.json` and dropped the potion,
berry and **Revive** gifts with it. One-line commit message, no mention of the
gifts, no decision doc, and D40 was never superseded — `git log -S "give:revive"`
finds the add and the silent removal and nothing else. That is why the
capstone's exit save carries orbs and nothing else.

## What was NOT the defect

- **Not `max_catch_failures` / `catch_orb_floor`.** The capstone's own
  correction stands: the bound fired exactly as documented on both runs where a
  throw landed. Untouched by this change.
- **Not the encounter's damage balance.** From the capstone's telemetry the
  bramblebun needs ~18 unanswered hits over ~40 seconds to take the starter
  down. That is a long time to stand still, and `catching.json` says the
  undefended aim *"is the whole design"*. Retuning it would trade a stated
  design intent for a symptom. Untouched.
- **Not the objectives ladder.** Rung 4 staying open while rung 5 completed
  looks wrong and is not: `quest_log.gd` tracks the first unset main entry, so
  the HUD line correctly read *"Catch your first wild creature."* — the right
  instruction, for a player who genuinely had not. `objectives.json` also bans
  prerequisites outright. Gating the road gate on the catch would have swapped
  stranded-outside for stranded-inside without adding a way up. Untouched.

## The fix

The opening already answers its other two dead-ends with a bounded floor. This
is the third, in the same idiom, in the same files:

1. **`data/config/opening.json`** — `encounter.faint_recovery_fraction: 1.0`,
   beside `catch_orb_floor` and commented like it. TUNABLE; `0` disables.
2. **`scripts/story/sequence_director.gd`** — `_hold_the_tutorial_team_floor()`,
   polled per frame beside `_hold_the_tutorial_orb_floor()`. While the opening
   is on its `walk_out`/`encounter` beat, no fight is running, and
   `party.all_fainted()` is true, it revives the party through D40's `revive()`
   and pushes one world message. Gated on the beat, which ends permanently at
   the first catch. Polled rather than hung off the `"lost"` outcome for the
   reason the orb floor gives about its own two entry points — and because a
   **save** made in the broken state (the capstone chained S03 off exactly one)
   recovers on load instead of staying stranded.
3. **`scripts/combat/encounter_director.gd`** — `_show_a_revived_follower()`.
   `combat_manager.gd::_finish()` hides the deployed body on the way out of
   every fight and only a handoff shows it again, so **any** un-fainting
   outside a fight — the floor above, or a Revive used from the belt, which is
   D40's entire point — left an invisible creature beside the trainer until the
   player recalled and re-summoned it or walked into another fight. Found while
   closing CAP-1; the recovery is not visible without it.
4. **`data/dialogue/opening.json`** — `give:revive:2` restored to Grandpa's
   first-catch supplies, on the beat before its first possible use rather than
   in the briefing three beats earlier (the reason the orbs moved there in the
   same rewrite). Potions and berries are **not** restored: those are a pacing
   question about the opening's supply; this is the one item a live decision
   made load-bearing.

## Evidence

`tools/_probe_cap1_faint_floor.gd` (new), on the real
`meadows_playground.tscn` with real autoloads — adopt the starter the way the
opening does, faint it, hide the body the way `_finish()` does:

```
=== the capstone's state: 18 unanswered hits, the starter down ===
  party all_fainted: true
  one second after the fight would have ended:
    beat:              encounter
    starter fainted:   false   hp 117.6 / 117.6
    follower visible:  true
    a fight is offered: true

=== and past the opening, where losing is supposed to cost ===
  party all_fainted: true
  one second later, outside the tutorial:
    beat:              free_play
    starter fainted:   true   hp 0.0 / 117.6
    a fight is offered: false
```

The same wipe recovers inside the tutorial and does not outside it.

`tests/test_tutorial_faint_floor.gd` (new, 8 tests / 39 assertions), built in
the shape of `test_tutorial_orb_floor.gd`. Verified to FAIL on the pre-fix data
(3 failures with the two config/dialogue changes reverted), so it is not
tautological.

Suites run on this branch, Godot 4.7-stable headless:

| suite | result |
|---|---|
| `tests/run_tests.gd` (full unit suite) | **1683 tests, 3630846 assertions, 0 failed** |
| `smoke_opening.gd` | pass |
| `smoke_catching.gd` | pass |
| `smoke_party_count_after_catches.gd` | pass |
| `smoke_gate_a_opening_segment.gd -- --gate-a-continuous-core` | see below |

## One pre-existing failure, NOT from this change

`smoke_gate_a_opening_segment.gd` fails on this branch, and it fails
**identically on a clean `origin/main` tree** (`git stash`, same command, same
environment):

```
gate A opening segment FAIL: NPC/gather continuation: Mira's required opening
visit left 'recipe_orb_basic' unset; the gift branch is what the Foreman's
hammer and the orb recipe wait on
```

That is past the catch, in the village continuation, and nothing here touches
it. Not investigated; flagged for whoever owns the Gate A lane.

The opening half of that same test passed on both trees — with one run worth
recording, because it is CAP-1's other half showing up in the project's own
harness. The first branch run failed the catch loop with **40 launches, 0
strikes**: the driven player had drifted to 24–26 m from the bramblebun, past
the orb's ~20 m ballistic reach (`speed 17` / `gravity 14`), so every throw was
short — `reason=ground`, reticle offsets of 1.5–2.4 against the 0.552 needed.
An immediate re-run on the same branch caught it on launch 1. Clean `main`
caught it on launch 4 (2 strikes, 2 misses). So the catch loop is
nondeterministic across identical trees — which is why CI wraps these smokes in
a retry loop, and it is independent corroboration of the capstone's 3-of-12
land rate. **It does not touch this fix**: both new functions return
immediately while `combat_manager.is_fighting()` is true, which covers the
whole fight including the aim.

## For whoever restarts the capstone

CAP-1 is closed and this branch does **not** touch either rig defect the
finding flagged as independent of it. Both are still live in the segment
scripts and both corrupt evidence silently rather than failing loudly:

- **CAP-5 / CD-3** — fixed `interact` press counts still in the segments;
  `advance_dialogue_until_closed` exists for this. It invalidated the only test
  of the Revive path in the whole run, which is why §6's question came back
  unproven rather than answered.
- **CAP-6 / CD-5** — `move_to` coordinate reach plus an unchecked `press` on
  S04's tournament sign-up; 23 presses produced no dialogue and the run could
  not tell a silent marshal from a player out of range.

Also still open, and worth having before the next run reasons about landed vs
missed throws again: **`catch_throw` is never emitted**, so landed-vs-missed is
only knowable by the absence of `catch_result` — the inference CD-6 warns
about. Not fixed here; it is instrumentation, not the defect.
