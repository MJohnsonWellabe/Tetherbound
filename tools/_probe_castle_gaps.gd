extends SceneTree

## STRONGHOLD-R2 diagnostic (scratch). Dumps every mesh in the castle prefab as
## `AABB <name> <x0> <y0> <z0> <x1> <y1> <z1>` in the prefab's own local frame,
## so `tools/_probe_castle_gaps.py` can ray-march the gate-close sightline
## through them and say WHERE the vertical sky slot in the south face is,
## rather than having the slot's cause guessed from the recipe's own prose.
## Delete with the rest of this pass's scratch probes.

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

	# In the CASTLE's own frame, not each module's -- `combined_aabb(node)`
	# answers in the node's own space, which for a scaled, yawed module is not
	# where it stands. Merging each mesh through its transform chain up to the
	# castle root is the only measurement worth printing here.
	for child in castle.get_children():
		if not child is Node3D:
			continue
		var node: Node3D = child
		var box: AABB = node.transform * (prefabs.call("combined_aabb", node) as AABB)
		print("AABB %s %.3f %.3f %.3f %.3f %.3f %.3f" % [
			node.name, box.position.x, box.position.y, box.position.z,
			box.end.x, box.end.y, box.end.z])
	quit(0)
