extends "res://tools/capture_stormwood_surge_phases.gd"

## ACCEPTANCE §6.1 F10 / S2, the reduced-motion flash variant (X03, UX §8
## motion/flash options). Runs the Stormwood lane's own phase capture
## (`capture_stormwood_surge_phases.gd`, unchanged) with Settings ->
## Accessibility -> Reduced motion set before any staging, so the Break frames
## show what that player sees: the strike's local light and sky flash scaled
## by `flash_motion_scale`, and the telegraph ring's pulse held steady.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_stormwood_reduced_motion.gd -- \
##     --motion=reduced --out=/abs/scratch/reduced --label=reduced \
##     --only=strips --strip-phases=break
##
## `--motion=normal|reduced` (default reduced) picks the preference, so both
## halves of the comparison run through this same script. Every other
## argument is the base tool's.
##
## STAGED STRIKE (disclosed): the base tool waits up to 100 s of Break for a
## natural strike near its stand, and in practice none lands there (both
## 2026-09-26 runs recorded "no strike telegraph within 100 s"). After the
## Break strip this script instead plays ONE strike through the lightning
## node's own client path (`_receive` with the same warning and impact events
## the host publishes) on open ground 7 m in front of the player camera, so
## the normal and reduced runs show the identical strike. It never touches
## combat, damage or the host schedule; it is a presentation witness only.

const MOTION_PREFS := preload("res://scripts/ui/motion_prefs.gd")
const STAGED_STRIKE_M := 7.0
const STAGED_STRIKE_ID := 900001

var _motion_mode := "reduced"


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--motion="):
			_motion_mode = arg.trim_prefix("--motion=")
	MOTION_PREFS.set_reduced_motion(_motion_mode == "reduced")
	print("[reduced-motion] mode=%s MOTION_PREFS.reduced_motion() = %s" % [
		_motion_mode, str(MOTION_PREFS.reduced_motion())])
	await super._run()


func _break_events(_start: float) -> void:
	if _lightning == null or not _lightning.has_method("_receive"):
		_frames.append({"id": "staged_strike", "missing": "no StormwoodLightning._receive in this build"})
		return
	_note("staged strike: one warning+impact pair through StormwoodLightning._receive, %.0f m ahead of the camera (motion=%s)" % [STAGED_STRIKE_M, _motion_mode])
	var forward := -_camera.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var at := _camera.global_position + forward * STAGED_STRIKE_M
	at.y = _floor_at(at.x, at.z) + 0.08
	_fine(1)
	_heal()
	_lightning.call("_receive", {"id": STAGED_STRIKE_ID, "kind": "warning", "at": at})
	# Half-way through the 1.2 s telegraph: the ring is on the ground and
	# (under normal motion) pulsing.
	for _tick in 36:
		await physics_frame
	await _capture("staged_telegraph", "Break: staged strike telegraph ring, 0.6 s into its 1.2 s warning (motion=%s)" % _motion_mode, true,
		{"motion_mode": _motion_mode, "strike_at": [at.x, at.y, at.z]})
	for _tick in 36:
		await physics_frame
	_lightning.call("_receive", {"id": STAGED_STRIKE_ID, "kind": "impact", "at": at, "hits": {}})
	for _frame in 2:
		await process_frame
	await _capture("staged_flash", "Break: the staged strike's impact flash, two frames after impact (motion=%s)" % _motion_mode, true,
		{"motion_mode": _motion_mode, "strike_at": [at.x, at.y, at.z]})
	_coarse()
