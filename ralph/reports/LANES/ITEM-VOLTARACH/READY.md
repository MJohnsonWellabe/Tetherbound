STATUS: ready (land; owner direction 9 Nov: "It needs 8 legs", "Use the real spider")
BRANCH: tb/item-voltarach
HEAD: see git log

# Voltarach: the real eight-legged spider (LANE-MESHY, 9 Nov)

## Cause
- The 1 Nov remake (Meshy 01a197f5, `remake_owner1101_voltarach`) is a tall hunched carapace dome whose mesh has no clean eight legs: clustering the ground contacts finds about six, and several curved gold legs never reach the ground. It rode the dog3 four-leg quadruped rig (prepare-report: legs found at 4 columns, front_lower_* only 62/66 weighted vertices), so idle and attack barely move it from rest. In the Hollows fight (alpha colourway) it reads as a pale plated armadillo.
- Blender renders (Cycles, rest/idle/attack) of the shipped remake and the native candidate are in the lane scratchpad; the native is a classic low, wide spider.

## Change
- `creature_model_flags.json remake_owner1101_voltarach` OFF with `_why_off` (owner direction). That restores species.json's native Voltarach: `assets/creatures/tetherbound/voltarach/candidate/models/creature_voltarach_native.glb`, a real eight-leg spider rig (leg_1..4 l/r, three segments each; thorax, abdomen, head) with its own clips, 4.25 m (taller than the trainer), charcoal shell, gold edges, blue facial nodes; its existing coat flags (vis1/glow2) apply. No new art, no Meshy.
- `tests/test_creature_model_flags.gd` HELD: adds the flag with the owner reason (every non-HELD remake must ship ON).
- Visibility sheet `_sheet_preview.jpg` (remake left, native right; Hollows i04/i08/i10/tell1-strike): eight legs read in every native frame.

## Follow-up (not in this change)
- The native's wider footprint moves the Hollows fight camera so trunks/foliage cover part of i08, i10 and tell1 (the existing F41 occlusion problem); worth a camera-occlusion pass, never a reframe that hides it.

## Checks
- Tests (all that grep voltarach or creature_model_flags, plus texture policy): 47 tests, 3502 assertions, 0 failed.

## Note for the coordinator
- Your queue says "re-rig at its current 4.25 m". The owner told this lane directly on 9 Nov: "It needs 8 legs", then "Use the real spider". The native model is the real eight-legged spider (your listed fallback), already at the established 4.25 m, so this lands it instead of a re-rig of the remake mesh, which has no eight clean legs to rig.
