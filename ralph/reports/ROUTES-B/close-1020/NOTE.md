# Routes-B close-1020: Cloudreach and Stormwood pieces (F49#0, earned-checkpoint half of F19#5)

## TO COORDINATOR: FINAL READY tb/routes-b-final __SHA__
Built from origin/main a4f8a6b7 plus tb/routes-b 9f5c1925. Owner direction: everything on main, without bloat. No file over 200 KB. Only small receipts, seam manifests and this note are added; saves and logs stay out.

**Proven** (accepted pieces from pinned start saves; seams match unless noted):
- **Cloudreach T4:**
  - Aster: master_t4 won, feast_t4 learned and the kit delivered.
  - Home Key → storage → portal return → walk back to the aerie.
  - Home Key before the Altar.
  - All five Altar slots: five at L40/cap40, paid through production input.
- **Stormwood T5:**
  - Rowan: master_t5 won, feast_t5 learned and the kit delivered.
  - Home Key → storage → portal return → walk back to Rowan.
  - Home Key before the Altar.
  - All five Altar slots: five at L50/cap50.
- **Stormwood ending:**
  - dynamo (rods, Kestrel, core).
  - marrow_settlement (Marrow defeated, Stormheart refused, same five).
  - home_key, then home_relic (Stormwood relic hung, ending receipts matched).

**Open (unproven, not run):**
- The T4 and T5 Kitchen and feed runs: training_t4_kitchen/feed/return and training_t5_kitchen/feed/return. The T4 Kitchen attempt before the wrap-up failed on the armed-placement walk; the fix is in this branch (homestead_common `_place_at`) but unproven.
- 07_stormward_handoff.
- home_credits (Grandpa and credits).
- The earned Cloudreach and Stormwood route segments before the boundaries used here.
- One seam with an UNEXPLAINED 8 m Load placement difference: t5_chest__preparehome.

**Code in this branch beyond main** (tooling only, no game code):
- `stormwood_chain_runner.gd`: the marrow_settlement piece and its home predecessors, and the watchdog counting walking progress.
- `homestead_common.gd::_place_at`: the armed return via the village road.

**Focused checks on this branch** (Godot 4.7 headless):
- `--check-only` passes for stormwood_chain_runner, homestead_common, f49_portal_travel, f20_portal_travel, earned_chain_runner, cloudreach_chain_runner and tidewake_piece_runner.
- `run_tests.gd --only=test_stormwood_pilot_reach,test_homestead_feed_selection,test_generated_arrival_saves,test_f49_training_prefix,test_material_bridge_legs,test_essence_earning_piece`: **23 tests, 165 assertions, 0 failed**.

## TO COORDINATOR
- 2026-10-22 22:10Z (superseded by FINAL READY above) STOPPED on request (lanes cut to save usage). Nothing is running. Everything is pushed on tb/routes-b.
- READY: Cloudreach T4 through altar_5; Stormwood T5 through altar_5; Stormwood ending through home_relic, on the declined-Stormheart (retained five) path. See RESUME.
- QUESTION: seam t5_chest__preparehome has one UNEXPLAINED difference. Production Load placed the trainer 8.0 m from the saved pose at Rowan's grove: saved (−1113.8,73.3,3001.5), loaded (−1121.3,73.3,3004.3). Everything else is identical. Unverified; probably the load's safe-arrival placement off Rowan's arena.

## RESUME
Saves are container-local in `/root/rb/` and are lost when the container is reclaimed. A new session regenerates each generated boundary (same profile, any SHA) and reruns from the last accepted piece; earlier pieces are not rerun, per the owner rule.

**Passed pieces (accepted end saves):**
- **Cloudreach T4** (boundary `cloudreach_t4_aster_independent`):
  - gen, then 06k, then 06l → `c4_…` (runs at a5223bd1)
  - 06m Aster duel (a5223bd1)
  - training_t4_home (a5223bd1)
  - storage (9144be95)
  - return (fd69c0c2)
  - 06l from the arrival (fd69c0c2)
  - 06p_aster_chest (833b67ee) → `/root/rb/c4_06p_aster_chest`
  - training_t4_preparehome → `/root/rb/c4b_preparehome`
  - altar_1..5 → `/root/rb/c4b_altar_1..5` (all at f08faa7d)
