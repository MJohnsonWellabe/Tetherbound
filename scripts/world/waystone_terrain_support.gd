extends RefCounted

## Keep only a waystone's real Terrain3D triangles resident. Dynamic collision
## follows one camera; a host still needs ground beneath a distant guest's
## actual physics body. This adds no platform, height offset or permission.
## Vertices come from Terrain3D 1.0.2's native mesh sampler, on its own lattice.
const HALF_WIDTH := 8.0
const MAX_VERTICES := 2048
const CHILD_NAME := "ResidentTerrainSupport"

static func mount(world: Node3D, stone: Node3D) -> bool:
	if world == null or stone == null or not world.is_inside_tree() or not stone.is_inside_tree(): return false
	var terrain := world.get_node_or_null(^"Terrain") as Node3D
	if terrain == null or not terrain.is_class("Terrain3D") or int(terrain.get("collision_mode")) != 1: return false
	if terrain.global_transform != Transform3D.IDENTITY: return false
	var data: Object = terrain.get("data")
	if data == null or not is_instance_valid(data): return false
	var existing := stone.get_node_or_null(NodePath(CHILD_NAME))
	if existing != null:
		if existing.get_meta("terrain_source", null) is WeakRef \
			and existing.get_meta("terrain_source").get_ref() == data: return true
		stone.remove_child(existing)
		existing.queue_free()
	var center := stone.global_position
	if not center.is_finite(): return false
	var faces := native_faces(data, float(terrain.get("vertex_spacing")), center)
	if faces.is_empty() or faces.size() % 3 != 0 or faces.size() > MAX_VERTICES: return false
	for i in faces.size():
		faces[i] = stone.to_local(faces[i])
	var body := StaticBody3D.new()
	body.name = CHILD_NAME
	body.collision_layer = int(terrain.get("collision_layer"))
	body.collision_mask = int(terrain.get("collision_mask"))
	body.set_meta("terrain_source", weakref(data))
	var native_collision: Object = terrain.get("collision")
	if native_collision != null: body.physics_material_override = native_collision.get("physics_material")
	var collision := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	collision.shape = shape
	body.add_child(collision)
	stone.add_child(body)
	# If terrain data changes, stale triangles cannot remain physical support.
	# The normal mount poll can recreate them from the new native data.
	var invalidate := _invalidate.bind(weakref(body), weakref(stone))
	for signal_name: String in ["height_maps_changed", "control_maps_changed", "region_map_changed"]:
		data.connect(signal_name, invalidate, CONNECT_ONE_SHOT)
	return true

static func _invalidate(body_ref: WeakRef, stone_ref: WeakRef) -> void:
	# Signal argument captures must never retain freed Node values: Godot
	# validates captures before a lambda's own validity guard can execute.
	var body := body_ref.get_ref() as Node
	var stone := stone_ref.get_ref() as Node
	if is_instance_valid(body) and is_instance_valid(stone) \
		and not body.is_queued_for_deletion() and body.get_parent() == stone:
		stone.remove_child(body)
		body.queue_free()

static func native_faces(data: Object, spacing: float, center: Vector3) -> PackedVector3Array:
	var empty := PackedVector3Array()
	if data == null or not is_instance_valid(data) or not center.is_finite() \
		or not is_finite(spacing) or spacing < .25 or spacing > 100.0: return empty
	var minimum := Vector2i(ceili((center.x - HALF_WIDTH) / spacing), ceili((center.z - HALF_WIDTH) / spacing))
	var maximum := Vector2i(floori((center.x + HALF_WIDTH) / spacing), floori((center.z + HALF_WIDTH) / spacing))
	var cells := maximum - minimum + Vector2i.ONE
	if cells.x <= 0 or cells.y <= 0 or cells.x * cells.y * 6 > MAX_VERTICES: return empty
	var vertices: Array[Vector3] = []
	# Never repeat the native region-edge fallback which substitutes an absent
	# neighbor's height. A missing vertex or painted hole rejects this patch.
	for z in range(minimum.y, maximum.y + 2):
		for x in range(minimum.x, maximum.x + 2):
			var at := Vector3(float(x) * spacing, 0.0, float(z) * spacing)
			var vertex: Vector3 = data.call("get_mesh_vertex", 0, 0, at)
			if not vertex.is_finite() or vertex.x != at.x or vertex.z != at.z: return empty
			vertices.append(vertex)
	var faces := PackedVector3Array()
	var row := cells.x + 1
	for z in cells.y:
		for x in cells.x:
			var i := z * row + x
			# Same LOD0 winding/diagonal as Terrain3D's _generate_triangle_pair.
			for index: int in [i, i + row + 1, i + row, i, i + 1, i + row + 1]:
				faces.append(vertices[index])
	return faces
