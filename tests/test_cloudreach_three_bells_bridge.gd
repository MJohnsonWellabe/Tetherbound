extends "res://tests/test_case.gd"

const PRESENTATION := preload("res://scripts/world/cloudreach_three_bells_bridge.gd")


func _materials() -> Dictionary:
	var result := {}
	for key: String in ["masonry", "stone_light", "weathered_timber", "bronze", "rope"]:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#81745e")
		result[key] = material
	return result


func test_three_bells_portal_is_bridge_aligned_readable_and_visual_only() -> void:
	var presentation := PRESENTATION.new()
	presentation.build(_materials())
	assert_almost_eq(rad_to_deg(presentation.rotation.y), 48.4, 0.01)
	var roles := {}
	var collision_count := 0
	for child: Node in presentation.get_children():
		var role := str(child.get_meta("three_bells_role", ""))
		if not role.is_empty():
			roles[role] = int(roles.get(role, 0)) + 1
		if child is CollisionObject3D:
			collision_count += 1
	assert_eq(int(roles.get("readable_bell", 0)), 3)
	assert_eq(int(roles.get("bell_pier", 0)), 2)
	assert_eq(int(roles.get("bridge_signal", 0)), 2)
	assert_eq(int(roles.get("route_pennant", 0)), 2)
	assert_eq(int(roles.get("bell_light", 0)), 2)
	assert_true(int(roles.get("bell_frame", 0)) >= 5)
	assert_eq(collision_count, 0, "the existing bridge and landmark ledge retain all traversal collision")
	presentation.free()


func test_three_bells_catalogue_starts_on_the_authored_west_approach() -> void:
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
				if str(spot.get("display_name", "")) == "Three Bells Bridge":
					found = spot
	assert_false(found.is_empty())
	assert_eq(found.get("position", []), [-535.0, 1274.5])
	assert_almost_eq(float(found.get("view_heading_deg", 0.0)), 48.0, 0.01)
	assert_true(Vector2(-535.0, 1274.5).distance_to(Vector2(-485.0, 1320.0)) > 60.0,
		"the catalogue must not return to the inside of a bell pier")


func test_cloudreach_world_mounts_the_dedicated_three_bells_presentation() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/cloudreach_world.gd")
	assert_true(source.contains("const THREE_BELLS_BRIDGE_PRESENTATION := preload("))
	assert_true(source.contains("presentation.name = \"ThreeBellsBridgePresentation\""))
	assert_false(source.contains("Vector3(side * 12.0, 8.0, 0.0), Vector3(3.2, 16.0, 4.0)"),
		"the former 16 m plain pillars must not return")


func test_bridge_landing_wildlife_is_kept_on_the_road_but_out_of_the_hero_frames() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_encounters.json"))
	assert_true(parsed is Dictionary)
	var wanted := {
		"road_visibility_broken_causeway_main_03": Vector3(-575.0, 325.0, 1238.0),
		"road_visibility_broken_causeway_main_04": Vector3(-410.0, 354.0, 1395.0),
	}
	var found := {}
	for raw: Variant in (parsed as Dictionary).get("wild_sites", []):
		var site := raw as Dictionary
		var id := str(site.get("id", ""))
		if wanted.has(id):
			found[id] = site
	assert_eq(found.size(), 2)
	var landings := [Vector2(-535.0, 1274.5), Vector2(-454.0, 1357.0)]
	for id: String in wanted:
		var site := found.get(id, {}) as Dictionary
		var raw := site.get("position", []) as Array
		var at := Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
		assert_eq(at, wanted[id])
		assert_eq(int(site.get("count", 0)), 2)
		assert_eq(str(site.get("table_id", "")), "cloudreach_causeway_wild")
		for landing: Vector2 in landings:
			assert_true(Vector2(at.x, at.z).distance_to(landing) - float(site.get("radius_m", 0.0)) > 45.0)
