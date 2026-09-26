extends "res://tests/test_case.gd"

## X04 / F13#5: the dock dressing layer is presentation only, uses installed
## models, never Team Tether red, and stands beside the swim lane.

const CONFIG := "res://data/config/water_dock_dressing.json"
const SCRIPT := "res://scripts/world/water_dock_dressing.gd"
const DRESSING := preload("res://scripts/world/water_dock_dressing.gd")


func _cfg() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return parsed as Dictionary if parsed is Dictionary else {}


func test_every_dressing_model_is_installed() -> void:
	var cfg := _cfg()
	var paths: Array = [str((cfg.pier as Dictionary).deck_model), str((cfg.pier as Dictionary).post_model),
		str((cfg.lanterns as Dictionary).model)]
	for item: Variant in (cfg.cargo as Dictionary).items:
		paths.append(str((item as Dictionary).model))
	for path: String in paths:
		assert_true(ResourceLoader.exists(path), "installed model exists: %s" % path)


func test_layer_is_presentation_only_and_clear_of_the_lane() -> void:
	var source := FileAccess.get_file_as_string(SCRIPT)
	assert_true(not source.contains("CollisionShape3D") and not source.contains("StaticBody3D"),
		"the dressing adds no collision")
	var pier := _cfg().pier as Dictionary
	assert_true(float(pier.lateral_offset_m) >= float(pier.width_m) * 0.5 + 2.0,
		"the pier stands beside the safe->shore swim lane, not across it")


func test_lantern_light_and_piling_tint_are_not_team_tether_red() -> void:
	var c := Color(str((_cfg().lanterns as Dictionary).light_colour))
	assert_true(not (c.r > c.g * 1.6 and c.r > c.b * 1.6), "lantern light is warm, not red")
	var tint := Color(str((_cfg().pier as Dictionary).get("post_tint", "#ffffff")))
	assert_true(tint.get_luminance() < 0.35 and not (tint.r > tint.g * 1.6 and tint.r > tint.b * 1.6),
		"pier pilings are darkened to wet wood, not the log texture's salmon pink")
	assert_true(float((_cfg().lanterns as Dictionary).get("glow_energy", 0.0)) > 0.0,
		"dock lanterns glow so they read lit at night")


func test_material_override_covers_root_mesh_and_children_without_mutating_source() -> void:
	var dressing := DRESSING.new()
	var root_mesh := MeshInstance3D.new()
	var shared_mesh := BoxMesh.new()
	var source_material := StandardMaterial3D.new()
	source_material.albedo_color = Color.WHITE
	shared_mesh.material = source_material
	root_mesh.mesh = shared_mesh
	var child_mesh := MeshInstance3D.new()
	child_mesh.mesh = shared_mesh
	root_mesh.add_child(child_mesh)
	var untouched := MeshInstance3D.new()
	untouched.mesh = shared_mesh
	var wet_wood := Color("#605348")
	dressing.call("_tint", root_mesh, wet_wood)
	for mesh: MeshInstance3D in [root_mesh, child_mesh]:
		var material := mesh.get_surface_override_material(0) as StandardMaterial3D
		assert_true(material != null, "root and nested imported meshes receive the dock treatment")
		if material != null:
			assert_eq(material.albedo_color, wet_wood, "the visible surface uses the dock palette")
	assert_eq(source_material.albedo_color, Color.WHITE, "the shared source material is unchanged")
	assert_true(untouched.get_surface_override_material(0) == null,
		"other instances of the installed family keep their own materials")
	root_mesh.free()
	untouched.free()
	dressing.free()


func test_installed_lantern_emits_only_from_glass_and_light_follows_insert() -> void:
	var dressing := DRESSING.new()
	var site := Node3D.new()
	var cfg := _cfg().lanterns as Dictionary
	dressing.call("_lantern", site, cfg, Vector3(4, 2, 8), PI * 0.5)
	var lantern := site.get_node_or_null(^"PierLantern") as Node3D
	var light := site.get_node_or_null(^"PierLanternLight") as OmniLight3D
	assert_true(lantern != null and light != null, "installed fixture and its light are constructed")
	if lantern != null and light != null:
		var glass := lantern.get_node_or_null(^"LanternGlass") as MeshInstance3D
		assert_true(glass != null, "installed cage contains the luminous insert")
		if glass != null:
			var material := glass.material_override as StandardMaterial3D
			assert_true(material != null and material.emission_enabled, "glass is the light source")
			assert_true(light.position.is_equal_approx(lantern.transform * glass.position),
				"illumination follows the fitted and rotated glass position")
		for node: Node in lantern.find_children("*", "MeshInstance3D", true, false):
			if node == glass:
				continue
			var mesh := node as MeshInstance3D
			for surface in mesh.mesh.get_surface_count():
				var housing := mesh.get_surface_override_material(surface) as StandardMaterial3D
				assert_true(housing != null and not housing.emission_enabled,
					"bracket, chain and cage retain opaque housing material")
	site.free()
	dressing.free()
