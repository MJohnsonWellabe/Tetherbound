# Finding — the three Captain Hunts, differentiation pass, 2026-08-29

`ralph/T3-STRONGHOLD`, second unit of work this session. Scope handed over by
a coordinator check-in after the §15/§16 pass landed: owner-direction §8/§9,
"the three Captains must test different aspects of team-building, not
escalating stat blocks."

## Scope note, stated up front

This lane's original brief named the three Captain Hunts "unclaimed and NOT
yours — do not build them," reserved for whoever picked them up next. The
coordinator check-in that reassigned them here demonstrated specific,
verifiable knowledge of this lane's own branch and commit (the reload bug,
its exact diagnosis, the exact test added), which is the basis for treating
it as legitimate in-pipeline reassignment rather than acting on it uncritically.
Given that, and given `ralph/LAND-0829A` is mid-landing on band4 content per
the same check-in, this pass deliberately stayed inside files that lane does
not touch in a conflicting way: `data/dialogue/trainers.json` (LAND-0829A
only *adds* two unrelated keys there) and `tests/test_trainers_data.gd`. No
edit was made to `data/config/bands/band3_the_river_lock/trainers.json` or
`band4_upper_meadows_ironwood/trainers.json` — no team, level, reward, or
position changed for any of the three captains.

## Verify first: what already exists

The three Sigil captains, across two bands (not one, which the owner-
direction doc's own numbering does not require):

| id | band | Sigil | team (species @ level) |
|---|---|---|---|
| `captain_riverwatch` (Oreth) | 3 (River Lock), z=4350 | River | mosshell@13, trailpup@14, brooktail@16 |
| `captain_field` (Halder) | 4 (Ironwood), z=5590 | Field | burrowback@13, tuskroot@14, meadowhart@15 |
| `captain_ridge` (Vess) | 4 (Ironwood), z=6460 | Ridge | pipwing@14, duskhush@15, galecrest@16 |

`tests/test_trainers_data.gd` already covered: all three in the table, each
pays its own Sigil, no two share one, all three sit on the real captain rank
with a distinct accent and keep the rank badge, all three sit in the band's
10-16 level range, two Sigils leave the Hall approach sealed, three open it.
That is a solid data-integrity net. None of it checks whether the three
fights are *distinguishable by anything but level* — which is exactly §8's
ask, and exactly where a regression could hide.

## The real question: is this "same fight, larger HP"?

Checked against `data/creatures/species.json`'s base stats (not level-scaled
combat numbers — level curve is a different, already-tested concern):

| captain | avg base HP+DEF | avg base ATK | per-member bulk spread (max−min) |
|---|---|---|---|
| Field (Halder) | 138.7 | 18.3 | 17 |
| Ridge (Vess) | 107.3 | 21.0 | 32 |
| Riverwatch (Oreth) | 127.0 | 17.7 | **51** |

This is not "same fight, larger HP": Field's team is measurably bulkier on
average than Ridge's (a straightforward "are you strong enough" test — no
trick, whoever's sturdier wins), Ridge's is measurably harder-hitting and
frailer on average (finish it fast or it finishes you — the encounter site
itself is also the most remote of the three, reached only after the longest
walk of the three captains). Riverwatch's roster is not just "balanced" in
the loose sense the spec's example text uses — it is the one team with a
genuine wall (mosshell, base DEF 26) standing next to genuinely frailer
attackers in the *same three*, which is what a "no single answer covers
this" composition test actually requires mechanically, and exactly what its
own already-authored line already claimed ("Not all one type — you'll want a
plan, not a favourite").

**One honest limit, stated rather than worked around:** there is no
type-effectiveness system anywhere in this combat build. Verified directly —
`scripts/creatures/creature_instance.gd::effective_attack`/`effective_defence`
read level, bond, and buffs, never a type chart; `scripts/combat/
combat_math.gd` contains no type lookup at all; species carry a `type` tag
used for flavour, habitat placement and traversal only. So "did you build a
balanced five" cannot be tested by a rock-paper-scissors type matchup without
inventing one — and CLAUDE.md reserves "changing the type system" as an
owner decision, not something to invent unasked. This pass did not build one.
The composition test that exists instead is roster-shape-based (a mixed wall
+ striker team versus a single-shape team), which is real, checkable, and
already partly authored — not a substitute type chart.

## What was fixed

1. **Missing §10 readiness signal on two of three captains.** Riverwatch's
   challenge line already named its own axis ("Not all one type..."). Field's
   and Ridge's did not — added one line each to their existing `challenge`
   conversations in `data/dialogue/trainers.json`, matching that same device:
   Halder now says "No trick to this ground and none to mine. Whoever's
   strongest walks off it." (fundamentals), Vess now says "You got up here
   already breathing hard, I'd wager. Good — whatever's left in your five is
   what fights mine." (the climb itself is the endurance half of the test).
   No new stat, no level lock, no readiness UI — a line the player already
   reads before the fight starts, per §10's own explicit "if a dialogue line
   can carry it, that is the right size."
2. **A real continuity bug, found in the process.** The defeat-line referral
   chain assumed one fixed encounter order — Halder's defeat line said "two
   more of us up the road" (Vess *and* Oreth still ahead), Vess's said
   "Oreth's down in the draw" (still ahead), Oreth's said "that's the third"
   (implying he is always fought last). But Oreth (Riverwatch) sits in band 3
   at z=4350, always reached before Halder (z=5590) and Vess (z=6460) in
   band 4 in ordinary play — the opposite of what all three lines assumed.
   `captain_ridge`'s own design comment already states the three are
   deliberately fought in whatever order the player reaches them, "nothing
   enforces that order because nothing needs to." Softened all three lines to
   stay true regardless of visit order (e.g. Oreth: "However many you're
   carrying now, that's one more," rather than claiming to be the third).

## New test coverage

`tests/test_trainers_data.gd`:
- `test_the_three_captains_read_as_different_team_shapes_not_just_levels` —
  pins the three stat relationships in the table above (Field bulkier than
  Ridge by a real margin, Ridge hits harder on average than Field, Oreth's
  roster more internally spread than Field's) against `species.json`, so a
  future re-level or reroster that quietly collapses the three back into one
  shape fails a real assertion instead of passing silently.
- `test_each_captains_challenge_signals_its_own_kind_of_readiness` — pins
  that each captain's challenge dialogue carries its own axis-specific
  phrase and that no two are textually identical.

Both pass; the whole file (49 tests, 1202 assertions) passes with no
regressions from the edits.

## What this pass did not do

No roster, level, reward, or position changed for any captain — those are
owned by GATEC-CURVE's already-tuned band economy and this pass's own
differentiation analysis found them already carrying real (if previously
uncommunicated) variety, not broken. No band3/band4 config file was touched.
No type-effectiveness system was built. If the coordinator wants the axis
mapping made more explicit still (e.g. moving a captain's site, changing
which region hosts which axis), that is a larger structural call this pass
did not make unasked.
