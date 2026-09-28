extends "res://tests/test_case.gd"

const SILHOUETTE := preload("res://scripts/world/water_veilfall_silhouette.gd")


func test_far_relief_crowns_are_local_and_disabled_by_default() -> void:
	var settings := {"enabled": true, "peaks": [
		{"offset_xz_m": [20.0, -10.0], "radius_m": 80.0, "height_m": 50.0, "power": 0.85}
	]}
	assert_eq(SILHOUETTE._far_relief_height(Vector2(20.0, -10.0), settings), 50.0)
	assert_eq(SILHOUETTE._far_relief_height(Vector2(100.0, -10.0), settings), 0.0)
	assert_eq(SILHOUETTE._far_relief_height(Vector2(20.0, -10.0), {}), 0.0)


func test_disabled_candidate_adds_nothing() -> void:
	var world := Node3D.new()
	var far := SILHOUETTE.new()
	world.add_child(far)
	var composition := Node3D.new()
	world.add_child(composition)
	assert_eq(far.add_decorative_far_meshes(world, composition, {}), 0)
	assert_eq(far.get_child_count(), 0)
	world.free()


func test_far_copy_shares_visible_geometry_without_copying_collision_or_mutating_near() -> void:
	var world := Node3D.new()
	var composition := Node3D.new()
	composition.position = Vector3(12.0, 30.0, 80.0)
	composition.rotation.y = 0.4
	world.add_child(composition)
	var holder := Node3D.new()
	holder.name = "Shoulder"
	holder.position = Vector3(5.0, -2.0, 3.0)
	composition.add_child(holder)
	var source := MeshInstance3D.new()
	source.name = "FacetedCragBody"
	source.mesh = BoxMesh.new()
	source.scale = Vector3(2.0, 4.0, 3.0)
	source.visibility_range_end = 1100.0
	source.material_override = StandardMaterial3D.new()
	holder.add_child(source)
	var collider := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	collider.add_child(shape)
	holder.add_child(collider)
	var unrelated := MeshInstance3D.new()
	unrelated.name = "DoNotCopy"
	unrelated.mesh = BoxMesh.new()
	holder.add_child(unrelated)
	var far := SILHOUETTE.new()
	far.position = Vector3(-4.0, 0.0, 1.0)
	far.visibility_range_begin = 1100.0
	far.material_override = ShaderMaterial.new()
	world.add_child(far)
	var original_transform := source.transform
	var original_material := source.material_override
	assert_eq(far.add_decorative_far_meshes(world, composition,
		{"enabled": true, "mesh_names": ["FacetedCragBody", "VegetatedShelfCap"]}), 1)
	assert_eq(far.get_child_count(), 1)
	var copy := far.get_child(0) as MeshInstance3D
	assert_true(copy != null)
	if copy != null:
		assert_eq(copy.mesh, source.mesh, "share the authored mesh without rebuilding it")
		assert_true((far.transform * copy.transform).is_equal_approx(
			composition.transform * holder.transform * source.transform), "exact world placement")
		assert_eq(copy.visibility_range_begin, 1100.0)
		assert_eq(copy.visibility_range_end, 0.0)
		assert_eq(copy.material_override, far.material_override)
		assert_eq(copy.get_child_count(), 0, "never duplicate source collision children")
	assert_eq(source.transform, original_transform)
	assert_eq(source.material_override, original_material)
	assert_eq(source.visibility_range_end, 1100.0)
	assert_eq(holder.get_child_count(), 3, "near source hierarchy unchanged")
	assert_eq(collider.get_child_count(), 1)
	world.free()
