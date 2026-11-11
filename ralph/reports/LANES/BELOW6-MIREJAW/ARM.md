STATUS: ready for GPU (High first): the Abyssal arm has returned, so two are in flight (heartwood, Thundertunnel)
ROW: F36#52 Mirejaw poses (GPU High 5.28 on main's stage; 6.70 base on the fixed stage in G-things-faint)
BRANCH: tb/below6 (config only, no import)
OVERLAY: ralph/reports/LANES/BELOW6-MIREJAW/overlay.json (`creature_clip_flags.json below6_mirejaw_hit`)
FRAMES: CAPTURE.json (capture_f36_poses.gd --species=mirejaw --whole-body --context, base and arm)

# ARM: Mirejaw grounded hit (LANE-BELOW6, 11 Nov 2026)

## Cause of the "pale translucent jaw" and the grey smear (2–3/3)
Nothing is translucent: the GLB has one opaque material. In the hit clip the body pitches so far that the head points at the floor with the jaw gaping to its pale mouth lining, and the paddle tail swings down through the stage, where its flat pale underside shows edge-on beside the trainer.

## The arm (flag OFF)
`below6_mirejaw_hit`: the hit's rotation keys scaled to 0.45 and position to 0.5, the hook that fixed Ribbonray's hit (GPU: airborne hit PARTIAL -> FIXED 3/3).

## CPU check (`_sheet_cpu.jpg`: base above, arm below; hit 000, 050, 075)
- Base 050: head down with a pale gaping jaw, tail bent down into a grey blade by the trainer.
- Arm 050: a flinch with the head up, jaw closed enough to read as a head, tail straight. No grey blade.
- Not changed by this arm: the tail still passes the trainer in every frame (stage spacing; LANE-THINGS' fixed stage clears it).
- No CPU judge batch was run.

## Expected
About +0.5 on main's stage, where the smear and jaw are named by 2–3 judges. On the fixed stage (base 6.70) the gain may be smaller; if the fixed stage lands first, judge this against it.
