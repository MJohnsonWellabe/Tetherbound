# Cloudreach floating cylinders: result (tb/cloudreach-look)

**Status, 1 Nov 2026: STOPPED by the coordinator.** The grounding pass is built and its probe proof passes, but the switch is **OFF** and nothing is landable yet. The owner's screenshot shows a second defect class that this pass does not fix (see "What remains").

## Built (switch: `data/config/cloudreach_grounding.json` `"enabled"`, false)

`scripts/world/cloudreach_grounding.gd` runs last in `cloudreach_look.gd::dress`. It changes visuals only: it adds no collider, surface or route, and moves, shrinks or hides nothing. It seats two kinds of floating piece.

1. **Upright CylinderMesh pieces whose base floats above the ground under the rim.** It adds a flared skirt in the piece's own material, sunk 0.45 m below the lowest ground point.
   - Found: the Realm Gate `ArrivalBeaconPlinth01/02` (`cloudreach_realm_gate_crag.gd::_add_beacon`), at (-32.2, 116, -167.1) and (-15.8, 116, -167.1). Their gaps were 3.4 m and 3.8 m.
2. **Procedural rock drums** (`cloudreach_world.gd::_mesa`, the `StratifiedCliffBody` mesh). Each drum's flared, open bottom ring hangs at a fixed depth.
   - The pass extrudes that ring down to the lowest ground under the drum's outline.
   - It seats a drum only when at least 20% of the outline has ground within 70 m below, and no road runs underneath.
   - It leaves alone drums that sit mostly over open sky, as well as the 8 sky islands.
3. **Counts** (CPU report, seed 2042):
   - 282 pieces seated, with gaps of 0.36–56 m:
     - 176 cliff-face shelves (`*/VegetatedGeologicalShelf#`)
     - 98 route rooted shelves (`*RootedShelf#`)
     - 6 route landing pads (`*_Ledge#`)
     - the 2 beacon plinths
   - 231 drums mostly over open sky, left as cliff faces.
   - 3 drums skipped because a road runs below.
   - `grounding_proof.json` lists every seated piece with its path, position, gap before the fix and proof.
4. **Proof:** `--cloudreach-grounding-report` probes every seated piece's footing again with the same ground definition. Result: **seated=282, failures=0.** Each piece's lowest footing point meets or sinks into the ground under it.
5. **Render check:** `--cloudreach-grounding-debug-colour` tints the added feet magenta. `_sheet_grounding_before_after_debug.jpg` shows that they render, at the back of the frame.
6. **Load cost:** about 6.5 s on CPU llvmpipe (`drum_ms` in the report). This should be measured on the GPU rig before landing.

## What remains (why it is not landable)

- **The owner's screenshot shows a different shape.** Your top-right frame, and stand `vegetatedgeolog12_1` @ (16.5, 4313.2), heading 56, in the sheet, show a big drum hanging overhead with a meadow underneath.
  - That overhang is the **upper bulge of a tall cliff mass's wall**, not a drum bottom. In `_mesa`, `upper_push` sits above a recessed `lower_push` band.
  - Where a lower meadow crown cuts across that wall, the bulge reads as a floating drum.
  - Those masses report "grounded", because their bottom is far below. So the grounding pass cannot reach this case.
- **Next fix:** where another walkable crown intersects a mass's wall, fill the wall between the bulge and that crown. One way is a flag-off option in `_mesa` that clamps the recess (`lower_push` ≥ `upper_push`) for rings that sit above a nearby crown. Another is a skirt from `upper_ring` down to the intersecting crown. Then re-shoot the same stand.
- **Visible change not yet shown:** none of the 15 seated drums I framed showed a visible before/after change at CPU Low. Most shelves' undersides are hidden inside their parent cliff. Before landing, choose stands where a seated foot is clearly in view.
- **Other floaters the survey found, not fixed:**
  - Realm Gate `GateWatchPillar` and its twin, 7 × 33 × 7 m: gaps of 2.8 m and 30.6 m.
  - `CragButtress01/02`: gaps of 18.7 m and 33.3 m.
  - The strata spire clusters at the gate: gaps of 7–10 m.
  - The Sky Shrine void spires: 5–8 m above lower ground.
  - The summit aviary drum and belvedere towers, measured at the rim. The earlier probe found gaps of 1.7 m and 0.6 m; the current centre-probe misses the rim.

## How to run

- **Command:** `tools/phase2_capture_locations.gd -- --biome=cloudreach --seed=2042 --subset=<no match> --spot=<id>@<x>,<z>@<heading> --cloudreach-grounding-report [--cloudreach-grounding-candidate] [--cloudreach-grounding-debug-colour] [--cloudreach-grounding-survey]`.
- **Ground-level stands:** the report's `view=` field gives a ground-level stand for each seated drum.
- **Arms:** run the before arm with the switch off, and the after arm with `--cloudreach-grounding-candidate`.
- **Setup:** TECHNICAL §8.1 has the setup steps and the `--spot` note.
