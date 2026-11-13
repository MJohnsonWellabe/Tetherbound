# BELOW6-FULGOCOBRA-FAINT: neck and hood down in the faint (F36#46)

Row: F36#46 Fulgocobra (pooled GPU High 5.87). Every panel across three rounds names the faint (3/3): "the neck stays raised at full height with the hood flared, so it never reaches the ground".

## Why the standard settle could not do it

The rig is one vertical chain (root, spine_1 to spine_4, head). The settle's head drop measures joint-to-head elevation, and this head already hooks down from a standing neck, so nothing drops. The standard crumple's torso drop sinks the coils into the floor.

## Arm

`data/config/creature_pose_settle.json` `below6_fulgocobra_scope` (OFF) runs the settle for Fulgocobra only, with its `faint.per_species` row:

- `end_pose`: stated end pitches for spine_1 (-35), spine_2 (-70), spine_3 (-30) and spine_4 (-10) degrees, ramped in from 30 percent of the clip. New small option in `scripts/creatures/creature_pose_settle.gd` (`faint.end_pose`, `Rig.pitch_joint`); absent for every other species.
- `crumple`: `torso_drop_ratio` 1.0 and `max_drop_deg` 0, so the coils keep their height and the measured drop stays out of the way.

Faint only. Presentation only. Overlay: `overlay.json`.

## CPU

`_sheet_cpu_base_top_arm_bottom.jpg`: `capture_f36_poses.gd --species=fulgocobra --game-clips --clear-ruler --roles=hit,faint --whole-body`, frames hit-050, faint-050, faint-075, faint-100. On the arm the neck folds forward through the faint and the hood lies on the floor in front of the coils at the end; the snake ends as a low heap.

Known side effect: the scope also brings the settle's hit pass for Fulgocobra (recoil and grounding). hit-050 on the arm is a slightly more upright recoil than base. If the judges mark the hit down, add a `hit.per_species` row that switches it off.
