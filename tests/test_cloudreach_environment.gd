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


func test_cloud_sea_uses_clustered_banks_instead_of_independent_white_ovals() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(VISUAL_CONFIG_PATH))
	var cloud: Dictionary = config.get("cloud_sea", {})
	assert_between(int(cloud.get("billow_bank_count", 0)), 80, 120,
		"Cloud sea uses the reviewed 80-120 coherent bank range")
	assert_false(cloud.has("billow_count"),
		"The exhausted independent-billow mechanism is no longer configured")
	var lobes: Array = cloud.get("billow_lobes_per_bank", [])
	assert_eq([int(lobes[0]), int(lobes[1])], [4, 7],
		"Each bank is made from several related lobes")
	assert_true(Color(str(cloud.get("billow_base_colour", "#ffffff"))).get_luminance()
		< Color(str(cloud.get("billow_colour", "#ffffff"))).get_luminance(),
		"Cloud banks have a darker base instead of one flat white value")
	var source := FileAccess.get_file_as_string("res://scripts/world/cloudreach_world.gd")
	assert_true(source.contains("var tier := lobe_index % 3"),
		"Bank lobes occupy three height tiers")
	assert_true(source.contains("The low body crosses the sheet"),
		"Every bank includes a broad body intersecting its deck")


func test_terrain_wear_is_true_coverage_and_route_joints_do_not_restart_fades() -> void:
	var worn := FileAccess.get_file_as_string("res://shaders/cloudreach_worn_ground.gdshader")
	var trail := FileAccess.get_file_as_string("res://shaders/cloudreach_trail.gdshader")
	var world := FileAccess.get_file_as_string("res://scripts/world/cloudreach_world.gd")
	assert_true(worn.contains("if(dirt<=coverage_hash){discard;}"),
		"Settlement wear reveals the real crown outside its dirt mask")
	assert_false(worn.contains("mix(turf,soil,dirt)"),
		"Wear no longer paints imitation turf over its polygon footprint")
	assert_true(trail.contains("if(edge<=coverage_hash){discard;}"),
		"Trail edges reveal the real terrain through stable coverage")
	assert_true(trail.contains("end_distance=UV2.y"),
		"Trail vertices carry independent distance from both true ends")
	assert_true(world.contains("fade_start, fade_end"),
		"Route construction preserves the continuous mask across internal joints")
