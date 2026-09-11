extends "res://tests/test_case.gd"

const PRESENTATION := preload("res://scripts/world/cloudreach_broken_skyroad_arch.gd")


func _materials() -> Dictionary:
	var result := {}
	for key: String in ["masonry", "stone_light", "path", "bronze"]:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#81745e")
		result[key] = material
	return result


func test_broken_arch_is_authored_asymmetrical_and_visual_only() -> void:
	var presentation := PRESENTATION.new()
	presentation.build(_materials())
	var roles := {}
	var collision_count := 0
	for child: Node in presentation.get_children():
		var role := str(child.get_meta("broken_arch_role", ""))
		if not role.is_empty():
			roles[role] = int(roles.get(role, 0)) + 1
		if child is CollisionObject3D:
			collision_count += 1
	assert_eq(int(roles.get("standing_support", 0)), 2)
	assert_eq(int(roles.get("arch_voussoir", 0)), 13)
	assert_eq(int(roles.get("fractured_keystone", 0)), 1)
	assert_eq(int(roles.get("skyroad_fragment", 0)), 2)
	assert_eq(int(roles.get("fallen_span", 0)), 2)
	assert_eq(int(roles.get("approach_paver", 0)), 7)
	assert_eq(int(roles.get("route_signal", 0)), 1)
	assert_eq(int(roles.get("route_signal_glow", 0)), 1)
	assert_eq(int(roles.get("route_signal_light", 0)), 1)
	assert_eq(int(roles.get("night_separation_light", 0)), 3)
	assert_eq(collision_count, 0, "the existing landmark mesa retains traversal collision")
	assert_true(absf(presentation.get_node("RuinedSupport01").rotation.z -
		presentation.get_node("RuinedSupport02").rotation.z) > 0.01)
	presentation.free()


func test_broken_arch_catalogue_uses_the_south_approach() -> void:
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
	assert_eq(found.get("position", []), [350.0, 1923.0])
	assert_almost_eq(float(found.get("view_heading_deg", -1.0)), 0.0, 0.01)
	assert_true(Vector2(350.0, 1923.0).distance_to(Vector2(350.0, 1940.0)) >= 17.0)


func test_cloudreach_world_mounts_the_dedicated_broken_arch_presentation() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/cloudreach_world.gd")
	assert_true(source.contains("const BROKEN_SKYROAD_ARCH_PRESENTATION := preload("))
	assert_true(source.contains("presentation.name = \"BrokenSkyroadArchPresentation\""))
	assert_true(source.contains("if landmark_id == \"broken_skyroad_arch\":"))
	assert_true(source.contains("ledge_size.z = 32.0"))
	assert_true(source.contains("Vector2(4.8, 14.0)"),
		"the cover system must keep the authored skyroad approach clear")
	assert_false(source.contains("_box(root, \"WestArchPier\""),
		"the former 20 m primitive slab must not return")
