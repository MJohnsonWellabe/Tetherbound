extends "res://tests/test_case.gd"

## F32#2 census: one or two attuned essence nodes per type in each live biome,
## each a registered renewable site that regrows on the configured host-day
## timer. Off-route distance is measured separately (see the F32 evidence).
const CATALOGUE := preload("res://scripts/world/essence_node_catalog.gd")
const SITES := preload("res://scripts/world/renewable_site_catalog.gd")
const REALMS := ["meadows", "water", "cloudreach", "stormwood"]

func test_one_or_two_nodes_per_type_per_live_biome() -> void:
	var data := CATALOGUE.read()
	assert_eq(CATALOGUE.validation_errors(data), [] as Array[String])
	var types := CATALOGUE.known_types()
	assert_eq(types.size(), 8, "eight creature types")
	for realm: String in REALMS:
		var counts := {}
		for node: Dictionary in CATALOGUE.nodes_for(realm, data):
			counts[node.type] = int(counts.get(node.type, 0)) + 1
		for type: String in types:
			var n := int(counts.get(type, 0))
			assert_true(n >= 1 and n <= 2, "%s has %d %s essence node(s)" % [realm, n, type])

func test_every_node_is_a_registered_site_on_the_configured_host_day_timer() -> void:
	var data := CATALOGUE.read()
	assert_eq(data.clock, "host_world_day")
	var respawn := int(data.respawn_days)
	assert_true(respawn >= 1, "configured respawn timer")
	for realm: String in REALMS:
		for node: Dictionary in CATALOGUE.nodes_for(realm, data):
			var site := SITES.by_id(realm, str(node.id))
			assert_false(site.is_empty(), str(node.id) + " is a registered renewable site")
			assert_eq(int(site.get("respawn_days", 0)), respawn, str(node.id) + " regrows on the configured timer")
			assert_true((site.get("outputs", {}) as Dictionary).has("essence_" + str(node.type)), str(node.id) + " yields its type essence")

## Main routes per realm, as ralph/reports/HOMESTEAD/f32/essence-census/route_distance.py
## measures them: authored Meadows streets/approaches, Tidewake main_path spines,
## Cloudreach region-to-region roads plus the arrival road, Stormwood critical roads.
func _main_routes(realm: String) -> Array:
	var read := func(path: String) -> Dictionary: return JSON.parse_string(FileAccess.get_file_as_string(path))
	var lines: Array = []
	match realm:
		"meadows":
			var paths: Dictionary = read.call("res://data/config/terrain_playground.json").paths
			for row: Dictionary in paths.routes + paths.approaches: lines.append(row.points)
		"water":
			for row: Dictionary in read.call("res://data/config/water_world.json").land_routes:
				if row.get("main_path") == true: lines.append(row.polyline)
		"cloudreach":
			for row: Dictionary in read.call("res://data/config/cloudreach_world.json").routes:
				if (row.from_region_id != row.to_region_id or row.id == "arrival_gate_road") and row.id != "observatory_latch_descent":
					lines.append(row.polyline)
		"stormwood":
			for row: Dictionary in read.call("res://data/config/stormwood_world.json").routes:
				if row.kind == "critical": lines.append(row.points)
	return lines

func _distance(at: Vector2, lines: Array) -> float:
	var best := INF
	for line: Array in lines:
		for i in line.size() - 1:
			var a := Vector2(float(line[i][0]), float(line[i][-1]))
			var b := Vector2(float(line[i + 1][0]), float(line[i + 1][-1]))
			best = minf(best, at.distance_to(Geometry2D.get_closest_point_to_segment(at, a, b)))
	return best

func test_nodes_are_mostly_off_the_main_route_in_every_biome() -> void:
	var data := CATALOGUE.read()
	var minimum := float(data.off_route_minimum_m)
	for realm: String in REALMS:
		var lines := _main_routes(realm)
		assert_true(not lines.is_empty(), realm + " has authored main routes")
		var off := 0
		var total := 0
		for node: Dictionary in CATALOGUE.nodes_for(realm, data):
			var d := _distance(Vector2(float(node.at[0]), float(node.at[1])), lines)
			total += 1
			if d >= minimum: off += 1
			assert_almost_eq(float(node.placement.main_route_distance_m), d, 0.01, str(node.id) + " recorded route distance")
			assert_eq(node.placement.off_route, d >= minimum, str(node.id) + " recorded off-route flag")
		assert_true(off * 2 > total, "%s essence nodes mostly off-route (%d/%d >= %.0f m)" % [realm, off, total, minimum])
