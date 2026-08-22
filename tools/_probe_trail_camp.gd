extends SceneTree

## BAND1-D1 round 3. Measures what the `trail_camp` cluster actually puts in
## the world -- every prop's world-space AABB (size and top height) and
## whether the CampfireGlow overlay node is instantiated at all -- so the
## round-2 blind verdict ("oversized inert logs, no flame, no glow, no
## smoke") can be attributed to the scene or to the capture path before any
## art is changed.

const SCENE := "res://scenes/world/meadows_playground.tscn"


func _init() -> void:
	_run()


func _run() -> void:
	var packed: PackedScene = load(SCENE)
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in 120:
		await physics_frame

	var camp: Node = _find(world, "trail_camp")
	if camp == null:
		print("trail_camp NOT FOUND")
		quit(1)
		return

	print("trail_camp children: %d" % camp.get_child_count())
	for child in camp.get_children():
		if child.name.ends_with("_Collision"):
			continue
		var n3 := child as Node3D
		if n3 == null:
			continue
		var meshes: Array = []
		_collect(n3, meshes)
		var glow := _find(n3, "CampfireGlow")
		if meshes.is_empty():
			print("  %-26s meshes=0 glow=%s" % [child.name, glow != null])
			continue
		var aabb: AABB = meshes[0].global_transform * meshes[0].get_aabb()
		for i in range(1, meshes.size()):
			aabb = aabb.merge(meshes[i].global_transform * meshes[i].get_aabb())
		print("  %-26s size=(%.2f, %.2f, %.2f)  base_y=%.2f top_y=%.2f  glow=%s" % [
			child.name, aabb.size.x, aabb.size.y, aabb.size.z,
			aabb.position.y, aabb.position.y + aabb.size.y, glow != null])
		if glow != null:
			_dump_glow(glow as Node3D)

	quit(0)


func _dump_glow(glow: Node3D) -> void:
	print("    CampfireGlow at world y=%.2f, children:" % glow.global_position.y)
	for c in glow.get_children():
		var extra := ""
		if c is OmniLight3D:
			var l := c as OmniLight3D
			extra = "energy=%.2f range=%.1f colour=%s" % [l.light_energy, l.omni_range, l.light_color]
		elif c is MeshInstance3D:
			var mi := c as MeshInstance3D
			var a: AABB = mi.global_transform * mi.get_aabb()
			extra = "size=(%.2f, %.2f) world_y=%.2f visible_in_tree=%s" % [
				a.size.x, a.size.y, mi.global_position.y, mi.is_visible_in_tree()]
		elif c is GPUParticles3D:
			extra = "emitting=%s amount=%d" % [(c as GPUParticles3D).emitting, (c as GPUParticles3D).amount]
		print("      %-12s %s %s" % [c.name, c.get_class(), extra])


func _find(node: Node, wanted: String) -> Node:
	if node.name == wanted:
		return node
	for c in node.get_children():
		var hit := _find(c, wanted)
		if hit != null:
			return hit
	return null


func _collect(node: Node, into: Array) -> void:
	if node is MeshInstance3D:
		into.append(node)
	for c in node.get_children():
		_collect(c, into)
