extends "res://tests/test_case.gd"

const SEGMENT := preload("res://tests/helpers/water_brine_segment.gd")


func test_result_requires_explicit_clean_completion() -> void:
	var segment := SEGMENT.new()
	assert_false(segment.result().ok)
	assert_false(SEGMENT.verdict(false, []))
	assert_false(SEGMENT.verdict(true, ["route failed"]))
	assert_true(SEGMENT.verdict(true, []))


func test_authored_crossing_and_tovin_contracts_match_segment() -> void:
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/water_world.json"))
	var characters: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/water_characters.json"))
	var route: Dictionary = {}
	for candidate: Dictionary in world.water_routes:
		if str(candidate.id) == SEGMENT.ROUTE_ID:
			route = candidate
	var trainer: Dictionary = {}
	for candidate: Dictionary in characters.trainers:
		if str(candidate.id) == SEGMENT.TOVIN_ID:
			trainer = candidate
	assert_true(SEGMENT.route_contract(route))
	assert_true(SEGMENT.trainer_contract(trainer))
	assert_eq(str(trainer.team[0].species), "cannonback")
	assert_eq(str(trainer.team[1].species), "riverdrake")
