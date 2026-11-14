# SCENE-LENSGROUND-LAND: the post-fight camera no longer rests on a dune face (F39#21)

STATUS: land (correctness fix; no GPU verdict claimed)

## The bug
F39#21 fell from 7.06 to 5.84 on main (G-rescore-1113, LANE-PLACES): at the Venn win, a flat grey plane fills the lower half of the frame (3/3). It is the dune face seen from a lens resting 0.35 m above it.

The 9 Nov lens ground clearance (`movement.json camera.lens_ground_clearance`, ON) is meant to stop exactly this, but it tested the lens at the full `spring_length`. When the arm's own collision has already pulled the camera in against a dune, the real lens sits at the hit length. The point at the full length is under the dune, its short downward ray finds nothing, and the arm was left alone.

Why it appeared after 10 Nov: whether the dune cuts the arm depends on the heading the fight ends at. On CPU, with `opponent_trainer_stand_1112` on, the fight ended facing the dune (yaw 147); with it off, along the beach (yaw 68). Fight captures drift run to run, so that comparison is one run each, but either way the clearance was the part that failed.

## How it was confirmed
- In-world probe (Tidewake booted, player at the Venn end-of-fight spot, camera turned to the bad run's heading with a 19 m arm):
  - old code: lens (356.26, 7.37, 3813.72), 0.35 m above the ground, arm 19.0 m, hit 10.98 m. This matches the bad run's logged lens (356.2, 7.37, 3813.67).
  - fixed: lens 1.03 m above the ground, arm 9.48 m.
- The clearance's own ray at the bad lens point hits Terrain3D (layer 1, inside the rig's mask), so the ray was never the problem; only the point it was cast from.

## The fix
`scripts/player/camera_rig.gd _keep_lens_off_ground`: start from `min(spring_length, get_hit_length())`. No other behaviour changes: the same min_m, step_m and min_arm_m; no pitch, yaw or framing change.

## Tests
- `tests/test_camera_lens_ground_clearance.gd` adds `test_a_lens_the_arm_already_pulled_in_is_tested_where_it_is`. It fails on the old code (checked) and passes with the fix.
- The 29 test files that touch the camera rig, with `test_flag_scopes.gd`: 217 tests, 0 failed (run on `tb/scene`, same two files).
- Not run: the full suite or any GPU capture. A one-sided re-score of F39#21 after landing gives the new number.
