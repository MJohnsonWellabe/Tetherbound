# BELOW6-GATE-TERRACE: stepped terrace on the Realm Gate Crag crown (F40#1)

Row: F40#1 Cloudreach open terrain (GPU High 5.90). Every panel names the crown "a broad uniform lawn"; eight dressing candidates at the stands failed as pasted-on props. This is real ground, at one stand only.

## Arm

`data/config/cloudreach_visual.json` `landmass.gate_crag_terrace_1113` (OFF, scope world_geometry). `scripts/world/cloudreach_world.gd` `_build_gate_crag_terrace`, called from `_build_realm_gate_crag`. Overlay: `overlay.json`.

Five stacked terrace bands on the crown: each a 0.32 m pale-stone lip with a 0.55 m stone kerb and a turf top on a wavy outline, inset 2.5 m from the one below, each tier shifted a little toward one side so the steps bunch on one flank. One mesh; the collider is `create_trimesh_shape()` of that same mesh, so render and collision cannot drift. With the flag off nothing is built.

## Checks (flag on)

- **Walk on it:** `tests/smoke_cloudreach_gate_crag_terrace.gd` (new; skips while the flag is off). Real stick input from the crown's north lawn to the terrace top: `CLOUDREACH GATE CRAG TERRACE PASS from=(0.0, 150.3, -112.0) to=(6.41, 151.70, -135.17) distance_m=24.8`, grounded, on the top tier (y 151.70 against a top of 151.70). The five lips are stepped, not jumped.
- **Route:** the crown is on no route; the arrival road passes 34 m below it. `tests/smoke_cloudreach_arrival_walk.gd`: `CLOUDREACH ARRIVAL WALK OK`.
- **CPU:** `_sheet_cpu_base_left_arm_right.jpg`, the row's Realm Gate Crag approach stand, base left, arm right: a stepped stone-and-turf rise in the middle of the lawn, in front of the far cliffs.

## To know

- Only one of the row's three frames changes (the other two are the Heartstone and Sky Shrine stands).
- An earlier attempt to capture the trainer standing on the top with `phase2_capture_locations.gd --spot` never produced a frame in three runs. The walk smoke shows the collider is sound, so that looks like the tool's spot survey, not the terrace; I did not chase it.
- The terrace is not registered with `ground_height_at` (the world's pure-math height lookup). Anything that seats itself from that lookup on this crown would sit at lawn height. Nothing is placed there today.

**13 Nov 11:50 UTC, ground registration (no visual change intended).** Each tier's turf top now registers as a ground surface (`GateCragTerrace<n>`, the circle inscribed in the tier's outline), so anything placed with `ground_height_at()` stands on the terrace. Flag-on smoke: PASS, and `ground_height_at` at the top tier returns 151.70 (top 151.70). Flag-off nothing registers.
