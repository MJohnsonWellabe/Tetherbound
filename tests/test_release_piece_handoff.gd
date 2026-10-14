extends "res://tests/test_case.gd"
const WITNESS := preload("res://tests/helpers/release_piece_handoff.gd")

func test_loaded_handoff_requires_each_saved_field_and_ordered_roster() -> void:
	var state := {"uids": ["a", "b"], "flags": ["one"], "items": {"potion": 2}, "realm": "water", "training": {"party": [{"uid": "a", "cap_level": 20}]}}
	var receipt := {"passed": true, "segment": "07b_calder", "after": state.duplicate(true)}
	assert_eq(WITNESS.error(receipt, "07b_calder", JSON.parse_string(JSON.stringify(state))), "")
	for key: String in state:
		var missing := state.duplicate(true)
		missing.erase(key)
		assert_false(WITNESS.error(receipt, "07b_calder", missing).is_empty())
	for change: Dictionary in [{"uids": ["b", "a"]}, {"flags": []}, {"items": {"potion": 1}}, {"realm": "meadows"}, {"training": {"party": [{"uid": "a", "cap_level": 10}]}}]:
		var altered := state.duplicate(true)
		altered.merge(change, true)
		assert_false(WITNESS.error(receipt, "07b_calder", altered).is_empty())

func test_loaded_handoff_refuses_invalid_or_wrong_predecessor_receipt() -> void:
	var state := {"uids": ["a"], "flags": [], "items": {}, "realm": "water", "training": {"party": []}}
	var receipt := {"passed": true, "segment": "07b_calder", "after": state}
	assert_false(WITNESS.error(receipt, "07a_salt_bex", state).is_empty())
	for verdict: Variant in [false, "true", 1, null]:
		var invalid := receipt.duplicate(true)
		invalid.passed = verdict
		assert_false(WITNESS.error(invalid, "07b_calder", state).is_empty())
	assert_false(WITNESS.error(null, "07b_calder", state).is_empty())
