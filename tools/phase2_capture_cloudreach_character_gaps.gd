extends "res://tools/phase2_capture_characters.gd"

## Targeted post survey where a nearby shelf blocks the normal trainer rig.

const IDS := [
	"cloudreach__inventory__character__healer_iven",
	"cloudreach__inventory__character__bridgekeeper_orrin",
	"cloudreach__inventory__character__courier_neri",
]

func _load_plan() -> bool:
	if not super._load_plan() or _biome_id != "cloudreach":
		return false
	var selected: Array[Dictionary] = []
	for row: Dictionary in _planned:
		if str(row.frame_id) not in IDS:
			continue
		row["stand_offsets_m"] = [0.0, 2.0, 5.0, 9.0, 14.0, 20.0]
		row["stand_laterals_m"] = [0.0, -4.0, 4.0, -8.0, 8.0, -15.0, 15.0]
		row["min_camera_player_distance_m"] = 1.5
		if str(row.frame_id) == "cloudreach__inventory__character__healer_iven":
			# The catalogue coordinate is west of Iven's mounted runtime post.
			# Aim the ordinary rig at the actual authored NPC position instead.
			row["position_xz"] = [-290.0, 526.0]
			row["stand_offsets_m"] = [8.0, 12.0, 5.0, 16.0, 2.0]
			row["stand_laterals_m"] = [0.0, -4.0, 4.0, -8.0, 8.0]
			row["min_camera_player_distance_m"] = 1.5
		selected.append(row)
	_planned = selected
	return not _planned.is_empty()