- **Stormwood T5** (boundary `stormwood_t5_rowan_independent`):
  - gen, then rowan_visit (master_t5 won) → home → storage → return
  - rowan_visit from the arrival → `/root/rb/s5b_rowan_visit`
  - rowan_chest (feast_t5) → `/root/rb/s5b_rowan_chest`
  - training_t5_preparehome → `/root/rb/s5c_preparehome`
  - altar_1..5 → `/root/rb/s5c_altar_1..5` (all at e8cff1d5)
- **Stormwood ending** (boundary `stormwood_rootgate_crown`):
  - gen → dynamo (e214d10f) → `/root/rb/sw_dynamo`
  - marrow_settlement: the Stormheart refused, the five retained (78d263e6) → `/root/rb/sw_marrow_settlement`
  - home_key → `/root/rb/sw_home_key`
  - home_relic → `/root/rb/sw_home_relic`

**Unproven pieces, each with its pinned start:**
- T4: training_t4_kitchen from `c4b_altar_5`, then feed, return, and 07_stormward_handoff.
  - The last kitchen attempt was stopped for the wrap-up. The one before failed on the armed-placement walk; fix 40588a50, not yet proven.
- T5: training_t5_kitchen from `s5c_altar_5`, then feed and return. Stopped for the wrap-up; it ran on the pre-40588a50 helper, so rerun it on the current head.
- Stormwood ending: home_credits from `sw_home_relic` (Grandpa and credits).
- Not started:
  - Cloudreach route segments 01–07 from an earned (non-generated) arrival.
  - Stormwood route pieces before dynamo (arrival_prefix … rootgate) from an earned arrival.

**Fixes this lane made (all reported to Routes):**
- earned_chain_runner tier map
- profiles T4/T5
- 06k detour
- Aster perch landing
- storage keeps keys
- portal walks: lesson cards (renamed f08faa7d) and the Hall entrance
- Stormwood pilot reach (+ test)
- cross-runner `items`
- watchdog walking progress
- armed return via the village road
- marrow_settlement and its home predecessors

## Cloudreach T4 (Aster Windward, master_t4): independent boundary

- **Generated boundary `cloudreach_t4_aster_independent`** (disclosed; committed in `tests/fixtures/earned_saves/generated_boundary_profiles.json`):
  - Restored Cloudreach at the Warden Aila reward body, with the main-route chapter flags. These are the same flags as the existing `stormwood` profile.
  - Five template creatures at generated L39/cap40 with breakthroughs [1,2,3].
  - Prior master_wins t1–t3 and feast_recipes t1–t3.
  - Held/hung relics, portal progress, the Stormwood key and five Tether Candy.
  - Since bb786c98, also sluice_metal 12 and reef_stone 10. That is exactly the Tidewake Kitchen-attachment bill with its two tidesteel ingots, which a T3 player carries from Ione's chest and which no Meadows source supplies. The T4 Kitchen needs every tier up to 3.
  - Not granted: no Aster win, feast_t4 recipe, Altar payment, Kitchen action or feed.
- **Shared helper change:** `earned_chain_runner.gd::_generate_boundary_fixture`. The prior-Master gate is now a tier map {T3 Ione, T4 Aster}, and it requires exactly the prior tiers' wins/recipes. The Routes lane was told.
- **Generate:** `godot --headless --fixed-fps 60 --path . --script tools/earned_saves/generate_boundary_save.gd -- --profile=cloudreach_t4_aster_independent --slot=0 --out=~/rb/c4_gen`
- **Pieces:** `godot --headless --fixed-fps 60 --path . --script tools/earned_saves/cloudreach_chain_runner.gd -- --segment=<id> --from=<prev> --out=<dir>` for the Aster pieces. Homestead pieces run through `tools/earned_saves/tidewake_piece_runner.gd -- --segment=training_t4_<phase> --from=<prev> --out=<dir>`.

