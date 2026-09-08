extends "res://tests/test_case.gd"

const SEGMENT := preload("res://tests/helpers/cloudreach_live_segment.gd")


func test_live_segment_refuses_missing_context_without_creating_a_fixture() -> void:
	var segment := SEGMENT.new()
	var observed: Dictionary = await segment.run(null, null, null)
	assert_false(observed.ok)
	assert_false(observed.completed)
	assert_true(not observed.failures.is_empty())
	assert_eq(observed.world, null)
	assert_eq(observed.game, null)


func test_party_handoff_accepts_an_earned_carrier_without_requiring_a_loaner() -> void:
	assert_true(SEGMENT.party_preserved([11, 12, 13], [11, 12, 13]))
	assert_true(SEGMENT.party_preserved([11, 12, 13, 14, 15], [11, 12, 13, 14, 15]))
	assert_false(SEGMENT.party_preserved([], []))
	assert_false(SEGMENT.party_preserved([11, 12], [11, 99]))
	assert_false(SEGMENT.party_preserved([11, 12], [11, 12, 13]))
	assert_false(SEGMENT.party_preserved([1, 2, 3, 4, 5, 6], [1, 2, 3, 4, 5, 6]))


func test_completion_fails_closed_on_any_route_failure() -> void:
	assert_false(SEGMENT.verdict(false, []))
	assert_false(SEGMENT.verdict(true, ["required fight lost"]))
	assert_true(SEGMENT.verdict(true, []))


func test_campaign_segment_contains_no_fixture_or_progression_shortcuts() -> void:
	var source := FileAccess.get_file_as_string("res://tests/helpers/cloudreach_live_segment.gd")
	for forbidden: String in ["reset_for_new_game", "set_flag(", "inventory.add(",
		"party.add(", "set_level(", "take_damage(", "_award_victory(",
		"_begin_resolve(", "load_game(", "save_game(", "enter_realm(",
		"global_position =", "global_position=", "set_physics_process(",
		"set_process(", "rig.set(", "cycle_active("]:
		assert_false(source.contains(forbidden), "campaign helper may not inject gameplay state: " + forbidden)
