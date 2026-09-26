extends "res://tools/capture_stormwood_reduced_motion.gd"

## F10#3 witness (STORMWOOD-B): readable lightning (1.2 s telegraph, 3 m) and
## Surge phase cues without HUD, at a day hour (12) and a night hour (0), under
## --motion=normal|reduced. Production CameraRig/Camera3D following the real
## Player at the base tool's strip stand, HUD CanvasLayers hidden.
## Per hour: one settled frame per phase, then in Break ONE staged strike
## played through StormwoodLightning._receive (client path, same events the
## host publishes; presentation only) 7 m ahead of the camera, captured at
## 0.3 s and 0.8 s of the 1.2 s warning and 2 frames after impact.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://ralph/reports/STORMWOOD/b/f10_3/capture_f10_3.gd -- \
##     --motion=normal --out=/abs/scratch/normal --label=normal --only=quick

var _strike_seq := 0
## --hours=12,0 (default both); --tick-cap=N physics ticks per rendered frame
## during the warning (default 1 = exact tick timing; 4 trades up to ~8 ticks
## of capture drift for a 4x faster software-GL run; drift is recorded).
var _hours: Array[float] = [12.0, 0.0]
var _tick_cap := 1


func _quick() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--hours="):
			_hours.clear()
			for part: String in arg.trim_prefix("--hours=").split(",", false):
				_hours.append(float(part))
		elif arg.begins_with("--tick-cap="):
			_tick_cap = int(arg.trim_prefix("--tick-cap="))
	for hour: float in _hours:
		_set_hour(hour)
		await _stand(STAND, _station_focus(), 2.0)
		var tag := "h%02d" % int(hour)
		for phase: String in PHASES:
			await _enter_phase(phase, false)
			for _frame in 20:
				await physics_frame
			_heal()
			await _capture("%s_%s_%s" % [_motion_mode, tag, phase], "%s at world hour %d (motion=%s)" % [phase, int(hour), _motion_mode], false,
				{"world_hour": float(_look.call("hour")), "motion_mode": _motion_mode})
		await _enter_phase("break", false)
		await _staged_strike(tag)


func _staged_strike(tag: String) -> void:
	_strike_seq += 1
	var forward := -_camera.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var at := _camera.global_position + forward * STAGED_STRIKE_M
	at.y = _floor_at(at.x, at.z) + 0.08
	_fine(_tick_cap)
	_heal()
	var id := STAGED_STRIKE_ID + _strike_seq
	_note("staged strike via StormwoodLightning._receive, %.0f m ahead of camera" % STAGED_STRIKE_M)
	_lightning.call("_receive", {"id": id, "kind": "warning", "at": at})
	var ticks := 0
	var t_warn := _surge_elapsed()
	for mark: Array in [[18, "t030"], [48, "t080"]]:
		while ticks < int(mark[0]):
			await physics_frame
			ticks += 1
		await _capture("%s_%s_telegraph_%s" % [_motion_mode, tag, mark[1]], "Break staged strike warning at %d/72 ticks of 1.2 s (motion=%s)" % [ticks, _motion_mode], true,
			{"motion_mode": _motion_mode, "strike_at": [at.x, at.y, at.z], "ticks_into_warning": ticks, "surge_s_into_warning_at_grab": snappedf(_surge_elapsed() - t_warn, 0.01), "world_hour": float(_look.call("hour"))})
		ticks = maxi(ticks + 2, int(round((_surge_elapsed() - t_warn) * 60.0)))
	while ticks < 72:
		await physics_frame
		ticks += 1
	_lightning.call("_receive", {"id": id, "kind": "impact", "at": at, "hits": {}})
	for _frame in 2:
		await process_frame
	await _capture("%s_%s_impact" % [_motion_mode, tag], "Break staged strike, two frames after impact (motion=%s)" % _motion_mode, true,
		{"motion_mode": _motion_mode, "strike_at": [at.x, at.y, at.z], "world_hour": float(_look.call("hour"))})
	for _tick in 90:
		await physics_frame
	_coarse()
