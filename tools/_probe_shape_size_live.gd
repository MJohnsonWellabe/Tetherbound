extends SceneTree

## Replicates playground_world.gd::_build_terrain()'s EXACT call sequence
## (collision_shape_size set BEFORE add_child, never touched again) to find
## the REAL live value in the shipped game, rather than reasoning about it.

func _init() -> void:
	var terrain: Node = ClassDB.instantiate("Terrain3D")
	terrain.set("region_size", 256)
	terrain.set("vertex_spacing", 1.0)
	terrain.set("collision_shape_size", 256)  # exactly what _build_terrain() does
	root.add_child(terrain)
	await process_frame
	await process_frame
	print("LIVE collision_shape_size after the game's real boot sequence: %s" % terrain.get("collision_shape_size"))
	print("LIVE collision_mode (never set until _ready): %s" % terrain.get("collision_mode"))
	print("LIVE collision_radius (never set at all in current main): %s" % terrain.get("collision_radius"))
	quit(0)
