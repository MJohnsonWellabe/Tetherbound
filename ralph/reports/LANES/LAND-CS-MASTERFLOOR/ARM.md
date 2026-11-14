# LAND-CS-MASTERFLOOR: the orange checker disc on the High Perches upper platform (F40#17)

Branch `tb/land-cs`. Flag `cloudreach_visual.json master_floor_1114`, OFF on the branch; `overlay.json` turns it on.

## Row and score
F40#17, 6.61 after RIMGLOW (G-land-cs-rimglow; the landing is in `tb/land-cs-rimglow-land`).

## Defect, as the judges put it
G-land-cs-rimglow, both sides, 3/3: "a flat orange checker disc on the upper platform reads as a placeholder". Next ask 2: "replace the orange checker platform top with an authored stone or grass material".

## Cause, and how I know
A pixel probe in the crown-rim-out day frame (rays against every visible mesh, temporary hook in `capture_cloudreach_high_perch_live.gd`, not committed) names `MasterT4/ArenaFloor` at three points on the disc. `dress_master_site` gives it the worn-ground soil overlay: the dirt-path texture at 0.48 repeats per metre (one tile every 2 m) with tint #9b805f, so from 40 m it reads as an orange checker.

## Change
- `cloudreach_worn_ground.gdshader`: the hard-coded 0.48 tile becomes a uniform with the same default.
- `cloudreach_world.gd dress_master_site`: when the flag is on, Master arena floors take `soil_scale` 0.14 (a 7 m tile) and `soil_tint` #80776a (muted grey-brown earth). Every other worn-ground yard keeps the shipped look. No collision, arena or gameplay change.

## CPU before and after
`_sheet_cpu_base_vs_arm.jpg`: the top of the crown-rim-out day frame, base left, arm right. The checker becomes a mottled earth patch on the turf.

## By-eye line for the GPU lane
crown-rim-out day and night, upper platform behind the tower: no orange checker; a muted earth patch. Hold if it is still orange or checkered.

## Not in this arm
- The Galecrest "griffin" clipping the tower: the probe names `AllyCreature/.../creature_galecrest_lod0`, the player's own companion, so it is companion placement (LANE-BEINGS or LANE-THINGS), not world dressing.
- The night grade (CLOUDNIGHT r2).

## Risks and no-loss
- Master T4's own fight frames use the same floor: they should be checked as no-loss (the arena ring still reads from the blue fight ring and the soil patch edge).

## Tests
`tests/test_master_floor_flag.gd` (ships OFF; muted, non-orange tint; shader default unchanged; applied in `dress_master_site` only), with `test_cloudreach_environment` and `test_vis_cloudreach_landed`.
