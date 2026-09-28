extends "res://tools/phase2_capture_locations.gd"

## The authored Glass Sink landmark lies in a non-walkable gap. Stand on the
## Hollow Crown island and look back across the sink with the production rig.

func _load_plan() -> bool:
	if not super._load_plan() or _biome_id != "stormwood":
		return false
	var selected: Array[Dictionary] = []
	for row: Dictionary in _planned:
		if str(row.identity) != "stormwood__landmark__glass_sink":
			continue
		if str(row.time) == "night":
			continue
		row["view_heading_deg"] = 180.0
		row["stand_offsets_m"] = [175.0, 165.0] if str(row.view) == "approach" else [125.0, 115.0]
		row["stand_laterals_m"] = [0.0, -20.0, 20.0]
		row["min_camera_player_distance_m"] = 1.5
		row["camera_pitch_deg"] = -22.0
		selected.append(row)
	_planned = selected
	return not _planned.is_empty()
