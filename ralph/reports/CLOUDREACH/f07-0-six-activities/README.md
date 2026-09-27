# F07#0 — six WORLD §11 Cloudreach activities, one per principal region

Criterion (ACCEPTANCE §6.1 F07): six WORLD §11 activities, one per principal
region, each passing the §5 rule (lure + distinct action + useful reward +
acknowledgement + saved completion + normal-play route) with a
retained-five-useful payoff.

Coordinator rulings on #356: Waycamp (b) upgrades Galefoot with a sheltered bed
and a longer rested bonus (Q1); the Tavi rematch stays (Q3); the Observatory
latch is (b), the drop between two existing pads made walkable; Windscar (a,
13:20): the couriers' thanks moves to the ravine shelter, gated on the
delivery; the Circuit TM co-op race is accepted as disclosed.

## Activities and regions

| # | Region (principal) | WORLD §11 activity | Source IDs | Lure | Action | Useful payoff | Ack | Saved |
|---|---|---|---|---|---|---|---|---|
| 1 | Lower Cliffs (`gate_lower_cliffs`) | Waycamp shelter | chain `waycamp_shelter`; interactions `waycamp_canvas_bundle`, `waycamp_shelter_supply`, `waycamp_shelter_rest` | Neri (giver) + canvas bundle on the arrival road | find bundle → 4 Gale Fiber → settle a companion in Galefoot's creature bed | rain cover over Galefoot's fire/bed (installed camp tent), and a companion that sleeps in the sheltered bed stays rested 2× as long (`sheltered_rest`, `apply_sheltered_rest_bonus`) | Iven `cloudreach_iven_waycamp_shelter` (greeting + standing topic `iven_waycamp_shelter`) | world flags `side_waycamp_*` |
| 2 | Broken Causeways (`broken_causeways`) → High Roost | `three_bells_against_silence` | interactions `side_*_bell`; payoffs `cloudreach_world_payoffs.gd` | lower bell beside the first span | find, ring Windscar, Fly to High Perches bell | travelers + route signal audio; the three known safe landings on the map (`landing_map_markers`) | Orrin / map pins | `side_three_bells_complete` |
| 3 | Windscar (`windscar_ravine`) | `packs_on_the_wrong_side` (Windscar step) | `courier_delivery`, `cr_reward_couriers_potions` (moved, ruling (a)) | Neri + the stranded pair at the ravine shelter | carry the recovered medicine to the shelter | the couriers' thanks at the shelter: personal potion_small ×2, once per character (`reward_grant`, `cloudreach_payout:couriers_thanks`) | the thanks acknowledgement; Neri's report; the pair relocates to Galefoot | world `side_courier_medicine_delivered` + personal receipt (reload-checked by `smoke_cloudreach_activity_rewards`) |
| 4 | High Roost (`high_roost_sky_shrine`) | `aeries_of_cloudreach` (High Perches) + bells finale | `survey_high_perches` | High Perches seen from the Fly route | Fly landing survey | safe landing restores traversal stamina; map pin "(surveyed)" | world message | `side_aerie_high_perches_surveyed` |
| 5 | Upper Cliffs (`upper_cloudreach`) | `the_cliff_circuit` | chain pairs + Tavi; `circuit_prize_*` (3) | circuit board (`circuit_board`) | beat the pairs and Tavi, choose one TM | one compatible TM of the chapter's three placed TMs via its own `claim_pickup` receipt; team mark on the board | board + Tavi rematch | `side_cliff_circuit_tm_chosen` + pickup cache flag |
| 6 | Summit (`summit_final_stronghold`) | Observatory return latch (+ Waterward aerie) | chain `observatory_return_latch`; `observatory_latch_sighting`, `observatory_return_latch`; route `observatory_latch_descent`; bridges `observatory_latch_stair_upper/_lower`; nodes `cr_node_cliffglass_latch_head/_landing/_foot` | the latch sighted from the plateau fork (upper route) | reach the summit's west edge, tap the latch | a walkable stone descent from the summit loop to the plateau fork (and on to the Observatory), with gather beats at head, landing and foot | Rusk `cloudreach_rusk_observatory_latch` (greeting + standing topic `rusk_latch_descent`) | world flag `side_observatory_latch_complete`; the deck follows it after reload |

## Commits (tb/cloudreach)

- 6af84b54 Bells / aerie map knowledge
- b871c0df Waycamp shelter; granted `side_*` flag scopes
- 7ed17c91, a6239ad7 Circuit prize (pads on production ground)
- 3f2ce571, 92911c46 Observatory latch and its two-span stair with mid landing
- e9a901fc re-check fixes: Waycamp rested bonus, Windscar thanks, TM claim-first, topic acknowledgements, latch stair climbable both ways
- c5678b51 + this head: summit bivouac lip rail (#356 11:20); 6483116d granted harness exit (Cloudreach-B); a017b529 origin/main merged; full suite at the shelf/world fixes: 5130 tests, 0 failed

## Proof

- Unit: `test_cloudreach_waycamp_shelter`, `test_cloudreach_circuit_prize`,
  `test_cloudreach_landing_map`, `test_cloudreach_observatory_latch`,
  `test_cloudreach_physical_runtime` (23 interactions), `test_realm_chapter_progression`
  (every side chain completes by its own events), `test_tidewake_return_cadence`
  (the whole return, now able to take the stair, has no new A7 interval).
- Engine: `smoke_cloudreach_observatory_latch` (stair absent before, both steps by
  real Interactable + interact input, walked down on foot, 137 s),
  `smoke_cloudreach_ground_truth` (holds the latch flag; open deck has no hole),
  `smoke_cloudreach_foundation` (7 bridges), `smoke_cloudreach_physical_placements`
  (every new interaction stands on ground; the smoke still exits 1 on the unrelated
  `cr_candy_broken_route_good_07`, which fails on main too), `smoke_cloudreach_summit_lip_rail`,
  `smoke_cloudreach_activity_rewards` (the Windscar thanks, claim and reload).
  Key result lines are in `results/`.

## Shortcuts (disclosed; owner ruling 06:58)

1. Fixture starts: flags written before load, level-30 retained five, trainer teleported to each prompt's pad.
2. Interactions use real Interactable + interact input; walking uses the harness stick pilot.
3. Payoff visuals for the stair, rain cover and rail have no new render capture
   here: the local software-GL capture stalled. The High Perches judge is separate (F08#3).
4. Circuit TM co-op race: two peers choosing different TMs within one round trip can each be paid one (never the same TM twice); an atomic choice+claim needs a `world_ledger` op (follow-up). The claim now commits before the choice is spent, so a refused claim leaves the choice open. If all three TMs were already collected in the field, the prize has nothing left to offer (by design: WORLD pays one of the three placed TMs through its own receipt).
5. The latch stair is new geometry (two 348 m stone spans + a mid landing pad with three regrowing cliffglass nodes), not an existing ledge; no render or code-blind judge of it yet.
6. The Waycamp rested bonus and the Windscar thanks delivery step are proven by unit tests and the fixture-seeded reward smoke (the delivery flag is written), not by an earned walk.
7. The earned full-route A7 witness (Cloudreach-B, F07#4) predates the latch stair; the stair is optional and its whole-return cadence is covered by the unit model above, not by an earned walk.