| Piece | SHA | Wall | Result |
|---|---|---|---|
| generate cloudreach_t4_aster_independent | 20ac3e3c | 173 s | PASS (L39 ×5, Aila pose (−414,1111,5647), day 16) |
| 06k_return_cliffhold a1 | 20ac3e3c | 826 s | FAIL: "Walking stalled toward (430,920,4500)" at (432.5,919.2,4519.7); see below |
| generate again (with Tidewake Kitchen bill) | bb786c98 | ~175 s | PASS |
| 06k_return_cliffhold (via plateau fork) | bb786c98 | 1291 s | PASS, 4.1 km, 0 sidesteps, (−339.7,830,3970.2) |
| 06l_return_aerie | d22b7373 | 1590 s | PASS, 5.4 km, one disclosed static sidestep (UpperPlateauCircuitCliffShoulders/Ridge003 at (410.6,919.6,4491.1)), aerie (399.7,610.1,3250.1) |
| 06m_aster_duel_only a1 | d22b7373 | 244 s | FAIL: "Flight ended before (950,1042.8,2706)". Stamina 1.65 at the last perch waypoint; Fly ended during `_land`'s hover hop with the body already on the pad 0.3 m from the landing point |
| 06m_aster_duel_only | b747d98a | 293 s | PASS: production 1v1 vs Aster won, master_t4 saved; five L39/cap40 |
| 06p_aster_chest a1 | b747d98a | 184 s | FAIL: "The chest did not teach feast_t4 (Satchel free slots 2; the kit needs room)" |

- **06m fix (c7d7dba4, my runner only):** `_land_on_perch` makes the hover hop with `_fly_to`'s existing `expected_landing`. A flight that ends on the way is judged by `_verify_landing` (on the floor, floor ray hit, within 14 m). The shared `_land` is unchanged.
- **06p:** the boundary's carry-over stacks took the room Aster's kit needs. The player-shaped resolution reuses existing pieces: Home Key → Altar slots (spend candy) → Storage Chest → portal return → chest.

### 06k a1: Old Wind Observatory ledge-rim stall (world-collision defect, fixed on main in #704)
- **Path:** the navigator walked the summit road down to its first bend (450,900,4660), then climbed `observatory_summit_link` toward the Observatory pad (430,920,4500).
- **Stall:** the trainer stopped dead at (432.48,919.17,4519.74), on the link's centreline about 20 m short of the pad centre.
  - Floor contact: `ObservatorySummitLinkCliffShoulders/Ridge000`.
  - Wall contact: `Landmarks/OldWindObservatory/LandmarkLedge/Collision`, normal (0.071,0.661,0.747). That is about 49°, steeper than the floor limit.
  - Stick input was (0.01,1.0). Velocity 0, no modal, no fight. Two disclosed static sidesteps failed the same way.
- **Cause (reading `cloudreach_world.gd`):** `_build_routes` joins every ribbon to a landing at `cap_half` ≈ 6.6 m (`_landing_join`), but the Observatory's flat cap is 18 m (`_landmark_cap_radius`).
  - The link climbs 20 m over 161 m, so at the 18 m rim the ramp is about 1.4–2 m under the flat crown, and the mesa rim there is a 49° face.
  - The plateau circuit enters from the west at 20 m over 649 m, so its rim step is only about 0.35 m.
  - Walking down the link (the 05 stronghold direction) is unaffected.
  - Fixed on main by the coordinator in PR #704 (`_route_join_cap`), after these runs.
- **Piece change (disclosed, ordinary route):** `06k_return_cliffhold` first navigates to the plateau fork (−180,900,4720) along the summit road. From there the normal navigator takes the circuit through the Observatory from the west (`aster_approach_via` log row).

