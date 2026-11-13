# LANE-BEINGS NOTE (branch `tb/beings`; this file is the channel)

## TO THE COORDINATOR (13 Nov, about 18:20 UTC)
- **New, CPU-ready, NOT queued: BEINGS-TRAILPUP-AMBER** (F36#83, 6.53): the owner-picked amber paws and eyes on the live coyote. Coat flag plus two derived textures, flag-off. Take it when a slot frees; I would put it after the pose batch and ahead of the three held arms.
- **Still please relay to the GPU lane:** the hit half of BEINGS-STORMRAVEN-WINGS does have a reader at 9c1bb38bc, `scripts/creatures/creature_pose_settle.gd` line 652 inside `settle_hit`. No fix needed; 9c1bb38bc is the right head.
- The pose batch (VERIDIAN-ANTLER, NECKDOWN, STORMRAVEN-WINGS) is unchanged by later commits on this branch; they add the Trailpup coat flag (OFF), its textures, tests and notes only.

## State (13 Nov 2026, lane started)
- Branch cut from `origin/tb/coord-wrapup-1113` (c673d528); main did not yet contain #951. Merge `origin/main` once it lands.
- Criteria closed: zero. Landed on main: nothing yet.

## Arms waiting on the GPU
The limit is two, and I inherited four. My order, for the coordinator to confirm or change:
1. **BEINGS-VERIDIAN-ANTLER** (F36#85, 6.33). Cause confirmed by probe; the fix is plainly visible on CPU.
2. **BEINGS-NECKDOWN** (F36#46 5.70, F36#88 6.32). Replaces BELOW6-FULGOCOBRA-FAINT, which had not been captured: the same Fulgocobra change plus the Water Abyssal Guardian's neck, one overlay, no new code.
3. Held until a slot frees: BELOW6-AQUARYN-RIDE (F39#8), BELOW6-STATICUB-FUR (F41#8, F41#18), BELOW6-UNIFORM-CLOTH (F41#18).

## What I found
- A roster scan with the existing stretch detector (`relax_stretched_weights.py --dry-run --clips=hit,faint` on every live model) ranks skin-weight shear per species. Veridian was the one where it draws the named defect. Table in `BEINGS-VERIDIAN-ANTLER/ARM.md`.
- Glimmermoth and Tempestwing wings and Mosshock spikes have no bones of their own; weight fixes do not change what the judges see. Their "appendage stays up" faint needs a different approach (see Next).
- A copied `owner1101` GLB re-extracts its embedded textures under the new name and loses the graded coat (Mosshock came out darker). A copy of a `nat1024` GLB does not. Check the albedo path in a test when copying a model.

## Tried and dropped
- **Stormraven, skin weights and tail pitch:** both ruled out before the real cause was found (details in `BEINGS-STORMRAVEN-WINGS/ARM.md`).
- **Glimmermoth, Tempestwing, Mosshock weight relax:** no visible change; removed.

## Next
- F38#2 and F38#1 (6.35, 6.58): read their latest panels for a shared cause.
- Stormraven faint end: find what the remaining low fan is.
- Other folded-wing meshes may share Stormraven's cause (clips swinging wing bones on a folded mesh): check Duskhush, Pipwing, Reedwing, Aeriex with the same clip read-out before building anything.

## Runbook additions
- Fresh checkout: `godot --headless --path . --import` takes about 25 minutes.
- `capture_f36_poses.gd` refuses an existing output folder; six species, two roles: 48 s on CPU.
- Bone and weight probes used here are throwaway scripts that extend `tools/_capture_creature_roster.gd`; they need `await process_frame`, then `_world = Node3D.new(); root.add_child(_world)` before `_spawn_creature`.
