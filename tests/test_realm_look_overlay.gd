extends "res://tests/test_case.gd"

## MEADOWS-VISUAL-PASS round 5: a realm's own look is deep-merged over the
## shared art.json presets (world_look.gd::merged_look), so a Meadows-only
## value never leaks into another chapter's sky.

const WORLD_LOOK := preload("res://scripts/world/world_look.gd")
const MEADOWS_LOOK := preload("res://scripts/world/meadows_look.gd")
const MEADOWS_FINISH := preload("res://scripts/world/meadows_surface_finish.gd")
const MEADOWS_GRADE := preload("res://scripts/world/meadows_colour_grade.gd")


func test_the_overlay_merges_key_by_key_and_leaves_both_inputs_alone() -> void:
	var base := {"environment": {"fog_colour": "#a6bccb", "exposure": 0.6}, "times": {"day": {"hour": 8.0}}}
	var overlay := {"environment": {"fog_colour": "#98b2cb"}, "horizon_mountains": {"strength": 1.0}}
	var merged: Dictionary = WORLD_LOOK.merged_look(base, overlay)
	assert_eq(str((merged["environment"] as Dictionary)["fog_colour"]), "#98b2cb")
	assert_almost_eq(float((merged["environment"] as Dictionary)["exposure"]), 0.6, 0.0001,
		"a key the overlay does not name keeps the shared value")
	assert_true(merged.has("horizon_mountains"))
	assert_eq(str((base["environment"] as Dictionary)["fog_colour"]), "#a6bccb", "base untouched")


func test_only_the_meadows_scene_carries_the_meadows_look() -> void:
	var meadows := FileAccess.get_file_as_string("res://scenes/world/meadows_playground.tscn")
	assert_true(meadows.contains('realm_look_path = "res://data/config/meadows_look.json"'))
	for other: String in ["res://scenes/world/cloudreach_cliffs.tscn", "res://scenes/world/stormwood.tscn",
			"res://scenes/world/water_archipelago.tscn"]:
		assert_false(FileAccess.get_file_as_string(other).contains("meadows_look.json"),
			"%s must keep its own horizon" % other)


func test_the_meadows_haze_lives_in_the_meadows_overlay() -> void:
	var meadows: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/meadows_look.json"))
	var env: Dictionary = (meadows as Dictionary).get("environment", {})
	assert_true(env.has("fog_colour"), "the Meadows distance haze is the overlay's to set")
	var art: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/art.json"))
	assert_ne(str(((art as Dictionary).get("environment", {}) as Dictionary).get("fog_colour", "")),
		str(env.get("fog_colour", "")), "art.json keeps the shared haze for the other realms")


func test_disabled_meadows_candidate_keeps_the_shipping_look() -> void:
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/art.json"))
	var overlay: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/meadows_look.json"))
	assert_false(bool(overlay.look_candidate.enabled), "unjudged candidate must ship OFF")
	var look := MEADOWS_LOOK.new()
	look.realm_look_path = "res://data/config/meadows_look.json"
	var resolved: Dictionary = look.call("_load")
	var expected := WORLD_LOOK.merged_look(base, overlay)
	assert_eq(resolved, expected, "disabled subclass must retain exact shipping lighting")
	look.free()


func test_candidate_preserves_the_clock_and_held_night() -> void:
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/art.json"))
	var candidate: Dictionary = MEADOWS_FINISH.settings().lighting
	var merged := WORLD_LOOK.merged_look(base, candidate)
	for time: String in ["dawn", "day", "golden", "night", "night_end"]:
		assert_eq(merged.times[time].hour, base.times[time].hour, "art must not move gameplay clock boundaries")
	var night := WORLD_LOOK._preset_over(merged, "night")
	var held := WORLD_LOOK._preset_over(merged, "night_end")
	for section: String in ["sun", "sky", "environment"]:
		assert_eq(held[section], night[section], "held night must inherit the whole Meadows rig")


