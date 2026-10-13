extends "res://tools/capture_lookdev_catalogue.gd"

## 12 production catalogue stands x 4 views x 4 times x 2 weather states =
## 384 frames per preset. Reuses world, traveller, camera, quality and weather
## APIs. No free camera, campaign claim, pose substitution or rendered-time skip.
## --piece=1..96 selects four contiguous views of the unchanged full plan.
## Pieces are partial evidence; F40#0 needs the complete union for both presets.
const CANDIDATE_PATH := "res://data/config/cloudreach_f40_visual.json"
const CHAPTER := preload("res://tools/capture_cloudreach_frame_matrix.gd")
const FRAMES_PER_PIECE := 4
var _capture_config: Dictionary = {}
var _active_weather := "clear"
var _piece_index := -1
var _full_frame_ids: Array[String] = []
var _full_plan_sha256 := ""


func _run() -> void:
	_capture_config = JSON.parse_string(FileAccess.get_file_as_string(CANDIDATE_PATH)).get("capture", {})
	seed(int(_capture_config.get("seed", 2042)))
	await super._run()


func _parse_args() -> bool:
	if not super._parse_args():
		return false
	if _biome_id != "cloudreach" or not _subsets.is_empty():
		push_error("F40 full recapture requires --biome=cloudreach and no subset")
		return false
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--piece="):
			var value := argument.trim_prefix("--piece=")
			if _piece_index != -1 or not value.is_valid_int() or int(value) < 1:
				push_error("F40 requires exactly one positive integer --piece")
				return false
			_piece_index = int(value) - 1
	if _piece_index == -1:
		push_error("F40 recapture requires --piece=1..N; unbounded captures are disabled")
		return false
	return true


func _prepare_character_fixture(game: Node) -> void:
	# Same disclosed upper-route fixture as the existing chapter matrix, no
	# claimed earned keys or finale victory. Every peer/durable proof is separate.
	for flag: String in CHAPTER.BOOT_FLAGS + CHAPTER.PRE_FINALE_FLAGS:
		game.get("progression").call("set_flag", flag)


func _load_plan() -> bool:
	if not super._load_plan():
		return false
	var destinations: Array[Dictionary] = []
	var seen := {}
	for row: Dictionary in _planned:
		if seen.has(row.destination_index):
			continue
		seen[row.destination_index] = true
		destinations.append(row)
	_planned.clear()
	for destination: Dictionary in destinations:
		var forward := _capture_forward(destination)
		var origin: Array = destination.position_xz
		for time_name: String in _capture_config.times:
			for weather_name: String in _capture_config.weather:
				for view: String in _capture_config.views:
					var row := destination.duplicate(true)
					row.time = time_name
					row["weather"] = weather_name
					row["view"] = view
					var offset := 0.0
					if view == "approach":
						offset = -float(_capture_config.approach_offset_m)
					elif view == "detail":
						offset = float(_capture_config.detail_offset_m)
					row.position_xz = [float(origin[0]) + forward.x * offset,
						float(origin[1]) + forward.y * offset]
					var yaw := atan2(forward.x, forward.y)
					row.view_heading_deg = rad_to_deg(yaw + (PI if view == "reverse" else 0.0))
					row.frame_id = str(destination.frame_id).trim_suffix("__" + str(destination.time)) \
						+ "__%s__%s__%s" % [view, time_name, weather_name]
					_planned.append(row)
	if _planned.size() < maxi(200, int(_capture_config.minimum_frames)):
		_failures.append("F40 recapture plan has fewer than 200 distinct frames")
		return false
	_full_plan_sha256 = JSON.stringify(_planned).sha256_text()
	var unique_ids := {}
	for row: Dictionary in _planned:
		var frame_id := str(row.frame_id)
		if unique_ids.has(frame_id):
			_failures.append("F40 full plan has a duplicate frame id: " + frame_id)
			return false
		unique_ids[frame_id] = true
		_full_frame_ids.append(frame_id)
	if _piece_index < 0 or _piece_index >= ceili(float(_planned.size()) / FRAMES_PER_PIECE):
		_failures.append("F40 piece is outside the full capture plan")
		return false
	var first := _piece_index * FRAMES_PER_PIECE
	_planned = _planned.slice(first, mini(first + FRAMES_PER_PIECE, _planned.size()))
	return true


