# Routes-B close-1020: Cloudreach and Stormwood pieces (F49#0, earned-checkpoint half of F19#5)

This is a cloud container: Godot 4.7-stable headless on CPU, installed by `tools/cloud_setup.sh`. Branch `tb/routes-b`, cut from `tb/routes` 0c8fb8ef. Engine flag: every piece runs with `--fixed-fps 60` (disclosed; it gives deterministic 1/60 s frames). Saves stay local under `~/rb/`. Only small receipts are committed, in `receipts/`.

## Cloudreach T4 (Aster Windward, master_t4): independent boundary

- **Generated boundary `cloudreach_t4_aster_independent`** (disclosed; committed in `tests/fixtures/earned_saves/generated_boundary_profiles.json`):
  - Restored Cloudreach at the Warden Aila reward body, with the main-route chapter flags. These are the same flags as the existing `stormwood` profile.
  - Five template creatures at generated L39/cap40 with breakthroughs [1,2,3].
  - Prior master_wins t1–t3 and feast_recipes t1–t3.
  - Held/hung relics, portal progress, the Stormwood key and five Tether Candy.
  - Not granted: no Aster win, feast_t4 recipe, Altar payment, Kitchen action or feed.
- **Shared helper change:** `earned_chain_runner.gd::_generate_boundary_fixture`. The prior-Master gate is now a tier map {T3 Ione, T4 Aster}, and it requires exactly the prior tiers' wins/recipes. The Routes lane was told.
- **Generate:** `godot --headless --fixed-fps 60 --path . --script tools/earned_saves/generate_boundary_save.gd -- --profile=cloudreach_t4_aster_independent --slot=0 --out=~/rb/c4_gen`
- **Pieces:** `godot --headless --fixed-fps 60 --path . --script tools/earned_saves/cloudreach_chain_runner.gd -- --segment=<id> --from=<prev> --out=<dir>` for the Aster pieces. Homestead pieces run through `tools/earned_saves/tidewake_piece_runner.gd -- --segment=training_t4_<phase> --from=<prev> --out=<dir>`.

| Piece | SHA | Wall | Result |
|---|---|---|---|
| generate cloudreach_t4_aster_independent | 20ac3e3c | 173 s | PASS (L39 ×5, Aila pose (−414,1111,5647), day 16) |
| 06k_return_cliffhold a1 | 20ac3e3c | 826 s | FAIL: "Walking stalled toward (430,920,4500)" at (432.5,919.2,4519.7); see below |

### 06k a1: Old Wind Observatory ledge-rim stall (open world-collision defect)
- **Path:** the navigator walked the summit road down to its first bend (450,900,4660), then climbed `observatory_summit_link` toward the Observatory pad (430,920,4500).
- **Stall:** the trainer stopped dead at (432.48,919.17,4519.74), on the link's centreline about 20 m short of the pad centre.
  - Floor contact: `ObservatorySummitLinkCliffShoulders/Ridge000`.
  - Wall contact: `Landmarks/OldWindObservatory/LandmarkLedge/Collision`, normal (0.071,0.661,0.747). That is about 49°, steeper than the floor limit.
  - Stick input was (0.01,1.0). Velocity 0, no modal, no fight. Two disclosed static sidesteps failed the same way.
- **Cause (reading `cloudreach_world.gd`):** `_build_routes` joins every ribbon to a landing at `cap_half` ≈ 6.6 m (`_landing_join`), but the Observatory's flat cap is 18 m (`_landmark_cap_radius`).
  - The link climbs 20 m over 161 m, so at the 18 m rim the ramp is about 1.4–2 m under the flat crown, and the mesa rim there is a 49° face.
  - The plateau circuit enters from the west at 20 m over 649 m, so its rim step is only about 0.35 m.
  - Walking down the link (the 05 stronghold direction) is unaffected.
  - **Open game defect, not fixed here** (world build; visual work is paused).
- **Piece change (disclosed, ordinary route):** `06k_return_cliffhold` first navigates to the plateau fork (−180,900,4720) along the summit road. From there the normal navigator takes the circuit through the Observatory from the west (`aster_approach_via` log row).