func test_surface_candidate_preserves_imported_material_and_is_idempotent() -> void:
	var settings := MEADOWS_FINISH.settings()
	var was_enabled := bool(settings.enabled)
	settings.enabled = true
	var source := StandardMaterial3D.new()
	source.albedo_color = Color("#76894e")
	source.roughness = 0.87
	source.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	source.cull_mode = BaseMaterial3D.CULL_DISABLED
	var finished := MEADOWS_FINISH.finish_standard(source)
	assert_ne(finished, source, "never mutate a shared imported material")
	assert_false(source.detail_enabled)
	assert_eq(finished.albedo_color, source.albedo_color)
	assert_eq(finished.roughness, source.roughness)
	assert_eq(finished.transparency, source.transparency)
	assert_eq(finished.cull_mode, source.cull_mode)
	assert_true(finished.detail_enabled)
	assert_true(finished.rim_enabled, "eligible kit materials join the shared rim family")
	assert_eq(finished.diffuse_mode, BaseMaterial3D.DIFFUSE_TOON)
	assert_eq(source.diffuse_mode, BaseMaterial3D.DIFFUSE_BURLEY)
	assert_false(source.rim_enabled, "the imported source retains its authored lighting")
	assert_almost_eq(finished.rim, float(settings.surface.rim_strength), 0.0001)
	assert_almost_eq(finished.rim_tint, float(settings.surface.rim_tint), 0.0001)
	assert_eq(MEADOWS_FINISH.finish_standard(finished), finished, "streaming revisit must not stack treatment")
	settings.enabled = was_enabled
	assert_eq(MEADOWS_FINISH.finish_standard(source), source, "OFF does not even duplicate a source")
	assert_false(bool(MEADOWS_FINISH.shader_parameters().meadows_rim_enabled), "master OFF also gates shader rim")


func test_rim_preserves_authored_detail_normal_ao_and_existing_rim() -> void:
	var settings := MEADOWS_FINISH.settings()
	var was_enabled := bool(settings.enabled)
	settings.enabled = true
	var source := StandardMaterial3D.new()
	source.detail_enabled = true
	source.detail_albedo = GradientTexture2D.new()
	source.detail_normal = GradientTexture2D.new()
	source.normal_enabled = true
	source.normal_texture = GradientTexture2D.new()
	source.normal_scale = 0.37
	source.ao_enabled = true
	source.ao_texture = GradientTexture2D.new()
	source.ao_light_affect = 0.23
	var finished := MEADOWS_FINISH.finish_standard(source)
	assert_ne(finished, source, "authored detail does not prevent adding the missing rim term")
	assert_eq(finished.detail_albedo, source.detail_albedo)
	assert_eq(finished.detail_normal, source.detail_normal)
	assert_eq(finished.normal_texture, source.normal_texture)
	assert_eq(finished.normal_scale, source.normal_scale)
	assert_eq(finished.ao_texture, source.ao_texture)
	assert_eq(finished.ao_light_affect, source.ao_light_affect)
	assert_true(finished.normal_enabled and finished.ao_enabled and finished.rim_enabled)
	source.rim_enabled = true
	source.rim = 0.42
	source.rim_tint = 0.19
	source.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	assert_eq(MEADOWS_FINISH.finish_standard(source), source, "complete authored terms need no override")
	assert_almost_eq(source.rim, 0.42, 0.0001)
	assert_almost_eq(source.rim_tint, 0.19, 0.0001)
	source.detail_enabled = false
	source.normal_enabled = false
	var with_detail := MEADOWS_FINISH.finish_standard(source)
	assert_ne(with_detail, source)
	assert_almost_eq(with_detail.rim, 0.42, 0.0001, "adding detail preserves authored rim")
	assert_almost_eq(with_detail.rim_tint, 0.19, 0.0001)
	settings.enabled = was_enabled


