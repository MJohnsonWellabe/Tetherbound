extends "res://tests/test_case.gd"

const VERGES := preload("res://scripts/world/cloudreach_route_verges.gd")
const WORLD_CONFIG := "res://data/config/cloudreach_world.json"
const LOOK_CONFIG := "res://data/config/cloudreach_look.json"


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "%s parses" % path)
	return parsed as Dictionary if parsed is Dictionary else {}


func test_route_ecology_reaches_every_grounded_route_and_skips_flight() -> void:
	var world := _json(WORLD_CONFIG)
	var look := _json(LOOK_CONFIG)
	var cfg := look.get("route_verges", {}) as Dictionary
	var plan := VERGES.route_verge_plan(world.get("routes", []), cfg)
	var planned_ids := {}
	for station: Dictionary in plan:
		planned_ids[str(station.get("route_id", ""))] = int(
			planned_ids.get(str(station.get("route_id", "")), 0)) + 1
	var grounded_ids := {}
	for route_raw: Variant in world.get("routes", []):
		var route := route_raw as Dictionary
		if str(route.get("traversal_mode", "ground")) == "ground":
			grounded_ids[str(route.get("id", ""))] = true
	assert_eq(grounded_ids.size(), 10)
	assert_eq(planned_ids.size(), grounded_ids.size())
	assert_false(planned_ids.has("windscar_to_high_roost_flight"))
	for route_id: String in grounded_ids:
		assert_true(planned_ids.has(route_id), "%s gets route ecology" % route_id)
		assert_true(int(planned_ids.get(route_id, 0)) >= 1)
		assert_true(int(planned_ids.get(route_id, 0)) <= int(cfg.get("max_stations_per_route", 16)))


func test_route_ecology_plan_is_bounded_clear_and_deterministic() -> void:
	var world := _json(WORLD_CONFIG)
	var cfg := (_json(LOOK_CONFIG).get("route_verges", {}) as Dictionary)
	var first := VERGES.route_verge_plan(world.get("routes", []), cfg)
	var second := VERGES.route_verge_plan(world.get("routes", []), cfg)
	assert_eq(first, second)
	assert_true(first.size() >= 100, "the mid-layer spans the biome rather than a landmark pocket")
	assert_true(first.size() <= 10 * int(cfg.get("max_stations_per_route", 16)))
	var minimum_offset := float(cfg.get("path_half_width_m", 2.1)) \
		+ float(cfg.get("path_clearance_m", 1.2)) \
		+ float(cfg.get("near_offset_m", 2.1)) \
		- float(cfg.get("verge_jitter_m", 0.8))
	assert_true(minimum_offset > float(cfg.get("path_half_width_m", 2.1)) + 0.25,
		"even maximum jitter leaves the visible route centre clear")
	assert_true(float(cfg.get("outer_offset_m", 0.0)) > float(cfg.get("near_offset_m", 0.0)))


func test_route_ecology_owns_no_collision_or_gameplay_state() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/cloudreach_route_verges.gd")
	assert_false(source.contains("StaticBody3D"))
	assert_false(source.contains("CollisionShape3D"))
	assert_false(source.contains("Area3D"))
	assert_false(source.contains("encounter_data"))
	assert_false(source.contains("progression_flags"))
	assert_false(source.contains("PromptArea"))
	assert_true(source.contains("MultiMeshInstance3D"), "the biome-wide layer is draw-call bounded")
	assert_false(source.contains("mesh_instance.global_transform"),
		"unmounted imported scenes must not query a SceneTree global transform")
	var look_source := FileAccess.get_file_as_string("res://scripts/world/cloudreach_look.gd")
	assert_true(look_source.contains("_dress_route_verges(config_data)"))
