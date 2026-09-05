extends "res://tests/test_case.gd"

const WORLD := preload("res://scripts/world/cloudreach_world.gd")

func test_generated_ground_faces_upward() -> void:
	var world := WORLD.new()
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	world.call("_add_surface_triangle", tool, Vector3(-1, 0, 0), Vector3(-1, 0, 1), Vector3(1, 0, 0))
	tool.generate_normals()
	var mesh := tool.commit()
	var arrays := mesh.surface_get_arrays(0)
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	assert_true(normals[0].y > 0.9, "Terrain triangles must face the player above them; normal=%s" % normals[0])
	world.free()


func test_cliff_walls_face_outward() -> void:
	var world := WORLD.new()
	world.set("_visual_config", {})
	world.call("_build_materials")
	var materials: Dictionary = world.get("_materials")
	var parent := Node3D.new()
	var mesa: Node3D = world.call("_mesa", parent, "TestMesa", Vector3.ZERO, Vector3(40, 60, 40),
		materials["cliff"], materials["upland"], false, 31)
	var mesh := (mesa.get_node("StratifiedCliffBody") as MeshInstance3D).mesh
	var cap := mesh.surface_get_arrays(0)
	assert_true((cap[Mesh.ARRAY_NORMAL] as PackedVector3Array)[0].y > 0.9, "Mesa cap is visible from above")
	assert_eq(mesh.get_surface_count(), 2, "Shared geology submits one cliff surface plus its separate ground cap")
	for surface in range(1, mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(surface)
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var outward := Vector3(positions[0].x, 0, positions[0].z).normalized()
		assert_true(normals[0].dot(outward) > 0.1, "Cliff band %d must face the outer landscape" % surface)
	parent.free()
	world.free()
