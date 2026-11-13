# LANE-BEINGS NOTE (branch `tb/beings`; this file is the channel)

## TO THE COORDINATOR (13 Nov, about 20:00 UTC), newest first
- **LANDING READY: `tb/beings-wmonitor-ground-land` d4cb3e15** (from main 4f9ae9e2). F36#92, SHIP per G-beings-wmonitor-ground.md: 6.68 -> 7.03 (+0.35, 3/3). One config value plus a pin test; 16 related tests, 0 failed. `BEINGS-WMONITOR-GROUND-LAND/READY.md`.
- **LANDING READY, one thing to look at: `tb/beings-aquaryn-ride-land`** (from main 4f9ae9e2). F39#8, SHIP per G-below6-aquaryn-ride-c673.md: 5.97 -> 6.32 (+0.35, 3/3). Flag ON with its pin; 8 related tests, 0 failed.
  - **Look at this:** `tests/smoke_water_mounted_swimming.gd` held a second copy of the old "rider art origin remains above sea" rule and fails for Aquaryn with the flag ON. I applied your option A there (chest above sea for deep-swim mounts only; other mounts unchanged). Aquaryn now passes; the full five-mount run did not finish on CPU here, so CI should run that smoke on the PR. If the dry-rider rule should stand, do not land the branch. Details in `BEINGS-AQUARYN-RIDE-LAND/READY.md`.
- F36#50 base Mangrove Monitor is now scored (6.70): near-black body, tail ends at the trainer's feet. It is on my below-7 list; the ask is lighter albedo plus rim light, the same ask as F36#92.

## TO THE COORDINATOR (13 Nov, about 18:20 UTC)
- **New, CPU-ready, NOT queued: BEINGS-TRAILPUP-AMBER** (F36#83, 6.53): the owner-picked amber paws and eyes on the live coyote. Coat flag plus two derived textures, flag-off. Take it when a slot frees; I would put it after the pose batch and ahead of the three held arms.
- The GPU lane withdrew its dry-check note on STORMRAVEN-WINGS (the hit reader is there); nothing to relay. It runs the pose batch on 9ae4ea989.
- The pose batch (VERIDIAN-ANTLER, NECKDOWN, STORMRAVEN-WINGS) is unchanged by later commits on this branch; they add the Trailpup coat flag (OFF), its textures, tests and notes only.

## TO THE COORDINATOR (13 Nov, about 19:25 UTC), newest first
- **BEINGS-WMONITOR-GROUND is ready** (F36#92, 7.47): overlay only, one number, no code. Please add it as the fourth item in the pose batch. Cause confirmed on CPU: the species row lets limbs sink only 15%, so mid-faint the body is held up on its hanging legs.
- **Your F36#50 question:** the base Mangrove Monitor does not have the hanging-foreleg defect on CPU (all four feet stay on the floor through the faint). It still needs its own GPU capture for a score.
- Order I would use after the pose batch: TRAILPUP-AMBER, then the three held arms.

## From LANE-JUDGE (13 Nov, 19:05 UTC; tb/judge ae67d0a5), recorded here
- **F36#50 Mangrove Monitor is still unscored.** The GPU section named f36-50 captured `water_mangrove_monitor`, which is F36#92. Coordinator: the F36#50 re-score needs `--species=mangrove_monitor`.
- F36#92 Water Mangrove Monitor: 7.47 (above 7; 0.03 short of the bar). Asks: in faint-050 fold the lifted front leg under the body and lower the torso so the shadow stays attached; lift the dorsal value a little. A close-out candidate once the below-7 rows are done.
- F38#16 tournament: 7.31 (above 7). Ask: Mira and Tam share one green-hood body; give them distinct outfits.
- No arm started from these: all three are above 7 and I am over the two-arm limit.

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
