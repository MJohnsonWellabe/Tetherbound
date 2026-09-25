# Cloudreach lane (F06–F08) — evidence

Lane session for ROADMAP F06–F08. This file holds the lane's evidence and is updated in place. It is not a status document; STATE is the status record, and the coordinator updates it.

## WO-1 · F06 / C1: Cloudreach saddle remount

In PR #229. Its evidence section is added to this file when that PR merges.

## WO-2 · F07 / C2: activity payoffs for couriers and aeries

**Baseline:** origin/main `47774c350`.

**Input:** a read-only audit of WORLD §11's six Cloudreach activities against ACCEPTANCE §5. None fully qualifies:

| Activity | Gaps found |
|---|---|
| `three_bells_against_silence` | Reward partial: no landing points revealed. |
| `packs_on_the_wrong_side` | Potion reward missing. The acknowledgement needs a backtrack to Galefoot. |
| `aeries_of_cloudreach` | The reward was a full night-rest bed (health, satiety, a day advance and an autosave), not WORLD's stamina-only landing rest. No map knowledge. |
| `the_cliff_circuit` | TM choice missing. The "Windscar pair" are story fights. The rematch tier exists although WORLD defers it. |
| `side_waycamp_shelter_complete`, `side_observatory_latch_complete` | Unbuilt. The latch needs traversable geometry in `cloudreach_world.gd`. |

### Changes

- **Couriers.** A new `activity_rewards` list in `cloudreach_physical_runtime.json` holds `cr_reward_couriers_potions`: two `potion_small` beside Neri at Galefoot, gated on `side_stranded_couriers_complete`.
  - It is delivered by the same pickup code and per-character once-only cache receipt as every placed pickup.
  - It is kept out of `chapter.pickups`, so the route census of 178 pickups (100 candy, 75 recovery, three TMs) stays unchanged, as in WORLD §4.4.
  - The pack and the delivery grant nothing, so no equivalent award is paid elsewhere.
  - Neri says where the potions are before the report line that completes the chain.
- **Aeries.** The `SurveyRest` night-rest beds are removed. A Fly landing within 12 m and 3 m of height of a surveyed aerie refills the trainer's traversal stamina, every time, and nothing else: no healing, no satiety, no day advance.

### Result (local, Godot 4.7-stable headless)

**`smoke_cloudreach_activity_rewards.gd`: 13 checks, 0 failures.**
- No reward before the report.
- Neri's report goes through the real dialogue guard and sets the completion flag.
- The thanks appears beside Neri. The ordinary interact press ("Take Small Potion") gives exactly two potions, and the receipt is recorded.
- After save and reload, the chain is still complete, the thanks does not return, and there are still exactly two potions.

**`smoke_cloudreach_world_payoffs.gd`: 60 checks, 0 failures.**
- For each of the three aeries: no bed, a landing restores stamina, and health is unchanged at 50%.
- The landing signal is emitted with the trainer on the aerie floor. This is a fixture, not a flown landing.

**`run_tests.gd --only=cloudreach`:** 162 tests, 0 failed.

### Open under F07

- **Bells map reveal.** The three known landing points are held for an interpretation. The third landing point, the Waterward roost, maps to the `waterward_overlook` landmark. That landmark is deliberately withheld until the finale (`stormward_route_revealed`: "future realm direction appear after the finale").
- **Aeries map knowledge.** Not added.
- **Couriers' acknowledgement.** Still needs a backtrack to Galefoot.
- **Circuit.** TM choice and rematch.
- **Unbuilt activities.** Waycamp shelter and Observatory latch.
- **Cadence.** The 885-second no-action stretch and the A7 intervals.
- **Ledger.** The route resource/XP ledger.
