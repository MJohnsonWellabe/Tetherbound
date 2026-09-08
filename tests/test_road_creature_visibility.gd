extends "res://tests/test_case.gd"

const MODEL := preload("res://tools/gate_f/road_creature_visibility_model.gd")
const CLOUDREACH_WORLD := "res://data/config/cloudreach_world.json"
const CLOUDREACH_ENCOUNTERS := "res://data/config/cloudreach_encounters.json"
const CLOUDREACH_CHAPTER := "res://data/config/cloudreach_chapter.json"
const SPECIES_DATA := "res://data/creatures/species.json"
const WATER_WORLD := "res://data/config/water_world.json"
const WATER_ENCOUNTERS := "res://data/config/water_encounters.json"
const CLOUDREACH_DIRECTOR := preload("res://scripts/combat/cloudreach_encounter_director.gd")

const HISTORICAL_BASELINE := {
	"meadows": {
		"band1_lower_meadows": [242, 124, 130.0],
		"band2_stone_and_root": [267, 184, 320.0],
		"band3_the_river_lock": [239, 144, 160.0],
		"band4_upper_meadows_ironwood": [345, 182, 200.0],
		"band5_stronghold_approach": [67, 25, 60.0],
	},
	"cloudreach": {
		"arrival_gate_road": [92, 92, 920.0],
		"lower_cliff_road": [69, 66, 550.0],
		"broken_causeway_main": [187, 187, 1870.0],
		"windscar_floor_loop": [179, 171, 1640.0],
		"windscar_counterweight_pass": [192, 192, 1920.0],
		"upper_summit_road": [155, 155, 1550.0],
	},
	"stormwood": {
		"ash_road": [261, 225, 670.0],
		"conductor_road": [249, 242, 920.0],
		"deepwood_road": [300, 220, 870.0],
	},
}


func test_projection_uses_the_measured_cp2_calibration() -> void:
	assert_almost_eq(MODEL.projected_height_px(1.0, 40.0), 15.0, 0.001)
	assert_almost_eq(MODEL.projected_height_px(2.0, 80.0), 15.0, 0.001)
	assert_almost_eq(MODEL.projected_height_px(0.75, 20.0), 22.5, 0.001)


func test_historical_road_baseline_can_only_improve() -> void:
	var result: Dictionary = MODEL.evaluate_all()
	for realm_id: String in HISTORICAL_BASELINE:
		var actual_by_id: Dictionary = {}
		for route: Dictionary in result.get(realm_id, []):
			actual_by_id[str(route.id)] = route
		var expected: Dictionary = HISTORICAL_BASELINE[realm_id]
		assert_eq(actual_by_id.size(), expected.size(),
			"historical route set changed in %s; update ROAD deliberately" % realm_id)
		for route_id: String in expected:
			assert_true(actual_by_id.has(route_id), "%s/%s remains sampled" % [realm_id, route_id])
			if not actual_by_id.has(route_id):
				continue
			var baseline: Array = expected[route_id]
			var actual: Dictionary = actual_by_id[route_id]
			assert_eq(int(actual.samples), int(baseline[0]), "%s/%s sample count" % [realm_id, route_id])
			assert_true(_does_not_regress(actual, baseline),
				"%s/%s may improve but never exceed its measured failure baseline" % [realm_id, route_id])


func test_historical_comparator_rejects_a_deliberately_worse_fixture() -> void:
	var baseline := [100, 7, 30.0]
	assert_false(_does_not_regress({"failing_samples": 8, "longest_failing_run_m": 30.0}, baseline),
		"one extra failing sample is a regression")
	assert_false(_does_not_regress({"failing_samples": 7, "longest_failing_run_m": 40.0}, baseline),
		"one longer empty run is a regression")
	assert_true(_does_not_regress({"failing_samples": 6, "longest_failing_run_m": 20.0}, baseline),
		"a strict improvement remains accepted")


