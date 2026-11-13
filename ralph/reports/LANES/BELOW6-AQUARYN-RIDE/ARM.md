# BELOW6-AQUARYN-RIDE: the ridden Aquaryn sits in the water (F39#8)

Row: F39#8 Aquaryn mounted-water pose (GPU High 5.82). Defect, G-rescore-stale-ext-tidewake 3/3: "the mount still stands on top of the surface" with no immersion.

Coordinator's decision (13 Nov), option A of `QUESTION.md`: sink the mount and let the rider sit waist-deep; the old rider-above-sea pin was a lane's working rule.

## Arm

`data/config/water_mount_presentation.json` `mounts.water_aquaryn.deep_swim_1113` (OFF): `extra_sink_m` 1.6 in place of the shipped 1.0. `scripts/world/water_mount_presentation.gd` `row()` returns a copy of the row with the deeper sink when the block is enabled. Overlay: `overlay.json`. Presentation only.

## Gameplay check before building (as asked)

Nothing keys off the rider's height here:
- Trainer swim and drown state: `water_mounted_swim.gd` forces the trainer's state to MOUNTED while riding, and at the shipped 1.0 the rider is already inside the swim entry band (`swim_controller.gd`: y at or below sea + 0.4), so 1.6 crosses no threshold.
- Water contact rings: `human_water_contact_view.gd` draws only in HUMAN mode, never MOUNTED.
- Camera: there is no underwater check in `camera_rig.gd`.
- Networked seat: `mount_offset` is unchanged; only the mount's own vertical follow target moves.

## Pins

`tests/test_uiposes_water_mount.gd`:
- `test_rider_stays_above_sea_at_deepest_bob` is kept and now reads the row as the game resolves it; it holds while the flag is off.
- `test_f39_8_deep_swim_pin` (new): with the flag on, at the deepest bob the rider's chest (art origin + 0.75 m) is above the sea (+0.26 m) and the seat is below it (-0.49 m); also that the shipped row is not edited in place.
- 6 tests, 0 failed.

## CPU

`_sheet_cpu_base_top_arm_bottom.jpg`: `phase2_capture_tidewake_mounted_swim.gd --seed=2042`, frames 03, 04, 05. Frames 03 and 05 are matched (same camera): on the arm the mount's legs and belly are under the surface and the rider sits at the waterline. Frame 04 is not matched: the mount faces the other way in the two runs (the tool's side view is not stable between runs), but it shows the body in the water with the fins and back above it.
