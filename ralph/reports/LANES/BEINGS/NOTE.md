# LANE-BEINGS NOTE (branch `tb/beings`; this file is the channel)

## TO THE COORDINATOR (13 Nov, about 16:50 UTC)
- main 4f9ee396 is merged; `tb/beings` head is this commit.
- **BEINGS-VERIDIAN-ANTLER** (F36#85): thanks, noted as queued.
- **BEINGS-NECKDOWN** (F36#46, F36#88): ready. It **replaces BELOW6-FULGOCOBRA-FAINT**; please capture only the new one. Overlay only, over code already on main.
- That makes two of mine waiting. Held until a slot frees, in this order unless you prefer another: BELOW6-AQUARYN-RIDE, BELOW6-STATICUB-FUR, BELOW6-UNIFORM-CLOTH.
- I start no new arm while two are waiting. Meanwhile I am finding the cause of the Stormraven slab (F36#74) and reading the F38#1 / F38#2 panels.

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
- **Stormraven tail slab (F36#74), one failure.** I took the cause to be skin weights: 2555 of 4103 tail-region vertices are weighted to both the tail and the wing tips. A copy with the tail freed of wing weight still showed the slab on CPU, and stretch got worse (118 to 382 triangles). So that is not what draws it. Tail end pitches of plus and minus 45 degrees only tilt the slab. Copy and flag removed. Not yet known: what the slab is. Next probe would be a second camera angle on hit-050 before any change.

## Next
- Stormraven: find what the slab is (above) before building.
- Trailpup (F36#83, 6.53): judges 3/3 say the owner-picked amber paws and eyes are missing.
- F38#2 and F38#1 (6.35, 6.58): read their latest panels for a shared cause.

## Runbook additions
- Fresh checkout: `godot --headless --path . --import` takes about 25 minutes.
- `capture_f36_poses.gd` refuses an existing output folder; six species, two roles: 48 s on CPU.
- Bone and weight probes used here are throwaway scripts that extend `tools/_capture_creature_roster.gd`; they need `await process_frame`, then `_world = Node3D.new(); root.add_child(_world)` before `_spawn_creature`.
