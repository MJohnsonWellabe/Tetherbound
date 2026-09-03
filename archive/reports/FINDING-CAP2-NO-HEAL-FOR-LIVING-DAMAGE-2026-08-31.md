# FINDING — CAP-2 is a GAME defect, and it is CAP-1's other half. Fixed.

**Verdict: GAME, and NOT intentional pacing.** The opening's starting kit is
supposed to contain potions and berries. Three separate documents say so and
none of them was ever superseded. They were removed by the same unremarked
2026-08-28 commit that removed the Revives, in the same four-line block, and
CAP-1 restored only one of the four.

Source finding: `ralph/reports/FINDING-CAP2-S03-TRAINING-LADDER-2026-08-31.md`
on `ralph/GATE-F-CAPSTONE-2` (commit `1325f887`). Fix branch:
`ralph/CAP2-NO-HEAL-FOR-LIVING-DAMAGE`.

## The question this was routed on, answered

*Was omitting potions and berries a deliberate pacing decision, or a second
silent regression from the reflow commit CAP-1 already found?*

**A second silent regression from the same commit.** The only text anywhere in
the repo that reads like a pacing decision is CAP-1's own sentence — *"they are
a pacing question about the opening's supply"* — written by the fix author three
days ago as a reason for **not deciding**, and repeated into
`docs/decisions/D40`. It is a deferral, not a decision, and nothing precedes it.

What does precede it, all still live:

| record | what it says the pack is |
|---|---|
| `docs/OPENING_SEQUENCE.md` beat 3 | *"gives you his old pack — **orbs, potions, berries**"* — and names `give:orb_basic:15`, `give:potion_small:3`, `give:berries:5` explicitly |
| `docs/decisions/D18-the-opening-starts-indoors.md` | *"a parting gift of **orbs and potions**"* |
| `docs/decisions/D40-fainting-needs-a-revive.md` | the Revives are added *"alongside the **existing orbs/potions/berries**"* |

And the diff:

```
$ git show 66eb47ec -- data/dialogue/opening.json
-          "effect": "give:orb_basic:15"      <- re-added, on the new beat
-          "effect": "give:potion_small:3"    <- dropped
-          "effect": "give:berries:5"         <- dropped
-          "effect": "give:revive:2"          <- dropped; restored by CAP-1
```

`66eb47ec` is titled *"First-hour: sequence opening through tournament signup"*
— a one-line commit message, no body, no decision doc, no mention of the gifts.
`git log -S "give:potion" -- data/dialogue/opening.json` and
`git log -S "give:berr" -- data/dialogue/opening.json` each return exactly two
commits: the add, and that removal. Same shape as `give:revive`, same commit,
same silence.

So: not pacing. Nobody ever decided the opening should ship potion-less, and
the three documents that describe the kit all still describe the pre-`66eb47ec`
one.

## Why restoring the Revive did not already cover this

D40 split recovery in two and meant it: **a Revive raises the fallen, a potion
tops up the living, and neither one covers the other's case.** Restoring one of
the two therefore answered exactly one of the two failure modes. CAP-2 is the
other one, and every route out is closed for a reason that is individually
correct:

| route | why it was closed | read at |
|---|---|---|
| a Revive | `revive()` **refuses a creature that has not fainted** — the mirror of the rule CAP-1 leaned on | `creature_instance.gd::revive()`, D40 |
| CAP-1's faint floor | gated on `party.all_fainted()`, and the starter went down beside a healthy caught bramblebun, so the party was never wiped and the floor correctly never fired | `sequence_director.gd::_hold_the_tutorial_team_floor()` |
| a potion | **the player has none** — this regression | the capstone's `S02-exit.json`: `orb_basic x12`, `revive x2` |
| crafting a potion | `potion_small` is known from the first minute, but costs 4 berries **and 1 fiber**, and `fiber` is `gathered_with: knife` — a village tool from after this beat | `data/recipes/recipes.json`, `data/items/items.json` |
| a creature bed | a buildable; its fiber needs the same knife | `data/items/buildables.json` |
| sleeping | a night heals only creatures **physically put to bed** | `night_rest.gd` → `game_state.complete_creature_bed_rests()` |

The capstone measured the cost precisely: the starter left S02 **alive at 53.0
of 117.6** — ordinary damage carried out of a fight the player won their way out
of — entered S03's first village training fight at that HP and lost it, and from
there the prompt read *"Ripplet is out of the fight."* for nine consecutive
engage attempts. Team never reached five; `home_materials_gathered`,
`home_built`, `creature_bed_built`, `player_slept_at_home` and
`tournament_team_fed` all stayed unset; S04 never signed up for the tournament.

## The fix

