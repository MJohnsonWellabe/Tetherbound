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