func test_rim_subswitch_and_material_exclusions_preserve_their_scope() -> void:
	var settings := MEADOWS_FINISH.settings()
	var saved := settings.duplicate(true)
	settings.enabled = true
	settings.surface.rim_enabled = false
	var plain := StandardMaterial3D.new()
	assert_false(MEADOWS_FINISH.finish_standard(plain).rim_enabled)
	assert_false(bool(MEADOWS_FINISH.shader_parameters().meadows_rim_enabled))
	settings.surface.rim_enabled = true
	for kind: String in ["emissive", "glass", "unshaded"]:
		var source := StandardMaterial3D.new()
		if kind == "emissive":
			source.emission_enabled = true
		elif kind == "glass":
			source.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		else:
			source.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		assert_eq(MEADOWS_FINISH.finish_standard(source), source, "%s remains authored" % kind)
	settings.clear()
	settings.merge(saved, true)


func test_procedural_detail_cannot_replace_base_normals_or_retarget_uv2_ao() -> void:
	var settings := MEADOWS_FINISH.settings()
	var was_enabled := bool(settings.enabled)
	settings.enabled = true
	for kind: String in ["normal", "uv2_ao"]:
		var source := StandardMaterial3D.new()
		source.normal_enabled = kind == "normal"
		source.normal_texture = GradientTexture2D.new()
		source.normal_scale = 0.37
		source.ao_enabled = kind == "uv2_ao"
		source.ao_on_uv2 = kind == "uv2_ao"
		source.ao_texture = GradientTexture2D.new()
		source.uv2_scale = Vector3(3.0, 4.0, 1.0)
		source.uv2_offset = Vector3(0.1, 0.2, 0.0)
		var active := MEADOWS_FINISH.finish_standard(source)
		assert_false(active.detail_enabled, "%s must not acquire the opaque detail-normal replacement" % kind)
		assert_eq(active.normal_enabled, source.normal_enabled)
		assert_eq(active.normal_texture, source.normal_texture)
		assert_eq(active.normal_scale, source.normal_scale)
		assert_eq(active.ao_enabled, source.ao_enabled)
		assert_eq(active.ao_on_uv2, source.ao_on_uv2)
		assert_eq(active.ao_texture, source.ao_texture)
		assert_eq(active.uv2_scale, source.uv2_scale)
		assert_eq(active.uv2_offset, source.uv2_offset)
		assert_false(active.uv2_triplanar)
		assert_true(active.rim_enabled)
		assert_eq(active.diffuse_mode, BaseMaterial3D.DIFFUSE_TOON)
	settings.enabled = was_enabled


func test_runtime_shader_keeps_its_streaming_writer_reference() -> void:
	var settings := MEADOWS_FINISH.settings()
	var was_enabled := bool(settings.enabled)
	settings.enabled = true
	var source := ShaderMaterial.new()
	source.shader = Shader.new()
	source.shader.code = "shader_type spatial;\n#include \"res://shaders/meadows_surface.gdshaderinc\"\nuniform float terrain_offset = 0.0; void fragment() { ALBEDO = vec3(terrain_offset); }"
	var finish := MEADOWS_FINISH.new()
	var active: ShaderMaterial = finish.call("_finish", source)
	assert_eq(active, source, "runtime grass still owns the material the surface renders")
	source.set_shader_parameter("terrain_offset", 128.0)
	assert_eq(active.get_shader_parameter("terrain_offset"), 128.0, "streaming updates must remain visible")
	finish.free()
	settings.enabled = was_enabled


