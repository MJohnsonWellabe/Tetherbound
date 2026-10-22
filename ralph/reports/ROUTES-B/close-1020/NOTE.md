# Routes-B close-1020: Cloudreach and Stormwood pieces (F49#0, earned-checkpoint half of F19#5)

This is a cloud container: Godot 4.7-stable headless on CPU, installed by `tools/cloud_setup.sh`. Branch `tb/routes-b`, cut from `tb/routes` 0c8fb8ef. Engine flag: every piece runs with `--fixed-fps 60` (disclosed; it gives deterministic 1/60 s frames). Saves stay local under `~/rb/`. Only small receipts are committed, in `receipts/`.

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
| T5.0 | generate `stormwood_t5_rowan_independent` | generate_boundary_save | template (generated, disclosed) | ed44d191 | ~200 s | PASS: Still Grove road (−160,2697.5), L49/cap50, tiers [1..4], wins/recipes t1–t4 |

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

## Unproven pieces
- **Cloudreach T4:**
  - 06p_aster_chest from T4.7 waits for #706. The Master-kit stack sizes fit 16 slots; coordinator decision (a).
  - Then: training_t4_preparehome → altar_1..5 → kitchen → feed → training_t4_return.
  - Then: 07_stormward_handoff.
- **Stormwood T5:**
  - rowan_visit from T5.0 is running (8f56994d).
  - Then: training_t5_home → storage → return.
  - rowan_chest waits for #706.
  - Then: preparehome → altar_1..5 → kitchen → feed → return.
  - Then: the Stormwood route pieces through home_key → home_relic → home_credits.

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
