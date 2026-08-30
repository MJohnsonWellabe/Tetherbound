extends SceneTree
func _init() -> void:
	var world: Node = load("res://scenes/world/meadows_playground.tscn").instantiate() if ResourceLoader.exists("res://scenes/world/meadows_playground.tscn") else null
	if world == null:
		print("no playground scene"); quit(1); return
	root.add_child(world)
	for i in 240:
		await physics_frame
	var gate: Node3D = world.find_child("RoadGate", true, false) as Node3D
	if gate == null:
		print("NO RoadGate node"); quit(1); return
	print("RoadGate at ", gate.global_position, " yaw=", rad_to_deg(gate.rotation.y))
	var n := 0
	for child in gate.get_children():
		if child is StaticBody3D:
			for sub in (child as StaticBody3D).get_children():
				var cs := sub as CollisionShape3D
				if cs == null: continue
				var b := cs.shape as BoxShape3D
				if b == null: continue
				n += 1
				print("  %-24s localx=%.2f size=%.2f disabled=%s" % [child.name, (child as StaticBody3D).position.x, b.size.x, str(cs.disabled)])
	print("total collision boxes: ", n)
	quit(0)
