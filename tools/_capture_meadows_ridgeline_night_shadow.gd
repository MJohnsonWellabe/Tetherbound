extends "res://tools/catalogue_survey.gd"

## Standard Ridgeline Watch pair with live Meadows lighting telemetry.
## Camera, travel, clear-weather pinning, clock pinning, HUD, and frame capture
## remain inherited from the production catalogue survey.

const TOOL_PATH := "res://tools/_capture_meadows_ridgeline_night_shadow.gd"


func _parse_args() -> bool:
	if not super._parse_args():
		return false
	if _biome_id != "meadows":
		push_error("Meadows night-shadow capture requires --biome=meadows")
		return false
	return true


func _load_plan() -> bool:
	if not super._load_plan():
		return false
	if _planned.size() != 2:
		push_error("Meadows night-shadow capture requires --subset=ridgeline_watch with day,night")
		return false
	for row: Dictionary in _planned:
		if "ridgeline_watch" not in str(row.get("frame_id", "")):
			push_error("Meadows night-shadow capture selected a non-Ridgeline-Watch frame")
			return false
	return true


func _write_manifest() -> void:
	_manifest["capture_tool"] = {
		"path": TOOL_PATH,
		"sha256": FileAccess.get_file_as_string(TOOL_PATH).sha256_text(),
	}
	if _world != null:
		var sun := _world.get_node_or_null(^"Sun") as DirectionalLight3D
		for index in _records.size():
			var record: Dictionary = _records[index]
			if record.has("meadows_lighting"):
				continue
			record["meadows_lighting"] = {
				"weather": str(_weather.call("weather")) if _weather != null and _weather.has_method("weather") else "",
				"world_look_time": str(_look.call("time_of_day")) if _look != null and _look.has_method("time_of_day") else "",
				"world_look_hour": float(_look.call("hour")) if _look != null and _look.has_method("hour") else null,
				"sun_shadow_opacity": sun.shadow_opacity if sun != null else null,
				"observed_after_frame_capture": true,
			}
			_records[index] = record
	super._write_manifest()
