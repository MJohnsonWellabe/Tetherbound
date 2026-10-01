extends "res://tests/test_case.gd"

## Meadows visual pass round 2: wall vines imported with every normal pointing
## up, so under a low moon they lit as ground and glowed white against a dark
## wall. `building_prefabs.gd::wall_foliage_mesh()` faces them out of the wall.

const PREFABS := preload("res://scripts/world/building_prefabs.gd")
const VINE := "res://assets/buildings/quaternius_medieval/Prop_Vine1.gltf"


func _first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _first_mesh(child)
		if found != null:
			return found
	return null


func test_the_shipped_vine_really_faces_up() -> void:
	var scene: Node = (load(VINE) as PackedScene).instantiate()
	var mesh := _first_mesh(scene).mesh
	var normals: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	assert_true(normals[0].y > 0.9, "if the kit is ever fixed upstream, this workaround can go")
	scene.free()


func test_repeated_prefab_placements_retain_modules_until_composer_release() -> void:
	var prefabs: RefCounted = PREFABS.new()
	prefabs.set("_recipes", {"cache_vines": {"modules": [
		{"module": "Prop_Vine1", "at": [1.0, 0.0, 0.0]},
		{"module": "Prop_Vine1", "at": [-1.0, 0.0, 0.0], "yaw_deg": 180.0, "scale": 0.5},
	]}})
	var first: Node3D = prefabs.call("instantiate", "cache_vines")
	# No strong test reference: keeping the scene alive is the composer's job.
	var module_ref: WeakRef = weakref(load(VINE))
	assert_true(module_ref.get_ref() != null, "placement retains the imported scene for cache reuse")
	if module_ref.get_ref() == null:
		first.free()
		return
	var module_id: int = module_ref.get_ref().get_instance_id()
	var second: Node3D = prefabs.call("instantiate", "cache_vines")
	assert_eq(module_ref.get_ref().get_instance_id(), module_id, "repeated placement keeps the same module resource")
	assert_true(first != second, "each placement owns a distinct node tree")
	assert_eq(first.get_child_count(), 2, "repeated modules preserve composition")
	assert_eq(second.get_child_count(), 2, "duplicate preserves composition")
	for index in 2:
		var a := first.get_child(index) as Node3D
		var b := second.get_child(index) as Node3D
		assert_true(a != b, "module nodes are distinct between placements")
		assert_eq(a.transform, b.transform, "duplicate keeps module placement")
	assert_eq((first.get_child(0) as Node3D).position, Vector3(1.0, 0.0, 0.0))
	assert_eq((first.get_child(1) as Node3D).position, Vector3(-1.0, 0.0, 0.0))
	var actual_rotation: Quaternion = (first.get_child(1) as Node3D).basis.get_rotation_quaternion().normalized()
	var expected_rotation: Quaternion = Basis(Vector3.UP, PI).get_rotation_quaternion().normalized()
	var relative_rotation: Quaternion = (expected_rotation.inverse() * actual_rotation).normalized()
	var rotation_error: float = 2.0 * atan2(
		Vector3(relative_rotation.x, relative_rotation.y, relative_rotation.z).length(),
		absf(relative_rotation.w))
	assert_almost_eq(rotation_error, 0.0, 0.0001, "same authored 180-degree rotation")
	assert_eq((first.get_child(1) as Node3D).scale, Vector3.ONE * 0.5)
	var original: Node3D = (load(VINE) as PackedScene).instantiate()
	var source := _first_mesh(original).mesh
	var first_mesh := _first_mesh(first)
	var second_mesh := _first_mesh(second)
	assert_eq(first_mesh.mesh.get_aabb(), source.get_aabb(), "same imported geometry bounds")
	assert_eq(first_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX],
		source.surface_get_arrays(0)[Mesh.ARRAY_VERTEX], "same imported vertices")
	var source_material := source.surface_get_material(0) as StandardMaterial3D
	var source_colour := source_material.albedo_color
	var sibling_material := second_mesh.get_active_material(0)
	prefabs.call("apply_retint", first, {source_material.resource_name: "#123456"})
	assert_eq((first_mesh.get_active_material(0) as StandardMaterial3D).albedo_color, Color("#123456"))
	assert_eq(second_mesh.get_active_material(0), sibling_material, "retint leaves sibling material untouched")
	assert_eq(source_material.albedo_color, source_colour, "retint leaves imported material untouched")
	var third: Node3D = prefabs.call("instantiate", "cache_vines")
	assert_eq(_first_mesh(third).get_active_material(0), sibling_material, "retint leaves cached template untouched")
	original.free()
	prefabs = null
	assert_true(module_ref.get_ref() == null, "composer release drops the PackedScene even with placed nodes alive")
	assert_eq(first_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX],
		source.surface_get_arrays(0)[Mesh.ARRAY_VERTEX], "placed meshes survive composer release")
	assert_eq((first_mesh.get_active_material(0) as StandardMaterial3D).albedo_color,
		Color("#123456"), "placed retint survives composer release")
	first.free()
	second.free()
	third.free()


func test_every_vine_normal_faces_out_of_the_wall_and_nothing_else_changes() -> void:
	var prefabs: RefCounted = PREFABS.new()
	var scene: Node = (load(VINE) as PackedScene).instantiate()
	var source := _first_mesh(scene).mesh
	var fixed: Mesh = prefabs.call("wall_foliage_mesh", source)
	assert_eq(fixed.get_surface_count(), source.get_surface_count())
	for s in source.get_surface_count():
		var before: Array = source.surface_get_arrays(s)
		var after: Array = fixed.surface_get_arrays(s)
		assert_eq(after[Mesh.ARRAY_VERTEX], before[Mesh.ARRAY_VERTEX], "same geometry")
		assert_eq(after[Mesh.ARRAY_TEX_UV], before[Mesh.ARRAY_TEX_UV], "same UVs")
		assert_eq(after[Mesh.ARRAY_INDEX], before[Mesh.ARRAY_INDEX], "same triangles")
		for n: Vector3 in (after[Mesh.ARRAY_NORMAL] as PackedVector3Array):
			assert_true(n.dot(Vector3.BACK) > 0.999, "normal %s must face +Z" % n)
		assert_eq(fixed.surface_get_material(s), source.surface_get_material(s), "same leaf material")
	assert_eq(prefabs.call("wall_foliage_mesh", source), fixed, "one copy per source mesh")
	scene.free()
