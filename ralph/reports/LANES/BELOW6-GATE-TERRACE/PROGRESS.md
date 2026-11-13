# BELOW6-GATE-TERRACE (F40#1): in progress, NOT an arm yet

Flag: `data/config/cloudreach_visual.json` `landmass.gate_crag_terrace_1113` (OFF). Code: `scripts/world/cloudreach_world.gd` `_build_gate_crag_terrace`, called from `_build_realm_gate_crag`.

## Built

Five stacked terrace bands on the Realm Gate Crag crown: each a 0.32 m pale-stone lip with a 0.55 m stone kerb and a turf top on a wavy outline, inset 2.5 m from the one below, each tier shifted a little toward one side. One mesh; the collider is `create_trimesh_shape()` of that same mesh.

## Checked

- CPU, the row's stand (`_sheet_cpu_base_left_arm_right.jpg`, Realm Gate Crag approach, base left, flag on right): a stepped stone-and-turf rise in the middle of the lawn, in front of the far cliffs.
- Route: this crown is on no route. The arrival road passes 34 m below it. `tests/smoke_cloudreach_arrival_walk.gd` with the flag on: `CLOUDREACH ARRIVAL WALK OK` (196 s).

## Not checked, and why it is not an arm yet

Walking on the terrace itself. I tried to stand the trainer on its top with `phase2_capture_locations.gd --spot=terrtop@6.5,-135.5@200`; three runs booted the world and then never produced a frame (585 s limit). I do not know whether that is the tool's stand survey failing to settle a body on the stepped trimesh, or a slow survey. Until a body is shown to stand and step on it, the collider is unproven.

## Next step

A small physics probe: drop the player body at the terrace's foot, walk it up the five lips with real input, and confirm it reaches the top without sticking. If the trimesh steps snag, replace the collider with one cylinder per tier (each 0.32 m taller than the last).
