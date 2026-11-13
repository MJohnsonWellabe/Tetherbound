# BEINGS-NECKDOWN: raised necks lie down in the faint (F36#46, F36#88)

This arm **replaces BELOW6-FULGOCOBRA-FAINT** in the queue (that arm had not been captured). It is the same Fulgocobra change plus the Water Abyssal Guardian, in one overlay over code already on the branch. Capture this one only.

| Row | Score (GPU High) | Defect, quoted |
|---|---|---|
| F36#46 Fulgocobra | 5.70 | 3/3, three rounds: "in the faint the neck stays raised at full height with the hood flared, so it never reaches the ground" |
| F36#88 Water Abyssal Guardian | 6.32 | G-rescore-tier2-batch-2, 3/3: "neck up in faint" PRESENT |

## Cause, and how it was confirmed
- **Fulgocobra:** see `../BELOW6-FULGOCOBRA-FAINT/ARM.md`. The rig is one vertical chain; the measured head drop cannot read it. Unchanged here.
- **Water Abyssal Guardian:** the id is in `exclude_species` (12 Nov: the standard settle stood its fins up), so nothing touches its faint, and the game's clip ends with the neck in a raised S and the head a body-height off the floor (CPU base frames faint-050 to faint-100). Confirmed by running the settle for it with every standard faint section off and only `end_pose` on: a negative neck pitch lays the neck forward; a positive one raises it further (both captured). So the neck joint's end pitch is the whole defect, and the fins stay as the game's clip leaves them.

## Change (overlay only, no new code)
`data/config/creature_pose_settle.json`:
- `below6_fulgocobra_scope.enabled: true` (as the inherited arm).
- `exclude_species: []` (its only entry was the guardian).
- `faint.per_species.water_abyssal_guardian`: side_lie, crumple, head_lift, level_trunk and face_camera off; `end_pose` neck -42, head +22 degrees from 30 percent of the clip. The land Abyssal Guardian is not touched (exact id).

## CPU before and after
`_sheet_cpu_wag_base_top_arm_bottom.jpg` (hit 050, faint 050, faint 075, faint 100). Base: the neck stays in a raised S to the end. Arm: the neck stretches forward and the chin rests on the floor at faint 100. Fulgocobra sheet: `../BELOW6-FULGOCOBRA-FAINT/_sheet_cpu_base_top_arm_bottom.jpg`.

## By-eye line for the GPU lane
- `water_abyssal_guardian-faint-100`: the head touches the floor in front of the body. If the head is still above the back line, hold.
- `fulgocobra-faint-100`: the hood lies on the floor in front of the coils. If the hood is still upright, hold.

## Risks and no-loss frames
- The guardian now runs the settle's hit pass too (recoil, grounding). hit-050 looks the same as base on CPU; if judges mark the hit down, add a `hit.per_species` row that switches it off.
- The guardian's body still sits a little above its shadow in both base and arm; `grounded` is on in the arm and did not lower it on CPU. Not claimed as fixed.
- Standing frames (`hit-000`) must be identical for both species.

## Landing notes
The landing puts the guardian row in the file, empties `exclude_species` with a `_exclude_why` update, and turns the Fulgocobra scope ON. If only one species ships, land that half alone.
