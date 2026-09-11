extends "res://tests/test_case.gd"

const PRESENTATION := preload("res://scripts/world/cloudreach_galefoot_waycamp.gd")


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _materials() -> Dictionary:
	var result := {}
	for key: String in ["weathered_timber", "key_glow"]:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#72898d")
		result[key] = material
	return result


func test_waycamp_presentation_builds_a_lived_in_night_read_without_collision() -> void:
	var cfg := _json(PRESENTATION.CONFIG_PATH)
	assert_eq(str(cfg.get("landmark_id", "")), "lower_cliffs_waycamp")
	assert_eq((cfg.get("benches", []) as Array).size(), 2)
	assert_eq((cfg.get("supply_corner", []) as Array).size(), 2)
	assert_true(float((cfg.get("hearth", {}) as Dictionary).get("light_range_m", 0.0)) >= 22.0)
	assert_eq(int((cfg.get("lantern_line", {}) as Dictionary).get("bulb_count", 0)), 7)
	var presentation := PRESENTATION.new()
	presentation.build(_materials())
	var roles := {}
	var collisions := 0
	for child: Node in presentation.get_children():
		var role := str(child.get_meta("waycamp_role", ""))
		if not role.is_empty():
			roles[role] = int(roles.get(role, 0)) + 1
		if child is CollisionObject3D:
			collisions += 1
	assert_eq(int(roles.get("communal_hearth", 0)), 1)
	assert_eq(int(roles.get("communal_flame", 0)), 1)
	assert_eq(int(roles.get("hearth_light", 0)), 1)
	assert_eq(int(roles.get("hearth_seat", 0)), 2)
	assert_eq(int(roles.get("lantern_bulb", 0)), 7)
	assert_eq(int(roles.get("lantern_cable", 0)), 6)
	assert_eq(int(roles.get("lantern_light", 0)), 1)
	assert_eq(int(roles.get("supply_dressing", 0)), 2)
	assert_eq(collisions, 0, "visual dressing must not change camp navigation")
	presentation.free()


func test_waycamp_wildlife_stays_outside_the_safe_commons_but_on_both_roads() -> void:
	var encounters := _json("res://data/config/cloudreach_encounters.json")
	var wanted := {
		"road_visibility_arrival_gate_road_08": Vector3(-290.0, 180.0, 455.0),
		"road_visibility_arrival_gate_road_09": Vector3(-256.0, 184.0, 547.0),
	}
	var found := {}
	for site_raw: Variant in encounters.get("wild_sites", []):
		var site := site_raw as Dictionary
		var id := str(site.get("id", ""))
		if wanted.has(id):
			found[id] = site
	assert_eq(found.size(), 2)
	var camp := Vector2(-280.0, 520.0)
	for id: String in wanted:
		var site := found.get(id, {}) as Dictionary
		var raw := site.get("position", []) as Array
		var at := Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
		assert_eq(at, wanted[id])
		assert_true(Vector2(at.x, at.z).distance_to(camp) - float(site.get("radius_m", 0.0)) > 28.0,
			"%s can scatter wildlife back into the safe camp" % id)
		assert_eq(int(site.get("count", 0)), 2)
		assert_eq(str(site.get("table_id", "")), "cloudreach_lower_wild")


func test_named_waycamp_catalogue_uses_the_overview_edge() -> void:
	var debug := _json("res://data/config/debug_teleport_spots.json")
	var found := {}
	for biome_raw: Variant in debug.get("biomes", []):
		var biome := biome_raw as Dictionary
		if str(biome.get("id", "")) != "cloudreach":
			continue
		for band_raw: Variant in biome.get("bands", []):
			for spot_raw: Variant in (band_raw as Dictionary).get("spots", []):
				var spot := spot_raw as Dictionary
				if str(spot.get("display_name", "")) == "Galefoot Waycamp":
					found = spot
	assert_false(found.is_empty())
	assert_eq(found.get("position", []), [-286.0, 535.0])
	assert_almost_eq(float(found.get("view_heading_deg", 0.0)), 155.0, 0.001)
	var edge_distance := Vector2(-286.0, 535.0).distance_to(Vector2(-280.0, 520.0))
	assert_true(edge_distance >= 16.0 and edge_distance < 28.0)


func test_cloudreach_world_mounts_the_waycamp_presentation_only_at_galefoot() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/cloudreach_world.gd")
	assert_true(source.contains("const GALEFOOT_WAYCAMP_PRESENTATION := preload("))
	assert_true(source.contains("if landmark_id == \"lower_cliffs_waycamp\":"))
	assert_true(source.contains("waycamp_presentation.name = \"GalefootWaycampPresentation\""))
