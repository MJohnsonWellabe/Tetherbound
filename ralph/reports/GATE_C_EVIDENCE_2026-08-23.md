# Gate C — the evidence, not the audit

**2026-08-23.** `GATE_C_AUDIT_2026-08-22.md` established what Gate C *has*.
This establishes what Gate C *does*, which is a different question and the one
the owner asked.

## What proving a systems gate means here

Gate C is not a play gate. `ralph/ACTIVE_GAME_PLAN.md` says so plainly — it
"does not need to be a single long serial block", and its seven prompts are
cross-chapter systems every regional package inherits. There is no continuous
segment to walk, because Gate C is not a segment: it is a set of properties that
must hold everywhere at once.

So its evidence is that those properties hold, checked against the shipping data
and code rather than asserted in prose. **232 invariants across 18 files, all
green in one run:**

```
1342 tests, 716399 assertions, 0 failed
```

## Prompt by prompt

| Prompt | Held up by | Count |
| --- | --- | --- |
| **57** TEAM-progression-curve | `test_chapter_curve` + `test_evolution` | 29 |
| **58** REWARD-resource-economy | `test_chapter_rewards` + `test_chapter_content_map` | 11 |
| **59** TRAINER-journey | `test_trainers_data` | 46 |
| **60** WILD-ecology-journey | `test_spawns_data`, `test_band_content`, `test_wild_alphas` | 29 |
| **61** EXPEDITION-rest-rhythm | `test_fainting`, `test_food`, `test_creature_condition`, `test_camp_supply_reaches_every_band` | 40 |
| **67** FIVE-creature-pressure | `test_party`, `test_bond`, `test_creature_history` | 52 |
| **68** CHAPTER-objective-chain | `test_quest_log` + `test_gateb_objective_chain` | 20 |
| (opening safety net) | `test_tutorial_orb_floor` | 5 |

## The five that carry the most weight

Not every invariant is equal. These are the ones whose failure would mean the
chapter is broken rather than untidy:

1. **`test_chapter_curve::test_a_creature_in_the_approach_is_not_a_practice_meadow_creature`**
   — deeper really is stronger, resolved from world **z** with no player scaling.
   Prompt 57's whole subject in one assertion.
2. **`test_trainers_data`'s ladder checks** — the warden's team is the hardest in
   the chapter, nothing in the stronghold out-levels him, each captain rewards a
   distinct sigil, three captains open the hall. The escalation is data, and it
   is checked.
3. **`test_quest_log::test_every_objective_waits_on_a_flag_something_actually_sets`**
   — no objective waits on a flag nothing writes. A chain that dead-ends is a
   chapter that cannot be finished.
4. **`test_party::test_a_sixth_creature_is_refused_and_changes_nothing`** —
   CLAUDE.md's hard rule, enforced in code rather than documented.
5. **`test_chapter_rewards::test_every_tm_in_the_game_can_actually_be_obtained`**
   — the check that caught three apex TMs with complete data and no acquisition
   path anywhere in the game.

## What this evidence does NOT cover

Stated plainly, because a green suite invites the wrong conclusion.

- **It is data and contract, not feel.** These prove the curve ascends, not that
  ascending it is satisfying. `CATCH-FEEL/OP9` is the standing example: catching
  is provably legal in every region and still measured at ~22% strike rate.
- **Two Gate C gaps stay open by choice**, named in the audit: species-specific
  shiny rates, and the spawn-siting audit artefact in prompt 60's requested
  shape.
- **Nothing here plays.** Gate B's continuous run is the play evidence, and it is
  blocked on `CONTINUOUS-CORE`.

## The honest verdict

**Gate C's properties hold.** Every one of its seven prompts has invariants
behind it, all 232 pass, and the four PARTIAL verdicts from the audit are closed
— the alpha tier exists, the reward audit covers the tournament, per-creature
history exists, and every band can pay for a rest point from its own ground.

That is what proving a systems gate looks like. It is a weaker claim than "Gate
B plays end to end", and deliberately so: they are different kinds of gate and
conflating them is how a repository ends up with 267 DONE entries and an
evidence path nothing has ever run.
