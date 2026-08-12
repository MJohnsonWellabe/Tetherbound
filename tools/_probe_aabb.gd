extends SceneTree

## EV6 scratch probe: print each module's combined AABB (min .. max) in the
## scene root's space, so prefab recipes can be authored against real pivots
## rather than guessed ones.
##
##   godot --headless --path . --script tools/_probe_aabb.gd -- <model> ...

const DIR := "res://assets/buildings/quaternius_medieval"


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		_report(str(arg))
	quit(0)


func _report(model: String) -> void:
	var path := "%s/%s.gltf" % [DIR, model]
	var scene: PackedScene = load(path)
	if scene == null:
		print("%s: cannot load" % model)
		return
	var root := scene.instantiate()
	var aabb := _combined(root, Transform3D.IDENTITY)
	print("%-34s min(%6.2f %6.2f %6.2f)  max(%6.2f %6.2f %6.2f)" % [
		model,
		aabb.position.x, aabb.position.y, aabb.position.z,
		aabb.end.x, aabb.end.y, aabb.end.z,
	])
	root.free()


func _combined(node: Node, xform: Transform3D) -> AABB:
	var local := xform
	if node is Node3D:
		local = xform * (node as Node3D).transform
	var result := AABB()
	var has := false
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			result = local * mi.mesh.get_aabb()
			has = true
	for child in node.get_children():
		var sub := _combined(child, local)
		if sub.size != Vector3.ZERO or sub.position != Vector3.ZERO:
			result = result.merge(sub) if has else sub
			has = true
	return result
