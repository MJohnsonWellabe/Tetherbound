# LANE-BEINGS NOTE (branch `tb/beings`; this file is the channel)

## State (13 Nov 2026, lane started)
- Branch cut from `origin/tb/coord-wrapup-1113` (c673d528); main did not yet contain #951. Merge `origin/main` once it lands.
- Criteria closed: zero. Landed on main: nothing yet.

## Arms waiting on the GPU
The limit is two, and I inherited four. My order, for the coordinator to confirm or change:
1. **BEINGS-VERIDIAN-ANTLER** (F36#85, 6.33). New. Cause confirmed by probe; the fix is plainly visible on CPU.
2. **BELOW6-FULGOCOBRA-FAINT** (F36#46, 5.70). Inherited; the lowest creature row.
3. Held behind those two until a slot frees: BELOW6-AQUARYN-RIDE (F39#8), BELOW6-STATICUB-FUR (F41#8, F41#18), BELOW6-UNIFORM-CLOTH (F41#18).

## What I found
- A roster scan with the existing stretch detector (`relax_stretched_weights.py --dry-run --clips=hit,faint` on every live model) ranks skin-weight shear per species. Veridian was the one where it draws the named defect. Table in `BEINGS-VERIDIAN-ANTLER/ARM.md`.
- Glimmermoth and Tempestwing wings and Mosshock spikes have no bones of their own; weight fixes do not change what the judges see. Their "appendage stays up" faint needs a different approach (see Next).
- A copied `owner1101` GLB re-extracts its embedded textures under the new name and loses the graded coat (Mosshock came out darker). A copy of a `nat1024` GLB does not. Check the albedo path in a test when copying a model.

## Next
- Stormraven tail fan (F36#74, 6.37): it stands up as a slab in hit and faint ("rigid flat slab", 3/3). The rig has `tail_1`/`tail_2`, so stated end pitches (`faint.end_pose`, already in the settle code) can lay it down. Fold into the Fulgocobra faint arm as one "appendage down" arm if the coordinator agrees, since that arm has not been captured.
- Water Abyssal Guardian neck up in the faint (F36#88, 6.32): it has `neck`/`head` bones and is excluded from the settle; same end-pose approach.
- Trailpup (F36#83): judges 3/3 say the owner-picked amber paws and eyes are missing.

## Runbook additions
- Fresh checkout: `godot --headless --path . --import` takes about 25 minutes.
- `capture_f36_poses.gd` refuses an existing output folder; six species, two roles: 48 s on CPU.
- Bone and weight probes used here are throwaway scripts that extend `tools/_capture_creature_roster.gd`; they need `await process_frame`, then `_world = Node3D.new(); root.add_child(_world)` before `_spawn_creature`.
