# ITEM-NYSA-STAND: Officer Nysa post stand (capture bug)

**Frames:**
- `stormwood__inventory__trainer__officer_nysa_deepwood_rod` (plain inventory)
- its `__dialogue` frame (F41#15 / P2-083), which uses the same plan row.

**Defect (GPU):** the camera sits inside a blue mesh. main062 `visual_validation.json` lists the frame as `subject_not_isolated`.

## Cause

- Stormwood trainers carry no authored facing.
- `tools/phase2_make_character_plan.py` gives every one heading 180 (facing 0 + 180).
- The stand therefore goes 2 to 8 m north of the post. Nysa's post is (-890, 4482), and the Deepwood rod station is 8 m north at (-890, 4490) (`stormwood_rod_stations.json`).
- The production camera arm (spring 5.2 m) backs into the station. The DLG1 manifest records the camera at z 4485.6, only 1.58 m behind the rig at z 4484, so the station's collision shortened the arm and the lens sits in its blue mesh.

## Fix (capture tooling only; no game change)

- `data/config/capture_stands.json` gains `heading_overrides` (enabled), with one frame: Nysa, heading 0. The stand is now on the open route side (south) and the station stands behind her.
- `tools/phase2_capture_world_inventory.gd` gains `static func stand_heading_override(path, identity)`, applied to each planned row and recorded as `view_heading_override`. Every other frame keeps its generated heading.
- `tests/test_capture_stand_heading_override.gd`: 2 tests.
- Earns no score credit: re-baseline live.

## Checks

- **CPU check** (`phase2_capture_characters.gd --subset=...officer_nysa_deepwood_rod`, Compatibility, 1 frame, kept local):
  - the manifest records `view_heading_deg 0`, `view_heading_override true` and `camera_player_distance_m` 5.77 (was 2.57 with the arm cut to 1.6 m by the station);
  - the camera is at (-891.0, 54.96, 4474.9), on the open route south of the post;
  - in the frame, Nysa stands beside the trainer, the rod station is behind her, and no mesh encloses the lens.
- `tests/test_capture_stand_heading_override.gd`: 2/2. The JSON error line in the log is the deliberate missing-file case.

**READY:** land. Capture tooling only; re-baseline the frame live.
