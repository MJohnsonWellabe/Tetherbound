extends "res://tools/catalogue_survey.gd"

## Standard catalogue Crown Overlook pair with realm-local lighting telemetry.
## Camera, travel, clock pinning, HUD, and frame capture remain inherited.

const TOOL_PATH := "res://tools/_capture_stormwood_shadow_contract.gd"


func _parse_args() -> bool:
	if not super._parse_args():
		return false
	if _biome_id != "stormwood":
		push_error("Stormwood shadow capture requires --biome=stormwood")
		return false
	return true


func _load_plan() -> bool:
	if not super._load_plan():
		return false
	if _planned.size() != 2:
		push_error("Stormwood shadow capture requires --subset=crown_overlook with day,night")
		return false
	for row: Dictionary in _planned:
		if "crown_overlook" not in str(row.get("frame_id", "")):
			push_error("Stormwood shadow capture selected a non-Crown-Overlook frame")
			return false
	return true


func _write_manifest() -> void:
	_manifest["capture_tool"] = {
		"path": TOOL_PATH,
		"sha256": FileAccess.get_file_as_string(TOOL_PATH).sha256_text(),
	}
	if _world != null:
		var surge := _world.get_node_or_null(^"StormwoodSurge")
		var sun := _world.get_node_or_null(^"Sun") as DirectionalLight3D
		for index in _records.size():
			var record: Dictionary = _records[index]
			if record.has("stormwood_lighting"):
				continue
			record["stormwood_lighting"] = {
				"phase": str(surge.get("phase")) if surge != null else "",
				"sun_shadow_opacity": sun.shadow_opacity if sun != null else null,
				"observed_after_frame_capture": true,
			}
			_records[index] = record
	super._write_manifest()
