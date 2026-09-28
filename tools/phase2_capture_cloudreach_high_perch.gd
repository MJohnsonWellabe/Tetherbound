extends "res://tools/capture_cloudreach_high_perch_live.gd"

## Pin randomness and constrain the installed production-camera flight pass to
## Phase 2 evidence. The parent drives arrival, landing, rim and lookback.
func _run() -> void:
	var target := ""
	var capture_seed := 2042
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			target = arg.trim_prefix("--output=")
		elif arg.begins_with("--seed="):
			capture_seed = int(arg.trim_prefix("--seed="))
	if not target.begins_with("res://ralph/reports/VISUAL/phase2/cloudreach/"):
		push_error("Cloudreach flight frames must stay in the Phase 2 report")
		quit(1)
		return
	seed(capture_seed)
	await super._run()


## The production script occasionally misses the second Jump after crossing
## the court. Keep the same walk and rig, but retry the input from a grounded
## stance so a dropped input does not omit the day departure evidence.
func _departure() -> void:
	Input.action_press("move_forward", 1.0)
	for step in 60 * 4:
		_steer(CROWN)
		await physics_frame
		if _flat(_player.global_position, CROWN) < 3.0:
			break
	for step in 60 * 5:
		_steer(NORTH_OUT)
		await physics_frame
		if _player.global_position.z - CROWN.z > 10.0:
			break
	var launched := false
	for attempt in 4:
		if _player.is_on_floor():
			await _tap("jump")
			for i in 7:
				_steer(NORTH_OUT)
				await physics_frame
		await _tap("jump")
		for i in 35:
			_steer(NORTH_OUT)
			await physics_frame
			if bool(_fly.call("is_flying")):
				launched = true
				break
		if launched:
			break
		for i in 90:
			_steer(NORTH_OUT)
			await physics_frame
			if _player.is_on_floor():
				break
	if not launched:
		Input.action_release("move_forward")
		_fail("%s departure: repeated Jump did not launch (%s)" % [_time_name, str(_fly.call("launch_blockers"))])
		return
	for i in 60:
		_steer(NORTH_OUT)
		await physics_frame
	Input.action_release("move_forward")
	Input.action_press("move_back", 1.0)
	for step in STEP_LIMIT:
		_steer(CROWN)
		await physics_frame
		if _flat(_player.global_position, CROWN) >= 35.0 or not bool(_fly.call("is_flying")):
			break
	if bool(_fly.call("is_flying")):
		await _capture("departure-lookback", CROWN)
	else:
		_fail("%s departure: the glide ended before 35 m" % _time_name)
	_release_all()
