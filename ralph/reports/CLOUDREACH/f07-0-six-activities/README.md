# F07#0 — six WORLD §11 Cloudreach activities, one per principal region

Criterion (ACCEPTANCE §6.1 F07): six WORLD §11 activities, one per principal
region, each passing the §5 rule (lure + distinct action + useful reward +
acknowledgement + saved completion + normal-play route) with a
retained-five-useful payoff.

Coordinator rulings on #356: Waycamp (b) upgrades Galefoot; Windscar's local
beat is the existing aerie-repair supply run; the Tavi rematch stays; the
Observatory latch is (b), the Fly-only drop made walkable; the Circuit TM co-op
race is accepted as disclosed.

## Activities and regions

| # | Region (principal) | WORLD §11 activity | Source IDs | Lure | Action | Useful payoff | Ack | Saved |
|---|---|---|---|---|---|---|---|---|
| 1 | Lower Cliffs (`gate_lower_cliffs`) | Waycamp shelter | chain `waycamp_shelter`; interactions `waycamp_canvas_bundle`, `waycamp_shelter_supply`, `waycamp_shelter_rest` | Neri (giver) + canvas bundle on the arrival road | find bundle → 4 Gale Fiber → settle a companion in Galefoot's creature bed | rain cover over Galefoot's fire/bed (installed camp tent) — a reusable sheltered rest | Iven `cloudreach_iven_waycamp_shelter` | world flags `side_waycamp_*` |
| 2 | Broken Causeways (`broken_causeways`) → High Roost | `three_bells_against_silence` | interactions `side_*_bell`; payoffs `cloudreach_world_payoffs.gd` | lower bell beside the first span | find, ring Windscar, Fly to High Perches bell | travelers + route signal audio; the three known safe landings on the map (`landing_map_markers`) | Orrin / map pins | `side_three_bells_complete` |
| 3 | Windscar (`windscar_ravine`) | local beat: aerie-repair supply run (ruling Q2) + `packs_on_the_wrong_side` couriers | `aerie_repair`, `cloudreach_personal_reward.gd` | ravine shelter / packs | supply the aerie / deliver the medicine | repaired aerie; personal small-potion ×2 once | couriers relocate to Galefoot | world + personal receipts |
| 4 | High Roost (`high_roost_sky_shrine`) | `aeries_of_cloudreach` (High Perches) + bells finale | `survey_high_perches` | High Perches seen from the Fly route | Fly landing survey | safe landing restores traversal stamina; map pin "(surveyed)" | world message | `side_aerie_high_perches_surveyed` |
| 5 | Upper Cliffs (`upper_cloudreach`) | `the_cliff_circuit` | chain pairs + Tavi; `circuit_prize_*` (3) | circuit board (`circuit_board`) | beat the pairs and Tavi, choose one TM | one compatible TM of the chapter's three placed TMs via its own `claim_pickup` receipt; team mark on the board | board + Tavi rematch | `side_cliff_circuit_tm_chosen` + pickup cache flag |
| 6 | Summit (`summit_final_stronghold`) | Observatory return latch (+ Waterward aerie) | chain `observatory_return_latch`; `observatory_latch_sighting`, `observatory_return_latch`; route `observatory_latch_descent`; bridges `observatory_latch_stair_upper/_lower`; nodes `cr_node_cliffglass_latch_head/_landing/_foot` | the latch sighted from the plateau fork (upper route) | reach the summit's west edge, tap the latch | a walkable stone descent from the summit loop to the plateau fork (and on to the Observatory), with gather beats at head, landing and foot | Rusk `cloudreach_rusk_observatory_latch` | world flag `side_observatory_latch_complete`; the deck follows it after reload |

## Commits (tb/cloudreach)

- 6af84b54 Bells / aerie map knowledge
- b871c0df Waycamp shelter; granted `side_*` flag scopes
- 7ed17c91, a6239ad7 Circuit prize (pads on production ground)
- 3f2ce571, 92911c46 Observatory latch and its two-span stair with mid landing
- c5678b51 + this head: summit bivouac lip rail (#356 11:20); 6483116d granted harness exit (Cloudreach-B); a017b529 origin/main merged (full suite 5129 tests, 0 failed)

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
  (the new interactions stand on ground), `smoke_cloudreach_summit_lip_rail`.

## Shortcuts (disclosed; owner ruling 06:58)

1. Fixture starts: flags written before load, level-30 retained five, trainer teleported to each prompt's pad.
2. Interactions use real Interactable + interact input; walking uses the harness stick pilot.
3. Payoff visuals for the stair, rain cover and rail have no new render capture
   here: the local software-GL capture stalled. The High Perches judge is separate (F08#3).
4. Circuit TM co-op race: two peers choosing different TMs within one round trip can each be paid one (never the same TM twice); an atomic choice+claim needs a `world_ledger` op (follow-up).
5. The earned full-route A7 witness (Cloudreach-B, F07#4) predates the latch stair; the stair is optional and its whole-return cadence is covered by the unit model above, not by an earned walk.
