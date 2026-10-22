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

### T4 homestead pieces (tidewake_piece_runner, exact-SHA b747d98a)
| Piece | SHA | Wall | Result |
|---|---|---|---|
| training_t4_preparehome | b747d98a | 212 s | PASS: Home Key from Aster's perch to Meadows; five retained |
| training_t4_altar_1 a1 | b747d98a | ~2 h | KILLED by the tool's 2 h background limit (not a piece failure). It was building the Altar from gathered materials: real ironwood +3 at (−379.3,2569.8) over the South Bridge, on the return walk at frame ~49k |
| training_t4_altar_1 | b747d98a | running | Detached rerun from the same preparehome save, 6 h piece cap |

- **Why altar_1 is long:** the Altar costs stone 10, rootstone 4 and ironwood 2. Ione's T3 chest kit carries that bill, so the T3 altar pieces took minutes. Aster's chest is not yet opened (Satchel full), so the first Altar slot gathers the bill across the bridge at about 7.5 simulated frames per wall second on this CPU.
- **Planned next:** altar_2..5 → storage → return → 06p_aster_chest (merging origin/main with #704 first) → home → kitchen → feed → return → 07_stormward_handoff.
- **Observatory ledge:** fixed on main by the coordinator in PR #704 (`_route_join_cap`). The 06k detour stays disclosed for the saves above.