`data/dialogue/opening.json` — `give:potion_small:3` and `give:berries:5`
restored to `grandpa_first_catch`, beside the orbs and the Revives, in the
pack's original order (orbs, potions, berries, Revives — which is also hurt,
fed, fallen). The two lines are the original spoken lines from `grandpa_house`,
restored verbatim:

> *"Three potions. For your creature, mind — you get soup."*
> *"Berries off my bushes. A fed creature forgives a long day."*

**Nothing else changed.** No new item, no new mechanic, no new recovery path, no
retune of any fight, no change to the faint floor's `all_fainted()` gate — that
gate is right and CAP-2 is not an argument against it. This is the removed data,
put back, on the beat CAP-1 already established as the right one for a `give:`.

Berries are restored alongside the potions and not as a separate favour: they
are the third named item in the pack, they are 4 of the 5 units of
`potion_small`'s own recipe (so they are the renewable half of this answer once
the knife arrives), and the ladder's own `tournament_team_fed` rung expects the
player to have some.

### On trivializing the tutorial

Three Small Potions is 105 HP of healing (`heal: 35` each) — against a starter
whose bar was 117.6 in the capstone's own save. **The whole gift is less than
one full heal of one creature.** It closes the 64.6 the tutorial itself opens
and leaves enough over to matter once, which is what a starting kit is for, and
it runs out. It is also the quantity the game shipped with for its entire
history until three days ago, so this restores a balance point rather than
proposing one.

One thing worth stating plainly rather than repeating D40's stale note: **the
hotbar is live during a fight.** D40's "What was deliberately not built" says
the belt is deaf mid-fight (D32/HD2); the owner's controller map has since
overridden that — `playground_hud.gd`'s own comment: *"the hotbar STAYS LIVE in
a fight … so food and orbs stay reachable mid-fight"* — with only the aim window
excluded. So these three potions are usable inside the training fights, not just
between them. That is the owner's directive working as intended and not
something this change introduces, but it is the honest read of what restoring
them does, and it is why the count was left at the historical three rather than
raised.

## Evidence

`tests/test_opening_healing_kit.gd` (new, 6 tests), built in the shape of
`tests/test_tutorial_faint_floor.gd`. It pins the gift by BEHAVIOUR rather than
by item id — the opening must hand over something carrying a `heal` field, and
enough of it to close the deficit the capstone actually measured
(`1 - 53.0/117.6` of the live species table's max HP, so a starter rebalance
moves the bar with it) — plus the three reasons nothing else substitutes:
`revive()` refuses a merely-hurt creature while `heal()` restores it,
`all_fainted()` is false for CAP-2's exact party shape (and stays false after
the starter goes down, because the caught creature is standing), and
`potion_small`'s recipe is gated behind a tool the opening does not hand over.

Verified non-tautological: with the two restored `give:` lines reverted, 2 of
the 6 tests fail — `test_the_opening_hands_over_something_that_heals_a_living_creature`
and `test_the_healing_gift_covers_the_damage_the_capstone_carried_out_of_s02`
(and `test_the_opening_hands_over_food`, if berries are reverted too).

Suites run on this branch, Godot 4.7-stable headless:

| suite | result |
|---|---|
| `tests/run_tests.gd` (full unit suite) | **1693 tests, 3632178 assertions, 0 failed** |
| `tests/test_opening_healing_kit.gd` | 6 tests, 72 assertions, 0 failed |
| the same file with the two `give:` lines reverted | **3 of 6 FAIL**, as intended |

The four smokes CAP-1 ran (`smoke_opening`, `smoke_catching`,
`smoke_party_count_after_catches`, `smoke_backpack_player_eats`) are left to
CI, which runs each with its own retry loop for the nondeterministic catch aim
rather than a single local pass.

## What this does NOT close

- **The zero `catch_throw` events in S03**, while four orbs were consumed, with
  fight 3 sitting in `combat_aim` for its entire length against an opponent
  whose HP never moved. That is the capstone's second undiagnosed fact and it is
  independent of this: it is either an instrumentation gap (CD-6's family) or a
  throw that does not register, and neither is a healing question. Still open.
- **`TOURNAMENT-SEMI-DIFFICULTY`.** Capstone-2 never signed up, so no semi-final
  existed to be hard. That item is neither confirmed nor cleared, exactly as the
  source finding says.
- **The Gate A `recipe_orb_basic` failure** in `smoke_gate_a_opening_segment.gd`,
  flagged by CAP-1 as pre-existing and untouched here.

## For whoever restarts the capstone

Restart from `S02-exit.json` or from a fresh run — **not** from any save at or
after S03, which is contaminated by the degraded handoff. A save made before
this fix does not gain the potions retroactively: the gift is a dialogue effect
on a beat that has already passed, so an old save stays potion-less. That is the
same property CAP-1's floor was deliberately built to work around (it recovers
on load), and it does not apply here — a merely-damaged creature in an old save
still has no answer. Any run intended to test this fix has to start a new game.
