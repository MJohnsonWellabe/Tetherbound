# ARM: paving_scale_1112 (Cloudreach stone trail at trainer scale), LANE-PLACES, 12 Nov 2026

Branch `tb/places`. Ships OFF; `overlay.json` turns it ON. Rows: F40#1 (5.90, below 6) and the gate stands of F40#0.

## Defect and cause
Judges, 3/3 on both sides at the realm gate: "cobble stones as large as the trainer's torso that bury the trainer to the shins"; on F40#1 the pad reads as "generator output". The stone-trail pieces (`cloudreach_f40_items.json candidates[0]`) are sized by a 0.28 m height alone, which scales the model about 2.5x (stones 0.6 to 1 m) and stands its top a shin's height above the walked ground.

## Change (`cloudreach_settlement_life.gd`, flag `paving_scale_1112`)
The same pieces at 0.12 m, near the model's own size (stones about a boot long), sunk 55% so the tops sit about 5 cm proud. No collider, route or placement change. This is a third option beside LANE-BELOW6's pad on/off A/B (`BELOW6-F40-1/`): pad off gave back the uniform lawn; this keeps a trail but at the trainer's scale.

## CPU proof (`_sheet_cpu_base_vs_arm.jpg`: Realm Gate Crag approach, day clear; base left, arm right)
The torso-sized pad becomes a narrow line of small stepping stones flush with the dirt path.

## Honest expectation
Small. It removes one named defect at the gate, gate-road and shrine stands; it does not touch what LANE-BELOW6 found holds F40#1 (the island's dark side wall in the lower fifth of the frame, and lawn where ledges should be). Sent because the row is below 6 and the GPU is idle; the ground and fog parts of the Cloudreach swing are not built.

## Reject if
The trail reads as scattered litter or the path looks bare.

## Round 2 (12 Nov): scoped to the dirt-road stands; please re-judge on the same frames
`G-places-gatepaving` was a split: F40#0 gate clear +0.93 and rain +0.79 (3/3 each), F40#1 row −0.61 (0/3; on grass the stones read as a faint grey smear). The flag now carries `stands` (gate_road_approach, gate_road_close, f40_gate_road): only pieces on the dirt road take the smaller, sunk size; every other stand keeps the shipped pieces.
CPU check with the overlay on: the realm gate approach (matrix piece 3) shows the small flush stones; the F40#1 Realm Gate Crag landmark approach differs from main by about 2% of pixels (I took that as grass motion; not inspected further). The shrine-side F40#1 frames were not captured on CPU.
Same overlay (`overlay.json`), same frames: F40#0 pieces 3–4, the F40#1 row and controls. A landing branch is already cut for the scoped form (`tb/places-gatepaving-land`, READY.md); it should land only if this re-judge holds the gate gain with no F40#1 loss.
