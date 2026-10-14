extends "res://tools/capture_lookdev_catalogue.gd"

## Fixed F38 look rounds using the existing production-camera capture path.
## Run small --subset=<view id> pieces; each writes its own fresh manifest.
## --meadows-candidate is an in-memory diagnostic opt-in, never a config edit.
const CAMERA_SET := "res://tools/visual_judge/camera_sets/F38-look.json"
const SLICE_CAMERA_SET := "res://tools/visual_judge/camera_sets/F38-village-hall-slice.json"
const FINISH := preload("res://scripts/world/meadows_surface_finish.gd")
const ROUTE := preload("res://tools/capture_lookdev_route.gd")
const RASTER := preload("res://tools/meadows_capture_raster.gd")
var _fixed: Dictionary = {}
var _active_view: Dictionary = {}
var _candidate := false
var _camera_set_path := CAMERA_SET


func _load_plan() -> bool:
	if _biome_id != "meadows":
		push_error("Meadows look capture requires --biome=meadows")
		return false
	_candidate = OS.get_cmdline_user_args().has("--meadows-candidate")
	FINISH.settings()["enabled"] = _candidate
	var slice := OS.get_cmdline_user_args().has("--village-hall-slice")
	_camera_set_path = SLICE_CAMERA_SET if slice else CAMERA_SET
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_camera_set_path))
	if not parsed is Dictionary:
		return false
	_fixed = parsed
	if slice:
		var preset := str(_graphics_capture.get("preset", ""))
		if not RASTER.matches_preset(_fixed, preset, _graphics_capture.get("resolution")):
			push_error("Village/Hall slice requires Low at 1280x720 and Medium/High at 1920x1080")
			return false
	for view: Dictionary in _fixed.get("views", []):
		for time: Dictionary in _fixed.get("times", []):
			for weather: String in _fixed.get("weather", []):
				var id := "%s__%s__%s" % [view.id, time.name, weather]
				if not _matches_subset(id):
					continue
				_planned.append({"frame_id": id, "biome_id": "meadows",
					"position_xz": [view.pos[0], view.pos[2]], "view_heading_deg": view.yaw,
					"pitch": view.pitch, "fov": view.fov, "time": time.name,
					"fixed_hour": time.hour, "weather": weather})
	return not _planned.is_empty()


func _prepare_character_fixture(game: Node) -> void:
	for flag: String in ROUTE.MEADOWS_OPENING_FLAGS:
		game.get("progression").call("set_flag", flag)


func _begin_manifest() -> void:
	super._begin_manifest()
	_manifest["fixed_camera_set"] = _fixed
	_manifest["fixed_camera_path"] = _camera_set_path
	_manifest["fixed_camera_sha256"] = FileAccess.get_file_as_string(_camera_set_path).sha256_text()
	_manifest["meadows_candidate"] = _candidate
	_manifest["requested_times"] = _fixed.times.map(func(time: Dictionary) -> String: return str(time.name))
	_manifest["fixture_disclosure"] = "Debug travel to fixed trainer stands; pinned time/weather; opening modal flags from existing lookdev route fixture. Ordinary production camera/HUD. No earned route, real fight, performance or Ally claim. Candidate flag is an in-memory opt-in; source data stays OFF."


func _capture_row(row: Dictionary) -> void:
	_active_view = row
	await super._capture_row(row)


func _pin_time(time_name: String) -> Dictionary:
	if _look == null or _weather == null:
		_failures.append("Fixed look capture needs production clock and weather")
		return {}
	# Freeze before settling; the older survey lets slow frames advance time.
	_look.call("set_clock_frozen", true)
	_look.set_process(false)
	_weather.set_process(false)
	_weather.call("set_weather", str(_active_view.weather))
	_look.call("apply_time", time_name)
	_rig.set("pitch", deg_to_rad(float(_active_view.pitch)))
	_rig.rotation.x = deg_to_rad(float(_active_view.pitch))
	_camera.fov = float(_active_view.fov)
	for _frame in LIGHT_SETTLE_FRAMES:
		await physics_frame
	# Freezing weather also stops its emitter-follow/roof check. Refresh that
	# production presentation at this stand's settled camera without advancing
	# the random weather cycle or leaving rain at the previous capture stand.
	_weather.call("_follow_player")
	var hour := float(_look.call("hour"))
	if absf(_camera.fov - float(_active_view.fov)) > 0.01 \
			or absf(rad_to_deg(float(_rig.get("pitch"))) - float(_active_view.pitch)) > 0.01:
		_failures.append("Production lens changed from the fixed set at %s" % str(_active_view.frame_id))
		return {}
	if str(_weather.call("weather")) != str(_active_view.weather):
		_failures.append("Requested weather was not applied at %s" % str(_active_view.frame_id))
		return {}
	if absf(hour - float(_active_view.fixed_hour)) > 0.01:
		_failures.append("Fixed hour drifted at %s" % str(_active_view.frame_id))
		return {}
	return {"requested": time_name, "hour": hour, "weather": _active_view.weather,
		"time_of_day": str(_look.call("time_of_day")), "clock_frozen": true}
