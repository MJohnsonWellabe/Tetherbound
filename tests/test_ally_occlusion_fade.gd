extends "res://tests/test_case.gd"

## MEADOWS-VISUAL-PASS: the piloted ally fades while it hides the foe from the
## camera (`scripts/combat/ally_occlusion_fade.gd`). Geometry only; no scene.

const FADE := preload("res://scripts/combat/ally_occlusion_fade.gd")

## A Terrapup-sized body: 2.9m wide, 3.85m tall, standing on the origin.
const ALLY_BOUNDS := AABB(Vector3(-1.46, 0.0, -1.46), Vector3(2.92, 3.85, 2.92))


func test_a_small_foe_straight_behind_a_big_ally_is_hidden() -> void:
	# Lens 9.5m behind and above the ally; the foe 2.5m on the other side.
	var eye := Vector3(0.0, 6.3, 8.6)
	var hidden := FADE.hidden_points(eye, Vector3(0.0, 0.0, -2.5), 2.0, Transform3D.IDENTITY, ALLY_BOUNDS)
	assert_true(hidden >= 2, "the foe behind the dome should read as hidden, got %d" % hidden)


func test_a_foe_off_to_the_side_is_not_hidden() -> void:
	var eye := Vector3(0.0, 6.3, 8.6)
	var hidden := FADE.hidden_points(eye, Vector3(4.5, 0.0, -2.5), 2.0, Transform3D.IDENTITY, ALLY_BOUNDS)
	assert_eq(hidden, 0)


func test_the_empty_corner_of_the_bounds_box_does_not_count() -> void:
	# A ray through the box's top corner but outside the inscribed ellipsoid.
	var corner := Vector3(1.4, 3.8, 1.4)
	assert_false(FADE.segment_hits_ellipsoid(corner + Vector3(0.0, 0.0, 5.0), corner + Vector3(0.0, 0.0, -5.0),
		Transform3D.IDENTITY, ALLY_BOUNDS))
	assert_true(FADE.segment_hits_ellipsoid(Vector3(0.0, 1.9, 5.0), Vector3(0.0, 1.9, -5.0),
		Transform3D.IDENTITY, ALLY_BOUNDS), "straight through the middle")


func test_a_foe_in_front_of_the_ally_is_never_hidden_by_it() -> void:
	# The segment stops at the foe, so a body beyond the foe cannot hide it.
	var eye := Vector3(0.0, 6.3, 12.0)
	assert_eq(FADE.hidden_points(eye, Vector3(0.0, 0.0, 5.0), 2.0, Transform3D.IDENTITY, ALLY_BOUNDS), 0)


func test_the_ally_transform_moves_the_ellipsoid() -> void:
	var moved := Transform3D(Basis.IDENTITY, Vector3(10.0, 0.0, 0.0))
	assert_false(FADE.segment_hits_ellipsoid(Vector3(0.0, 1.9, 5.0), Vector3(0.0, 1.9, -5.0), moved, ALLY_BOUNDS))
	assert_true(FADE.segment_hits_ellipsoid(Vector3(10.0, 1.9, 5.0), Vector3(10.0, 1.9, -5.0), moved, ALLY_BOUNDS))


func _mesh_with(material: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.material = material
	mesh.mesh = box
	return mesh


func test_apply_dithers_every_surface_and_restores_what_was_there() -> void:
	var root := Node3D.new()
	var shipped := StandardMaterial3D.new()
	var a := _mesh_with(shipped)
	var nested := Node3D.new()
	var b := _mesh_with(shipped)
	var colourway := StandardMaterial3D.new()
	b.set_surface_override_material(0, colourway)
	root.add_child(a)
	root.add_child(nested)
	nested.add_child(b)
	var state := {}
	FADE.apply(root, 0.6, state)
	var faded_a := a.get_active_material(0) as BaseMaterial3D
	assert_eq(faded_a.distance_fade_mode, BaseMaterial3D.DISTANCE_FADE_OBJECT_DITHER)
	assert_eq(faded_a.transparency, BaseMaterial3D.TRANSPARENCY_DISABLED,
		"stays in the opaque pass, so the body keeps its own depth order")
	assert_true(b.get_active_material(0) != colourway, "the colourway surface is faded too")
	FADE.apply(root, 0.3, state)
	assert_true(a.get_active_material(0) == faded_a, "a changing fade reuses the same copy")
	FADE.apply(root, 0.0, state)
	assert_true(a.get_surface_override_material(0) == null, "the shipped material shows again")
	assert_true(b.get_surface_override_material(0) == colourway, "the colourway comes back")
	assert_true(state.is_empty())
	root.free()


func test_the_dither_covers_the_wanted_fraction_at_the_camera_distance() -> void:
	# OBJECT_DITHER draws clamp((d - 0) / max) of the pixels.
	var max_d := FADE.dither_max_distance(10.0, 0.6)
	assert_almost_eq(10.0 / max_d, 0.4, 0.0001)


func test_a_swap_made_during_the_fade_is_not_undone() -> void:
	var a := _mesh_with(StandardMaterial3D.new())
	var state := {}
	FADE.apply(a, 0.6, state)
	var night := StandardMaterial3D.new()
	a.set_surface_override_material(0, night)
	FADE.restore(state)
	assert_true(a.get_surface_override_material(0) == night)
	a.free()


func test_the_config_is_declared() -> void:
	var camera: Dictionary = (load("res://scripts/combat/combat_math.gd").config().get("camera", {}) as Dictionary)
	var cfg: Dictionary = camera.get("occlusion_fade", {}) as Dictionary
	assert_true(bool(cfg.get("enabled", false)))
	assert_true(float(cfg.get("transparency", 0.0)) > 0.0 and float(cfg.get("transparency", 1.0)) < 1.0)
