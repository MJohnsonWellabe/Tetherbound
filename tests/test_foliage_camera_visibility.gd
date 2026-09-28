extends "res://tests/test_case.gd"

const VISIBILITY := preload("res://scripts/world/foliage_camera_visibility.gd")
const BUSH := "res://assets/environment/stylized_nature/Bush_Common.gltf"

func _mesh() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.UP])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#78906f")
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = 0.45
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0,material)
	mesh.shadow_mesh = mesh.duplicate(false)
	return mesh

func test_solid_unknown_and_unlisted_models_keep_their_materials() -> void:
	var mesh := _mesh()
	assert_true(VISIBILITY.apply(mesh,BUSH,{"collides":true}) == mesh)
	assert_true(VISIBILITY.apply(mesh,BUSH,{}) == mesh)
	assert_true(VISIBILITY.apply(mesh,"res://assets/environment/stylized_nature/CommonTree_1.gltf",{"collides":false}) == mesh)
	assert_eq((mesh.surface_get_material(0) as BaseMaterial3D).distance_fade_mode,BaseMaterial3D.DISTANCE_FADE_DISABLED)

func test_bush_fade_cannot_mutate_shared_source_or_rebuild_geometry() -> void:
	var source := _mesh()
	var faded := VISIBILITY.apply(source,BUSH,{"collides":false}) as ArrayMesh
	assert_true(faded != source)
	assert_eq(faded.surface_get_arrays(0)[Mesh.ARRAY_VERTEX],source.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	assert_true(faded.shadow_mesh == source.shadow_mesh,"imported shadow mesh stays shared")
	var material := faded.surface_get_material(0) as ShaderMaterial
	var original := source.surface_get_material(0) as BaseMaterial3D
	assert_true(material != original)
	assert_eq(original.distance_fade_mode,BaseMaterial3D.DISTANCE_FADE_DISABLED)
	assert_eq(material.get_shader_parameter("leaf_tint"),original.albedo_color)
	assert_eq(material.get_shader_parameter("alpha_cutoff"),original.alpha_scissor_threshold)
	assert_true(material.get_shader_parameter("use_vertex_tint"),"Terrain3D instance colours survive")
	assert_true(material.get_meta("foliage_unfaded_material") == original)
	assert_true(material.get_shader_parameter("clear_distance") < material.get_shader_parameter("opaque_distance"))

func test_unsupported_leaf_features_are_not_silently_lost() -> void:
	var mesh := _mesh()
	var original := mesh.surface_get_material(0) as BaseMaterial3D
	original.normal_enabled = true
	var out := VISIBILITY.apply(mesh,BUSH,{"collides":false})
	assert_true(out.surface_get_material(0) == original)
