extends "res://tools/capture_stormwood_surge_phases.gd"

## ACCEPTANCE §6.1 F10 / S2, the reduced-motion flash variant (X03, UX §8
## motion/flash options). Runs the Stormwood lane's own phase capture
## (`capture_stormwood_surge_phases.gd`, unchanged) with Settings ->
## Accessibility -> Reduced motion switched ON before any staging, so the
## Break telegraph and strike frames show what a reduced-motion player sees:
## the strike's local light and sky flash scaled by `flash_motion_scale`, and
## the telegraph ring's pulse held steady. Pair with a normal run of the base
## tool at the same stand and label the two for the judge.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_stormwood_reduced_motion.gd -- \
##     --out=/abs/scratch/reduced --label=reduced --only=strips --strip-phases=break
##
## Every argument is the base tool's. The only difference is the motion
## preference, which is also printed so the frames' mode is on record.

const MOTION_PREFS := preload("res://scripts/ui/motion_prefs.gd")


func _run() -> void:
	MOTION_PREFS.set_reduced_motion(true)
	print("[reduced-motion] MOTION_PREFS.reduced_motion() = %s" % str(MOTION_PREFS.reduced_motion()))
	await super._run()
