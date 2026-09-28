extends "res://tools/phase2_capture_world_inventory.gd"

## Wider production-camera stands for two cliffside pickups that failed the
## ordinary inventory pass. The authored world coordinates stay unchanged.

const IDS := [
	"cloudreach__inventory__pickup__great_candy",
	"cloudreach__inventory__pickup__tm_wind_blade",
]

func _load_plan() -> bool:
	if not super._load_plan() or _biome_id != "cloudreach":
		return false
	var selected: Array[Dictionary] = []
	for row: Dictionary in _planned:
		if str(row.frame_id) not in IDS:
			continue
		row["stand_offsets_m"] = [0.0, 2.0, 5.0, 8.0, 12.0, 20.0]
		row["stand_laterals_m"] = [0.0, -4.0, 4.0, -8.0, 8.0, -15.0, 15.0]
		row["min_camera_player_distance_m"] = 1.5
		selected.append(row)
	_planned = selected
	return not _planned.is_empty()
