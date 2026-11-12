# THINGS-SPEAKERCENTRE: the conversation shot keeps the speaker near the middle (Hess). READY, not queued.

LANE-THINGS, 12 Nov 2026. Branch `tb/things`. CPU proof: `_sheet_hess_main_vs_arm_cpu.jpg` (main left, arm right).

## Cause (G-things-convclear-meadows, on every side)
`relay_picket_hess` stands cut off at the left edge of his own shot, in profile, with a Team Tether banner down the middle of the frame and the player's hand at the right edge. The clearance rule counted the shot as clear because the trainer was out of frame; it never asked where the speaker stood.

## The arm
Flag `camera.json conversation.twoshot_v2.clearance_1112.speaker_centre` (OFF; overlay turns it on). A speaker more than half a half-frame from the centre makes the shot not clear, and the existing swing search looks for an angle with them nearer the middle (`camera_rig.gd _speaker_centre_term`). One unit test; 42 camera tests pass.

## CPU result
Hess stands left of centre in three-quarter view, face readable, whole upper body in frame; the banner is out of the picture; crates and trees behind.

## Why it is not queued
Two arms are on the GPU. Also, this term can move any conversation shot whose speaker stands off-centre, in every realm where the rule runs (not Stormwood), so it needs the whole Meadows dialogue set as its no-loss check, not one frame. I captured only Hess on CPU.

## Estimate
+0.3 to +0.5 on F38#37 or whichever row holds Hess's frame; unknown on the rest. Queue it when a slot frees.
