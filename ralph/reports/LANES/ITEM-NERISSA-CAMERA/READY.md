STATUS: land (camera bug fix, no score claim)
BRANCH: tb/item-nerissa-camera
HEAD: (this commit)

Bug: in Nerissa's Heart Chamber fight the camera stood behind the containment
crystal. With occlusion fade on it washed the frame translucent pale blue; with
fade off it hid the player (GPU G-occlusion-fade-off-nerissa 662ea63af vs
G-recheck-nerissa-win 580fe1728).

Cause: the crystal has only a camera-only box (water_veilfall.json
camera_occluders, bit 31). That box stops the spring arm on the pivot-to-lens
line, but not a lens beside the crystal looking past it at a fighter. The fight
camera solver's lens-to-torso sight rays (`_fight_world_sight_targets` /
`_fight_visibility_score`) ran only in Stormwood sight-fade arenas, and their
mask skipped bit 31.

Fix:
- scripts/world/water_veilfall.gd: new `fight_camera_world_sight_at(x, z)`.
  It returns true inside the arena_bounds rooms when water_veilfall.json
  `fight_camera_world_sight` is on (it is, with `_why`).
- scripts/combat/combat_manager.gd: new `_fight_room_camera_sight()`. Where the
  room provider answers true, the solver's existing sight rays run, and their
  mask includes the room's camera-only boxes (`world_sight_mask`). The solver
  then takes a clear orbit. Off-room fights are unchanged, with the same mask
  and the same gating.
- Test: tests/test_veilfall_fight_camera_sight.gd.

Proof:
- Nerissa repro (--verified-victory-lifecycle --expected-resolution=1280x720
  --seed=2042 --max-frames=200, CPU): the full fight, 177 frames and the win
  verified, 0 failures.
- _sheet_nerissa_camera.jpg shows the 47/56/72/87 s frames and the two frames
  with the most crystal-cyan pixels (t11, t14). Through every fight frame the
  crystal sits at the frame edge, never between the lens and a fighter. The
  most crystal-cyan frame is 4.4% cyan pixels; the median is 0.9%.
- Tests (21 fight-camera and Veilfall files): 94 tests, 0 failed.
- smoke_trainer_battle_camera: PASS.
- smoke_combat_camera (Meadows) fails the same checks on clean origin/main:
  render-corner crops at the 3 m and 9 m frames, and "after creature switch:
  right-stick did not orbit". That is 4 failures on main and 5 here; the crop
  corners vary run to run, and the code here only acts where a room provider
  opts in.

Not in scope: the post-win frames use the exploration camera, not the fight
solver. In the CPU aftermath and receipt frames a dark translucent panel fills
the right edge behind the trainer. The coordinator has that on the GPU as the
occlusion-fade arm. The doubled reward prefix in the win frame is fixed on
tb/item-victory-card.
