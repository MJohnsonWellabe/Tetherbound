extends SceneTree

const SCENE := "res://scenes/world/meadows_playground.tscn"

func _init() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 60:
		await physics_frame
	var gate: Node3D = world.get_node_or_null(^"SigilGate") as Node3D
	print("gate.rotation.y (rad) = %s, deg = %s" % [gate.rotation.y, rad_to_deg(gate.rotation.y)])
	print("gate.global_transform.basis.x = %s" % gate.global_transform.basis.x)
	print("gate.global_transform.basis.z = %s" % gate.global_transform.basis.z)
	var across_real := Vector2(gate.global_transform.basis.x.x, gate.global_transform.basis.x.z).normalized()
	print("REAL across (from live node) = %s" % across_real)

	var carve_axis := Vector2.RIGHT.rotated(deg_to_rad(28.6))
	print("carve axis_deg=28.6 -> Vector2.RIGHT.rotated = %s" % carve_axis)

	print("dot(across_real, carve_axis) = %s (1.0 = perfectly aligned)" % across_real.dot(carve_axis))
	print("angle between them (deg) = %s" % rad_to_deg(across_real.angle_to(carve_axis)))
	quit(0)
