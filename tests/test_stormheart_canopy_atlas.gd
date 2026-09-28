extends "res://tests/test_case.gd"

const TREE := preload("res://scripts/world/stormheart_tree.gd")
const FAMILY_TREE := preload("res://assets/environment/stylized_nature/TwistedTree_2.gltf")


func test_canopy_candidate_keeps_authored_alpha_atlas_and_cached_material() -> void:
	var tree := TREE.new()
	var model := FAMILY_TREE.instantiate()
	var visuals := model.find_children("*", "MeshInstance3D", true, false)
	if model is MeshInstance3D:
		visuals.append(model)
	var original_textures: Array[Texture2D] = []
	for visual: MeshInstance3D in visuals:
		for surface in visual.mesh.get_surface_count():
			var source := visual.mesh.surface_get_material(surface) as StandardMaterial3D
			original_textures.append(source.albedo_texture)
	tree._presentation = {"enabled": true, "canopy_atlas": {"enabled": true, "leaf_colour": "#75924d", "roughness": 0.91}}
	tree._green_canopy(model)
	var corrected_count := 0
	var material_index := 0
	for visual: MeshInstance3D in visuals:
		for surface in visual.mesh.get_surface_count():
			var source := visual.mesh.surface_get_material(surface) as StandardMaterial3D
			assert_eq(source.albedo_texture, original_textures[material_index], "cached imported materials must not change")
			material_index += 1
			if source.resource_name == "Leaves_TwistedTree":
				corrected_count += 1
				var corrected := visual.get_surface_override_material(surface) as ShaderMaterial
				assert_true(corrected != null, "enabled leaf surface receives the material correction")
				if corrected != null:
					assert_eq(corrected.get_shader_parameter("leaf_atlas"), source.albedo_texture, "alpha texture remains paired with the imported leaf UVs")
					assert_eq(corrected.get_shader_parameter("alpha_cutoff"), source.alpha_scissor_threshold, "authored alpha cutoff is preserved")
			else:
				assert_true(visual.get_surface_override_material(surface) == null, "bark surfaces keep their original material")
	assert_true(corrected_count > 0, "the actual installed tree must exercise its leaf material")
	_free_model(model)
	tree.free()


func test_master_disabled_keeps_legacy_canopy_material() -> void:
	var tree := TREE.new()
	var model := FAMILY_TREE.instantiate()
	tree._presentation = {"enabled": false, "canopy_atlas": {"enabled": true}}
	tree._green_canopy(model)
	var visuals := model.find_children("*", "MeshInstance3D", true, false)
	if model is MeshInstance3D:
		visuals.append(model)
	var checked := 0
	for visual: MeshInstance3D in visuals:
		for surface in visual.mesh.get_surface_count():
			var source := visual.mesh.surface_get_material(surface) as StandardMaterial3D
			if source.resource_name == "Leaves_TwistedTree":
				checked += 1
				var legacy := visual.get_surface_override_material(surface) as StandardMaterial3D
				assert_true(legacy != null, "master disabled keeps the existing StandardMaterial path")
				if legacy != null:
					assert_true(legacy.albedo_texture.resource_path.ends_with("Leaves_NormalTree_C_desat55.png"), "disabled candidate preserves the current atlas")
	assert_true(checked > 0, "the disabled check must reach an actual leaf surface")
	_free_model(model)
	tree.free()


func _free_model(model: Node) -> void:
	# Retain detached overrides through destruction: Godot 4.7's dummy
	# renderer otherwise queries a released material during mesh cleanup.
	var retained: Array[Material] = []
	var visuals := model.find_children("*", "MeshInstance3D", true, false)
	if model is MeshInstance3D:
		visuals.append(model)
	for visual: MeshInstance3D in visuals:
		for surface in visual.get_surface_override_material_count():
			var material := visual.get_surface_override_material(surface)
			if material != null:
				retained.append(material)
				visual.set_surface_override_material(surface, null)
	model.free()
