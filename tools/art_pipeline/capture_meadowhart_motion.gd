extends "res://tools/capture_visual_audit.gd"

## Native 30-second six-clip witness for the production Meadowhart body.
## Add --write-movie <path.avi> --fixed-fps 30 to the Godot invocation.
## The common --out flag selects the PNG/manifest directory.
## Direct clip playback is a neutral-stage deformation test, not a fight witness.

func _run_roster() -> void:
	await _build_stage()
	var body := _spawn_creature("meadowhart", Vector3.ZERO, -72.0)
	var size := _measured(body.get_node("Model"))
	_trainer.position = Vector3(-3.0, 0, 0)
	_frame(-3.5, 2.0, maxf(size.y, 1.8), 0.0, size.z * 0.4)
	var players := body.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		push_error("Meadowhart motion witness lacks an AnimationPlayer")
		return  # no frames: inherited _finish exits with failure
	var ap := players[0] as AnimationPlayer
	var clips: Array[String] = ["idle", "walk", "run", "attack", "hit", "faint"]
	# Check the complete plan before capturing anything: a partial screenshot
	# set must never let the common finish path report success.
	for clip: String in clips:
		if not ap.has_animation(clip):
			push_error("Meadowhart motion witness lacks clip: %s" % clip)
			return
	for clip: String in clips:
		ap.play(clip)
		for frame in 150:
			if frame > 0 and (not ap.is_playing() or ap.current_animation != clip) and clip != "faint":
				ap.play(clip)
			await process_frame
		_log_line({"kind": "motion", "clip": clip, "frames": 150, "fps": 30})
		await _shoot("%s_motion_end" % clip, {"subject": "meadowhart", "clip": clip})
