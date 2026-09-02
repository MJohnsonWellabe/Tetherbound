extends SceneTree

## Scratch diagnostic for OWNER-0902-VILLAGE-GATE-REGRESSION. Corner[3]
## (18.0, 21.0) still jumped out in the exhaustive PART 6 sweep even after
## `_build_corner_guards` was added. This inspects the actual built collider
## and real ground heights around it directly, instead of paying for another
## full jump-sweep reboot per hypothesis.
##
##   godot --headless --path . --script tools/_diag_corner3.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var boundary := world.get_node_or_null(^"VillageBoundary")
	if boundary == null:
		print("no VillageBoundary node")
		quit(1)
		return

	var guard := boundary.get_node_or_null(^"FenceCornerGuard_3")
	if guard == null:
		print("NO FenceCornerGuard_3 NODE -- the post was never built at this vertex")
	else:
		print("FenceCornerGuard_3 global_position = %s" % str(guard.global_position))
		for c: Node in guard.get_children():
			if c is CollisionShape3D:
				var box: BoxShape3D = (c as CollisionShape3D).shape
				print("  box size=%s  world top=%.2f bottom=%.2f" % [
					str(box.size), guard.global_position.y + box.size.y * 0.5,
					guard.global_position.y - box.size.y * 0.5])

	print("\n--- ground heights around the corner (18,21) ---")
	var square := Vector3(10.0, 0.0, -10.0)
	var at := Vector2(18.0, 21.0)
	var out_dir := (at - Vector2(square.x, square.z)).normalized()
	print("out_dir = %s" % str(out_dir))
	for d: float in [-4.0, -2.0, -1.0, 0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 6.0]:
		var p := at + out_dir * d
		var g: float = float(world.call("ground_height_at", p.x, p.y))
		print("  d=%5.1f  at=%s  ground=%.2f" % [d, str(p.snapped(Vector2.ONE * 0.01)), g])

	print("\n--- fence panels/guards near the corner ---")
	_dump_near(boundary, at, 6.0)

	quit(0)


func _dump_near(node: Node, at: Vector2, radius: float) -> void:
	for child: Node in node.get_children():
		if (child is StaticBody3D) and (str(child.name).begins_with("FencePanelCollision") or str(child.name).begins_with("FenceCornerGuard")):
			var here := child as Node3D
			var d: float = Vector2(here.global_position.x - at.x, here.global_position.z - at.y).length()
			if d <= radius:
				for c: Node in child.get_children():
					if c is CollisionShape3D:
						var box: BoxShape3D = (c as CollisionShape3D).shape
						print("  %-28s at=%s  size=%s  dist=%.2f" % [
							str(child.name), str(here.global_position.snapped(Vector3.ONE * 0.01)),
							str(box.size), d])
		_dump_near(child, at, radius)
