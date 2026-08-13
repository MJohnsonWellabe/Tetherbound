extends SceneTree

## Throwaway probe (OF7 round 7). Builds ONLY world_perimeter.gd against the
## pure heightfield — no terrain bake, no scatter, no render — and reports the
## things a render argument keeps turning on:
##
##   * the coursed wall top: per wall run, how many risers, how big, and how
##     far the wall's real height strays from nominal;
##   * the biggest boulder the perimeter itself can produce, so a "what is
##     that huge dark blocky thing on the boundary" question can be answered
##     with a number instead of a guess about whose scatter it is.

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

	var ring: Node = node.get_node_or_null(^"Ring")
	if ring == null:
		print("no ring")
		quit(1)
		return

	# NOTE: `MultiMesh.get_instance_transform()` reads back as IDENTITY under
	# `--headless` (the dummy rendering driver drops the instance buffer), so
	# per-instance placement cannot be measured here. Base mesh sizes are real;
	# the size a boulder can REACH is computed from the constants instead.
	print("--- perimeter MultiMesh batches ---")
	for child in ring.get_children():
		if not (child is MultiMeshInstance3D):
			continue
		var mm := child as MultiMeshInstance3D
		if mm.multimesh == null or mm.multimesh.mesh == null:
			continue
		var base: AABB = mm.multimesh.mesh.get_aabb()
		print("  %-10s %4d instances   base mesh %.2f x %.2f x %.2f" % [
			mm.name, mm.multimesh.instance_count,
			base.size.x, base.size.y, base.size.z,
		])
	var top_scale: float = float(PERIMETER.ROCK_HEIGHT) / float(PERIMETER.ROCK_MODEL_HEIGHT) * 1.32
	print("  biggest formation boulder possible: %.2fm across, %.2fm tall (Rock_Medium_3 at x%.2f)" % [
		3.48 * top_scale, 2.32 * top_scale, top_scale,
	])

	print("--- coursed wall top, per wall run ---")
	for s in 40:
		if s % 4 != 0:
			continue
		var i0: int = s * int(PERIMETER.SPANS_PER_SEGMENT)
		var course: PackedFloat32Array = node.call("_course_line", i0, int(PERIMETER.SPANS_PER_SEGMENT))
		var risers := 0
		var biggest_riser := 0.0
		for k in course.size() - 1:
			var d: float = absf(course[k + 1] - course[k])
			if d > 0.001:
				risers += 1
				biggest_riser = maxf(biggest_riser, d)
		var lo := INF
		var hi := -INF
		var kerb: float = float(PERIMETER.BANK_HEIGHT) + float(PERIMETER.KERB_HEIGHT)
		for k in course.size():
			var ground: float = float(node.get("_ring")[posmod(i0 + k, 720)].y)
			var height: float = course[k] - ground - kerb
			lo = minf(lo, height)
			hi = maxf(hi, height)
		if s % 8 == 0 or risers > 3:
			print("  wall run seg %2d: %d risers, biggest %.2fm; wall height above kerb %.2f .. %.2fm" % [
				s, risers, biggest_riser, lo, hi
			])
	quit(0)
