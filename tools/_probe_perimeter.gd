extends SceneTree

## Throwaway probe. Builds ONLY world_perimeter.gd against the pure
## heightfield (no terrain bake, no scatter, no render), so a parse error or a
## runtime error costs seconds instead of a 30-minute capture. Also measures
## how far the visible geometry sits from real ground, which is the number
## OF7 is actually about.

const PERIMETER := preload("res://scripts/world/world_perimeter.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")


class StubWorld:
	extends Node
	var field: RefCounted

	func ground_height_at(x: float, z: float) -> float:
		return float(field.call("height_at", x, z))


func _init() -> void:
	var field: RefCounted = HEIGHTFIELD.new()
	var world := StubWorld.new()
	world.field = field
	root.add_child(world)

	var player := CharacterBody3D.new()
	root.add_child(player)

	var node: Node3D = PERIMETER.new()
	root.add_child(node)
	node.call("build", world, player, Vector3.ZERO)

	print("--- node census ---")
	_census(node, 0)

	# How far does real ground move across one 37m segment, and how far would
	# a single-Y rigid segment be from it?
	print("--- terrain across the ring ---")
	var worst := 0.0
	var worst_seg := -1
	for s in 40:
		var lo := INF
		var hi := -INF
		for k in 19:
			var t := (float(s) + float(k) / 18.0) / 40.0
			var angle := t * TAU
			var r := 235.0
			var h := float(field.call("height_at", cos(angle) * r, sin(angle) * r))
			lo = minf(lo, h)
			hi = maxf(hi, h)
		if hi - lo > worst:
			worst = hi - lo
			worst_seg = s
		if s % 8 == 0 or hi - lo > 8.0:
			print("  seg %2d  ground %7.2f .. %7.2f   spread %5.2fm  (a rigid one-Y segment misses by up to %.2fm)" % [
				s, lo, hi, hi - lo, (hi - lo) * 0.5
			])
	print("  worst segment %d: %.2fm of ground movement across its own length" % [worst_seg, worst])

	# Where does the built geometry actually sit relative to ground?
	print("--- built geometry vs ground ---")
	var ring: Node = node.get_node_or_null(^"Ring")
	if ring != null:
		for child in ring.get_children():
			if child is MeshInstance3D:
				var mi := child as MeshInstance3D
				var aabb: AABB = mi.mesh.get_aabb() if mi.mesh != null else AABB()
				print("  %-12s aabb y %7.2f .. %7.2f  (%d surfaces)" % [
					mi.name, aabb.position.y, aabb.position.y + aabb.size.y,
					mi.mesh.get_surface_count() if mi.mesh != null else 0
				])
			elif child is MultiMeshInstance3D:
				var mm := child as MultiMeshInstance3D
				var count: int = mm.multimesh.instance_count if mm.multimesh != null else 0
				var off_ground := 0.0
				for i in mini(count, 400):
					var xf: Transform3D = mm.multimesh.get_instance_transform(i)
					var g := float(field.call("height_at", xf.origin.x, xf.origin.z))
					off_ground = maxf(off_ground, absf(xf.origin.y - g))
				print("  %-12s %4d instances, worst |y - ground| = %.2fm" % [mm.name, count, off_ground])
	quit(0)


func _census(node: Node, depth: int) -> void:
	var counts: Dictionary = {}
	_count(node, counts)
	for key: String in counts.keys():
		print("  %-24s %d" % [key, counts[key]])


func _count(node: Node, counts: Dictionary) -> void:
	var key := node.get_class()
	counts[key] = int(counts.get(key, 0)) + 1
	for child in node.get_children():
		_count(child, counts)