func test_toon_variant_preserves_shader_source_and_live_parameters() -> void:
	var settings := MEADOWS_FINISH.settings()
	var saved := settings.duplicate(true)
	var original := Shader.new()
	original.code = "shader_type spatial;\n#include \"res://shaders/meadows_surface.gdshaderinc\"\n#ifdef MEADOWS_TOON\nrender_mode diffuse_toon, specular_disabled;\n#else\nrender_mode diffuse_lambert, specular_disabled;\n#endif\nuniform float terrain_offset = 0.0;\nuniform sampler2D terrain_map;\nvoid fragment() { ALBEDO = vec3(terrain_offset); }"
	var code := original.code
	settings.enabled = false
	assert_eq(MEADOWS_FINISH.finish_shader(original), original, "OFF selects the authored shader object")
	settings.enabled = true
	settings.surface.toon_enabled = false
	assert_eq(MEADOWS_FINISH.finish_shader(original), original, "subswitch isolates stepped shading")
	settings.surface.toon_enabled = true
	var source := ShaderMaterial.new()
	source.shader = original
	var texture := GradientTexture2D.new()
	source.set_shader_parameter("terrain_offset", 128.0)
	source.set_shader_parameter("terrain_map", texture)
	var finish := MEADOWS_FINISH.new()
	var active: ShaderMaterial = finish.call("_finish", source)
	assert_eq(active, source, "streaming retains the same material writer")
	assert_ne(active.shader, original)
	assert_eq(original.code, code, "other realms retain the original compiled source")
	assert_eq(active.shader.code, "#define MEADOWS_TOON\n" + code)
	assert_eq(MEADOWS_FINISH.finish_shader(original), active.shader, "one variant per source")
	assert_eq(MEADOWS_FINISH.finish_shader(active.shader), active.shader, "no stacked defines")
	assert_eq(active.get_shader_parameter("terrain_offset"), 128.0)
	assert_eq(active.get_shader_parameter("terrain_map"), texture)
	source.set_shader_parameter("terrain_offset", 256.0)
	assert_eq(active.get_shader_parameter("terrain_offset"), 256.0)
	finish.free()
	settings.clear()
	settings.merge(saved, true)


func test_colour_grade_is_gated_local_cached_and_preserves_clock_adjustments() -> void:
	var candidate := MEADOWS_FINISH.settings().duplicate(true)
	var source := Environment.new()
	var authored := GradientTexture1D.new()
	source.adjustment_color_correction = authored
	source.adjustment_contrast = 1.06
	source.adjustment_saturation = 0.8
	source.tonemap_exposure = 0.63
	candidate.enabled = false
	assert_eq(MEADOWS_GRADE.apply_to(source, candidate), source)
	candidate.enabled = true
	candidate.colour_grade.enabled = false
	assert_eq(MEADOWS_GRADE.apply_to(source, candidate), source)
	candidate.colour_grade.enabled = true
	var active := MEADOWS_GRADE.apply_to(source, candidate)
	assert_ne(active, source, "do not mutate a shared authored environment")
	assert_eq(source.adjustment_color_correction, authored)
	assert_false(source.adjustment_enabled)
	assert_true(active.adjustment_enabled)
	assert_almost_eq(active.adjustment_contrast, 1.06, 0.0001)
	assert_almost_eq(active.adjustment_saturation, 0.8, 0.0001)
	assert_almost_eq(active.tonemap_exposure, 0.63, 0.0001)
	assert_true(active.adjustment_color_correction is GradientTexture1D)
	var lut := active.adjustment_color_correction as GradientTexture1D
	assert_eq(lut.width, 256)
	assert_eq(lut.gradient.sample(0.0), Color.BLACK)
	assert_eq(lut.gradient.sample(1.0), Color.WHITE)
	assert_eq(MEADOWS_GRADE.apply_to(active, candidate), active, "clock updates do not allocate another environment")
	var other := MEADOWS_GRADE.apply_to(Environment.new(), candidate)
	assert_eq(other.adjustment_color_correction, lut, "the small LUT is shared, not regenerated per clock tick")


func test_all_opted_in_shader_variants_keep_the_uniform_interface() -> void:
	var settings := MEADOWS_FINISH.settings()
	var saved := settings.duplicate(true)
	settings.enabled = true
	settings.surface.toon_enabled = true
	for name: String in ["terrain_ground", "grass_field", "cover_tier", "far_cover", "stone_field",
			"earth_bank", "ironwood_ancient_tree", "warrens_boulder_stain"]:
		var source := load("res://shaders/%s.gdshader" % name) as Shader
		assert_true(source != null, "%s source loads" % name)
		if source == null:
			continue
		var active := MEADOWS_FINISH.finish_shader(source)
		assert_ne(active, source, "%s selects its candidate variant" % name)
		var original_uniforms := source.get_shader_uniform_list()
		assert_false(original_uniforms.is_empty(), "%s parsed its uniforms" % name)
		assert_eq(active.get_shader_uniform_list(), original_uniforms,
			"%s retains terrain/streaming/wind and surface inputs" % name)
	settings.clear()
	settings.merge(saved, true)


