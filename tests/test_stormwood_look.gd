extends "res://tests/test_case.gd"

const LOOK := preload("res://scripts/world/stormwood_look.gd")


func test_disabled_profile_is_exact_base() -> void:
	var base := {"pin_time_of_day": true, "reference_time": "day",
		"overrides": {"sun": {"energy": 1.4}}}
	var profile := LOOK.read_config()
	assert_false(bool(profile.enabled), "unjudged candidate ships OFF")
	assert_eq(LOOK.rig_overrides(base, profile), base)


func test_enabled_rig_preserves_clock_pin_and_does_not_mutate_source() -> void:
	var base := {"pin_time_of_day": true, "reference_time": "day",
		"overrides": {"sun": {"energy": 1.4, "shadow_enabled": true}}}
	var before := base.duplicate(true)
	var profile := LOOK.read_config()
	profile.enabled = true
	var result := LOOK.rig_overrides(base, profile)
	assert_eq(base, before)
	assert_true(bool(result.pin_time_of_day))
	assert_eq(result.reference_time, "day")
	assert_true(bool(result.overrides.sun.shadow_enabled))
	assert_eq(result.overrides.sun.energy, profile.rig.sun.energy)
	assert_eq(result.overrides.environment.fog_colour, result.overrides.sky.horizon_colour)
	assert_false(result.has("phases"), "visual rig must not replace Surge gameplay")


func test_shader_adapter_keeps_original_body_and_rejects_later_functions() -> void:
	var source := "shader_type spatial;\nvoid fragment() {\nALBEDO = vec3(1.0);\nif (UV.x < 0.2) { discard; }\n}\n"
	var adapted := LOOK.detail_shader_code(source)
	assert_true(adapted.contains("if (UV.x < 0.2) { discard; }"))
	assert_true(adapted.contains(LOOK.DETAIL_INCLUDE))
	assert_true(adapted.contains(LOOK.DETAIL_CALL))
	assert_true(adapted.find(LOOK.DETAIL_CALL) > adapted.find("discard;"))
	assert_eq(LOOK.detail_shader_code(source + "void light() { DIFFUSE_LIGHT = vec3(1.0); }"), "")
	assert_eq(LOOK.detail_shader_code("shader_type spatial;"), "")


func test_all_admitted_shader_layouts_have_a_safe_fragment_tail() -> void:
	var profile := LOOK.read_config()
	for path: String in profile.materials.shader_paths:
		var code := FileAccess.get_file_as_string(path)
		assert_false(code.is_empty(), path)
		assert_false(LOOK.detail_shader_code(code).is_empty(), path)


func test_standard_material_retains_authored_identity() -> void:
	var look := LOOK.new()
	look.config = LOOK.read_config()
	var source := StandardMaterial3D.new()
	source.albedo_color = Color("7e8163")
	source.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	source.alpha_scissor_threshold = 0.37
	source.vertex_color_use_as_albedo = true
	var result := look.adapt_material(source) as StandardMaterial3D
	assert_ne(result, source)
	assert_eq(result.albedo_color, source.albedo_color)
	assert_eq(result.alpha_scissor_threshold, source.alpha_scissor_threshold)
	assert_eq(result.transparency, source.transparency)
	assert_true(result.vertex_color_use_as_albedo)
	assert_false(source.detail_enabled, "imported source stays untouched")
	assert_true(result.detail_enabled)
	assert_eq(look.adapt_material(source), result, "one shared variant per source")
	assert_eq(look.adapt_material(result), result, "idempotent traversal")
	var light_source := StandardMaterial3D.new()
	light_source.emission_enabled = true
	assert_eq(look.adapt_material(light_source), light_source, "glowing semantic surfaces retain their material")
	look.free()


func test_packed_vegetation_mesh_keeps_geometry_and_source_material() -> void:
	var look := LOOK.new()
	look.config = LOOK.read_config()
	var source := ArrayMesh.new()
	var box := BoxMesh.new()
	source.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box.get_mesh_arrays())
	var bark := StandardMaterial3D.new()
	source.surface_set_material(0, bark)
	var result := look.adapt_mesh(source)
	assert_ne(result, source)
	assert_eq(result.get_aabb(), source.get_aabb())
	assert_eq(result.surface_get_arrays(0), source.surface_get_arrays(0))
	assert_eq(source.surface_get_material(0), bark)
	assert_false(bark.detail_enabled)
	assert_true((result.surface_get_material(0) as StandardMaterial3D).detail_enabled)
	assert_eq(look.adapt_mesh(source), result)
	assert_eq(look.adapt_mesh(result), result)
	look.free()


func test_camp_and_later_committed_building_receive_world_materials() -> void:
	var world := Node3D.new()
	var look := LOOK.new()
	look.config = LOOK.read_config()
	world.add_child(look)
	# stormwood_camps.mount creates this sibling of StormwoodCampsRuntime.
	var camps := Node3D.new()
	camps.name = "StormwoodCamps"
	world.add_child(camps)
	var camp_prop := _plain_world_mesh(camps)
	look._queue(world)
	_drain_walk(look)
	assert_true((camp_prop.material_override as StandardMaterial3D).detail_enabled,
		"initial walk reaches camp dressing under its actual root")
	# BuildPlacer attaches geometry first, then marks the committed parent.
	var placed := Node3D.new()
	world.add_child(placed)
	var piece := _plain_world_mesh(placed)
	look._node_added(placed)
	placed.add_to_group("placed_building")
	_drain_walk(look)
	assert_true((piece.material_override as StandardMaterial3D).detail_enabled,
		"later committed sibling receives the same material treatment")
	world.free()


func test_building_coverage_excludes_ghosts_actors_and_other_worlds() -> void:
	var world := Node3D.new()
	var look := LOOK.new()
	look.config = LOOK.read_config()
	world.add_child(look)
	var ghost := _plain_world_mesh(world)
	assert_false(look.eligible(ghost), "uncommitted preview has no placed-building group")
	var placed := Node3D.new()
	placed.add_to_group("placed_building")
	world.add_child(placed)
	var actor := CharacterBody3D.new()
	placed.add_child(actor)
	assert_false(look.eligible(_plain_world_mesh(actor)), "actor below a building stays excluded")
	var other_world := Node3D.new()
	var foreign := Node3D.new()
	foreign.add_to_group("placed_building")
	other_world.add_child(foreign)
	assert_false(look.eligible(_plain_world_mesh(foreign)), "group cannot cross the owning world boundary")
	other_world.free()
	world.free()


func _plain_world_mesh(parent: Node) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.mesh = BoxMesh.new()
	visual.material_override = StandardMaterial3D.new()
	parent.add_child(visual)
	return visual


func _drain_walk(look: Node) -> void:
	for _frame in 16:
		if look._pending.is_empty():
			break
		look._process(0.0)
	assert_true(look._pending.is_empty(), "bounded fixture traversal settles")
