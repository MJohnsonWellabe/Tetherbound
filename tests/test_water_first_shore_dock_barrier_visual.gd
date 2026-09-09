extends "res://tests/test_case.gd"

const DOCKS := preload("res://scripts/world/water_dock_actions.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")


func test_first_shore_blocker_visually_fills_the_existing_collision() -> void:
	var builder := DOCKS.new()
	var barrier := Node3D.new()
	builder.call("_build_first_shore_barrier_visual", barrier, 10.0, 2.5)
	assert_eq(barrier.get_child_count(), 15,
		"First Shore uses three full courses of five installed fence bays")
	var combined := AABB()
	var first := true
	for child: Node in barrier.get_children():
		assert_true(child is Node3D, "barrier visual children are installed scene roots")
		assert_true(child.name.begins_with("FirstShoreBarrierFence_"),
			"barrier visual has a scoped production identity")
		assert_eq(child.find_children("*", "CollisionObject3D", true, false).size(), 0,
			"installed fence visuals do not add collision")
		var local_bounds: AABB = RENDER_BOUNDS.measure(child as Node3D)
		var placed := (child as Node3D).transform * local_bounds
		combined = placed if first else combined.merge(placed)
		first = false
	assert_almost_eq(combined.position.x, -5.0, 0.002,
		"visible fence begins at the existing collision's west edge")
	assert_almost_eq(combined.end.x, 5.0, 0.002,
		"visible fence ends at the existing collision's east edge")
	assert_almost_eq(combined.position.y, 0.0, 0.002,
		"lowest fence course is grounded")
	assert_almost_eq(combined.end.y, 2.5, 0.002,
		"three kit-proportion courses depict the 2.5m solid blocker")
	assert_true(combined.size.z <= 0.13,
		"visible barrier remains inside the existing 0.35m collision depth")
	barrier.free()
	builder.free()


func test_other_departure_barriers_keep_the_existing_box_path() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/water_dock_actions.gd")
	assert_true(source.contains('if str(dock.id) == FIRST_SHORE_DOCK:'),
		"installed fence treatment is explicitly scoped to First Shore")
	assert_true(source.contains('_box(barrier, Vector3(0, height * 0.5, 0), Vector3(width, height, 0.35), Color("70583e"))'),
		"all other departure barriers retain their existing visual path")
	assert_true(source.contains("box.size = Vector3(width, height, 0.35)"),
		"the shared physical barrier keeps its exact configured dimensions")
