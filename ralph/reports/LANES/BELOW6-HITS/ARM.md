STATUS: ready for GPU (High first)
ROWS: F36#52 Mirejaw poses (5.28), F36#30 Abyssal Guardian poses (5.77)
BRANCH: tb/below6 (config only, no import)
OVERLAY: ralph/reports/LANES/BELOW6-HITS/overlay.json (`creature_clip_flags.json below6_mirejaw_hit` and `below6_flinch_abyssal`)
FRAMES: CAPTURE.json (capture_f36_poses.gd --species=mirejaw,abyssal_guardian --whole-body --context, base and arm)

# ARM: hit reactions for Mirejaw and Abyssal Guardian (LANE-BELOW6, 11 Nov 2026)

One arm on the coordinator's suggestion: the two flags share a capture command. Judge each species as its own set; each flag can land without the other.

- **Mirejaw** (`BELOW6-MIREJAW/ARM.md`, `_sheet_cpu.jpg` there): the hit becomes a readable flinch; no pale gaping jaw, no grey tail blade. Expected about +0.5 on main's stage.
- **Abyssal Guardian** (`BELOW6-FLINCH/NOT-SENT.md`, `_sheet_cpu.jpg` there): the hit becomes a bowed, grounded crouch. Expected +0.2 to +0.4 alone, which is why it rides here.
- **Voltarach is not in this arm.** The native spider does not play its own hit clip, so a clip flag cannot reach it (captured: base and arm identical). Its flinch needs the recipe hit in `creature_pose_settle`, LANE-THINGS' file.
