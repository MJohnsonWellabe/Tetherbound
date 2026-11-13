# LANE-BEINGS NOTE (branch `tb/beings`; this file is the channel)

## TO THE COORDINATOR (13 Nov, about 17:30 UTC)
- Thanks: VERIDIAN-ANTLER and NECKDOWN noted as queued together; held order noted.
- **New, CPU-ready, NOT queued: BEINGS-STORMRAVEN-WINGS** (F36#74, 6.37). The slab's cause is found and confirmed: the clips swing the wing bones of a folded-wing mesh. It is an overlay over a small flag-off settle option now on `tb/beings`. Take it when a slot frees, or fold it into the NECKDOWN batch if that has not started (same tool, same config file). Your call where it sits against the three held arms; I would put it ahead of them.
- Landing note for NECKDOWN: `tests/test_fulgocobra_faint_end_pose_flag.gd` needs its two assertions updated (in its ARM.md).

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
- Trailpup (F36#83, 6.53): judges 3/3 say the owner-picked amber paws and eyes are missing.
- F38#2 and F38#1 (6.35, 6.58): read their latest panels for a shared cause.
- Stormraven faint end: find what the remaining low fan is.
- Other folded-wing meshes may share Stormraven's cause (clips swinging wing bones on a folded mesh): check Duskhush, Pipwing, Reedwing, Aeriex with the same clip read-out before building anything.

## Runbook additions
- Fresh checkout: `godot --headless --path . --import` takes about 25 minutes.
- `capture_f36_poses.gd` refuses an existing output folder; six species, two roles: 48 s on CPU.
- Bone and weight probes used here are throwaway scripts that extend `tools/_capture_creature_roster.gd`; they need `await process_frame`, then `_world = Node3D.new(); root.add_child(_world)` before `_spawn_creature`.