func test_every_critical_route_has_two_forward_visible_creatures_at_every_sample() -> void:
	var result: Dictionary = MODEL.evaluate_all()
	var expected_route_counts := {
		"meadows": 5,
		"cloudreach": 6,
		"stormwood": 3,
		# Eight main island spines plus both authored choices for seven
		# required crossings. Optional island detours remain outside ROAD.
		"water": 22,
	}
	for realm_id: String in expected_route_counts:
		var routes: Array = result.get(realm_id, [])
		assert_eq(routes.size(), int(expected_route_counts[realm_id]),
			"critical route set changed in %s; update ROAD deliberately" % realm_id)
		for route: Dictionary in result[realm_id]:
			assert_true(int(route["samples"]) > 0, "%s/%s must be sampled" % [realm_id, route["id"]])
			assert_true(int(route["minimum_visible"]) >= MODEL.REQUIRED_VISIBLE,
				"%s/%s drops below two forward-visible bodies" % [realm_id, route["id"]])
			assert_eq(int(route["failing_samples"]), 0,
				"%s/%s has failing 10m samples" % [realm_id, route["id"]])
			assert_almost_eq(float(route["longest_failing_run_m"]), 0.0, 0.001,
				"%s/%s has an empty road run" % [realm_id, route["id"]])
	assert_true(MODEL.all_routes_pass(result))


func test_measured_runtime_repairs_keep_complete_footprints_in_route_core() -> void:
	var cloud_world := _json(CLOUDREACH_WORLD)
	var cloud_encounters := _json(CLOUDREACH_ENCOUNTERS)
	var water_world := _json(WATER_WORLD)
	var water_encounters := _json(WATER_ENCOUNTERS)
	var cases: Array[Dictionary] = [
		{"realm": "cloudreach", "route": "windscar_floor_loop",
			"site": "road_visibility_windscar_floor_loop_07", "count": 2,
			"pad": [-300.0, 460.03, 3100.0]},
		{"realm": "cloudreach", "route": "windscar_floor_loop",
			"site": "road_visibility_windscar_floor_loop_08", "count": 2,
			"pad": [-300.0, 460.03, 3100.0]},
		{"realm": "water", "route": "tidal_cradle_exploration_spine",
			"site": "road_visibility_tidal_cradle_exploration_spine_04", "count": 2},
		{"realm": "water", "route": "tidal_cradle_exploration_spine",
			"site": "road_visibility_tidal_cradle_exploration_spine_05", "count": 2},
		{"realm": "water", "route": "tidal_cradle_exploration_spine",
			"site": "water_tidal_cradle_wild_005", "count": 1},
		{"realm": "water", "route": "tidal_cradle_exploration_spine",
			"site": "water_tidal_cradle_wild_013", "count": 1},
		{"realm": "water", "route": "sluice_isle_exploration_spine",
			"site": "road_visibility_sluice_isle_exploration_spine_04", "count": 2},
	]
	for spec: Dictionary in cases:
		var world: Dictionary = cloud_world if spec.realm == "cloudreach" else water_world
		var encounters: Dictionary = cloud_encounters if spec.realm == "cloudreach" else water_encounters
		var routes: Array = world.get("routes", []) if spec.realm == "cloudreach" \
			else world.get("land_routes", [])
		var route := _find_id(routes, str(spec.route))
		var site := _find_id(encounters.get("wild_sites", []), str(spec.site))
		assert_false(route.is_empty(), "%s route exists" % spec.route)
		assert_false(site.is_empty(), "%s site exists" % spec.site)
		if route.is_empty() or site.is_empty():
			continue
		if spec.has("pad"):
			var position: Array = site.position
			var pad: Array = spec.pad
			assert_true(absf(float(position[0]) - float(pad[0])) <= 4.01
					and absf(float(position[2]) - float(pad[2])) <= 4.01,
				"%s stays inside the measured Windscar landing crown" % spec.site)
			assert_almost_eq(float(position[1]), float(pad[1]), 0.01,
				"%s keeps the physical landing-crown stratum" % spec.site)
		else:
			var projected := _project_to_polyline(site.position, route.polyline)
			assert_true(float(projected.offset_m) <= 1.01,
				"%s remains within the measured one-metre route core" % spec.site)
			assert_almost_eq(float(site.position[1]), float(projected.height), 0.01,
				"%s keeps the authored route stratum" % spec.site)
		assert_eq(int(site.count), int(spec.count), "%s keeps its population" % spec.site)


