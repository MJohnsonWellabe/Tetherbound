extends "res://tests/test_case.gd"

const PRESENTATION := preload("res://scripts/world/cloudreach_stormward_overlook.gd")


func _materials() -> Dictionary:
	var result := {}
	for key: String in ["masonry", "masonry_trim", "bronze"]:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#81745e")
		result[key] = material
	return result


func test_stormward_threshold_is_open_directional_and_visual_only() -> void:
	var presentation := PRESENTATION.new()
	presentation.build(_materials())
	var roles := {}
	var collision_count := 0
	for child: Node in presentation.get_children():
		var role := str(child.get_meta("stormward_role", ""))
		if not role.is_empty():
			roles[role] = int(roles.get(role, 0)) + 1
		if child is CollisionObject3D:
			collision_count += 1
	assert_eq(int(roles.get("survey_pier", 0)), 2)
	assert_eq(int(roles.get("ruined_wing", 0)), 2)
	assert_eq(int(roles.get("approach_paver", 0)), 4)
	assert_eq(int(roles.get("stormward_needle", 0)), 3)
	assert_eq(int(roles.get("compass_signal", 0)), 1)
	assert_eq(int(roles.get("compass_signal_core", 0)), 1)
	assert_eq(int(roles.get("direction_streamer", 0)), 2)
	assert_eq(int(roles.get("beacon_glow", 0)), 2)
	assert_eq(int(roles.get("beacon_light", 0)), 2)
	assert_eq(collision_count, 0)
	presentation.free()


func test_stormward_catalogue_uses_the_authored_south_crown_endpoint() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/debug_teleport_spots.json"))
	var found := {}
	for biome_raw: Variant in (parsed as Dictionary).get("biomes", []):
		var biome := biome_raw as Dictionary
		if str(biome.get("id", "")) != "cloudreach":
			continue
		for band_raw: Variant in biome.get("bands", []):
			for spot_raw: Variant in (band_raw as Dictionary).get("spots", []):
				var spot := spot_raw as Dictionary
				if str(spot.get("display_name", "")) == "Stormward Overlook":
					found = spot
	assert_eq(found.get("position", []), [-418.0, 5634.0])
	assert_almost_eq(float(found.get("view_heading_deg", NAN)), -6.0, 0.01)
	var arrival := Vector2(-418.0, 5634.0)
	var crown_centreline := Vector2(-420.0, 5650.0) + Vector2(-4.571, -16.0)
	assert_true(arrival.distance_to(crown_centreline) < 8.0,
		"catalogue stand must remain inside the existing 16 m half-width crown")
	assert_true(absf(arrival.x + 420.0) <= 17.0 and absf(arrival.y - 5650.0) <= 17.0,
		"catalogue stand must be inside ground_height_at's landmark footprint")


func test_cloudreach_world_mounts_the_dedicated_stormward_presentation() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/cloudreach_world.gd")
	assert_true(source.contains("const STORMWARD_OVERLOOK_PRESENTATION := preload("))
	assert_true(source.contains("presentation.name = \"StormwardOverlookPresentation\""))
	assert_false(source.contains("_box(root, \"WaterwardPillar\""))
	assert_true(source.contains("Vector3(-8.0, -2.4, -28.0), Vector3.ZERO, 5.0"))
