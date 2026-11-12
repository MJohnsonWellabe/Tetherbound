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