## Piece protocol (owner direction, 22 Oct)
- Each piece starts from a pinned start save. That is either a disclosed generated boundary or an accepted end save of the previous piece, from any earlier SHA.
- No earlier piece is rerun because the SHA moved, and there are no chain restarts.
- Seams: `seams/<from>__<to>.json` compares piece N's saved end state (`receipt.after`) with piece N+1's state after production Load (`receipt.before`). Compared fields: realm, position, flags, party (uid, species, level, cap, tiers), inventory and key items, Master wins and recipes. Every difference is listed with a reason; UNEXPLAINED fails the seam.
- Receipts: `receipts/`. Saves stay local in `~/rb/` and are copied on request.

## Piece table (accepted end saves)
| # | Piece | Runner | Start save | SHA | Wall | Result / end spot |
|---|---|---|---|---|---|---|
| T4.0 | generate `cloudreach_t4_aster_independent` | generate_boundary_save | template (generated, disclosed) | a5223bd1 | ~180 s | PASS: Aila reward body (−414,1111,5647), L39/cap40 ×5, tiers [1,2,3], wins/recipes t1–t3, hung-relic blueprints |
| T4.1 | 06k_return_cliffhold | cloudreach_chain_runner | T4.0 | a5223bd1 | 1811 s | PASS: Cliffhold (−339.7,830,3970.2), via the plateau fork |
| T4.2 | 06l_return_aerie | cloudreach_chain_runner | T4.1 | a5223bd1 | 2411 s | PASS: aerie (399.7,610.1,3250.1), 0 sidesteps |
| T4.3 | 06m_aster_duel_only | cloudreach_chain_runner | T4.2 | a5223bd1 | 476 s | PASS: master_t4 won (production 1v1), perch (952.4,1020.2,2701.3) |
| T4.4 | training_t4_home | tidewake_piece_runner | T4.3 | a5223bd1 | 350 s | PASS: Home Key to the plot (Meadows) |
| T4.5 | training_t4_storage | tidewake_piece_runner | T4.4 | 9144be95 | 1415 s | PASS: Storage Chest built and paid; every non-tool, non-key stack stored |
| T4.6 | training_t4_return | tidewake_piece_runner | T4.5 | fd69c0c2 | 679 s | PASS: Crossing Hall entrance → Cloudreach arch; arrival (0,105,−260) |
| T4.7 | 06l_return_aerie | cloudreach_chain_runner | T4.6 | fd69c0c2 | 3109 s | PASS: aerie (399.7,610.1,3250.2), 5.2 km, 0 sidesteps |
| T4.8 | 06p_aster_chest | cloudreach_chain_runner | T4.7 | 833b67ee | 503 s | PASS: feast_t4 + kit; perch (946,1020.2,2701.4) |
| T5.0 | generate `stormwood_t5_rowan_independent` | generate_boundary_save | template (generated, disclosed) | ed44d191 | ~200 s | PASS: Still Grove road (−160,2697.5), L49/cap50, tiers [1..4], wins/recipes t1–t4 |
| T5.1 | rowan_visit | stormwood_chain_runner | T5.0 | 833b67ee | 5191 s | PASS: rest at Still Grove, ten approach wins, Capacitor Alpha cleared, master_t5 won |
| T5.2 | training_t5_home | tidewake_piece_runner | T5.1 | 833b67ee | 239 s | PASS: Home Key to the Hall home arrival (96.2,0.9,14) |
| T4.9 | training_t4_preparehome | tidewake_piece_runner | T4.8 | f08faa7d | 388 s | PASS |
| T4.10–14 | training_t4_altar_1..5 | tidewake_piece_runner | prev | f08faa7d | 529/148/219/160/162 s | PASS: five at L40/cap40, paid |
| T4.15 | training_t4_kitchen | tidewake_piece_runner | T4.14 | f08faa7d | 18814 s | FAIL: armed-placement walk blocked by GrandpaHouse (fix 40588a50); rerun stopped for the wrap-up |
| T5.3 | training_t5_storage | tidewake_piece_runner | T5.2 | f08faa7d | 1947 s | PASS |
| T5.4 | training_t5_return | tidewake_piece_runner | T5.3 | f08faa7d | 613 s | PASS |
| T5.5 | rowan_visit (from the arrival) | stormwood_chain_runner | T5.4 | e8cff1d5 | 5389 s | PASS |
| T5.6 | rowan_chest | stormwood_chain_runner | T5.5 | e8cff1d5 | 97 s | PASS: feast_t5 + kit |
| T5.7 | training_t5_preparehome | tidewake_piece_runner | T5.6 | e8cff1d5 | 166 s | PASS |
| T5.8–12 | training_t5_altar_1..5 | tidewake_piece_runner | prev | e8cff1d5 | 890/168/166/245/167 s | PASS: five at L50/cap50 |
| SW.0 | generate `stormwood_rootgate_crown` | generate_boundary_save | template | 7627675c | — | PASS |
| SW.1 | dynamo | stormwood_chain_runner | SW.0 | e214d10f | 12972 s | PASS: rods, Kestrel, core |
| SW.2 | marrow_settlement | stormwood_chain_runner | SW.1 | 78d263e6 | 980 s | PASS: Marrow defeated, Stormheart refused, five retained |
| SW.3 | home_key | stormwood_chain_runner | SW.2 | 78d263e6 | 363 s | PASS |
| SW.4 | home_relic | stormwood_chain_runner | SW.3 | 78d263e6 | — | PASS: Stormwood relic hung, ending receipts matched |

