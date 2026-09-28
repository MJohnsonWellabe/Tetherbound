extends "res://tools/phase2_capture_dialogue.gd"

## Four ordinary production-rig approaches around Iven's mounted post. The
## existing catalogue angle hides the character behind the house corner.
func _load_plan() -> bool:
	if not super._load_plan() or _biome_id != "cloudreach":
		return false
	var selected: Array[Dictionary] = []
	for row: Dictionary in _planned:
		if str(row.frame_id) != "cloudreach__inventory__character__healer_iven":
			continue
		for approach: Dictionary in [
			{"name": "east", "heading": 270.0},
			{"name": "west", "heading": 90.0},
			{"name": "south", "heading": 0.0},
			{"name": "north", "heading": 180.0},
		]:
			var candidate := row.duplicate(true)
			candidate["frame_id"] = "%s__from_%s" % [str(row.frame_id), str(approach.name)]
			candidate["identity"] = candidate.frame_id
			candidate["position_xz"] = [-290.0, 526.0]
			candidate["view_heading_deg"] = approach.heading
			candidate["stand_offsets_m"] = [5.0, 8.0, 12.0]
			candidate["stand_laterals_m"] = [0.0, -4.0, 4.0]
			candidate["min_camera_player_distance_m"] = 1.5
			selected.append(candidate)
	_planned = selected
	return not selected.is_empty()