func _begin_manifest() -> void:
	super._begin_manifest()
	_manifest["f40_revision"] = JSON.parse_string(FileAccess.get_file_as_string(CANDIDATE_PATH)).revision
	_manifest["candidate_preview"] = OS.get_cmdline_user_args().has("--f40-candidate")
	_manifest["capture_plan"] = _capture_config
	_manifest["candidate_config_sha256"] = FileAccess.get_file_as_string(CANDIDATE_PATH).sha256_text()
	_manifest["biome_look_candidate"] = not preload("res://scripts/world/cloudreach_biome_look.gd").config().is_empty()
	_manifest["biome_look_config_sha256"] = FileAccess.get_file_as_string("res://data/config/cloudreach_biome_look.json").sha256_text()
	_manifest["capture_scope"] = "partial_f40_piece"
	_manifest["piece_number"] = _piece_index + 1
	_manifest["piece_count"] = ceili(float(_full_frame_ids.size()) / FRAMES_PER_PIECE)
	_manifest["frames_per_piece"] = FRAMES_PER_PIECE
	_manifest["full_planned_frame_count"] = _full_frame_ids.size()
	_manifest["full_planned_frame_ids"] = _full_frame_ids
	_manifest["full_plan_sha256"] = _full_plan_sha256
	_manifest["piece_complete"] = false
	_manifest["fixture_disclosure"] = "Direct chapter mount, upper-route flags, catalogue teleports plus declared 12m/3m stand offsets, pinned production dawn/day/golden/night and clear/rain. Production CameraRig; no earned route, fight, Ally or visual PASS claim. Obstructed or unsupported stands fail and require a corrected matched pair."
	_manifest["fixture_disclosure"] += " Four-view bounded piece; no route/save handoff because every stand is a disclosed teleport fixture. Aggregate capture coverage requires every piece of the same source/plan/preset/candidate, without duplicate or missing frame ids."


func _finish(complete: bool) -> void:
	_manifest["capture_finished_utc"] = Time.get_datetime_string_from_system(true)
	_manifest["captured_frame_count"] = _records.size()
	_manifest["planned_frame_count"] = _planned.size()
	var observed_ids: Array[String] = []
	for row: Dictionary in _records:
		observed_ids.append(str(row.frame_id))
	var expected_ids: Array[String] = []
	for row: Dictionary in _planned:
		expected_ids.append(str(row.frame_id))
	_manifest["piece_complete"] = complete and _failures.is_empty() \
		and not _planned.is_empty() and observed_ids == expected_ids
	# An old whole-matrix consumer must never mistake four images for F40#0.
	_manifest["complete"] = false
	_write_manifest()
	for failure: String in _failures:
		push_error(failure)
	quit(0 if bool(_manifest.piece_complete) and _failures.is_empty() else 1)


func _capture_row(row: Dictionary) -> void:
	_active_weather = str(row.weather)
	var count := _records.size()
	await super._capture_row(row)
	if _records.size() == count:
		return
	var record: Dictionary = _records.back()
	record["frame_process_ms"] = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	record["frame_physics_ms"] = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	# Never count an airborne/downstairs capture as a usable upper-perch frame.
	var drawn := float(_world.call("ground_height_at", _player.global_position.x, _player.global_position.z))
	if not _player.is_on_floor() or drawn - _player.global_position.y > 3.0:
		_failures.append(str(row.frame_id) + ": trainer is unsupported or below the drawn crown")
	record["on_floor"] = _player.is_on_floor()
	record["observed_weather"] = str(_weather.call("weather")) if _weather != null else "unavailable"
	_write_manifest()


func _pin_time(time_name: String) -> Dictionary:
	var observed := await super._pin_time(time_name)
	if observed.is_empty() or _weather == null or not _weather.has_method("set_weather"):
		_failures.append("F40 production clock/weather unavailable")
		return {}
	_weather.call("set_weather", _active_weather)
	for frame in int(_capture_config.weather_settle_frames):
		await process_frame
	if str(_weather.call("weather")) != _active_weather:
		_failures.append("F40 weather request did not match observed weather")
		return {}
	observed["weather"] = _active_weather
	return observed
