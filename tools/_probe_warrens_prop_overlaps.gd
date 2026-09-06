extends SceneTree
## WARRENS-ART-0906. The blind verdict named "two copies of the chest asset at
## nearly the same transform, interpenetrating" in three interior frames, and
## `data/config/burrow_warrens.json::dressing` authors no chest at all -- so
## either two different props are being read as one doubled asset, or something
## other than the dressing list is placing a second copy. This measures it
## instead of guessing: build the warrens against the same flat fixture world
## `tests/smoke_warrens_fixture.gd` uses, walk every placed prop, and print any
## pair of props whose origins are closer than `NEAR_M`, with their names and
## their parents so the placer that put each one there is identifiable.
const BURROW_WARRENS := preload("res://scripts/world/burrow_warrens.gd")
const NEAR_M := 1.4

class FlatWorld extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := FlatWorld.new()
	root.add_child(world)
	var warrens: Node3D = BURROW_WARRENS.new()
	warrens.name = "BurrowWarrens"
	world.add_child(warrens)
	if warrens.has_method("build"):
		warrens.call("build", world, null)
	await process_frame
	await process_frame

	# Every node that carries a mesh and is not part of the procedural shell.
	var props: Array = []
	var stack: Array[Node] = [warrens]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if not (n is Node3D):
			continue
		var n3 := n as Node3D
		# A "prop" here is an instanced scene root: it has a parent whose name
		# is a holder, and at least one MeshInstance3D under it.
		if n3.get_parent() == warrens:
			continue
		var has_mesh := false
		var inner: Array[Node] = [n3]
		while not inner.is_empty():
			var m: Node = inner.pop_back()
			if m is MeshInstance3D:
				has_mesh = true
				break
			for c2 in m.get_children():
				inner.append(c2)
		if not has_mesh:
			continue
		# only leaf-ish instanced roots, not every mesh inside a model
		if n3.get_parent() != null and n3.get_parent().get_parent() == warrens:
			props.append({"node": n3, "name": n3.name,
				"holder": n3.get_parent().name, "at": n3.global_position})

	print("[probe] %d placed props under the warrens" % props.size())
	var reported := 0
	for i in props.size():
		for j in range(i + 1, props.size()):
			var a: Dictionary = props[i]
			var b: Dictionary = props[j]
			var d: float = (a["at"] as Vector3).distance_to(b["at"] as Vector3)
			if d > NEAR_M:
				continue
			print("[probe] %.2fm apart: %s/%s at %s  <->  %s/%s at %s"
				% [d, a["holder"], a["name"], str(a["at"]).pad_decimals(1),
					b["holder"], b["name"], str(b["at"]).pad_decimals(1)])
			reported += 1
	print("[probe] %d prop pairs closer than %.1fm" % [reported, NEAR_M])
	quit(0)