func test_runtime_instance_buffer_keeps_its_streaming_writer_reference() -> void:
	_check_runtime_instance_buffer(false)


## The per-instance API is a no-op in Godot 4.7's dummy renderer. Keep its
## exact transform assertion in smoke_meadows_instance_buffer.gd, which
## requires a renderer; the headless suite checks the retained RID's buffer.
func check_runtime_instance_transform_with_renderer() -> void:
	_check_runtime_instance_buffer(true)


func _check_runtime_instance_buffer(per_instance: bool) -> void:
	var settings := MEADOWS_FINISH.settings()
	var was_enabled := bool(settings.enabled)
	settings.enabled = true
	var source := MultiMesh.new()
	source.transform_format = MultiMesh.TRANSFORM_3D
	source.instance_count = 1
	var mesh := BoxMesh.new()
	mesh.material = StandardMaterial3D.new()
	source.mesh = mesh
	var finish := MEADOWS_FINISH.new()
	var active: MultiMesh = finish.call("_finish_multimesh", source)
	assert_eq(active, source, "runtime instancer retains the rendered transform buffer")
	assert_ne(active.mesh, mesh, "material slots must not mutate an imported/shared source mesh")
	var moved := Transform3D(Basis.IDENTITY, Vector3(128.0, 3.0, -64.0))
	if per_instance:
		source.set_instance_transform(0, moved)
		assert_eq(active.get_instance_transform(0), moved, "later streaming placement reaches the rendered instance")
	else:
		# The real buffer API stores data in both dummy and GPU backends. Use
		# a full 3D transform (three matrix rows, translation in each row's w),
		# written through the builder reference after finishing the material.
		var buffer := PackedFloat32Array([
			1.0, 0.0, 0.0, moved.origin.x,
			0.0, 1.0, 0.0, moved.origin.y,
			0.0, 0.0, 1.0, moved.origin.z,
		])
		source.buffer = buffer
		assert_eq(active.buffer, buffer, "later buffer upload reaches the retained instancer unchanged")
	assert_eq(finish.call("_finish_multimesh", active), active, "revisits do not copy the instance buffer")
	finish.free()
	settings.enabled = was_enabled


func test_deferred_surface_batch_uses_late_materials_and_skips_departed_nodes() -> void:
	var settings := MEADOWS_FINISH.settings()
	var was_enabled := bool(settings.enabled)
	settings.enabled = true
	var world := Node.new()
	var elsewhere := Node.new()
	var finish := MEADOWS_FINISH.new()
	finish.set("_world", world)
	var meshes: Array[MeshInstance3D] = []
	for index in 64:
		var mesh := MeshInstance3D.new()
		world.add_child(mesh)
		finish.call("_node_added", mesh)
		# Production builders commonly assign the material after add_child.
		mesh.material_override = StandardMaterial3D.new()
		meshes.append(mesh)
	var plain := Node.new()
	world.add_child(plain)
	finish.call("_node_added", plain)
	assert_eq((finish.get("_pending") as PackedInt64Array).size(), 64, "only geometry enters the batch")
	assert_true(bool(finish.get("_flush_queued")), "burst has one pending flush")
	meshes[0].free()
	# These ancestry fixtures are intentionally outside SceneTree: there is
	# no global transform to preserve when exercising departure from _world.
	meshes[1].reparent(elsewhere, false)
	finish.call("_flush_pending")
	assert_false((meshes[1].material_override as BaseMaterial3D).detail_enabled,
		"a node moved out of this world must keep its original material")
	for index in range(2, meshes.size()):
		assert_true((meshes[index].material_override as BaseMaterial3D).detail_enabled,
			"the assigned material is finished when the batch drains")
	assert_true((finish.get("_pending") as PackedInt64Array).is_empty())
	finish.free()
	world.free()
	elsewhere.free()
	settings.enabled = was_enabled
