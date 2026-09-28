extends "res://tools/phase2_capture_locations.gd"

## The debug catalogue coordinates for these elevated destinations are
## themselves walkable camera stands. Earlier surveys stepped backward from
## them into open sky. Keep the production spring-arm camera at the catalogue
## stand and record its actual compression in the engine manifest.


func _load_plan() -> bool:
	if not super._load_plan():
		return false
	if _biome_id != "cloudreach":
		return false
	var selected: Array[Dictionary] = []
	for row: Dictionary in _planned:
		var identity := str(row.identity)
		if identity == "cloudreach__broken_causeways__04__broken_skyroad_arch":
			row["stand_offsets_m"] = [0.0, -3.0, -6.0]
			# Built-floor resolution finds the lower shelf beneath this overlapping
			# cliff mesh; use the production terrain height for this camera stand.
			row["prefer_terrain_ground"] = true
		elif identity == "cloudreach__broken_causeways__03__three_bells_bridge" and str(row.view) == "approach":
			row["stand_offsets_m"] = [0.0, -5.0]
		else:
			continue
		row["stand_laterals_m"] = [0.0, 2.0, -2.0]
		row["min_camera_player_distance_m"] = 1.5
		selected.append(row)
	_planned = selected
	return not _planned.is_empty()
