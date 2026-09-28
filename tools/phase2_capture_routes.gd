extends "res://tools/phase2_capture_locations.gd"

## Seeded visual walk around the authored catalogue waypoints. The waypoint
## sequence is an audit route proxy, not proof of campaign traversal. Each
## off-route shot records the cumulative random-walk offset in the manifest.

const WALK_STEPS := 3


func _load_plan() -> bool:
	if not super._load_plan():
		return false
	var waypoints: Array[Dictionary] = []
	for destination: Dictionary in _all_destinations:
		if "__landmark__" not in str(destination.identity):
			waypoints.append(destination)
	_all_destinations.clear()
	_all_destinations.append_array(waypoints)
	_planned.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	for destination: Dictionary in waypoints:
		var origin_values := destination.position_xz as Array
		var origin := Vector2(float(origin_values[0]), float(origin_values[1]))
		var identity := str(destination.identity)
		var display_name := identity.replace("__", " / ").replace("_", " ")
		var base := {
			"identity": identity, "biome_id": _biome_id,
			"biome_display_name": _biome_id.capitalize(),
			"band_id": identity.split("__")[1], "band_display_name": "",
			"destination_index": int(destination.destination_index),
			"spot_index_in_band": 0,
			"destination_display_name": display_name,
			"view_heading_deg": destination.view_heading_deg,
		}
		var route_row := base.duplicate(true)
		route_row.merge({"frame_id": "%s__route_day" % identity,
			"position_xz": [origin.x, origin.y], "time": "day",
			"view": "close", "route_class": "main",
			"walk_seed": _seed, "walk_step": 0,
			"walk_offset_xz": [0.0, 0.0]}, true)
		_planned.append(route_row)
		var delta := Vector2.ZERO
		for step in WALK_STEPS:
			var angle := rng.randf_range(-PI, PI)
			var distance := rng.randf_range(18.0, 28.0)
			delta += Vector2(cos(angle), sin(angle)) * distance
			var off_row := base.duplicate(true)
			off_row.merge({"frame_id": "%s__walk_%02d_day" % [identity, step + 1],
				"position_xz": [origin.x + delta.x, origin.y + delta.y],
				"time": "day", "view": "close", "route_class": "off",
				"walk_seed": _seed, "walk_step": step + 1,
				"walk_offset_xz": [delta.x, delta.y],
				"walk_angle_rad": angle, "walk_distance_m": distance}, true)
			_planned.append(off_row)
		var vista_row := base.duplicate(true)
		vista_row.merge({"frame_id": "%s__vista_dusk" % identity,
			"position_xz": [origin.x, origin.y], "time": "golden",
			"view": "vista", "route_class": "main",
			"walk_seed": _seed, "walk_step": 0,
			"walk_offset_xz": [0.0, 0.0]}, true)
		_planned.append(vista_row)
	return not _planned.is_empty()
