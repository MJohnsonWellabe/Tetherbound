extends Node

## Session composition mounts authored stones in ready local worlds and
## occupied host shells. Separate world instances always get their own set.
var _left := 0.0

func _process(delta: float) -> void:
	_left -= delta
	if _left > 0.0: return
	_left = 0.5
	var session := get_parent().get_parent()
	if session.call("portal_runtime_ready") != true: return
	for realm: String in ["meadows", "water", "cloudreach", "stormwood"]:
		var world := session.call("_portal_world_node", realm) as Node3D
		if world != null: mount(world, realm)

static func mount(world: Node3D, realm: String) -> bool:
	if world == null or not world.is_inside_tree() or not world.has_method("ground_height_at") \
		or (world.has_method("world_realm") and str(world.call("world_realm")) != realm) \
		or (world.has_method("shell_build_complete") and world.call("shell_build_complete") != true): return false
	if world.has_node(^"Waystones"):
		var existing := world.get_node(^"Waystones")
		if existing.get_script() != preload("res://scripts/world/waystone.gd"): return false
		_resident_support(world, existing)
		return true
	var stones := preload("res://scripts/world/waystone.gd").new()
	stones.name = "Waystones"
	world.add_child(stones)
	stones.build(world, realm)
	_resident_support(world, stones)
	return true

static func _resident_support(world: Node3D, stones: Node) -> void:
	for child: Node in stones.get_children():
		if child is Node3D and not str(child.get("waystone_id")).is_empty():
			preload("res://scripts/world/waystone_terrain_support.gd").mount(world, child)
