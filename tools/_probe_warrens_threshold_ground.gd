extends SceneTree
## ROUND-4-0906: what is the pale strip in front of the Warrens' mouth? Boots
## the playground headless and, along the mouth's own axis, prints the
## world's ground height, the bank's own height, and what a downward ray
## actually hits first (collider name + height), relative to the cave node.
##
##   godot --headless --path . --script tools/_probe_warrens_threshold_ground.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"

func _init() -> void:
	_run()

func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 120:
		await physics_frame
	var warrens: Node3D = world.get_node_or_null(^"BurrowWarrens") as Node3D
	if warrens == null:
		print("PROBE: no BurrowWarrens")
		quit(1)
		return
	var space := (world as Node3D).get_world_3d().direct_space_state
	var base_y := warrens.global_position.y
	print("PROBE: cave node y=%.2f floor_y=%.2f" % [base_y, float(warrens.get("_floor_y"))])
	for x in [0.0, 3.0]:
		var z := -16.0
		while z <= 2.0:
			var g := warrens.to_global(Vector3(x, 0.0, z))
			var ground := float(world.call("ground_height_at", g.x, g.z))
			var bank := float(warrens.call("_bank_height_at", x, z))
			var q := PhysicsRayQueryParameters3D.create(Vector3(g.x, base_y + 30.0, g.z), Vector3(g.x, base_y - 10.0, g.z))
			var hit := space.intersect_ray(q)
			var who := "nothing"
			var hy := NAN
			if not hit.is_empty():
				var c: Node = hit["collider"]
				var p := c.get_parent()
				who = "%s/%s" % [str(p.name) if p != null else "?", str(c.name)]
				hy = (hit["position"] as Vector3).y - base_y
			print("PROBE: x=%+.0f z=%+5.1f ground(rel)=%+.2f bank=%.2f top-hit=%s @%+.2f" % [x, z, ground - base_y, bank, who, hy])
			z += 1.0
	quit(0)
