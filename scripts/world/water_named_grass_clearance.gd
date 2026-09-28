extends RefCounted

## Water-only spawn attachment for P2-057. GrassField already consumes this
## group and radius at each live body's position. The body owns its lifetime;
## no extra nodes, duplicate coordinates, collision or per-frame work are added.
const CONFIG := "res://data/config/water_named_grass_clearance.json"
const GROUP := &"grass_clear"
const RADIUS_META := &"grass_clear_radius"


static func settings() -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return raw if raw is Dictionary else {}


static func apply(body: Node3D, world: Node, supplied: Dictionary = {}) -> bool:
	var config := supplied if not supplied.is_empty() else settings()
	if not bool(config.get("enabled", false)) or not is_instance_valid(body):
		return false
	# The shared GrassField queries scene-wide groups. A host's off-screen
	# Water simulation must not clear the active realm at matching coordinates.
	if not is_instance_valid(world) or not world.has_method("world_realm") \
			or str(world.call("world_realm")) != "water" or bool(world.get("simulation_only")):
		return false
	var radius := float(config.get("radius_m", 2.5))
	if not is_finite(radius):
		return false
	radius = clampf(radius, 2.0, 3.0)
	# NPCs reused as trainers pass through both spawn hooks. Keep any existing
	# footprint exactly as its original owner authored it, including its group.
	if body.is_in_group(GROUP) or body.has_meta(RADIUS_META):
		return false
	body.set_meta(RADIUS_META, radius)
	body.add_to_group(GROUP)
	return true
