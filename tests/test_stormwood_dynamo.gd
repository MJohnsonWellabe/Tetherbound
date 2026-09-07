extends "res://tests/test_case.gd"

## The Dynamo rules are a small policy object, but these are player-facing
## promises: a five-creature captain fight escalates once, the visible banks
## really fire around the room, and the final piloted run has a hard deadline.
const DYNAMO := preload("res://scripts/world/stormwood_dynamo_rules.gd")


func _rules() -> RefCounted:
	return DYNAMO.new()


func _period(rules: RefCounted, phase_name: String) -> float:
	var timing: Dictionary = rules.config.phases[phase_name]
	return float(timing.charge_seconds) + float(timing.fire_seconds) + float(timing.recovery_seconds)


func test_five_creature_captain_team_moves_through_the_three_combat_phases() -> void:
	var rules := _rules()
	rules.update_team(5, 5)
	assert_eq(rules.phase, "bank_cycle", "a full five-creature team starts in the readable bank cycle")
	rules.update_team(3, 5)
	assert_eq(rules.phase, "bank_cycle", "three remaining is still above half of a five-creature team")
	rules.update_team(2, 5)
	assert_eq(rules.phase, "overload", "two remaining must trigger the half-team overload")
	rules.update_team(1, 5)
	assert_eq(rules.phase, "overload", "overload must not retreat back to bank cycle")
	rules.update_team(0, 5)
	assert_eq(rules.phase, "break_core", "defeating the captain's final creature opens the conduit run")


func test_overload_shortens_the_window_without_changing_the_four_bank_order() -> void:
	var rules := _rules()
	var normal_period := _period(rules, "bank_cycle")
	var overload_period := _period(rules, "overload")
	assert_true(overload_period < normal_period,
		"Overload must give less time between banks than the opening phase")

	rules.update_team(2, 5)
	for expected_bank in 4:
		var state: Dictionary = rules.bank_state()
		assert_eq(int(state.bank), expected_bank,
			"the banks must discharge in a predictable 0, 1, 2, 3 order")
		assert_eq(str(state.state), "charge", "each new bank begins with a readable charge telegraph")
		rules.advance(overload_period)
	assert_eq(int(rules.bank_state().bank), 0, "the fifth discharge begins the next four-bank cycle")


func test_three_rod_plates_are_safe_and_each_bank_has_a_real_lane() -> void:
	var rules := _rules()
	assert_eq(rules.config.plates.size(), 3, "the core is designed around exactly three grounded rod plates")
	for point: Array in rules.config.plates:
		var plate := Vector2(float(point[0]), float(point[1]))
		assert_true(rules.on_plate(plate), "an authored rod plate must be recognized as safe ground")
		for bank in int(rules.config.bank_count):
			assert_false(rules.in_discharge_lane(plate, bank),
				"a rod plate must override every capacitor lane")
	for bank in int(rules.config.bank_count):
		var lane_point: Vector2 = rules.bank_position(bank).normalized() * 12.0
		assert_true(rules.in_discharge_lane(lane_point, bank),
			"each capacitor needs a damaging radial lane away from its safe plates")
		assert_false(rules.in_discharge_lane(lane_point, (bank + 1) % int(rules.config.bank_count)),
			"adjacent capacitor lanes must stay distinct")
	assert_false(rules.in_discharge_lane(Vector2.ZERO, -1), "an invalid bank index must not create a lane")


func test_only_a_piloted_creature_within_reach_can_strike_each_conduit_once() -> void:
	var rules := _rules()
	rules.update_team(0, 5)
	var first: Vector2 = rules.bank_position(0)
	assert_false(rules.strike_conduit(0, first, false), "the human cannot strike a conduit")
	assert_false(rules.strike_conduit(0, first + Vector2.RIGHT * 3.201, true),
		"a remote creature must be refused outside conduit reach")
	assert_true(rules.strike_conduit(0, first + Vector2.RIGHT * 3.2, true),
		"the reach boundary is a legal piloted conduit hit")
	assert_false(rules.strike_conduit(0, first, true), "the same exposed conduit cannot be farmed twice")
	for bank in range(1, int(rules.config.bank_count)):
		assert_true(rules.strike_conduit(bank, rules.bank_position(bank), true),
			"each distinct conduit accepts its piloted hit")
	assert_eq(rules.phase, "released", "all four distinct piloted hits release the captive")
	assert_false(rules.strike_conduit(4, Vector2.ZERO, true), "an invalid fifth conduit cannot alter a released core")


func test_missing_a_full_four_bank_core_cycle_clears_partial_conduit_progress() -> void:
	var rules := _rules()
	rules.update_team(0, 5)
	assert_true(rules.strike_conduit(0, rules.bank_position(0), true))
	assert_true(rules.strike_conduit(1, rules.bank_position(1), true))
	var one_bank := _period(rules, "break_core")
	rules.advance(one_bank)
	assert_eq(rules.conduits, [0, 1], "one bank firing is not a missed full core cycle")
	rules.advance(one_bank * 3.0)
	assert_eq(rules.conduits, [], "missing all four bank discharges restarts the conduit run")
	assert_eq(rules.phase, "break_core", "a missed run resets progress without releasing the captive")


func test_save_load_keeps_a_partial_conduit_window_and_reset_never_keeps_release() -> void:
	var original := _rules()
	original.update_team(0, 5)
	assert_true(original.strike_conduit(0, original.bank_position(0), true))
	assert_true(original.strike_conduit(2, original.bank_position(2), true))
	original.advance(2.25)
	var restored := _rules()
	restored.load_data(original.save_data())
	assert_eq(restored.phase, "break_core", "loading a partial core run must not return to captain combat")
	assert_eq(restored.conduits, [0, 2], "loading must preserve the distinct conduits already struck")
	assert_almost_eq(restored.elapsed, original.elapsed, 0.0001, "loading must preserve the time left in the window")
	assert_eq(restored.advance(0.5), original.advance(0.5), "the restored run must continue on the same bank and timing")

	for bank in [1, 3]:
		assert_true(restored.strike_conduit(bank, restored.bank_position(bank), true))
	assert_eq(restored.phase, "released", "the restored partial run can still complete normally")
	var prior_attempt: int = restored.attempt
	restored.reset()
	assert_eq(restored.phase, "bank_cycle", "reset must reopen the encounter, never retain release")
	assert_eq(restored.conduits, [], "reset must remove prior conduit strikes")
	assert_eq(restored.attempt, prior_attempt + 1, "reset records the next encounter attempt")
