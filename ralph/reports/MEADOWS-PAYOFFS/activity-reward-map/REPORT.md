# The optional Meadows activities were missing from the chapter's reward map

ROADMAP Phase 1 item 6 counts six optional Meadows activities and requires each
to carry a useful reward. Item 8 asks for a traced source/spend ledger. Both
read against `data/config/chapter_rewards.json`, the chapter's reward audit --
and every optional activity was absent from it.

This is the same gap the file's own `_comment_audit_gap_closed` records for the
tournament: the rewards existed in shipping data, and the table that exists to
answer "is this reward useful" could not see them. Found by reading
`data/progression/objectives.json`'s `local` array against the map.

## What the trace found

Read off shipping data, not invented. Nothing was tuned.

| Activity | Source of the figure | Pays |
|---|---|---|
| `band1_old_champion` (Bram) | band1 `old_champion_bram.reward` | 60 coins, 5 orb_greater, 3 potion_small |
| `band1_meadowhart_herd` | `meadowhart_herd_visit.gd` defaults | 3 orb_basic + team bond credit |
| `band1_broken_cart` (Coll) | `cart_repair.gd` | **spends 1 wood + 1 stone + 1 fiber, pays nothing back** |
| `band2_night_watch` (Farro) | band2 `night_watch_farro.reward` | 40 coins, 2 potion_small |
| `band3_river_nest` (Doss) | `river_nest_clear.gd` constants | spends 1 wood + 1 fiber, pays 45 coins + 1 potion_large |
| `band4_first_ironwood` | shares `defeated_captain_field` | no reward of its own, by design |
| `band4_lost_creature` (Rue/Juno) | band4 `lost_creature_rue.reward` | 50 coins, 1 revive |

The herd is the one optional activity that pays the five directly rather than
the satchel. Doss holds the chapter's only `potion_large` before the Hall.

## The one real gap, stated rather than filled

**Coll's cart spends three materials and returns no item and no coins.** Its
payoff is the repaired cart, its flag and Coll's repaired line. Whether a world
change alone satisfies item 6's "useful reward for an unchanged five" is the
owner's judgement, and a payout figure is a design decision this audit will not
make up. The row records the gap; a test asserts the row keeps saying so, so
that either the cart gets a reward and the row is updated, or the question stays
visible instead of being re-lost.

## The checks

`tests/test_chapter_rewards.gd` -- 13 tests, 187 assertions, 0 failed.

Three added:

1. Every row in `objectives.json`'s `local` array appears in the map, matched by
   `objective_id` rather than by a human re-reading two files. The check asserts
   the objectives array is non-empty first, so it cannot pass vacuously.
2. The audited coin figures match what the trainers actually pay, for the three
   local requests whose reward is a trainer reward block, with a floor of three
   comparisons so the check cannot go quiet.
3. The cart's row still records that it pays nothing back.

A new `every_local_request_is_in_the_map` invariant records the rule in the
file's own invariants block, beside the ones already there.

## Evidence

    godot --headless --path . --script tests/run_tests.gd -- --only=test_chapter_rewards.gd
    13 tests, 187 assertions, 0 failed

Mutation check: deleting the Doss row fails
`test_every_optional_activity_is_in_the_reward_map`. The file was restored.

## Scope

`chapter_rewards.json` is an audit table with no runtime consumer -- the only
mention outside its test is a comment in `playground_world.gd`. No gameplay
number changed and no reward moved. This slice makes the optional content
auditable; whether those rewards are *good* is item 6's judgement half and the
owner's.
