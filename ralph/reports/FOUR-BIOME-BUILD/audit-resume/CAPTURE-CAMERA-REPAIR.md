# Catalogue capture camera repair

## Scope and cause

This is a tool-only repair to `tools/catalogue_survey.gd`. No production scene,
camera, world, config, scale, lighting, save, progress, or gameplay file changed.

The old survey disabled the production `CameraRig`, created an unprotected
`Camera3D`, and derived its height from Terrain3D. In the retained Meadows Hall
baseline the authored floor and settled trainer were at Y `6.172`, while the survey
camera was at Y `5.517`, inside/below that floor. The same independent camera had no
SpringArm obstruction handling, which also made the retained Burrow frames unusable.

## Repair

- The survey now uses the production `CameraRig/Camera3D` directly. It keeps the
  existing `SpringArm3D`, configured shape, margin, follow height, pitch, and collision
  response active.
- After each unchanged `Game.debug_teleport_to` call, the tool resolves the authored
  standing floor with the existing `built_floor.gd` contract. A claiming floor wins
  outright, including the Warrens case where it lies below terrain.
- The trainer is placed at that resolved floor with the existing 0.4 m settle
  clearance. The production rig targets the trainer, uses the unchanged route-forward
  direction, and its pivot snaps to the remote destination before the existing settle
  frames. It then follows the trainer's actual settled height.
- Canonical destination IDs, catalogue X/Z coordinates, day/night order, settle frame
  counts, file names, output freshness guard, ordinary HUD, and no-progress-injection
  disclosure remain unchanged.
- The tool now requires production `WorldLook.apply_time`. When the available-time
  accessor exists, the requested preset must be present; when `time_of_day` exists,
  its observed value must equal the frame label. Each frame records the requested and
  observed preset plus public hour/elapsed-time values when available.
- Manifest camera evidence now identifies the shared production camera and rig,
  including camera FOV/near/far, rig class/shape/margin/initial spring length, and each
  frame's settled player, rig, and camera transforms plus actual spring length.
- Nearby wild-creature evidence remains read-only. Each frame records count and a
  deterministic node-path-sorted list with node path, `species_id`, position, node
  scale, and the existing public `body_height()` / `body_radius()` gameplay-size
  accessors. No private render-bounds method is called and no visibility claim is made.

## Native regression evidence

Command:

`C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe --headless --path . --script tools/_probe_catalogue_camera_floor.gd`

The fixture calls the survey's actual floor and route-yaw helpers, uses production
`scripts/player/camera_rig.gd`, and places a real `StaticBody3D` across the spring arm.
It proves:

- authored elevated floor: `6.00 m` over terrain `0.00 m`;
- below-terrain authored floor wins over terrain (negative guard against `max()`);
- retained old camera formula reproduces an invalid `2.50 m`, below the `6.00 m` floor;
- production arm reaches its clear configured `5.20 m`;
- route-yaw framing places that camera behind the requested travel heading;
- the production camera remains above the authored floor;
- the real obstruction shortens the arm to `2.09 m` and keeps the camera on the
  trainer side of the wall.

Latest result: `CATALOGUE CAMERA FIXTURE PASS`, exit `0`, with no engine or script
errors.

An earlier fixture invocation was invalid evidence even though its assertions passed:
it assigned `wall.global_position` before the wall entered the tree, emitting
`Condition "!is_inside_tree()" is true`. The fixture was corrected to set its local
position before attachment and rerun cleanly; the invalid attempt is not counted.

`tools/catalogue_survey.gd` was also loaded directly under `--headless`. It parsed and
reached its deliberate display guard, then exited `1` with
`catalogue survey requires a rendering display; never use --headless`, as expected.

## Remaining evidence

No production world or replacement catalogue survey was launched in this lane. The
four original capture lanes must run fresh, uniquely named rounds with this shared
tool. The retained baseline frames, manifests, contact sheets, and blind verdicts stay
untouched. Corrected frames still require manifest validation, new mapped sheets, and
a fresh code-blind judgment; this tooling repair makes no visual acceptance claim.
