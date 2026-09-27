# F13#3 lures, round 3: Lantern Cove and Drowned Garden only

Criterion: ACCEPTANCE §6.1 **F13#3**, §5 "see the lure" clause; AUDIT rows V-TW-2 (Lantern) and
V-TW-4 (Garden). Round 2: `../f13_3_lures_r2/`. The lures for Gull, Cradle, Deep and Lastlight are unchanged.

## Changes
- **Smoke.** The coordinator ruling for Meadows (#356, 12:00) reuses Juno's in-game column. Its values
  come from `TetherHoldingFire` in band4 props at f46b6669: top 42 m, alpha 1.0, colour `#2e2a27`,
  top size 14 m, fade 0.2, base 2.5 m. They now apply to every Lantern and Garden signal column:
  `lantern_cove_rise`, `lantern_cove_nook`, `drowned_garden_saddle` and `drowned_garden_vault`.
  `scripts/world/water_local_chains.gd` now passes a piece's `smoke_colour` to `configure_smoke`.
  Before this change the colour was ignored.
- **Lantern.** `lantern_cove_rise` moved from (-327.7, 134.5) to (-292.0, 155.0). It now sits on the
  grass crest left of the crest tree, 41 m from the landing camera and 17 m from the walked route.
  In the landing frame the banner base is at (508, 179), in front of the rock and no longer beside
  the trunk. Its fire moved to offset (3.0, 6.0) and the lamp to (-1.0, -1.2), so the column rises
  against the sky rather than across the banner.
- **Garden** (three iterations):
  - `drowned_garden_rise` moved to (1079.0, 2259.0), 28 m from the landing camera and 7.7 m from the
    route. Its base is at (592, 233) in the landing frame. It has an ordinary camp fire with no
    signal column, plus a crate-and-barrel stack.
  - New `drowned_garden_saddle` at the round-2 saddle spot (1137.5, 2270.2), 4 m from the route. It
    holds a banner and the Juno column.
  - New `drowned_garden_crest` at (1168.5, 2307.0), 28 m ahead of the approach stand and 17 m from
    the route. Its base is at (490, 254) in the approach frame. It has a banner, a lamp, an ordinary
    fire and crates.
  - New art-only piece kind `prop` for the crates and barrel. It uses the Water docks' own
    `Crate_Wooden.gltf` and `Barrel.gltf`.
- `tools/capture_water_chain_lures.gd` now also logs the walk planner's route and each lure's
  distance from it (`route <key> ... aside=`). The stands are unchanged.

## Checks (final data)
- Chain walks with `tests/smoke_tidewake_b_chain_route.gd -- --only=<chain>`: lantern passed 54/0
  and garden passed 59/0. Both are **PASS**. Logs: `walk_*.log`.
- `tests/run_tests.gd -- --only=water,tidewake`: 437 tests, 0 failed (`unit_water_tidewake.log`).
- Capture command: as in round 2, with `--out` set to this directory (`capture.log`). All twelve frames
  are from the final data.

## Judges
Each judge was a fresh `claude -p --safe-mode --tools Read` process with the prompt on stdin
(`JUDGE_PROMPT.txt`, unchanged). It ran in an isolated /tmp directory holding only the renamed
`frame_NN.jpg` (see `JUDGE_FRAME_MAP.txt`), `_sheet.png` (built before keyart was copied) and
`keyart.png`.

| Iteration | Lantern A/B | Garden A/B | Evidence |
|---|---|---|---|
| 1 | YES / YES | WEAK / WEAK ("black cone reads as an artifact" at 28 m) | `iter1/` |
| 2 (column moved to saddle) | NO / YES (Lantern frames identical to iteration 1) | WEAK / WEAK ("banners high and small") | `iter2/` |
| 3 (final: crest group closer, crates) | WEAK / "WEAK/YES" (identical frames) | **YES / YES** | `JUDGE_VERDICT_A/B.txt` |

- **Garden passes** on the final frames.
- **Lantern stays open.** It passed with both judges once (iteration 1), but on identical frames it
  then scored NO/YES and WEAK/WEAK-YES. Every judge says the landing frame's banner is small and
  off-centre. They describe the Juno column as a "black spike/cone artifact" in several frames.
- On unchanged frames, judges also scored Gull NO/WEAK, Cradle WEAK/YES and Deep NO (iteration 2, B).
  This is judge variance. Those chains are out of scope for this round.
