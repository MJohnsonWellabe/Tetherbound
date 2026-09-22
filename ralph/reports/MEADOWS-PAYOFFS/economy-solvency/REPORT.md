# Meadows economy solvency: what was already proven, and the one thing that was not

ROADMAP Phase 1 item 8: "Trace actual sources and spends ... Prove solo and
four-player ledgers with two-loss recovery, atomic full-inventory refusal and
useful rewards for retained five."

## The trace, and what already holds it

Most of item 8 turned out to be covered, and this slice deliberately does not
re-test it. Recording where each half lives is part of the audit:

| Item 8 clause | Already held by |
|---|---|
| Atomic full-inventory refusal | `test_reward_delivery.gd::test_full_bag_keeps_reward_pending_then_settles_exactly_once`, plus per-component sources so one full satchel cannot burn the rest |
| Vendors transact exactly, deny overflow, never buy-then-sell at profit | `test_trade.gd` (23 tests) |
| Four-player payouts are not divided | `test_encounter_rewards.gd::test_items_are_not_divided_by_participant_count_either` and `test_every_participant_is_addressed_by_every_component_of_the_payout` |
| Coins have a reachable sink | `test_chapter_rewards.gd::test_coin_income_can_buy_the_things_worth_saving_for` |
| `cart_repair.gd::_on_tried` splitting client cost from public completion | fixed separately; item 8 names it explicitly |
| Useful rewards for an unchanged five | judgement; the owner's, and not asserted anywhere |

## What nothing checked

**Can a player who does only what the chapter requires afford to lose twice?**
Optional content is optional. A chapter that is solvent only for a completionist
is not solvent, and no check distinguished the two — the existing coin-income
test sums *every* trainer in the game.

Traced against shipping data:

- Required-route income: **1,005 coins** (975 from rows the reward map marks
  `required`, plus the 30 starting float in `trade.json`).
- Optional income: **280 coins** on current main.
- One loss, priced at SYSTEMS' own restock figure (2 small potions + 1 revive,
  from "Target supply policy"): 2x28 + 80 = **136 coins**. Food is excluded
  because the same paragraph says a player with zero coins can gather it.
- Two losses: **272 coins**, against 1,005. Margin 733.

Solvent, with the money in required content rather than in activities a player
can walk past (975 required against 280 optional).

## The check

`tests/test_meadows_economy_solvency.gd` — 4 tests, 13 assertions, 0 failed.

1. The prices the ledger is built on are real: every basket item is actually
   sold and the required income is non-zero. Without this the ledger would
   "balance" against nothing.
2. The required route alone pays for two losses.
3. Optional content is a margin, not the budget — required income exceeds
   optional income, so clause 2 is not true by a hair.
4. Four players are each owed the whole payout, compared component by component
   against the solo grant rather than asserted in the abstract, with a floor of
   two components compared.

The loss basket is SYSTEMS' declared restock, not a number chosen here; the
income is read off the reward map's own `required` column; the four-player
figures come from `encounter_rewards.gd::grants` itself.

## Evidence

    godot --headless --path . --script tests/run_tests.gd -- --only=test_meadows_economy_solvency.gd
    4 tests, 13 assertions, 0 failed

## Still open in item 8

- "Useful rewards for retained five" is judgement and stays with the owner.
- Coll's cart spends three materials and pays nothing back; recorded separately
  in the activity reward map rather than filled in with an invented figure.
- Strain stays out, per item 8's own instruction, unless the item 4 play check
  selects it.
