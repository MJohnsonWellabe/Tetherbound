# LAND-CS-RIMSEAT: seat the tan rim cluster back from the lip, and a smaller residual glow (F40#17)

Branch `tb/land-cs`. Flag `cloudreach_physical_runtime.json rim_pickup_seat_1114`, OFF on the branch. `overlay.json` turns it on and lowers the landed `rim_glow_1113.scale` from 0.45 to 0.3. Base is main with RIMGLOW (#961).

## Row and score
F40#17, 6.61 (G-land-cs-rimglow; that panel's base was 6.03, a later panel read main at 6.04).

## Defect, as the judges put it
- G-land-cs-masterfloor, next ask 2 (3/3): "the subject decides the row: seat the tan cluster back from the lip on soil with a contact shadow, remove the residual pale sphere at the cluster bases, and vary cluster size and spacing."
- G-land-cs-rimglow, judge a: "the orange cluster still sits at the very lip, with ambiguous base contact."

## Cause, and how I know
- `rim_pickup_cluster` (ON since 4 Nov) puts the three rim finds within 1.5 m of each other about 20 m from the crown centre. They are on the very edge: a test spot 0.3 m further out has no surface at all ("placement needs a surface" for the speed find), so the lip under the tan cluster is the island's edge.
- The residual pale sphere: both the halo and the ground aura already take RIMGLOW's scale (`pickup_glow.gd` lines 397 to 426), so what is left is that 0.45 halo, about 0.3 m across, at each base.

## Change
- `cloudreach_physical_runtime.gd _pickup_override`: the new flag is read first. It moves only the stamina (tan) find about 1.2 m inward. The speed and wild finds keep their spots, so all three stay in the fixed frame. A wider respacing (round 1 on CPU, not sent) pushed the orange cluster out of frame and the tan one behind the trainer.
- Overlay only: `rim_glow_1113.scale` 0.3 (clamp floor 0.2; the finds still glow).
- Same ids, items, counts and claims. Only the authored spot changes, on open crown turf.

## CPU before and after
`_sheet_cpu_base_vs_arm.jpg`, crown-rim-out day, cropped to the patch: base left (tan cluster on the rim lip, the three in a row along the edge), arm right (tan cluster on open turf, an uneven triangle, all in frame). The CPU renderer draws the glow faint on both sides.

## By-eye line for the GPU lane
crown-rim-out day and night: the tan cluster sits on open grass inside the rim, not on the lip; all three clusters in frame; no pale ball at their bases. Hold if the tan cluster is still at the edge or any cluster leaves the frame.

## Not in this arm
The Galecrest companion clipping the tower (companion placement, LANE-BEINGS or LANE-THINGS); the night grade (CLOUDNIGHT r2); the platform top (parked by LANE-JUDGE).

## Tests
`tests/test_rim_pickup_seat_flag.gd` (ships OFF; only the stamina find moves, closer to the crown centre; read first), with `test_rim_glow_flag`, `test_below6_perch_rim_landed`, `test_cloudreach_physical_runtime`.
