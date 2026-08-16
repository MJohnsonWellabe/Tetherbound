extends SceneTree

## OW5B (ralph/BAKE-GUARDS). What collision_radius / collision_shape_size /
## collision_mode actually do on THIS vendored Terrain3D build, verified
## rather than assumed -- MEADOWS_MACRO_LAYOUT.md §8.2 names two traps:
## collision_radius silently clamps to 16-256 step 16, collision_shape_size to
## 8-64 step 8, and Terrain3D setters are no-ops while the node is out of the
## tree. This probe checks both against ClassDB-confirmed getters, not the
## values that were set.
##
##   godot --headless --path . --script tools/_probe_terrain_collision.gd

func _init() -> void:
	if not ClassDB.class_exists("Terrain3D"):
		print("Terrain3D ABSENT from ClassDB")
		quit(1)
		return

	var terrain: Node = ClassDB.instantiate("Terrain3D")

	print("-- before add_child (out of tree) --")
	terrain.set("collision_mode", 1)
	terrain.set("collision_radius", 512)
	terrain.set("collision_shape_size", 64)
	print("  collision_mode=%s collision_radius=%s collision_shape_size=%s (as set, node not yet in tree)" %
		[terrain.get("collision_mode"), terrain.get("collision_radius"), terrain.get("collision_shape_size")])

	root.add_child(terrain)
	await process_frame

	print("-- immediately after add_child + 1 frame, no re-set --")
	print("  collision_mode=%s collision_radius=%s collision_shape_size=%s" %
		[terrain.get("collision_mode"), terrain.get("collision_radius"), terrain.get("collision_shape_size")])

	print("-- now IN TREE: set collision_mode=1, collision_radius=512, collision_shape_size=64 --")
	terrain.set("collision_mode", 1)
	terrain.set("collision_radius", 512)
	terrain.set("collision_shape_size", 64)
	print("  got back: collision_mode=%s collision_radius=%s collision_shape_size=%s" %
		[terrain.get("collision_mode"), terrain.get("collision_radius"), terrain.get("collision_shape_size")])

	print("-- sweep collision_radius while in tree (16-256 step 16 claimed) --")
	for want in [8, 16, 32, 48, 100, 256, 257, 300, 512, 1000]:
		terrain.set("collision_radius", want)
		print("  set %d -> got %s" % [want, terrain.get("collision_radius")])

	print("-- sweep collision_shape_size while in tree (8-64 step 8 claimed) --")
	for want in [4, 8, 16, 40, 63, 64, 65, 100, 256, 512]:
		terrain.set("collision_shape_size", want)
		print("  set %d -> got %s" % [want, terrain.get("collision_shape_size")])

	quit(0)