## Seam table
| Seam | Manifest | Result |
|---|---|---|
| T4.0 → T4.1 | generated start; 06k receipt `before` plus `receipts/t4_generated_boundary.PROVENANCE.json` | generated boundary (disclosed), no earned predecessor |
| T4.1 → T4.2 | seams/t4_06k__06l.json | match, 0 differences |
| T4.2 → T4.3 | seams/t4_06l__06m.json | match, 0 differences |
| T4.3 → T4.4 | seams/t4_06m__home.json | match, 0 differences |
| T4.4 → T4.5 | seams/t4_home__storage.json | match, 0 differences |
| T4.5 → T4.6 | seams/t4_storage__return.json | match, 0 differences |
| T4.6 → T4.7 | seams/t4_return__06l_arrival.json | match, 0 differences |
| T4.7 → T4.8 | seams/t4_06l_arrival__06p.json | match, 0 differences |
| T5.0 → T5.1 | generated start; `receipts/t5_generated_boundary.PROVENANCE.json` | generated boundary (disclosed) |
| T5.1 → T5.2 | seams/t5_rowan__home.json | match, 0 differences (147 flags) |
| T4.8 → T4.9 … T4.13 → T4.14 | seams/t4_06p__preparehome, t4_preparehome__altar_1, t4_altar_{1..4}__{2..5} | all match, 0 differences |
| T5.2 → T5.3 → T5.4 → T5.5 → T5.6 | seams/t5_home__storage, t5_storage__return, t5_return__rowan_visit, t5_rowan_visit__chest | all match, 0 differences |
| T5.6 → T5.7 | seams/t5_chest__preparehome.json | **1 UNEXPLAINED**: position 8.0 m (see QUESTION) |
| T5.7 → … → T5.12 | seams/t5_preparehome__altar_1, t5_altar_{1..4}__{2..5} | all match, 0 differences |
| SW.0 → SW.1 | generated start; receipts/sw_generated_boundary.PROVENANCE.json | generated boundary (disclosed) |
| SW.1 → SW.2 → SW.3 → SW.4 | seams/sw_dynamo__marrow_settlement, sw_marrow_settlement__home_key, sw_home_key__home_relic | all match, 0 differences |

## Unproven pieces
See RESUME.

## History (failed attempts and fixes)
### T4 run 1 (superseded) (exact SHA b747d98a, superseded)
- training_t4_preparehome PASS (212 s).
- training_t4_altar_1 was lost twice. The tool's 2 h limit killed it once, then a container restart at ~02:50Z killed it at frame 93k, on the way home with earned ironwood (+3 at (−379.3,2569.8)).
- Then origin/tb/routes 7b6f376b (hung-relic blueprints) applied to this boundary too, so the T4 lineage was regenerated.

