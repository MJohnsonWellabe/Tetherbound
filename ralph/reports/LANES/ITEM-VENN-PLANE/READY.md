STATUS: land pending GPU regression check (camera bug fix, flag ON)
BRANCH: tb/item-venn-plane
HEAD: (this commit)

Bug: in the Venn aftermath frame a flat grey wedge filled the lower-left corner.
Cause, from a ray-pick at G-recheck-f39-21's pose (ARM.md): the lens rested 0.35 m
above a 42 degree dune face. That wedge, and the "grey rocks", are the Terrain at
point-blank range.

Fix: movement.json camera.lens_ground_clearance is now ON (min_m 1.0, step_m 0.25,
min_arm_m 2.0), with `_why_on` citing ITEM-VENN-PLANE and the ray-pick.
camera_rig.gd `_keep_lens_off_ground` shortens the arm until the ground is at
least 1 m below the lens. No pitch, yaw or framing change.

Checks with the flag ON:
- Every camera and occlusion test file (test_*camera*, test_*occlusion*):
  146 tests, 0 failed. That includes test_camera_lens_ground_clearance, now
  pinned ON with its cause.
- smoke_trainer_battle_camera: PASS.
- smoke_combat_camera: 4 failures, all "requested frame crops a render corner"
  at 3 m and 9 m. That is the same class clean origin/main fails (main had 4:
  three crops plus the right-stick orbit check, which passes here).
- The GPU Venn run never put the lens near the ground (3.5 m and 5.3 m
  clearance), so it cannot show the fix. Per the coordinator, this lands if
  LANE-SCOUT's 11 wider GPU frames show no regression.
