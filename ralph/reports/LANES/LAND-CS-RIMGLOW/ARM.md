# LAND-CS-RIMGLOW: smaller pickup glow on the High Perches rim mushrooms (F40#17)

Branch `tb/land-cs`. Flag `mushroom_pickup_variants.json perch_rim_cluster_1112.rim_glow_1113`, OFF on the branch; `overlay.json` turns it on.

## Row and score
F40#17 High Perches rim mushroom, 5.61 GPU High (G-rescore-1113 on tb/places dd4dcc349; was 6.18).

## Defect, as the judges put it
"The mushroom reads as toy-like glow blobs on a featureless lawn rim. The night frame's navy-blue grade differs from the day frame (3/3)."

## Cause, and how I know
- The judged GPU frames (`tb/gpu-frames-1113` G-rescore-1113-rows/F40-17) show three small rim patches, each inside a soft round ball of light (yellow, blue, orange) larger than the patch.
- That ball is the shared pickup glow (`pickup_glow.gd`, owner OP-0830-3: every find glows so it can be seen). Its halo is 0.7 m across (`pickup_glow.json mote.radius`), sized for the old caps. The rim patches that shipped on 12 Nov (`perch_rim_cluster_1112`) are about 0.6x the old cap, so the halo now dominates them.
- Switching only the glow scale at these three placements removes the balls on CPU and leaves the patches.

## Change
- `mushroom_pickup_presentation.gd glow_scale(placement_id)`: 1.0 for every pickup, except the three rim placements when the flag is on (`scale`, 0.45, clamped 0.2 to 1.0).
- `item_cache_pickup.gd` passes it at its four glow registrations.
- The pickups still glow (owner direction kept); interaction, claims and saves unchanged.

## CPU before and after
`_sheet_cpu_base_vs_arm.jpg`: `phase2_capture_cloudreach_high_perch.gd --seed=2042`, crown-rim-out day, base left, arm right. The CPU renderer draws the halo fainter than the GPU, so the GPU difference should be larger.

## By-eye line for the GPU lane
crown-rim-out day and night: the three mushroom patches by the trainer have no large soft ball of light round them; a small glow at their base is expected. Hold if the balls look the same as base.

## Not in this arm
The night navy grade is the queued THINGS-CLOUDNIGHT round 2's target; not duplicated here.

## Risks
- If a judge cannot find the finds without the halo; the glow is smaller, not removed.
- No-loss: the other High Perches views (the court), and any other mushroom pickup (unchanged by construction).

## Tests
`tests/test_rim_glow_flag.gd` (ships OFF; OFF and non-rim pickups keep 1.0; the scale is clamped and never removes the glow), with `test_below6_perch_rim_landed`, `test_pickup_glow`, `test_item_cache_pickup`: 32 tests, 0 failed.
