extends SceneTree

## GATE-E-STRONGHOLD-ART diagnostic (scratch): the castle prefab's REAL
## per-module extents, so the occupation dressing is placed against measured
## geometry instead of against numbers inferred from the recipe's `_why` text.
## Delete once the placement is settled.

const PREFABS := preload("res://scripts/world/building_prefabs.gd")


func _init() -> void:
	_run()


func _run() -> void:
	var holder := Node3D.new()
	root.add_child(holder)
	var prefabs: RefCounted = PREFABS.new()
	if not prefabs.call("load_recipes"):
		push_error("no recipes")
		quit(1)
		return
	var templates := Node3D.new()
	templates.visible = false
	holder.add_child(templates)
	prefabs.call("set_template_holder", templates)

	var castle: Node3D = prefabs.call("instantiate", "castle")
	castle.name = "Castle"
	holder.add_child(castle)
	await process_frame

	var whole: AABB = prefabs.call("combined_aabb", castle)
	print("CASTLE combined AABB: pos (%.2f, %.2f, %.2f) size (%.2f, %.2f, %.2f)" % [
		whole.position.x, whole.position.y, whole.position.z,
		whole.size.x, whole.size.y, whole.size.z,
	])
	print("  x %.2f..%.2f   y %.2f..%.2f   z %.2f..%.2f" % [
		whole.position.x, whole.end.x, whole.position.y, whole.end.y,
		whole.position.z, whole.end.z,
	])
	print("")
	print("every module, sorted by x:")
	var rows: Array = []
	for child in castle.get_children():
		if not child is Node3D:
			continue
		var node: Node3D = child
		var box: AABB = prefabs.call("combined_aabb", node)
		if box.size == Vector3.ZERO:
			continue
		rows.append([node.position.x, node.name, box])
	rows.sort_custom(func(a, b): return a[0] < b[0])
	for row: Array in rows:
		var box: AABB = row[2]
		print("  %-34s x %7.2f..%7.2f  y %6.2f..%6.2f  z %7.2f..%7.2f" % [
			row[1], box.position.x, box.end.x, box.position.y, box.end.y,
			box.position.z, box.end.z,
		])
	quit(0)
