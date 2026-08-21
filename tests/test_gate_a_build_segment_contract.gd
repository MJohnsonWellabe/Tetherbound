extends "res://tests/test_case.gd"

## Static guard for the reusable Gate A controller segment. The real Meadows
## wrapper is a smoke test; this keeps future convenience edits from quietly
## turning the reusable segment back into a direct-state fixture.

const SEGMENT := preload("res://tests/helpers/gate_a_build_segment.gd")
const SOURCE_PATH := "res://tests/helpers/gate_a_build_segment.gd"


func test_reusable_segment_parses() -> void:
	var segment: RefCounted = SEGMENT.new()
	assert_true(segment != null, "the continuous-evidence helper must remain loadable")


func test_reusable_segment_mutates_play_only_through_parsed_controller_events() -> void:
	var source := FileAccess.get_file_as_string(SOURCE_PATH)
	for banned in [
		"set(\"pending_build\"",
		"_spawn_building",
		"register_building",
		"dismantle_piece",
		"global_position =",
		"inventory.call(\"add\"",
		"inventory.call(\"remove\"",
	]:
		assert_false(source.contains(banned), "reusable segment must not use bypass '%s'" % banned)
	assert_true(source.contains("Input.parse_input_event"), "controller events must cross the live InputMap")
	for action in ["build_open", "ui_accept", "build_place", "build_dismantle", "build_cancel", "move_right", "move_back"]:
		assert_true(source.contains(action), "controller sequence must include %s" % action)


func test_reusable_segment_names_the_canonical_paid_house_contract() -> void:
	var source := FileAccess.get_file_as_string(SOURCE_PATH)
	assert_true(source.contains("before_wood - 39"), "2x2 house must spend its exact 39 wood")
	assert_true(source.contains("before_stone - 34"), "2x2 house must spend its exact 34 stone")
	assert_true(source.contains("built_records != 12"), "four floors + door + three walls + four roofs")
	assert_true(source.contains("wood_before + 6"), "dismantled wall must refund all six wood")
	assert_true(source.contains("stone_before + 2"), "dismantled wall must refund both stone")
