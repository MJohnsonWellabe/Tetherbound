extends "res://tests/test_case.gd"

const FINISH := preload("res://scripts/world/stormwood_voltcap_finish.gd")
const LOOK := preload("res://scripts/world/stormwood_look.gd")


func test_off_profile_leaves_visual_untouched() -> void:
	var profile := FINISH.read_config()
	# Ships ON by coordinator decision (22 Oct wind-down: r11 beat control);
	# the OFF profile must still leave the visual untouched.
	assert_true(bool(profile.enabled), "finish ships ON")
	profile.enabled = false
	var visual := MeshInstance3D.new()
	visual.mesh = BoxMesh.new()
	var source := StandardMaterial3D.new()
	visual.mesh.surface_set_material(0, source)
	assert_eq(FINISH.apply(visual, profile), 0)
	assert_eq(visual.get_active_material(0), source)
	assert_eq(visual.get_surface_override_material(0), null)
	visual.free()


func test_installed_mushroom_keeps_mesh_atlas_and_transform() -> void:
	var profile := FINISH.read_config()
	profile.enabled = true
	var scene := load(str(profile.model)) as PackedScene
	assert_true(scene != null, "installed model is required")
	if scene == null:
		return
	var visual := scene.instantiate() as Node3D
	var meshes := visual.find_children("*", "MeshInstance3D", true, false)
	if visual is MeshInstance3D:
		meshes.push_front(visual)
	var sources: Array[Dictionary] = []
	for node: MeshInstance3D in meshes:
		for surface in node.mesh.get_surface_count():
			sources.append({"node": node, "surface": surface, "mesh": node.mesh,
				"transform": node.transform, "material": node.get_active_material(surface)})
	assert_true(FINISH.apply(visual, profile) > 0, "actual installed material must be supported")
	for entry: Dictionary in sources:
		var node := entry.node as MeshInstance3D
		assert_eq(node.mesh, entry.mesh, "geometry and LOD resources retained")
		assert_eq(node.transform, entry.transform, "authored scale/placement retained")
		assert_eq(node.mesh.surface_get_material(entry.surface), entry.material, "imported material retained")
		var adapted := node.get_surface_override_material(entry.surface) as ShaderMaterial
		assert_true(adapted != null)
		if adapted != null:
			assert_eq(adapted.get_shader_parameter("source_texture"), entry.material.albedo_texture)
	assert_eq(FINISH.apply(visual, profile), 0, "second application does not wrap the shader")
	visual.free()


func test_unrecognized_effect_material_is_preserved() -> void:
	var profile := FINISH.read_config()
	profile.enabled = true
	var visual := MeshInstance3D.new()
	visual.mesh = BoxMesh.new()
	var material := ShaderMaterial.new()
	visual.mesh.surface_set_material(0, material)
	assert_eq(FINISH.apply(visual, profile), 0)
	assert_eq(visual.get_active_material(0), material)
	visual.free()


func test_shared_look_preserves_the_voltcap_finish() -> void:
	var look := LOOK.new()
	look.config = LOOK.read_config()
	look.config.enabled = true
	var material := ShaderMaterial.new()
	material.shader = FINISH.SURFACE
	assert_eq(look.adapt_material(material), material, "biome material walk must retain the authored resource finish")
	assert_eq(material.shader, FINISH.SURFACE)
	look.free()
