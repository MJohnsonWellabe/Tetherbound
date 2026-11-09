ROW: F39#21 bug, flat grey plane in the Venn aftermath frame (tidewake__fight__venn_resolve__aftermath-142_53)
BRANCH: tb/item-venn-plane
HEAD: 1508bdfae15ccc83a8e976c29410ad0492f1a448
OVERLAY: ralph/reports/LANES/ITEM-VENN-PLANE/overlay_lens_ground.json
FRAMES: CAPTURE.json (Venn lifecycle: win, aftermath, receipt-expired), base and candidate

Identified on CPU without a render. A probe loaded the Water world, put a camera at
G-recheck-f39-21's aftermath pose (354.53, 7.06, 3810.39), looking
(0.773, -0.242, -0.587), and ray-picked the suspect pixels:
- Bottom-left wedge (x 0-170, y 940-1080): every ray hits /root/WaterArchipelago/Terrain
  1.5-1.6 m from the lens.
- "Smooth grey rocks" at (790, 930) and (1170, 1050): the same Terrain, about 2.4 m out.
  The StoneField and ground-cover tiles sit 9-13 m further, behind it.
- Ground straight under the lens is at 6.71 m on a 42 degree slope: the lens is only
  0.35 m above the dune face. The player stands 10 m away on 6 degree sand.
There is no stray plane, missing material or placeholder. The grey is the dune
surface at point-blank range. The SpringArm only shortens for geometry between the
pivot and the lens, and a slope rising under and beside the lens never counts.

Fix candidate (OFF on the branch): movement.json camera.lens_ground_clearance
(min_m 1.0, step_m 0.25, min_arm_m 2.0). camera_rig.gd `_keep_lens_off_ground`
shortens the arm until a downward ray from the lens finds ground at least min_m
below. No pitch, yaw or framing change. It applies to every exploration camera,
so judge it on the GPU before it ships.

Tests: tests/test_camera_lens_ground_clearance.gd (open ground keeps the arm, a
rising slope shortens it until clear and never below min_arm_m, OFF never touches
it, ships OFF), plus the camera rig, shoulder, clear-orbit and occlusion tests:
35 tests, 0 failed.
