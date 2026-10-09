extends "res://tests/test_case.gd"

const PRESENTATION := preload("res://scripts/world/cloudreach_broken_skyroad_arch.gd")


func _config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PRESENTATION.CONFIG_PATH))
	assert_true(parsed is Dictionary, "Broken Skyroad visual config parses")
	return parsed as Dictionary if parsed is Dictionary else {}


func _materials() -> Dictionary:
	var result := {}
	for key: String in ["stone_light", "masonry"]:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#77736b")
		result[key] = material
	return result


func test_broken_arch_uses_installed_gateway_asymmetry_and_no_collision() -> void:
	var cfg := _config()
	assert_true(ResourceLoader.exists("res://assets/buildings/quaternius_castle/WallEntranceBricks.obj"),
		"the gateway uses the installed castle kit")
	assert_eq(cfg.get("gateway_size_m", []), [26.0, 19.0, 5.5],
		"the gateway retains its measured landmark-scale silhouette")
	assert_true(absf(float(cfg.get("gateway_yaw_deg", 0.0))) >= 20.0,
		"the installed gateway breaks the old front-on twin-slab read")
	var presentation := PRESENTATION.new()
	presentation.build(_materials())
	var roles := {}
	var collisions := 0
	for child: Node in presentation.get_children():
		var role := str(child.get_meta("skyroad_arch_role", ""))
		if not role.is_empty():
			roles[role] = int(roles.get(role, 0)) + 1
		if child is CollisionObject3D:
			collisions += 1
	assert_eq(int(roles.get("installed_gateway", 0)), 1)
	assert_eq(int(roles.get("grounded_buttress", 0)), 3)
	assert_eq(int(roles.get("fallen_crown", 0)), 3)
	assert_eq(int(roles.get("wind_fracture", 0)), 3)
	assert_eq(int(roles.get("fracture_light", 0)), 1)
	assert_eq(collisions, 0)
	presentation.free()


func test_broken_arch_catalogue_no_longer_stands_between_the_old_slabs() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/debug_teleport_spots.json"))
	assert_true(parsed is Dictionary)
	var found := {}
	for biome_raw: Variant in (parsed as Dictionary).get("biomes", []):
		var biome := biome_raw as Dictionary
		if str(biome.get("id", "")) != "cloudreach":
			continue
		for band_raw: Variant in biome.get("bands", []):
			for spot_raw: Variant in (band_raw as Dictionary).get("spots", []):
				var spot := spot_raw as Dictionary
				if str(spot.get("display_name", "")) == "Broken Skyroad Arch":
					found = spot
	assert_false(found.is_empty())
	assert_eq(found.get("position", []), [365.0, 1925.0])
	assert_almost_eq(float(found.get("view_heading_deg", 0.0)), -42.0, 0.01)
	assert_true(Vector2(365.0, 1925.0).distance_to(Vector2(350.0, 1940.0)) > 20.0)


func test_cloudreach_world_mounts_dedicated_broken_arch_presentation() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/cloudreach_world.gd")
	assert_true(source.contains("const BROKEN_SKYROAD_ARCH_PRESENTATION := preload("))
	assert_true(source.contains("presentation.name = \"BrokenSkyroadArchPresentation\""))
	assert_false(source.contains("Vector3(-10.0, 10.0, 0.0), Vector3(5.0, 20.0, 6.0)"))
	var world := preload("res://scripts/world/cloudreach_world.gd").new()
	var visual: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))
	world.set("_visual_config", visual)
	world.call("_build_materials")
	var materials: Dictionary = world.get("_materials")
	assert_eq(materials["stone"], materials["masonry"], "architectural blocks share the production coursed stone")
	assert_eq(materials["stone_light"], materials["masonry_trim"], "gateway and fallen crown share its trim family")
	var presentation := PRESENTATION.new()
	presentation.build(materials)
	var gateway := presentation.get_node("InstalledSkyroadGateway") as MeshInstance3D
	assert_eq(gateway.material_override, materials["masonry_trim"], "the actual installed gateway receives the architectural stone")
	for key: String in ["masonry", "masonry_trim"]:
		var material := materials[key] as ShaderMaterial
		assert_true(material != null)
		if material == null:
			continue
		for map_key: String in ["albedo_tex", "normal_tex", "rough_tex"]:
			var texture := material.get_shader_parameter(map_key) as Texture2D
			assert_true(texture != null and texture.resource_path.contains("/T_Brick_"),
				"actual %s uses the same installed rectangular course maps" % map_key)
			if texture != null:
				assert_true(texture.get_image().has_mipmaps(), "actual %s supplies the mip chain requested by the stone sampler" % map_key)
		var tile := float(material.get_shader_parameter("tile"))
		assert_between(tile, 0.25, 0.35, "courses retain a metre-scale pitch across scaled architecture")
		var albedo := material.get_shader_parameter("albedo_tex") as Texture2D
		var image := albedo.get_image()
		assert_true(image != null)
		if image != null:
			if image.is_compressed():
				assert_eq(image.decompress(), OK)
			var luminance: Array[float] = []
			for y in range(0, image.get_height(), 32):
				for x in range(0, image.get_width(), 32):
					var colour := image.get_pixel(x, y).srgb_to_linear()
					luminance.append(colour.r * 0.299 + colour.g * 0.587 + colour.b * 0.114)
			luminance.sort()
			var joint_end := float(material.get_shader_parameter("joint_threshold")) + float(material.get_shader_parameter("joint_softness"))
			assert_true(not luminance.is_empty() and luminance[luminance.size() / 2] > joint_end,
				"the actual linear stone-face median %.6f is beyond the mortar moss mask %.6f" % [luminance[luminance.size() / 2], joint_end])
	presentation.free()
	world.free()
