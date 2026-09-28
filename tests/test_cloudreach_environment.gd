extends "res://tests/test_case.gd"

const WORLD := preload("res://scripts/world/cloudreach_world.gd")
const VISUAL_CONFIG_PATH := "res://data/config/cloudreach_visual.json"

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


func test_cloud_banks_are_deterministic_and_below_registered_ground() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(VISUAL_CONFIG_PATH))
	var cloud: Dictionary = config["cloud_sea"].duplicate(true)
	cloud["billow_bank_count"] = 8
	config["cloud_sea"] = cloud
	var world := WORLD.new()
	world.set("_visual_config", config)
	world.set("_config", {"regions": [{"position": [0, 300, 0]}]})
	world.register_runtime_surface({"kind": "rect", "centre": Vector2.ZERO,
		"half": Vector2(10000, 10000), "height": 200.0})
	world.call("_build_materials")
	var first := Node3D.new()
	var second := Node3D.new()
	var heights: Array[float] = [500.0, 500.0, 500.0, 500.0]
	for parent in [first, second]:
		world.call("_add_cloud_billows", parent, cloud, 0.0, 0.0, 110.0, 2, 2, heights, 9000.0)
	var a := (first.get_node("CloudBillows") as MultiMeshInstance3D).multimesh
	var b := (second.get_node("CloudBillows") as MultiMeshInstance3D).multimesh
	assert_eq(a.instance_count, 8)
	var box := a.mesh.get_aabb()
	var ceiling := 200.0 - float(cloud["min_clearance_m"])
	for i in a.instance_count:
		var transform := a.get_instance_transform(i)
		assert_true(transform.is_equal_approx(b.get_instance_transform(i)), "stable bank placement after rebuild")
		assert_true(transform.basis.determinant() > 0.0, "finite positive cloud volume")
		var bounds := transform * box
		assert_true(bounds.end.y <= ceiling + 0.001, "whole bank proxy below registered ground clearance")
	first.free()
	second.free()
	world.free()


func test_route_joints_do_not_restart_fades() -> void:
	var trail := FileAccess.get_file_as_string("res://shaders/cloudreach_trail.gdshader")
	var world := FileAccess.get_file_as_string("res://scripts/world/cloudreach_world.gd")
	# Settlement wear is judged in native paired captures across grass and
	# paving. The former source assertions required its square-grid cutout.
	# Trail-edge appearance is verified in matched native captures. The old
	# exact discard-expression check pinned the visible square-grid defect.
	assert_true(trail.contains("end_distance=UV2.y"),
		"Trail vertices carry independent distance from both true ends")
	assert_true(world.contains("fade_start, fade_end"),
		"Route construction preserves the continuous mask across internal joints")
