extends SceneTree

## G3-HARNESS-0904. Is a given world point inside a CarveFailsafe recovery
## volume? `tools/_probe_river_gate.gd` already named the mechanism: an
## Area3D that writes `global_position` to a fixed point on every
## `body_entered`, which reads to any walker, old or new, as a wall that
## never moves -- and, in route.csv, as a perfect centimetre-exact freeze
## rather than the small continuous jitter a genuinely stuck stick_navigator
## produces. Written for two S08/S05 walker freezes this session that both
## turned out NOT to be CarveFailsafe volumes (see G3-HARNESS-0904's report);
## kept general because it is cheap and the next stranding deserves the same
## five-minute check before a longer investigation.
##
##   godot --headless --path . --script tools/gate_f/probe_carve_failsafe_at.gd -- --at=X,Y,Z

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const NEARBY_RADIUS := 60.0


func _init() -> void:
	_run()


func _run() -> void:
	var point := Vector3.ZERO
	var given := false
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--at="):
			var parts := arg.trim_prefix("--at=").split(",")
			if parts.size() == 3:
				point = Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
				given = true
	if not given:
		print("usage: --at=X,Y,Z (the point to test)")
		quit(2)
		return

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var areas := _failsafes(world)
	print("%d CarveFailsafe volumes in the scene" % areas.size())
	var inside := _containing(areas, point)
	print("point (%.2f, %.2f, %.2f) is %s" % [
		point.x, point.y, point.z,
		("INSIDE: " + ", ".join(inside)) if not inside.is_empty() else "not inside any CarveFailsafe volume"])

	# A small column and a ring around the point, in case the exact y a
	# freeze was recorded at is not the y the volume actually tests on entry.
	for dy in [-2.0, -1.0, 0.0, 1.0, 2.0]:
		var p := point + Vector3(0, dy, 0)
		var hit := _containing(areas, p)
		if not hit.is_empty():
			print("  (%.2f, %.2f, %.2f) INSIDE: %s" % [p.x, p.y, p.z, ", ".join(hit)])
	for dx in [-5.0, -2.0, 2.0, 5.0]:
		for dz in [-5.0, -2.0, 2.0, 5.0]:
			var p := point + Vector3(dx, 0, dz)
			var hit := _containing(areas, p)
			if not hit.is_empty():
				print("  (%.2f, %.2f, %.2f) INSIDE: %s" % [p.x, p.y, p.z, ", ".join(hit)])

	print("\nvolumes within %.0fm of the point:" % NEARBY_RADIUS)
	var any_nearby := false
	for area: Area3D in areas:
		if area.global_position.distance_to(point) > NEARBY_RADIUS:
			continue
		any_nearby = true
		var shape: CollisionShape3D = area.get_child(0) as CollisionShape3D
		var box: BoxShape3D = shape.shape as BoxShape3D if shape != null else null
		var to: Vector3 = area.get_meta("recover_to", Vector3.ZERO)
		if box != null:
			print("  %-46s at (%8.1f,%7.2f,%8.1f) size (%6.1f,%5.1f,%5.1f) yaw %6.1f -> back to (%.1f, %.1f)" % [
				_owner_label(area), area.global_position.x, area.global_position.y, area.global_position.z,
				box.size.x, box.size.y, box.size.z, rad_to_deg(area.global_rotation.y), to.x, to.z])
	if not any_nearby:
		print("  none")
	quit(0)


func _failsafes(node: Node) -> Array:
	var out: Array = []
	if node is Area3D and node.has_meta("recover_to"):
		out.append(node)
	for child in node.get_children():
		out.append_array(_failsafes(child))
	return out


func _containing(areas: Array, point: Vector3) -> Array[String]:
	var out: Array[String] = []
	for area: Area3D in areas:
		var shape: CollisionShape3D = area.get_child(0) as CollisionShape3D
		if shape == null or not shape.shape is BoxShape3D:
			continue
		var half: Vector3 = (shape.shape as BoxShape3D).size * 0.5
		var local: Vector3 = area.global_transform.affine_inverse() * point
		if absf(local.x) <= half.x and absf(local.y) <= half.y and absf(local.z) <= half.z:
			out.append(_owner_label(area))
	return out


func _owner_label(area: Area3D) -> String:
	var path := str(area.get_path())
	var parts := path.split("/")
	var tail := parts.slice(maxi(parts.size() - 3, 0))
	return "/".join(tail)
