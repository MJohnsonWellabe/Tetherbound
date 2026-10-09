extends "res://tools/capture_lookdev_catalogue.gd"

## 12 production catalogue stands x 4 views x 4 times x 2 weather states =
## 384 frames per preset. Reuses world, traveller, camera, quality and weather
## APIs. No free camera, campaign claim, pose substitution or rendered-time skip.
const CANDIDATE_PATH := "res://data/config/cloudreach_f40_visual.json"
const CHAPTER := preload("res://tools/capture_cloudreach_frame_matrix.gd")
var _capture_config: Dictionary = {}
var _active_weather := "clear"
var _segment := ""
var _full_planned_frames := 0
var _stormward_approach_only := false
var _cliffhold_interior_only := false


func _run() -> void:
	_capture_config = JSON.parse_string(FileAccess.get_file_as_string(CANDIDATE_PATH)).get("capture", {})
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--cliffhold-interior-only":
			if _cliffhold_interior_only:
				push_error("F40 accepts one Cliffhold interior selector")
				quit(2)
				return
			_cliffhold_interior_only = true
		if arg == "--stormward-approach-only":
			if _stormward_approach_only:
				push_error("F40 accepts one Stormward approach repair selector")
				quit(2)
				return
			_stormward_approach_only = true
		if arg.begins_with("--segment="):
			if not _segment.is_empty() or arg.trim_prefix("--segment=") not in ["dawn", "day", "golden", "night"]:
				push_error("F40 requires one known clock segment, or none for the full matrix")
				quit(2)
				return
			_segment = arg.trim_prefix("--segment=")
	if _cliffhold_interior_only and (_stormward_approach_only or not _segment.is_empty()):
		push_error("F40 Cliffhold interior selector cannot combine with a quarter or Stormward repair")
		quit(2)
		return
	seed(int(_capture_config.get("seed", 2042)))
	await super._run()


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
					# A look bearing is not a walkable route bearing. Narrow
					# authored thresholds rejected the generic backwards offset;
					# Skyroad's old catalogue stand also missed its flat crown.
					# Use disclosed route/pad stands for both sides of a matched
					# pair; travel, on-floor and obstruction checks still apply.
					var authored: Dictionary = _capture_config.get("authored_stands", {}).get(
						_slug(str(destination.destination_display_name)), {}).get(view, {})
					if not authored.is_empty():
						var at: Variant = authored.get("position_xz")
						var bearing: Variant = authored.get("view_heading_deg")
						if not at is Array or at.size() != 2 \
								or typeof(at[0]) not in [TYPE_INT, TYPE_FLOAT] \
								or typeof(at[1]) not in [TYPE_INT, TYPE_FLOAT] \
								or typeof(bearing) not in [TYPE_INT, TYPE_FLOAT] \
								or not is_finite(float(at[0])) or not is_finite(float(at[1])) \
								or not is_finite(float(bearing)) or str(authored.get("basis", "")).is_empty():
							_failures.append("F40 invalid authored stand: %s/%s" % [destination.destination_display_name, view])
							return false
						row.position_xz = at.duplicate()
						row.view_heading_deg = float(bearing)
						row["authored_stand_basis"] = str(authored.basis)
					row.frame_id = str(destination.frame_id).trim_suffix("__" + str(destination.time)) \
						+ "__%s__%s__%s" % [view, time_name, weather_name]
					_planned.append(row)
	if _planned.size() < int(_capture_config.minimum_frames):
		_failures.append("F40 recapture plan has fewer than 200 distinct frames")
		return false
	_full_planned_frames = _planned.size()
	# Hosted quarters preserve the whole plan above. Every clock quarter is
	# required; a successful quarter never certifies the >=200-frame recapture.
	if not _segment.is_empty():
		var selected: Array[Dictionary] = []
		for row: Dictionary in _planned:
			if str(row.time) == _segment:
				selected.append(row)
		if selected.is_empty() or selected.size() * _capture_config.times.size() != _full_planned_frames:
			_failures.append("F40 segment does not contain a complete clock quarter")
			return false
		_planned = selected
	if _stormward_approach_only:
		var repair_rows: Array[Dictionary] = []
		for row: Dictionary in _planned:
			if _slug(str(row.destination_display_name)) == "stormward_overlook" and str(row.view) == "approach":
				repair_rows.append(row)
		var required_rows: int = _capture_config.weather.size() * (1 if not _segment.is_empty() else _capture_config.times.size())
		if repair_rows.is_empty() or repair_rows.size() != required_rows:
			_failures.append("F40 Stormward repair lacks every requested clock/weather approach")
			return false
		_planned = repair_rows
	if _cliffhold_interior_only:
		var interior_rows: Array[Dictionary] = []
		for row: Dictionary in _planned:
			if _slug(str(row.destination_display_name)) == "cliffhold" and str(row.view) == "approach" \
					and str(row.time) == "day" and str(row.weather) == "clear":
				interior_rows.append(row)
		if interior_rows.size() != 1:
			_failures.append("F40 Cliffhold interior selection requires exactly the original approach/day/clear row")
			return false
		_planned = interior_rows
	return true


func _begin_manifest() -> void:
	super._begin_manifest()
	_manifest["f40_revision"] = JSON.parse_string(FileAccess.get_file_as_string(CANDIDATE_PATH)).revision
	_manifest["candidate_preview"] = OS.get_cmdline_user_args().has("--f40-candidate")
	_manifest["capture_plan"] = _capture_config
	_manifest["segment"] = _segment
	_manifest["stormward_approach_only"] = _stormward_approach_only
	_manifest["cliffhold_interior_only"] = _cliffhold_interior_only
	_manifest["selected_frame_ids"] = _planned.map(func(row: Dictionary) -> String: return str(row.frame_id))
	_manifest["capture_scope"] = "Original full matrix or declared clock quarter"
	if _stormward_approach_only:
		_manifest["capture_scope"] = "Stormward approach repair only; no full-matrix claim"
	if _cliffhold_interior_only:
		_manifest["capture_scope"] = "Cliffhold original approach/day/clear interior picture only; no arrival or full-matrix claim"
	_manifest["required_segments"] = _capture_config.times
	_manifest["full_matrix_planned_frames"] = _full_planned_frames
	_manifest["candidate_config_sha256"] = FileAccess.get_file_as_string(CANDIDATE_PATH).sha256_text()
	_manifest["fixture_disclosure"] = "Direct chapter mount, upper-route flags, catalogue teleports with default 12m/3m offsets except explicitly declared existing route/threshold stands in capture_plan.authored_stands (all Skyroad views use its flat crown); pinned production dawn/day/golden/night and clear/rain. Both sides of a comparison must use the same stand plan. Production CameraRig; no earned route, fight, Ally or visual PASS claim. Obstructed or unsupported stands still fail."


func _finish(complete: bool) -> void:
	_manifest["full_matrix_complete"] = _segment.is_empty() and not _stormward_approach_only and not _cliffhold_interior_only and complete and _failures.is_empty() \
		and _records.size() == _full_planned_frames
	super._finish(complete)


func _prepare_capture_shell() -> bool:
	if not super._prepare_capture_shell():
		return false
	if _weather == null or not _weather.has_method("set_weather") or not _weather.has_method("weather"):
		_failures.append("F40 production visual weather runtime unavailable before matrix")
		return false
	_manifest["weather_scope"] = "Production visual weather API, pinned fixture; no canonical encounter weather or earned travel claim"
	return true


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
