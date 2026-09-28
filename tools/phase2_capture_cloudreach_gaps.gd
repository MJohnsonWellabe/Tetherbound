extends "res://tools/phase2_capture_locations.gd"

## Revisit the four elevated named destinations whose generic route stands
## failed. The production camera and ordinary debug travel remain in use;
## wider stand candidates are recorded in each frame's engine manifest.

const GAP_IDENTITIES := [
	"cloudreach__gate_lower_cliffs__02__galefoot_waycamp",
	"cloudreach__broken_causeways__03__three_bells_bridge",
	"cloudreach__broken_causeways__04__broken_skyroad_arch",
	"cloudreach__summit_final_stronghold__12__stormward_overlook",
]


func _load_plan() -> bool:
	if not super._load_plan():
		return false
	if _biome_id != "cloudreach":
		return false
	var selected: Array[Dictionary] = []
	for row: Dictionary in _planned:
		var identity := str(row.identity)
		if not GAP_IDENTITIES.has(identity):
			continue
		row["stand_offsets_m"] = [24.0, 16.0, 32.0, 40.0, 48.0, 8.0] if str(row.view) == "approach" else [5.0, 8.0, 12.0, 16.0, 24.0]
		row["stand_laterals_m"] = [0.0, -10.0, 10.0, -20.0, 20.0, -35.0, 35.0, -50.0, 50.0]
		row["min_camera_player_distance_m"] = 2.0
		selected.append(row)
	_planned = selected
	return not _planned.is_empty()
