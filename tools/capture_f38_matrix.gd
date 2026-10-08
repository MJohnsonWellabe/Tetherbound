extends "res://tools/phase2_capture_locations.gd"

## Queue-only visual fixture; debug travel/time/weather, never earned evidence.
## Reuses production-camera grounding, obstruction rejection and manifests.
## Run on the SAME integrated SHA with --f38-baseline / --f38-candidate.
const F38_PLAN := "res://ralph/reports/R2-F38/capture-definition.json"
const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")
var _f38_weather := "clear"
var _f38_preset := "High"
var _f38_source := ""


func _run() -> void:
	# Retain the initialized native raster in the inherited manifest.
	await process_frame
	await super._run()


func _parse_args() -> bool:
	_biome_id = "meadows"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--f38-preset="):
			_f38_preset = arg.trim_prefix("--f38-preset=")
		elif arg.begins_with("--source-commit="):
			_f38_source = arg.trim_prefix("--source-commit=")
			if _f38_source.is_empty():
				push_error("F38 source commit cannot be empty when supplied")
				return false
	if not _f38_source.is_empty():
		var source_pattern := RegEx.new()
		source_pattern.compile("^[0-9a-f]{40}$")
		if source_pattern.search(_f38_source) == null:
			push_error("F38 source commit must be an exact SHA when supplied")
			return false
	if not ["Low", "Medium", "High"].has(_f38_preset):
		push_error("F38 preset must be Low, Medium or High")
		return false
	if not super._parse_args():
		return false
	# Process-local fixture override, never persist the owner's device setting.
	# Explicit renderer at launch must match this preset before world boot.
	GRAPHICS.load_preferences()
	GRAPHICS._base = _f38_preset
	GRAPHICS._choice = _f38_preset
	GRAPHICS._custom = {}
	if GRAPHICS.restart_required():
		push_error("F38 launch renderer does not match requested preset")
		return false
	return true


func _load_plan() -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(F38_PLAN))
	if not parsed is Dictionary:
		return false
	var index := 0
	for site: Dictionary in parsed.sites:
		index += 1
		if not _matches_subset(str(site.id).to_lower()):
			continue
		for time_name: String in _times:
			for weather_name: String in parsed.weather:
				for view: Dictionary in parsed.views:
					var heading := float(site.heading_deg) + float(view.heading_offset_deg)
					_planned.append({
						"frame_id": "%s__%s__%s__%s" % [site.id, time_name, weather_name, view.id],
						"identity": site.id, "biome_id": "meadows", "biome_display_name": "Meadows",
						"band_id": site.region, "band_display_name": site.region,
						"destination_index": index, "spot_index_in_band": index,
						"destination_display_name": site.id, "position_xz": site.at,
						"view_heading_deg": heading, "time": time_name, "view": view.id,
						"weather": weather_name, "stand_offsets_m": [float(view.offset_m)],
						"stand_laterals_m": [0.0], "preset": _f38_preset,
					})
	return not _planned.is_empty()


func _begin_manifest() -> void:
	super._begin_manifest()
	_manifest["f38_definition"] = F38_PLAN
	_manifest["source_commit"] = _f38_source
	var presentation: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/meadows_catalog_presentation.json"))
	_manifest["shipping_presentation_enabled"] = bool(presentation.get("enabled", false)) if presentation is Dictionary else false
	_manifest["preset"] = GRAPHICS.selected()
	_manifest["renderer"] = RenderingServer.get_current_rendering_method()
	_manifest["candidate"] = OS.get_cmdline_user_args().has("--f38-candidate")
	_manifest["fixture_limit"] = "Debug travel with strict fixed stands; real fight and earned F17 walk are separate required proofs. Rejected stands are missing evidence."


func _capture_row(row: Dictionary) -> void:
	_f38_weather = str(row.weather)
	var started := Time.get_ticks_msec()
	await super._capture_row(row)
	if not _records.is_empty() and _records.back().get("frame_id") == row.frame_id:
		_records.back()["capture_wall_ms"] = Time.get_ticks_msec() - started
		_records.back()["process_cpu_ms"] = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		_records.back()["physics_cpu_ms"] = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		_records.back()["timing_limit"] = "CPU monitor sample and capture wall time; neither is GPU frame-time or Ally performance acceptance."
		_write_manifest()


func _pin_time(time_name: String) -> Dictionary:
	var observed := await super._pin_time(time_name)
	if observed.is_empty():
		return observed
	if _weather == null or not _weather.has_method("set_weather"):
		_failures.append("F38 production weather unavailable")
		return {}
	_weather.set_process(true)
	_weather.set_physics_process(true)
	var weather_rng: Variant = _weather.get("_rng")
	if weather_rng is RandomNumberGenerator:
		weather_rng.seed = _seed
	_weather.call("set_weather", _f38_weather)
	for frame: int in 90:
		await physics_frame
	_weather.set_process(false)
	_weather.set_physics_process(false)
	observed["requested_weather"] = _f38_weather
	if not _weather.has_method("weather") or str(_weather.call("weather")) != _f38_weather:
		_failures.append("F38 requested weather did not bind")
		return {}
	observed["actual_weather"] = str(_weather.call("weather"))
	return observed
