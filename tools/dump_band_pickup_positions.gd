extends SceneTree

## Boot the Meadows solo and print every placed band pickup's exact position,
## one `BANDPICKUP <name> <x> <y> <z>` line each (full float precision), sorted.
## Used to prove placement is bit-identical across a change:
##
##   TB_WORLD_SEED=<n> godot --headless --path . --script tools/dump_band_pickup_positions.gd
##
## `TB_WORLD_SEED` pins the world seed the way the net harness does.

const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var scene: Node = (load(WORLD_SCENE) as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	for i in 6000:
		await physics_frame
		if scene.has_method("shell_build_complete") and bool(scene.call("shell_build_complete")):
			break
	for i in 30:
		await physics_frame
	var rows: Array[String] = []
	for child: Node in scene.get_children():
		if str(child.name).begins_with("BandPickup_") and child is Node3D:
			var p: Vector3 = (child as Node3D).global_position
			rows.append("BANDPICKUP %s %s %s %s" % [child.name, var_to_str(p.x), var_to_str(p.y), var_to_str(p.z)])
	rows.sort()
	print("BANDPICKUP_SEED %s count %d" % [OS.get_environment("TB_WORLD_SEED"), rows.size()])
	for row in rows:
		print(row)
	quit(0 if not rows.is_empty() else 1)
