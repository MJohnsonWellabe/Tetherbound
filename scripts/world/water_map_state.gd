extends "res://autoload/map_state.gd"

## Each trainer owns their Water fog, island discoveries and pins. The shared
## world supplies geometry only; discovering an island does not unlock a dock.
var _bounds: Dictionary = {}


func configure_water(world: Dictionary) -> void:
	_bounds = world.get("world_bounds", {}).duplicate(true)
	var tuning: Dictionary = world.get("map", {})
	var size := float(tuning.get("cell_m", 8.0))
	set_extent(Vector2(float(_bounds.min_x), float(_bounds.min_z)),
		ceili((float(_bounds.max_x) - float(_bounds.min_x)) / size),
		ceili((float(_bounds.max_z) - float(_bounds.min_z)) / size), size)
	var landmarks_data: Array = []
	for authored: Dictionary in world.get("landmarks", []):
		var at: Array = authored.position
		landmarks_data.append({"id": authored.id, "display_name": authored.name,
			"position": [at[0], at[2]], "category": "landmark",
			"discover_radius": float(tuning.get("landmark_discovery_radius_m", 30.0))})
	var islands_data: Array = []
	for island: Dictionary in world.get("islands", []):
		islands_data.append({"id": island.id, "display_name": island.name,
			"centre": island.center_xz_m, "radius": island.shore_radius_m})
	configure({"landmarks": landmarks_data, "regions": islands_data,
		"reveal_radius": float(tuning.get("reveal_radius_m", 45.0)),
		"minimap_span_m": float(tuning.get("minimap_span_m", 160.0))})


func world_bounds() -> Dictionary:
	return _bounds.duplicate()


func map_display_name() -> String:
	return "Water Archipelago"
