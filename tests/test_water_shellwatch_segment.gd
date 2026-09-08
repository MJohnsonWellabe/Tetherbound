extends "res://tests/test_case.gd"

const SEGMENT := preload("res://tests/helpers/water_shellwatch_segment.gd")


func test_result_requires_explicit_clean_completion() -> void:
	var segment := SEGMENT.new()
	assert_false(segment.result().ok)
	assert_false(SEGMENT.verdict(false, []))
	assert_false(SEGMENT.verdict(true, ["action failed"]))
	assert_true(SEGMENT.verdict(true, []))


func test_authored_route_trainers_and_actions_match_segment() -> void:
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/water_world.json"))
	var characters: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/water_characters.json"))
	var docks: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/water_dock_actions.json"))
	var route: Dictionary = {}
	for candidate: Dictionary in world.water_routes:
		if str(candidate.id) == SEGMENT.ROUTE_ID:
			route = candidate
	var trainers: Dictionary = {}
	for candidate: Dictionary in characters.trainers:
		trainers[str(candidate.id)] = candidate
	assert_true(SEGMENT.route_contract(route))
	assert_true(SEGMENT.trainer_contract(trainers.get(SEGMENT.SOLM_ID, {}),
		SEGMENT.SOLM_ID, 47, ["mirejaw", "mangrove_monitor"]))
	assert_true(SEGMENT.trainer_contract(trainers.get(SEGMENT.IRVA_ID, {}),
		SEGMENT.IRVA_ID, 48, ["riptusk", "cannonback"]))
	assert_true(SEGMENT.dock_contract(docks))
	assert_true(SEGMENT.world_dock_contract(world))
	assert_eq(SEGMENT.DEPARTURE_BARRIER, "shellwatch_to_tidal_cradle_dockBarrier")
	var camp: Dictionary = {}
	var camp_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/water_camps.json"))
	for candidate: Dictionary in camp_data.camps:
		if str(candidate.id) == SEGMENT.CAMP_ID:
			camp = candidate
	assert_eq(str(camp.get("island_id", "")), "shellwatch")
	assert_eq(camp.get("at", []), [359.289459228516, 971.46923828125])
