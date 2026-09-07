extends "res://tests/test_case.gd"

## Catalogue-only checks. These prove census, live placeholder/rank references,
## and placement against the authored route; they do not stand up trainer NPCs.

const PATH := "res://data/config/stormwood_trainers.json"
const WORLD_PATH := "res://data/config/stormwood_world.json"
const ART_PATH := "res://data/config/art.json"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const HEIGHTFIELD := preload("res://scripts/world/stormwood_heightfield.gd")
const STARTERS := ["terrapup", "ripplet", "galewisp"]


func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var delta := b - a
	var along := clampf((point - a).dot(delta) / maxf(delta.length_squared(), 0.001), 0.0, 1.0)
	return point.distance_to(a + delta * along)


func _distance_to_routes(point: Vector2, world: Dictionary) -> float:
	var closest := INF
	for route: Dictionary in world.get("routes", []):
		var points: Array = route.get("points", [])
		for index in range(points.size() - 1):
			var a: Array = points[index]
			var b: Array = points[index + 1]
			closest = minf(closest, _distance_to_segment(point, Vector2(float(a[0]), float(a[1])), Vector2(float(b[0]), float(b[1]))))
	return closest


func test_trainer_census_covers_all_regions_and_path_classes() -> void:
	var trainers: Array = _read(PATH).get("trainers", [])
	assert_eq(trainers.size(), 26)
	var critical := 0
	var optional := 0
	var by_region := {}
	for trainer: Dictionary in trainers:
		var region := str(trainer.get("region_id", ""))
		by_region[region] = int(by_region.get(region, 0)) + 1
		if str(trainer.get("route_class", "")) == "critical":
			critical += 1
		elif str(trainer.get("route_class", "")) == "optional":
			optional += 1
	assert_eq(critical, 14)
	assert_eq(optional, 12)
	for region: String in ["cinder_verge", "glowmoss_hollows", "conductor_run", "hollow_crown", "deepwood", "dynamo"]:
		assert_true(int(by_region.get(region, 0)) >= 3, region + " needs at least three trainers")


func test_parties_ranks_and_critical_ladder_are_live_and_bounded() -> void:
	var art := _read(ART_PATH)
	var last_ace := 0
	var critical_orders := {}
	for trainer: Dictionary in _read(PATH).get("trainers", []):
		assert_true(art.has(str(trainer.get("humanoid_key", ""))), "trainer uses an installed art.json humanoid")
		assert_true(["trainer", "lieutenant", "officer", "ace", "captain"].has(str(trainer.get("rank", ""))))
		assert_false(str(trainer.get("replacement_point", "")).is_empty())
		var party: Array = trainer.get("party", [])
		assert_true(party.size() >= 2 and party.size() <= 4)
		for member: Dictionary in party:
			var species := str(member.get("placeholder_species", ""))
			assert_true(SPECIES.has(species))
			assert_false(STARTERS.has(species))
			assert_false(str(member.get("replacement_point", "")).is_empty())
		if str(trainer.get("route_class", "")) == "critical":
			critical_orders[int(trainer.get("critical_order", 0))] = trainer
	for order in range(1, 15):
		assert_true(critical_orders.has(order), "critical trainer order is contiguous")
		if critical_orders.has(order):
			var ace := int((critical_orders[order] as Dictionary).get("ace_level", 0))
			if order > 1:
				assert_true(ace - last_ace <= 4, "critical ace progression may not jump over four levels")
			last_ace = ace
	assert_eq(last_ace, 44, "Captain Marrow's ace is the chapter cap")
	var named_ranks := {}
	var picket_leaders := 0
	for trainer: Dictionary in _read(PATH).get("trainers", []):
		named_ranks[str(trainer.get("id", ""))] = str(trainer.get("rank", ""))
		if str(trainer.get("group", "")) == "picket_leader":
			picket_leaders += 1
	assert_eq(named_ranks.get("tamsin_surge_lesson", ""), "trainer")
	assert_eq(named_ranks.get("lieutenant_dace_hollows_rod", ""), "lieutenant")
	assert_eq(named_ranks.get("lieutenant_varga_rodline_bridge", ""), "lieutenant")
	assert_eq(named_ranks.get("officer_kestrel_outer_works", ""), "officer")
	assert_eq(named_ranks.get("captain_marrow_dynamo_core", ""), "captain")
	assert_eq(picket_leaders, 4, "four rod/Outer Works picket leaders are separately authored")
	var catalogue := _read(PATH)
	var leaders: Dictionary = catalogue.get("leaders", {})
	assert_eq(leaders.keys().size(), 4, "the four rod stations have explicit leader slots")
	for station: String in ["verge", "hollows", "deepwood", "dynamo"]:
		assert_true(leaders.has(station), station + " station leader is declared")
	var expected_regions := {
		"verge": "cinder_verge",
		"hollows": "glowmoss_hollows",
		"deepwood": "deepwood",
		"dynamo": "dynamo"
	}
	for station: String in expected_regions:
		var leader_id := str(leaders.get(station, ""))
		var matches := (catalogue.get("trainers", []) as Array).filter(func(trainer: Dictionary) -> bool: return str(trainer.get("id", "")) == leader_id)
		assert_eq(matches.size(), 1, station + " maps to exactly one trainer")
		if matches.size() == 1:
			var leader: Dictionary = matches[0]
			assert_eq(str(leader.get("region_id", "")), str(expected_regions[station]))
			assert_eq(str(leader.get("group", "")), "picket_leader")


func test_anchors_are_unique_grounded_and_near_authored_routes() -> void:
	var world := _read(WORLD_PATH)
	var ids := {}
	for trainer: Dictionary in _read(PATH).get("trainers", []):
		var id := str(trainer.get("id", ""))
		assert_false(id.is_empty() or ids.has(id))
		ids[id] = true
		var position: Array = trainer.get("position", [])
		assert_eq(position.size(), 3)
		if position.size() == 3:
			var anchor: Dictionary = trainer.get("encounter_anchor", {})
			assert_true(bool(anchor.get("route_grounded", false)))
			assert_true(_distance_to_routes(Vector2(float(position[0]), float(position[2])), world) <= float(anchor.get("max_route_distance_m", 30.0)), id + " anchor drifts off the root-authored routes")
	var heightfield := HEIGHTFIELD.new(HEIGHTFIELD.load_config())
	for trainer: Dictionary in _read(PATH).get("trainers", []):
		var position: Array = trainer.get("position", [])
		if position.size() != 3:
			continue
		var ground_y := heightfield.height_at(float(position[0]), float(position[2])) + 0.15
		if str(trainer.get("surface_id", "")) == "dynamo_core":
			assert_almost_eq(float(position[1]), ground_y + 150.0, 0.01, "core captain uses the elevated Dynamo surface")
		else:
			assert_true(str(trainer.get("surface_id", "")).is_empty(), "%s may not silently opt out of terrain grounding" % str(trainer.get("id", "")))
			assert_almost_eq(float(position[1]), ground_y, 0.01, "%s is terrain-grounded" % str(trainer.get("id", "")))
