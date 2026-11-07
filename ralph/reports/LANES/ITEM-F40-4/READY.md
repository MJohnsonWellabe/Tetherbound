STATUS: parked
BRANCH: tb/item-f40-4  HEAD: 7c2a124645d8ac53042ab996e5a421b54dc9f6a4 (READY committed in the next commit)

# F40#4 P2-023 exposed landform edges: strata edges (LANE-CR, 7 Nov 2026, Blender row)

Row F40#4 P2-023. Live: 6.27 CPU (NEAR6-CR `shelf_edge_fringe` ON). This round's base mapped 7.19, which is calibration drift between batches. No judged gain; nothing turned ON.

## New art (Blender, flag OFF)
- **`assets/props/lanecr-1107/cloudreach_strata_cliff/`**: a sculpted strata cliff module.
  - Nine thin, uneven strata with random insets and overhangs, grass ledges and an uneven stepped top. Native 23.8 x 11.4 x 8.8 m.
  - Built procedurally: `blender/strata_cliff.py` (variant r3; the F40#1 terrace script with r1/r2 kept) and `blender/strata_textures.py`.
  - Scale check: `blender/_strata_cliff_scale_check.jpg`, next to a 1.80 m cylinder. Provenance: `provenance.json`.
  - Textures are on the VRAM import policy (check PASS). `scripts/world/cloudreach_settlement_life.gd` PROPS gains `strata_cliff`.

## Round
- **Arm:** `cloudreach_f40_items.json` candidates[13] `--cloudreach-f40-strata-cliff-candidate` swaps the four shared stand-pattern `cliff_shelf` modules (the white mesas in the Sky Shrine and Heartstone frames) for the new module.
- **r1a (self-look, not judged):** at the shelf's 18 m height the module (wide and low, unlike the 31 m-tall shelf block, which is sunk 9–12 m) grew to about 49 x 23 m and swallowed both cameras.
- **r1 `qj/F40-4-r1`:** placed at its visible height (6.5 m and 8 m, sunk 0.5 m).
  - Mapped 7.19 -> **5.98 (-1.21, worse)**. Raw base 5.9 / 6.3 / 6.1, candidate 4.9 / 5.6 / 5.1. RMSE 0.567.
  - All three judges: "flat stacked-slab walls with straight extruded edges, regular horizontal strata, reads as generated blockout". They preferred the installed grass-capped Meshy mesas.
  - Stays OFF.

The procedural stacked-strata family has now failed on F40#1 (flat) and on F40#4 (worse), so it is parked for both rows.

## Flags
- ON: none.
- OFF, left in the tree: candidates[13] (strata cliff).

## Tests
- `run_tests.gd --only=test_texture_import_policy`: 2 tests, 0 failed (merged tree).
- JSON parse checked.

## Files touched
- `assets/props/lanecr-1107/cloudreach_strata_cliff/**`
- `data/config/cloudreach_f40_items.json` (one OFF candidate appended)
- `scripts/world/cloudreach_settlement_life.gd` (one PROPS key)
- `ralph/reports/LANES/ITEM-F40-4/**`

## Landing note
- origin/main (#851) is merged in.
- tb/item-f40-1 also appends two OFF candidates after index 12, and also adds PROPS keys on the same line. When both land, keep every candidate entry and every PROPS key; all are OFF.

## Judges' remaining asks
- Rounded, eroded stratified rock masses, not stacked slabs.
- Tapered floating-island undersides.
- Break the remaining straight shelf lips (frame 2, right shelf).
- Clump the grass carpet and vary the rubble scatter.

## Next idea
- Sculpted rather than procedural: an eroded, rounded rock mass from Blender sculpt/remesh with noise, or a recombination of the installed Meshy strata spire cluster and cliff shelf meshes into an irregular massif. Keep their textures, which the judges like.
- Leave the present mesas in place and only break their straight lips with installed strata spire pieces.