func test_windscar_air_patrol_is_deterministic_large_and_duplicate_safe() -> void:
	var world := _json(CLOUDREACH_WORLD)
	var encounters := _json(CLOUDREACH_ENCOUNTERS)
	var chapter := _json(CLOUDREACH_CHAPTER)
	var species: Dictionary = _json(SPECIES_DATA).get("species", {})
	var route := _find_id(world.get("routes", []), "windscar_floor_loop")
	var table := _find_id(chapter.get("encounter_tables", []), "cloudreach_windscar_wild")
	var sites: Array[Dictionary] = []
	for site: Dictionary in encounters.get("wild_sites", []):
		if str(site.get("placement_mode", "")) == "air_patrol":
			sites.append(site)
	assert_eq(sites.size(), 2, "Windscar bridge owns exactly two authored Air patrol pairs")
	var member_ids: Dictionary = {}
	for site: Dictionary in sites:
		assert_eq(int(site.get("count", 0)), 2, "%s remains a pair" % site.id)
		assert_almost_eq(float(site.position[1]) - float(site.ground_reference_y), 8.0, 0.001,
			"%s keeps its authored eight-metre flight altitude" % site.id)
		var projected := _project_to_polyline(site.position, route.polyline)
		assert_true(float(projected.offset_m) <= 1.01,
			"%s stays over the chain-bridge corridor" % site.id)
		assert_almost_eq(float(site.ground_reference_y), float(projected.height), 0.01,
			"%s altitude is measured from the authored bridge stratum" % site.id)
		for index in int(site.count):
			var plan: Dictionary = CLOUDREACH_DIRECTOR.air_patrol_member_plan(site, index)
			assert_false(plan.is_empty(), "%s member %d has a plan" % [site.id, index])
			assert_false(member_ids.has(str(plan.id)), "%s is globally deterministic" % plan.id)
			member_ids[str(plan.id)] = true
			assert_eq(int(plan.authority_id), 1, "%s remains listen-host-owned" % plan.id)
			assert_almost_eq(float((plan.position as Vector3).y), float(site.position[1]), 0.001,
				"%s remains in the fixed flight plane" % plan.id)
		assert_true(CLOUDREACH_DIRECTOR.site_needs_spawn({}, {}, str(site.id)),
			"%s spawns on first construction" % site.id)
		var spawned: Dictionary = {}
		var failed: Dictionary = {}
		spawned[str(site.id)] = true
		failed[str(site.id)] = true
		assert_false(CLOUDREACH_DIRECTOR.site_needs_spawn(spawned, {}, str(site.id)),
			"%s cannot duplicate when setup/reconnect sees its spawned ID" % site.id)
		assert_false(CLOUDREACH_DIRECTOR.site_needs_spawn({}, failed, str(site.id)),
			"%s does not retry a failed ID every frame" % site.id)
	for entry: Dictionary in table.get("entries", []):
		var definition: Dictionary = species.get(str(entry.placeholder_species), {})
		assert_eq(str(definition.get("type", "")), "air",
			"Windscar patrol table contains only existing Air species")
		var height := float(definition.get("placeholder", {}).get("height", 0.0))
		assert_true(height >= 1.9 and height <= 7.2,
			"%s stays inside the required presentation-height range" % entry.placeholder_species)


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _find_id(rows: Array, id: String) -> Dictionary:
	for row: Dictionary in rows:
		if str(row.get("id", "")) == id:
			return row
	return {}


func _project_to_polyline(raw_at: Array, raw_points: Array) -> Dictionary:
	var at := Vector2(float(raw_at[0]), float(raw_at[2]))
	var best_offset := INF
	var best_height := NAN
	for index in raw_points.size() - 1:
		var raw_a: Array = raw_points[index]
		var raw_b: Array = raw_points[index + 1]
		var a := Vector2(float(raw_a[0]), float(raw_a[2]))
		var b := Vector2(float(raw_b[0]), float(raw_b[2]))
		var segment := b - a
		if segment.length_squared() <= 0.001:
			continue
		var along := clampf((at - a).dot(segment) / segment.length_squared(), 0.0, 1.0)
		var offset := at.distance_to(a.lerp(b, along))
		if offset < best_offset:
			best_offset = offset
			best_height = lerpf(float(raw_a[1]), float(raw_b[1]), along)
	return {"offset_m": best_offset, "height": best_height}


func _does_not_regress(actual: Dictionary, baseline: Array) -> bool:
	return int(actual.get("failing_samples", 0)) <= int(baseline[1]) \
		and float(actual.get("longest_failing_run_m", 0.0)) <= float(baseline[2])
