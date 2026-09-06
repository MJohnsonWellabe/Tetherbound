extends SceneTree
## Where does the den guardian actually stand? Prints its body origin, the
## warrens floor plane under it, and the world-space AABB of every visual mesh
## on it, so "is the boss floating" is a number instead of an impression.
const SCENE := "res://scenes/world/meadows_playground.tscn"

func _init() -> void:
	_run()

func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 400:
		await physics_frame
	var warrens: Node3D = world.get_node_or_null(^"BurrowWarrens") as Node3D
	if warrens == null:
		print("PROBE: no BurrowWarrens")
		quit(1)
		return
	var floor_y: float = float(warrens.get("_floor_y")) + warrens.global_position.y
	var guardian: Node3D = warrens.call("guardian") as Node3D
	if guardian == null or not is_instance_valid(guardian):
		print("PROBE: no guardian")
		quit(1)
		return
	print("PROBE floor plane y = %.3f" % floor_y)
	print("PROBE guardian origin y = %.3f  (origin - floor = %.3f)"
		% [guardian.global_position.y, guardian.global_position.y - floor_y])
	if guardian is CharacterBody3D:
		var body := guardian as CharacterBody3D
		print("PROBE is CharacterBody3D, on_floor=%s velocity=%s" % [body.is_on_floor(), body.velocity])
	var aabb := AABB()
	var first := true
	var meshes := 0
	var stack: Array[Node] = [guardian]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is VisualInstance3D:
			var vi := n as VisualInstance3D
			var box := vi.get_aabb()
			var world_box := vi.global_transform * box
			meshes += 1
			if first:
				aabb = world_box
				first = false
			else:
				aabb = aabb.merge(world_box)
	print("PROBE %d visual instances; visual AABB y = %.3f .. %.3f (height %.3f)"
		% [meshes, aabb.position.y, aabb.end.y, aabb.size.y])
	print("PROBE lowest visual point sits %.3f m above the floor plane"
		% (aabb.position.y - floor_y))
	var shapes: Array[Node] = [guardian]
	while not shapes.is_empty():
		var n: Node = shapes.pop_back()
		for c in n.get_children():
			shapes.append(c)
		if n is CollisionShape3D:
			var cs := n as CollisionShape3D
			print("PROBE collider %s shape=%s origin_y=%.3f (%.3f above floor)"
				% [cs.name, cs.shape, cs.global_position.y, cs.global_position.y - floor_y])
	quit(0)
