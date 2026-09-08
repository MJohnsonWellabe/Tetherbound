extends "res://tests/test_case.gd"

const SEGMENT := preload("res://tests/helpers/stormwood_earned_marrow_segment.gd")
const RULES := preload("res://scripts/world/stormwood_dynamo_rules.gd")

class QuietSegment extends SEGMENT:
	func _fail(message: String) -> bool:
		failures.append(message)
		return false

func test_bank_selection_uses_actual_positions_and_excludes_accepted_conduits() -> void:
	var rules := RULES.new()
	assert_eq(SEGMENT.next_bank(rules, rules.bank_position(2)), 2)
	rules.conduits.append(2)
	assert_true(SEGMENT.next_bank(rules, rules.bank_position(2)) != 2)
	rules.conduits = [0, 1, 2, 3]
	assert_eq(SEGMENT.next_bank(rules, Vector2.ZERO), -1)

func test_conservative_travel_bound_accounts_for_actual_start_speed_and_remaining_banks() -> void:
	var rules := RULES.new()
	var expected := (35.0 - 3.2 + 3.0 * (35.0 * sqrt(2.0) - 6.4)) / 5.6
	assert_almost_eq(SEGMENT.travel_lower_bound_seconds(rules, Vector2.ZERO, 5.6), expected, 0.001)
	assert_true(expected > 28.0)
	assert_true(SEGMENT.travel_lower_bound_seconds(rules, Vector2(20, 0), 5.6) < expected)
	rules.conduits = [0, 1, 2]
	assert_almost_eq(SEGMENT.travel_lower_bound_seconds(rules, rules.bank_position(3), 5.6), 0.0, 0.001)
	rules.conduits.append(3)
	assert_almost_eq(SEGMENT.travel_lower_bound_seconds(rules, Vector2.ZERO, 5.6), 0.0, 0.001)

func test_actual_roster_finished_is_separate_from_conduit_release() -> void:
	var segment := SEGMENT.new()
	segment._observe_marrow({"kind": "finished", "trainer_id": "other", "won": true})
	assert_true(segment._outcomes.is_empty())
	segment._observe_marrow({"kind": "finished", "trainer_id": SEGMENT.CAPTAIN, "won": true})
	assert_true(segment._outcomes[SEGMENT.CAPTAIN])
	assert_false(segment.result().passed)
	for index in 5:
		segment._observe_marrow({"kind": "state", "trainer_id": SEGMENT.CAPTAIN,
			"round": index, "total": 5, "team_entry": {"slot": index + 1}})
	assert_eq(segment._rounds.size(), 5)
	assert_false(segment.result().passed)
	segment._observe_marrow({"kind": "dynamo_verdict", "verdict": {"ok": false, "reason": "unrelated"}})
	assert_eq(segment._conduit_refusal, "")
	segment._waiting_bank = 1
	segment._observe_marrow({"kind": "dynamo_verdict", "verdict": {"ok": false, "reason": "face conduit"}})
	assert_eq(segment._conduit_refusal, "face conduit")

func test_missing_live_entry_cannot_claim_release() -> void:
	var segment := QuietSegment.new()
	var observed: Dictionary = await segment.run(null, null, null)
	assert_false(observed.passed)
	assert_eq(observed.failures.size(), 1)

func test_controller_preserves_one_window_and_production_authority() -> void:
	var source := FileAccess.get_file_as_string("res://tests/helpers/stormwood_earned_marrow_segment.gd")
	for bypass in ["request_conduit_strike", "request_move", "global_position =", "face_towards",
		"emit_event(", "begin_for_peer(", "strike_conduit(", "pending_catch", "ending_claim"]:
		assert_false(source.contains(bypass), bypass)
	for condition in ["int(state.cycle) != conduit_cycle", "_rounds.size() != 5",
		"Time.get_ticks_msec() - started < ATTEMPT_MS", "control.get(\"_body\") == ally",
		"DYNAMO.facing_conduit", "rules.config.conduit_reach_m", "Engine.time_scale = scale_before",
		"Engine.physics_ticks_per_second = hz_before"]:
		assert_true(source.contains(condition), condition)
	assert_eq(SEGMENT.ATTEMPT_MS, 300000)
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_dynamo.json"))
	var phase: Dictionary = config.phases.break_core
	assert_almost_eq(float(config.bank_count) * (float(phase.charge_seconds) + float(phase.fire_seconds)
		+ float(phase.recovery_seconds)), 28.0, 0.001)
