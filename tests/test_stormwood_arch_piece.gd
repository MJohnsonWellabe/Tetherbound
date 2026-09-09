extends "res://tests/test_case.gd"

const ARCH := preload("res://scripts/build/stormwood_arch_piece.gd")


func _collision_shapes(piece: Node3D) -> Array[CollisionShape3D]:
	var found: Array[CollisionShape3D] = []
	for child in piece.get_children():
		if child is StaticBody3D:
			for shape: Node in child.get_children():
				if shape is CollisionShape3D:
					found.append(shape as CollisionShape3D)
	return found


func test_real_arch_is_normalized_to_four_metres_and_leaves_a_real_aperture() -> void:
	var arch := ARCH.new()
	arch.build_real()
	var frame := arch.get_node_or_null("StormglassFrame") as MeshInstance3D
	assert_true(frame != null, "installed WallEntranceBricks mesh is present")
	assert_almost_eq(frame.mesh.get_aabb().size.y * frame.scale.y, ARCH.HEIGHT, 0.001)
	assert_eq(frame.mesh.get_surface_count(), 2, "installed frame preserves masonry and raised-detail surfaces")
	assert_eq(frame.mesh.surface_get_name(0), "LightRock", "surface 0 is the installed broad masonry")
	assert_eq(frame.mesh.surface_get_name(1), "DarkRock", "surface 1 is the installed raised brick detail")
	var masonry := frame.get_surface_override_material(0) as StandardMaterial3D
	var stormglass := frame.get_surface_override_material(1) as StandardMaterial3D
	assert_true(masonry != null and stormglass != null, "frame and stormglass details have separate materials")
	assert_false(masonry.emission_enabled, "broad masonry never becomes an emissive white block")
	assert_true(stormglass.emission_enabled, "raised stormglass details carry the relight state")
	var rear := arch.get_node_or_null("RearStormglassDetails") as MeshInstance3D
	assert_true(rear != null, "installed raised detail is readable from both directions of travel")
	assert_eq(rear.mesh.get_surface_count(), 1, "rear duplicate contains only installed detail geometry")
	assert_eq(rear.get_surface_override_material(0), stormglass, "both faces share one relight state")
	var frame_bounds: AABB = frame.transform * frame.mesh.get_aabb()
	var rear_bounds: AABB = rear.transform * rear.mesh.get_aabb()
	assert_almost_eq(rear_bounds.end.z, frame_bounds.position.z, 0.002,
		"mirrored detail begins on the measured rear shell face")
	assert_true(rear_bounds.position.z < frame_bounds.position.z - 0.05,
		"mirrored detail projects visibly outside the rear shell")
	var detail_vertices := frame.mesh.surface_get_arrays(1)[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var detail_min_z := INF
	var detail_max_z := -INF
	for vertex: Vector3 in detail_vertices:
		detail_min_z = minf(detail_min_z, vertex.z)
		detail_max_z = maxf(detail_max_z, vertex.z)
	assert_almost_eq(detail_min_z, ARCH.FRONT_DETAIL_BASE_Z, 0.0001,
		"installed front detail begins on its measured shell face")
	assert_true((detail_max_z - detail_min_z) * frame.scale.z > 0.05,
		"installed front detail projects visibly outside its shell face")
	var shapes := _collision_shapes(arch)
	assert_eq(shapes.size(), 3, "two jambs plus lintel; never one doorway-sealing AABB")
	var centre_blocked := false
	for collision in shapes:
		var box := collision.shape as BoxShape3D
		if absf(collision.position.x) < 0.001 and collision.position.y < ARCH.OPEN_HEIGHT:
			centre_blocked = true
		assert_true(box.size.x > 0.0 and box.size.y > 0.0 and box.size.z > 0.0)
	assert_false(centre_blocked, "the lower centre remains open for walking")
	arch.free()


func test_authored_display_reuses_finish_without_constructed_collision() -> void:
	var arch := ARCH.new()
	arch.build_display()
	assert_true(arch.get_node_or_null("StormglassFrame") is MeshInstance3D)
	assert_true(_collision_shapes(arch).is_empty(), "ancient arch keeps runtime-owned collision exactly")
	arch.set_lit(true)
	assert_true(arch.is_lit(), "authored display uses the same relit presentation state")
	arch.free()


func test_ghost_has_no_collision_and_supports_existing_placer_tint_api() -> void:
	var ghost := ARCH.new()
	ghost.build_ghost()
	assert_true(ghost.has_method("tint_ghost_state"))
	assert_true(ghost.has_method("tint_ghost"))
	assert_true(_collision_shapes(ghost).is_empty(), "ghost preview never creates collision")
	ghost.tint_ghost_state(ARCH.STATE_UNSUPPORTED)
	var frame := ghost.get_node_or_null("StormglassFrame") as MeshInstance3D
	assert_true(frame.material_override is StandardMaterial3D)
	assert_eq((frame.material_override as StandardMaterial3D).transparency,
		BaseMaterial3D.TRANSPARENCY_ALPHA)
	ghost.free()


func test_lit_hook_changes_only_the_arch_presentation_state() -> void:
	var arch := ARCH.new()
	arch.build_real()
	assert_false(arch.is_lit())
	arch.set_lit(true, 1.5)
	assert_true(arch.is_lit())
	arch.set_lit(false)
	assert_false(arch.is_lit())
	arch.free()
