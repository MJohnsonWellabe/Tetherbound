extends "res://tools/capture_lookdev_catalogue.gd"

## 12 production catalogue stands x 4 views x 4 times x 2 weather states =
## 384 frames per preset. Reuses world, traveller, camera, quality and weather
## APIs. No free camera, campaign claim, pose substitution or rendered-time skip.
## --piece=1..96 selects four contiguous views of the unchanged full plan.
## Pieces are partial evidence; F40#0 needs the complete union for both presets.
const CANDIDATE_PATH := "res://data/config/cloudreach_f40_visual.json"
const P2_030_CANDIDATE_PATH := "res://data/config/creature_surface_finish_p2_030_candidate.json"
const P2_033_CANDIDATE_PATH := "res://data/config/cloudreach_pickup_readability.json"
const P2_021_CANDIDATE_PATH := "res://data/config/cloudreach_open_terrain_candidate.json"
const CHAPTER := preload("res://tools/capture_cloudreach_frame_matrix.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const VIEW_FALLBACK := preload("res://tools/capture_view_fallback.gd")
const FRAMES_PER_PIECE := 4
var _capture_config: Dictionary = {}
var _active_weather := "clear"
var _piece_index := -1
var _piece_last := -1
var _full_frame_ids: Array[String] = []
var _full_plan_sha256 := ""
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
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--piece="):
			# --piece=N or a contiguous span --piece=N-M (one world load for
			# several pieces on a machine with the memory for it).
			var span := argument.trim_prefix("--piece=").split("-")
			if _piece_index != -1 or span.size() > 2 or not span[0].is_valid_int() or int(span[0]) < 1 \
					or not span[-1].is_valid_int() or int(span[-1]) < int(span[0]):
				push_error("F40 requires exactly one positive integer --piece or N-M span")
				return false
			_piece_index = int(span[0]) - 1
			_piece_last = int(span[-1]) - 1
	if _piece_index == -1:
		push_error("F40 recapture requires --piece=1..N; unbounded captures are disabled")
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
					row["stand_origin_xz"] = [float(origin[0]), float(origin[1])]
					row["view_offset_m"] = offset
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
	_full_plan_sha256 = JSON.stringify(_planned).sha256_text()
	for row: Dictionary in _planned:
		var frame_id := str(row.frame_id)
		_full_frame_ids.append(frame_id)
	if _piece_index < 0 or _piece_last >= ceili(float(_planned.size()) / FRAMES_PER_PIECE):
		_failures.append("F40 piece is outside the full capture plan")
		return false
	var first := _piece_index * FRAMES_PER_PIECE
	_planned = _planned.slice(first, mini((_piece_last + 1) * FRAMES_PER_PIECE, _planned.size()))
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
	_manifest["biome_look_candidate"] = not preload("res://scripts/world/cloudreach_biome_look.gd").config().is_empty()
	_manifest["biome_look_config_sha256"] = FileAccess.get_file_as_string("res://data/config/cloudreach_biome_look.json").sha256_text()
	_manifest["cliffhold_detail_candidate"] = not preload("res://scripts/world/cloudreach_cliffhold_detail.gd").config().is_empty()
	_manifest["cliffhold_detail_config_sha256"] = FileAccess.get_file_as_string("res://data/config/cloudreach_cliffhold_detail.json").sha256_text()
	_manifest["capture_scope"] = "partial_f40_piece"
	_manifest["piece_number"] = _piece_index + 1
	_manifest["piece_last"] = _piece_last + 1
	_manifest["piece_count"] = ceili(float(_full_frame_ids.size()) / FRAMES_PER_PIECE)
	_manifest["frames_per_piece"] = FRAMES_PER_PIECE
	_manifest["full_planned_frame_count"] = _full_frame_ids.size()
	_manifest["full_planned_frame_ids"] = _full_frame_ids
	_manifest["full_plan_sha256"] = _full_plan_sha256
	_manifest["piece_complete"] = false
	_manifest["fixture_disclosure"] = "Direct chapter mount, isolated capture save, upper-route flags, catalogue teleports plus declared 12m/3m stand offsets, pinned production dawn/day/golden/night and clear/rain. Production CameraRig; no earned route, fight, Ally or visual PASS claim. Obstructed or unsupported stands fail and require a corrected matched pair."
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
	if not _ground_offset_view(row):
		_failures.append("%s: no grounded, open approach/detail point within the bounded fallback" % str(row.frame_id))
		_write_manifest()
		return
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


## A fixed 12 m approach (or 3 m detail) can back off a ledge into the void,
## where the production teleport refuses it, or stand inside a wall. Step in toward the stand, then
## try small turns; the row records the offset and heading actually used.
func _ground_offset_view(row: Dictionary) -> bool:
	var offset := float(row.get("view_offset_m", 0.0))
	if is_zero_approx(offset):
		return true
	var game := root.get_node_or_null(^"Game")
	var origin := Vector2(float(row.stand_origin_xz[0]), float(row.stand_origin_xz[1]))
	var space := _world.get_world_3d().direct_space_state
	var eye := func(point: Vector2) -> Vector3:
		return Vector3(point.x, float(_world.call("ground_height_at", point.x, point.y)) + 1.6, point.y)
	# Grounded and walkable (the production teleport checks), and an open
	# eye-height line to the stand, so the view is not taken from inside a
	# wall or trunk (GPU F40 baseline: Cliffhold approach on a blank wall).
	var grounded := func(point: Vector2) -> bool:
		if is_nan(float(_world.call("ground_height_at", point.x, point.y))) or game == null \
				or not bool(game.call("_debug_teleport_walkable", _world, _player, point.x, point.y)):
			return false
		var query := PhysicsRayQueryParameters3D.create(eye.call(point), eye.call(origin))
		query.exclude = [_player.get_rid()]
		return space.intersect_ray(query).is_empty()
	var yaw := deg_to_rad(float(row.view_heading_deg))
	var chosen := VIEW_FALLBACK.resolve(origin, Vector2(sin(yaw), cos(yaw)), offset, grounded)
	if chosen.is_empty():
		return false
	if bool(chosen.fallback):
		row.position_xz = chosen.position_xz
		row.view_heading_deg = rad_to_deg(atan2(float(chosen.forward[0]), float(chosen.forward[1])))
		row["view_fallback"] = {"offset_m": chosen.offset_m, "turn_deg": chosen.turn_deg, "planned_offset_m": offset}
	return true
