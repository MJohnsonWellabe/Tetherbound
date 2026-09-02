# Does the first fight actually stage? — answered

**T5-FEEL, 2026-08-30. Routed to this lane by the coordinator on the strength of
two instrumented Gate F segments (S02 on 2026-08-27, X04 tonight) that between
them produced zero `combat_start`, zero `combat_hit`, zero `combat_end` and zero
`catch_throw` events.**

## The answer

**Combat engages. Catching works. This is a RIG defect, not a game defect.**

Real combat and real catching were driven through the real input path, in the
real world scene, dozens of times, while measuring OP-0830-5. They were not
staged through an API back door.

## The evidence

`tools/_probe_catch_rate.gd` boots `res://scenes/world/meadows_playground.tscn`,
walks the player with the `move_forward` action, engages with the `interact`
action, and then throws with the `combat_throw` action. Every step is the
player's own verb.

Across six runs (three before my catch fix, three after), at two health tiers
and two aim qualities:

| | |
|---|---|
| Encounters entered (`is_fighting` true after one `interact` press) | **every attempt; not one failed to stage** |
| Orbs thrown through the real aim camera and `throw_aim.gd` | **99** |
| Orbs that physically struck the target body | **88** |
| Wild creatures actually caught into the party | **21** |

One run's raw shape, verbatim from `ralph/reports/T5-FEEL/catch-before_hp0.5_j0.log`:
17 throws, 16 strikes, 3 catches; and after the fix, 14 throws, 12 strikes,
6 catches. The `catch launch: release / commit / placement / strike` lines are
`throw_aim.gd`'s and `orb.gd`'s own logging, from real flights.

The probe also re-acquires a fresh encounter after each catch or faint — spawn a
wild creature, walk to it, press `interact`, fight again. That loop ran to
completion repeatedly. A world where the first fight never stages cannot do that
once, let alone twenty times.

## What this does NOT prove, stated plainly

The probe **bypasses the opening**. `_leave_the_farmhouse()` places the player
near the practice cluster at (48, -58) rather than walking them out of Grandpa's
house, because it exists to measure the throw, not the first act.

So the honest split is:

* **Ruled out:** "the Meadows has no combat", "the encounter never stages",
  "catching is unreachable". All three are false, with 99 throws behind the
  claim.
* **NOT ruled out:** that the *opening sequence* fails to deliver the player to
  their first fight. That is a different defect in a different place, and it is
  where I would look next.

Two things point that way rather than at combat:

1. X04's own stop cause, as the Gate F lane reported it, was **an unanswered
   narrative modal holding locomotion for 3601 frames**. A player who cannot
   move cannot reach a creature, and a segment that never reaches a creature
   logs zero combat events without combat being broken.
2. OP-0830-4 in the same owner playtest is exactly this shape one beat earlier:
   *"after the first conversation with grandpa you're trapped in his house with
   nothing telling you to talk to him again before you can go."* A player stuck
   in the opening also produces a telemetry census with no combat in it.

Both are consistent with the segments being **stopped upstream of the fight**,
which is the coordinator's own second hypothesis, and neither requires combat to
be broken.

## Recommendation

Route the zero-combat census back to the Gate F lane as a harness/flow question,
with two specific asks:

* Make the engage step assert that **combat actually started**, not that input
  was injected. The finding already notes six of S02's seven failures cascade
  from a step that "PASSES because it asserts that INPUT WAS INJECTED, not that
  anything received it" — that is the defect, and it will keep producing false
  greens and false blockers until it checks `CombatManager.is_fighting()`.
* Check the opening's modal/locomotion gate before the fight steps, since that
  is what actually stopped X04.

`tools/_probe_catch_rate.gd` is available to either lane as a worked example of
driving a real engagement through real input and asserting on the fight's own
state.
