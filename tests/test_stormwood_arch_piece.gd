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
	assert_true(frame != null, "installed WallEntrance mesh is present")
	assert_almost_eq(frame.mesh.get_aabb().size.y * frame.scale.y, ARCH.HEIGHT, 0.001)
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
