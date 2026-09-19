extends TestCase

const CONDITION := preload("res://tools/gate_f/verified_condition.gd")


func test_every_s03_catch_chip_stops_after_the_required_roster_is_earned() -> void:
	var segment: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/gate_f/segments/S03.json"))
	var chip_count := 0
	var final_roster_check := false
	for step: Dictionary in segment.steps:
		if str(step.action) == "chip_to_floor":
			chip_count += 1
			assert_eq(step.args.get("skip_if", {}), {"check": "party_size", "min": 5.0}, str(step.id))
		if str(step.id) == "S03-39":
			final_roster_check = str(step.action) == "assert" and step.args == {"check": "party_size", "min": 5.0}
	assert_eq(chip_count, 10)
	assert_true(final_roster_check, "conditional attacks cannot replace actual five-member acceptance")


func test_every_supported_action_preserves_live_predicate_and_no_input_receipt() -> void:
	for action in CONDITION.ACTIONS:
		var calls := []
		var predicate := {"check": "party_size", "at_least": 5}
		var result := CONDITION.evaluate(action, predicate, func(args: Dictionary) -> Dictionary:
			calls.append(args)
			return {"ok": true, "actual": "party_size=5"})
		assert_true(result.satisfied, action)
		assert_eq(calls, [predicate])
		assert_eq(result.predicate, predicate)
		assert_eq(result.readback, "party_size=5")
		assert_false(result.input_issued)
		assert_true(result.actual.begins_with("CONDITION-SATISFIED " + action))
		assert_true(result.actual.contains("no action input issued"))


func test_failed_unevaluable_or_contradictory_readback_is_not_satisfied() -> void:
	for receipt in [{"ok": false, "actual": "party_size=4"},
		{"ok": true, "skip": true, "actual": "context missing"},
		{"ok": "true", "actual": "party_size=5"}, {"ok": 1, "actual": "party_size=5"},
		{"ok": true}, {"ok": true, "actual": "SKIPPED missing context"},
		{"ok": true, "actual": "FAIL context"}, {"ok": true, "actual": "BLOCKER lost scene"},
		{"ok": true, "actual": "HARNESS-ERROR missing binding"}]:
		var result := CONDITION.evaluate("press", {"check": "party_size"},
			func(_args: Dictionary) -> Dictionary: return receipt)
		assert_false(result.satisfied)
		assert_eq(result.actual, "")


func test_only_explicit_conditional_actions_invoke_readback() -> void:
	var calls := []
	var read := func(_args: Dictionary) -> Dictionary:
		calls.append(true)
		return {"ok": true, "actual": "true"}
	assert_false(CONDITION.evaluate("probe_cell", {"check": "party_size"}, read).satisfied)
	assert_false(CONDITION.evaluate("press", {}, read).satisfied)
	assert_false(CONDITION.evaluate("press", {"optional": true}, read).satisfied)
	assert_eq(calls.size(), 0)


func test_each_evaluation_rereads_current_state_and_cannot_reuse_prior_success() -> void:
	var live := {"party_size": 5, "reads": 0}
	var read := func(args: Dictionary) -> Dictionary:
		live.reads += 1
		return {"ok": live.party_size >= int(args.at_least), "actual": "party_size=%d" % live.party_size}
	var predicate := {"check": "party_size", "at_least": 5}
	assert_true(CONDITION.evaluate("throw_until_caught", predicate, read).satisfied)
	live.party_size = 4
	assert_false(CONDITION.evaluate("throw_until_caught", predicate, read).satisfied)
	assert_eq(live.reads, 2)
