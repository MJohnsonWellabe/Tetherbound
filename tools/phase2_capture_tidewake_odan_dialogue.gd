extends "res://tools/phase2_capture_defeated_dialogue.gd"

## Odan's authored south-facing post points the generic dialogue stand into
## the cliff. Try the opposite approach with the same production camera and
## post text; no battle or defeated world state is set.

func _load_plan() -> bool:
	if not super._load_plan() or _biome_id != "water":
		return false
	var selected: Array[Dictionary] = []
	for row: Dictionary in _planned:
		if str(row.frame_id) != "water__inventory__trainer__water_trainer_odan__defeated":
			continue
		row["view_heading_deg"] = 0.0
		row["stand_offsets_m"] = [2.0, 3.0, 5.0, 8.0, 12.0]
		row["stand_laterals_m"] = [0.0, -2.0, 2.0, -5.0, 5.0, -9.0, 9.0]
		row["min_camera_player_distance_m"] = 1.5
		selected.append(row)
	_planned = selected
	return not _planned.is_empty()
