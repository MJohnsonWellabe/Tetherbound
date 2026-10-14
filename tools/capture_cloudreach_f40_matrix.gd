extends "res://tools/capture_lookdev_catalogue.gd"

## 12 production catalogue stands x 4 views x 4 times x 2 weather states =
## 384 frames per preset. Reuses world, traveller, camera, quality and weather
## APIs. No free camera, campaign claim, pose substitution or rendered-time skip.
const CANDIDATE_PATH := "res://data/config/cloudreach_f40_visual.json"
const P2_030_CANDIDATE_PATH := "res://data/config/creature_surface_finish_p2_030_candidate.json"
const P2_033_CANDIDATE_PATH := "res://data/config/cloudreach_pickup_readability.json"
const P2_021_CANDIDATE_PATH := "res://data/config/cloudreach_open_terrain_candidate.json"
const CHAPTER := preload("res://tools/capture_cloudreach_frame_matrix.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
var _capture_config: Dictionary = {}
var _active_weather := "clear"
var _save_fixture := ""


func _run() -> void:
	var parsed_config: Variant = JSON.parse_string(FileAccess.get_file_as_string(CANDIDATE_PATH))
	if not parsed_config is Dictionary or not parsed_config.get("capture", null) is Dictionary:
		push_error("F40 capture config is not a JSON object with a capture plan")
		quit(1)
		return
	_capture_config = parsed_config.get("capture", {}).duplicate(true)
	if not _validate_capture_config():
		quit(1)
		return
	seed(int(_capture_config.get("seed", 2042)))
	await super._run()


func _validate_capture_config() -> bool:
	var required_sets := {
		"times": ["dawn", "day", "golden", "night"],
		"weather": ["clear", "rain"],
		"views": ["approach", "gameplay", "reverse", "detail"],
	}
	for key: String in required_sets:
		var actual: Variant = _capture_config.get(key, null)
		if not actual is Array or actual != required_sets[key]:
			push_error("F40 capture plan %s must retain the complete ordered matrix: %s" % [key, str(required_sets[key])])
			return false
	if int(_capture_config.get("minimum_frames", 0)) != 384:
		push_error("F40 capture plan must require exactly 384 frames per preset")
		return false
	if int(_capture_config.get("weather_settle_frames", 0)) < 24:
		push_error("F40 capture plan must settle requested weather for at least 24 frames")
		return false
	return true


func _parse_args() -> bool:
	if not super._parse_args():
		return false
	if _biome_id != "cloudreach" or not _subsets.is_empty():
		push_error("F40 full recapture requires --biome=cloudreach and no subset")
		return false
	return true


func _prepare_character_fixture(game: Node) -> void:
	# Same disclosed upper-route fixture as the existing chapter matrix, no
	# claimed earned keys or finale victory. Every peer/durable proof is separate.
	for flag: String in CHAPTER.BOOT_FLAGS + CHAPTER.PRE_FINALE_FLAGS:
		game.get("progression").call("set_flag", flag)


func _mount_production_world() -> bool:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		_failures.append("F40 Game service unavailable")
		return false
	_save_fixture = "user://f40_capture_%s_%s/" % [
		str(Time.get_unix_time_from_system()).replace(".", "_"), OS.get_process_id()]
	game.set("save_system", SAVE.new(_save_fixture))
	_manifest["f40_isolated_save_fixture"] = _save_fixture
	return await super._mount_production_world()


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
	var seen_frame_ids := {}
	for row: Dictionary in _planned:
		var frame_id := str(row.get("frame_id", ""))
		if frame_id.is_empty() or seen_frame_ids.has(frame_id):
			_failures.append("F40 recapture plan has an empty or duplicate frame id: %s" % frame_id)
			return false
		seen_frame_ids[frame_id] = true
	var expected_count: int = destinations.size() * _capture_config.times.size() \
		* _capture_config.weather.size() * _capture_config.views.size()
	var destination_indices := {}
	for destination: Dictionary in destinations:
		destination_indices[int(destination.destination_index)] = true
	for destination_index in range(1, 13):
		if not destination_indices.has(destination_index):
			_failures.append("F40 recapture plan is missing catalogue destination %d" % destination_index)
			return false
	if destinations.size() != 12 or expected_count != 384 or _planned.size() != 384:
		_failures.append("F40 recapture plan is incomplete: %d destinations, %d planned; expected 12 and 384" % [
			destinations.size(), _planned.size()])
		return false
	return true


func _begin_manifest() -> void:
	super._begin_manifest()
	_manifest["f40_revision"] = JSON.parse_string(FileAccess.get_file_as_string(CANDIDATE_PATH)).revision
	var user_args := OS.get_cmdline_user_args()
	var f40_candidate_preview := user_args.has("--f40-candidate")
	var p2_030_candidate_preview := user_args.has("--p2-030-surface-candidate")
	var p2_021_open_terrain_preview := user_args.has("--f40-open-terrain-candidate")
	_manifest["candidate_preview"] = f40_candidate_preview or p2_030_candidate_preview or p2_021_open_terrain_preview
	_manifest["f40_visual_candidate_preview"] = f40_candidate_preview
	_manifest["p2_033_pickup_candidate_preview"] = f40_candidate_preview
	_manifest["p2_030_surface_candidate_preview"] = p2_030_candidate_preview
	_manifest["p2_021_open_terrain_candidate_preview"] = p2_021_open_terrain_preview
	_manifest["capture_plan"] = _capture_config
	_manifest["candidate_config_sha256"] = FileAccess.get_file_as_string(CANDIDATE_PATH).sha256_text()
	_manifest["p2_030_candidate_config_sha256"] = FileAccess.get_file_as_string(P2_030_CANDIDATE_PATH).sha256_text()
	_manifest["p2_033_candidate_config_sha256"] = FileAccess.get_file_as_string(P2_033_CANDIDATE_PATH).sha256_text()
	_manifest["p2_021_candidate_config_sha256"] = FileAccess.get_file_as_string(P2_021_CANDIDATE_PATH).sha256_text()
	_manifest["fixture_disclosure"] = "Direct chapter mount, isolated capture save, upper-route flags, catalogue teleports plus declared 12m/3m stand offsets, pinned production dawn/day/golden/night and clear/rain. Production CameraRig; no earned route, fight, Ally or visual PASS claim. Obstructed or unsupported stands fail and require a corrected matched pair."


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