### T4 run 2: regenerated boundary with blueprints (a5223bd1 onward)
Order changed: the chest opens before the altar slots, because Aster's kit carries the Altar bill.

| Piece | SHA | Wall | Result |
|---|---|---|---|
| generate cloudreach_t4_aster_independent | a5223bd1 | ~180 s | PASS |
| 06k_return_cliffhold | a5223bd1 | 1811 s | PASS |
| 06l_return_aerie | a5223bd1 | 2411 s | PASS, 0 sidesteps (#704 merged) |
| 06m_aster_duel_only | a5223bd1 | 476 s | PASS: master_t4 won through production input |
| training_t4_home | a5223bd1 | 350 s | PASS: Home Key from the perch |
| training_t4_storage a1 | a5223bd1 | 1388 s | FAIL: "Storing stormwood_portal_key was not saved ()". The chest refused the held key with an empty reason after the other stacks stored |
| training_t4_storage | 9144be95 | 1415 s | PASS: helper keeps key items (homestead_common.gd::storage_trip) |
| training_t4_return a1 | 9144be95 | 651 s | FAIL: froze 4.8 m from Tam. His onboarding lesson card held input |
| training_t4_return a2 | 102a18fe | 513 s | FAIL: lesson cards confirmed; then the Cloudreach arch offered nothing |
| training_t4_return | fd69c0c2 | 679 s | PASS: walks into the Crossing Hall by its entrance; arrival (0,106.4,−260) |
| 06p_aster_chest a2 | fd69c0c2 | 262 s | FAIL: Fly deploy refused at the biome-entry arrival (the piece expects the aerie lifts) |
| 06l_return_aerie (from the arrival) | fd69c0c2 | 3109 s | PASS, 5.2 km, 0 sidesteps |
| 06p_aster_chest a3 | fd69c0c2 | 449 s | **BLOCKED**: "The chest did not teach feast_t4 (Satchel free slots 18)" |

- **Arch diagnosis** (three local diagnostic runs, uncommitted prints, saves discarded):
  - The trainer walked straight from the plot and stopped outside the Hall's back wall at (102.4,0.9,21.6).
  - Arch_cloudreach: label "Enter Cloudreach Cliffs…", actionable, view open/character_open, radius 3.2. But `interaction_offer` = {} at 1.7 m, because its line-of-sight ray hit `Village/crossing_hall_shell_12/Collision` at (103.19,1.71,20.78).
  - Every arch's `Approach` marker (e.g. (104,1.05,17.1)) is inside the hall, with clear line of sight.
  - Fix in `f49_portal_travel.gd::_hall_entry_via`: from outside the hall, walk 2.5 m outside `entrance`, then `entrance`, then `home_arrival`, then the arch's `Approach`. Inside the hall there are no waypoints, so tidewake_handoff is unchanged.
- **Lesson-card fix:** `f49_portal_travel.gd::activate` confirms onboarding lesson cards during its walks, the gate_b_tail_segment pattern. Six cards were confirmed at Tam.
- **BLOCKER (decision needed): Aster's chest kit does not fit.**
  - `breakthrough.gd::prepare_chest` is all-or-nothing (`chest_pending_make_satchel_room`).
  - master_t4 needs 19 slots: cliffglass_ore 200/50 = 4, windworn_heartwood 128/50 = 3, skyplume 45/30 = 2, 8 singles, Tether Candy 1, attuned_ground 10 = 1.
  - The 24-slot Satchel, emptied to the 4 tools + Home Key, has 19 free. The Stormwood portal key, held from Veyra until entering Stormwood, leaves 18.
  - master_t5 is also 19, so it fits only with nothing but tools and the Home Key.
  - Options:
    - (a) Larger stacks for the bulk Master materials.
    - (b) Smaller kits.
    - (c) A partial chest delivery that holds the rest. This changes the transaction semantics.
  - Not chosen here.
