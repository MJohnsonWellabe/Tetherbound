# Finding (PROGRESSION §6 solvency, UX onboarding): pre-camp creature healing runs at zero slack

**Status:** finding for the coordinator to take to the owner. **No spec violation:** SYSTEMS §145 is met by the buildable creature bed. **No numbers changed.**
**Code:** tb/reproof-earned at 8515d88b and later (826d273c3 plus origin/main plus tb/f17 navigator fixes plus the care-basket harness fix).

## What happened
- On 826d273c3, the earned-team segment lost practice fights on seed 1 (F02#6), seed 15 (F02#0) and others. The pilot was fine: it deals more than it takes in almost every fight (`F21-knockback-AB.md`, per-fight `training_combat_observation`). The team simply entered fights at 1–25% HP after the 3 carried potions ran out.
- A harness gap caused this: the `--legacy-order-diagnostic` path skipped the 5-potion care basket the F49 path buys at Mira's first visit. With that fixed (8515d88b), seeds 15, 1 and 26 all reach team_ready (`F02-6-r2.md`). **Every seed ends with exactly 0 potions.**

## Numbers (earned-team segment: 3 catches, then 10–12 practice fights to L5x5)
| seed | potions used | revives used | fights (won/lost) | fights per healing item | potions left |
|---|---|---|---|---|---|
| 15 | 8 | 0 | 10 / 0 | 1.25 | 0 |
| 1 | 8 | 1 | 11 / 1 | 1.33 | 0 |
| 26 | 8 | 1 | 11 / 0 | 1.22 | 0 |
| 1, before the fix (3 potions) | 3 | 4 | 6 / 4 | 1.43 | 0, then lost the 4th |
| 15, before the fix (F02#0) | 3 | 3 | 9 / 4 | 2.17 | 0, then lost the 4th |

- **Coin:** the purse is 140 at the village (`trade.json`; raised from 30 for F02#6 two-loss solvency on 2026-09-27). The basket spends all of it: 5 × `potion_small` at 28 = 140. **Practice wilds pay 0 coin.** The purse stays at 0 through the whole earned-team segment (route ledger `stage=earned_team coin=0`). The first income is the tournament (old r41 ledger: 225 at `tournament_won`).
- **Potion yield:** `potion_small` restores 50 HP (SYSTEMS §93). Practice-wild fights cost the lead about 14–100 HP each (`damage_taken` per observation), so one potion buys roughly one fight.
- **Revive:** per spec. SYSTEMS §93 says a revive "brings creature to 50% effective maximum", and the observed results were 47–71 HP (`care` receipts). This corrects my earlier "no usable HP pool" note: revives work. What runs dry is healing for creatures that are low but not fainted. A revive can't target them.
- **Restock:** impossible during training. After the first visit, every Mira greeting while she is unbeaten routes to `village_mira_challenge` (battle), per `village_npcs.json` greeting_when. The shop returns only after `defeated_mira`. Bram's inn sells no healing (`trade.json`).
- **Margin: zero.** All three seeds finish at 0 potions. Seed 26 fought its final practice fight on a `care_depleted_pilot`. One extra loss or a harder roll means the team runs dry before the L5 gate.

## Free creature healing a player can reach before the paid camp (SYSTEMS §145, Gate A)
SYSTEMS §145: "A player with zero coins can repair freely, reach a free bed and gather basic food; recovery is never a paid-only service."
Gate A (`night_rest.gd`): "sleep completes only pals physically put to bed. Non-resting party members keep their current HP."

| option | where | distance from the practice meadow (30,-40) | heals creatures? |
|---|---|---|---|
| Grandpa's home bed (SleepPrompt) | village | about 60 m | **no**: trainer only (Gate A) |
| **Buildable creature bed** (`data/items/buildables.json`: 6 wood + 8 fiber, no flag or unlock; hammer held from the village) | anywhere | 0 m (build it beside the meadow) | **yes**: 0→100% in 120 s of world time (`progression.json creature_bed.full_heal_seconds`), one occupant per bed |
| trail_camp authored creature bed | band1, bed at (347,934) | 1,026 m | yes, one occupant |
| ranger_camp, riverwatch_rest, highfield_stockcamp, ridge_patrol_camp, the_waystop | bands 2–5 | 2,318 / 3,744 / 5,698 / 6,518 / 7,497 m | yes, one each |

Village-stage ledgers show wood 4, fiber 29, stone 4, so one bed costs 2 more wood of gathering. **§145 is satisfied**, provided the player knows to build one.

## UX/onboarding finding (U1)
Nothing teaches "build a creature bed to heal" before the training fights. The main objective ladder (`data/progression/objectives.json`) orders: 6 build your team of five, then **7 train your team**, then 8 gather camp supplies, 9 make camp, then **10 prepare three Creature Beds**, then 11 rest your entrants. A new player follows the ladder into ten-plus practice fights holding 8 potions at most, with no shop and no prompt that beds heal. The first mention of beds comes after the training they were needed for.

## Options for the owner (smallest first; none implemented)
1. **Onboarding, data only:** move the creature-bed rung before "Train your team", or add a hint at objective 7 ("Hurt creatures recover in a Creature Bed: 6 wood, 8 fiber"). This keeps every number.
2. **Supply margin:** a small potion or revive stock that does not require beating Mira (for example, Bram or Tam selling potions), or a coin trickle from practice wilds. These are PROGRESSION §6 numbers changes.
3. **Free home creature bed:** Grandpa's house gains one creature bed, using the existing `creature_bed.gd` component the authored camps already use (`rest_point.gd _build_creature_bed`). It's one data or props entry. The "home" then heals creatures, matching what a new player expects from the objective text "Rest at camp and let a creature recover".

## Harness follow-up (coordinator plan, not yet needed)
If a seed still runs dry with the care basket, the earned-team segment will gather the shortfall, build one creature bed beside the meadow through ordinary Build input (reusing the gate_b tail bed helpers), and bed the lowest creature until it heals. Each build and heal will go in the route ledger with its time. Seeds 15, 1 and 26 did not need it on 8515d88b.
