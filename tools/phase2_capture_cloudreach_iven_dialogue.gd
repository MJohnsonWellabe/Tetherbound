extends "res://tools/phase2_capture_dialogue.gd"

## Reshoot Iven at the mounted runtime post. The Settings catalogue coordinate
## is west of the current NPC position, where the spring arm faces a wall.
func _load_plan() -> bool:
	if not super._load_plan() or _biome_id != "cloudreach":
		return false
	var selected: Array[Dictionary] = []
	for row: Dictionary in _planned:
		if str(row.frame_id) != "cloudreach__inventory__character__healer_iven":
			continue
		row["position_xz"] = [-290.0, 526.0]
		row["stand_offsets_m"] = [8.0, 12.0, 5.0, 16.0, 2.0]
		row["stand_laterals_m"] = [0.0, -4.0, 4.0, -8.0, 8.0]
		row["min_camera_player_distance_m"] = 1.5
		selected.append(row)
	_planned = selected
	return not selected.is_empty()
