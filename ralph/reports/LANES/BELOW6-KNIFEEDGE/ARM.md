# BELOW6-KNIFEEDGE: the black strip across the grass at the Three Bells bridge (F40#15 6.08, F40#8)

**Flag:** `data/config/cloudreach_visual.json landmass.end_face_follows_row_1112` (OFF; overlay turns it on).
**Code:** `scripts/world/cloudreach_world.gd _route_ridge`, the end faces. Test: `tests/test_cloudreach_end_face_flag.gd`.

**Cause (found by hiding node groups in the capture, then dumping triangles):** the strip is not a rail or a prop. It is the end face of the route shoulder `AuthoredRoutes/BrokenCausewayMainCliffShoulders/Ridge000`. The face's top edge was one straight line between the last row's two outer vertices, at 330.01 and 330.83 (the second rides up the bridge deck). The five vertices between them are clamped flat at 330.01, just under the pad crown at 330.03. So over 23 m the face stood 0 to 0.8 m above the grass as a zero-thickness wall in the dark cliff material.

**Fix:** with the flag on, each end face is a fan through all seven row vertices, so its top edge is the row itself. Render only: the collider is built from the top rows (`_emit_shoulder_top`) and is unchanged. It applies to both ends of every Cloudreach route shoulder.

**CPU look** (`_sheet_cpu_base_top_arm_bottom.jpg`, day frame; base top, arm bottom): the black line from the bridge foot to the lower left is gone. A small dark wedge remains at the bridge's left foot post, where the outer vertex still rises to the deck. 0 script errors. Golden and night were not captured on CPU.

**Expected gain:** over 0.5 on the three bridge frames (the defect is 3/3 in all three and crosses the foreground). F40#15's own two frames may not move: the judges already call them FIXED 2 of 3.
