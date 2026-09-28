extends "res://tools/phase2_capture_locations.gd"

## Stormwood's real Surge presentation at three representative normal-camera
## stands. The ephemeral realm clock is moved to each phase midpoint; the
## production Surge applies its settled presentation without changing saves.

const PHASES := ["calm", "building", "break", "fading"]
var _requested_phase := ""
var _motion_seconds := 0.0
var _motion_frames: Array[Dictionary] = []


func _load_plan() -> bool:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--motion-seconds="):
			_motion_seconds = clampf(float(arg.trim_prefix("--motion-seconds=")), 0.0, 20.0)
	if not super._load_plan():
		return false
	if _biome_id != "stormwood":
		push_error("Storm phase capture requires Stormwood")
		return false
	var base_rows: Array[Dictionary] = []
	var seen := {}
	for row: Dictionary in _planned:
		if str(row.time) != "day" or str(row.view) != "close":
			continue
		if "__landmark__" in str(row.identity) or seen.has(row.identity):
			continue
		seen[row.identity] = true
		base_rows.append(row)
	if base_rows.is_empty():
		return false
	# A manifest replay selects one original stand. Only the unfiltered survey
	# samples first/middle/last; narrowing it must not require three locations.
	var selected: Array[Dictionary] = base_rows
	if _subsets.is_empty() and base_rows.size() >= 3:
		selected = [base_rows[0], base_rows[int(base_rows.size() / 2)], base_rows.back()]
	_planned.clear()
	for base: Dictionary in selected:
		for phase: String in PHASES:
			var row := base.duplicate(true)
			row["phase"] = phase
			row["frame_id"] = "%s__%s" % [str(base.frame_id), phase]
			_planned.append(row)
	return true


func _capture_row(row: Dictionary) -> void:
	_requested_phase = str(row.phase)
	var before := _records.size()
	await super._capture_row(row)
	if _records.size() == before or _motion_seconds <= 0.0:
		return
	# Let the production storm run at the captured stand. No extra clock pins,
	# camera moves, lightning injection or gameplay changes between samples.
	var surge := _world.get_node(^"StormwoodSurge")
	var sample_count := int(_motion_seconds * 2.0)
	for index in sample_count:
		await create_timer(0.5).timeout
		_hide_hud()
		await RenderingServer.frame_post_draw
		var frame_id := "%s__motion_%02d" % [str(row.frame_id), index]
		var path := "%s/%s.jpg" % [_output_dir, frame_id]
		var picture := root.get_texture().get_image()
		if picture == null or picture.is_empty() or picture.save_jpg(path, 0.87) != OK:
			_failures.append("%s: motion frame save failed" % frame_id)
			continue
		_motion_frames.append({"frame_id": frame_id, "file": path,
			"parent_frame_id": row.frame_id, "sample_index": index,
			"phase_info": surge.call("phase_info_at", _player.global_position),
			"camera_position": _vec3(_camera.global_position),
			"engine_ticks_msec": Time.get_ticks_msec()})
	_manifest["motion_frames"] = _motion_frames
	_write_manifest()


func _pin_time(time_name: String) -> Dictionary:
	var clock := await super._pin_time(time_name)
	if clock.is_empty():
		return clock
	var surge := _world.get_node_or_null(^"StormwoodSurge")
	var game := root.get_node_or_null(^"Game")
	if surge == null or game == null:
		_failures.append("Stormwood Surge or Game is missing")
		return {}
	var selected := false
	for second in range(0, 2000, 5):
		var environment: Dictionary = game.get("realm_environment")
		var storm: Dictionary = environment.get("stormwood", {}).duplicate(true)
		storm["elapsed"] = float(second)
		environment["stormwood"] = storm
		game.set("realm_environment", environment)
		var info: Dictionary = surge.call("phase_info_at", _player.global_position)
		if str(info.get("phase", "")) != _requested_phase:
			continue
		storm["elapsed"] = float(second) + float(info.get("duration", 0.0)) * 0.5 - float(info.get("elapsed", 0.0))
		environment["stormwood"] = storm
		game.set("realm_environment", environment)
		selected = true
		break
	if not selected:
		_failures.append("Could not locate Surge phase %s" % _requested_phase)
		return {}
	for _frame in 3:
		await physics_frame
	surge.call("settle_presentation")
	for _frame in 5:
		await process_frame
	clock["stormwood_phase"] = str(surge.get("phase"))
	clock["stormwood_phase_info"] = surge.call("phase_info_at", _player.global_position)
	if str(clock.stormwood_phase) != _requested_phase:
		_failures.append("Surge phase mismatch: wanted %s got %s" % [_requested_phase, str(clock.stormwood_phase)])
		return {}
	return clock
