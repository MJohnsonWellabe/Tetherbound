extends "res://tests/test_case.gd"

const DATA := preload("res://tests/test_foundation_resources.gd")
const ACTIONS := preload("res://scripts/net/foundation_actions.gd")
const DELIVERY := preload("res://scripts/net/foundation_delivery.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")

func _context(index: Variant = 2) -> Dictionary:
	return {"character_id": DATA.CHARACTER, "expected_revision": 0, "source_key": "den:meadows:b3",
		"station_id": "den", "in_range": true, "in_combat": false, "homestead": true,
		"den_index": index, "foundation_runtime_authorized": true}

func test_den_rest_journal_survives_json_and_keeps_the_same_owned_creature_and_bed() -> void:
	var before := DATA.new()._before()
	var intent := {"creature_uid": before.party[0].uid, "action": "rest", "action_id": DATA.TXN}
	var proposal := ACTIONS.stage(before, 0, "den", intent, _context(), RECORD.errors)
	assert_true(proposal.get("ok") == true, str(proposal))
	if proposal.get("ok") != true: return
	proposal.character_revision = 1
	var row := DELIVERY.make_record("resource-slot", "resource-namespace", "resource-epoch", proposal, null, RECORD.errors)
	assert_false(row.is_empty())
	if row.is_empty(): return
	var decoded: Dictionary = JSON.parse_string(JSON.stringify(row))
	assert_true(DELIVERY.valid(decoded, RECORD.errors))
	var owner := DELIVERY.owner_plan(before, decoded, RECORD.errors)
	assert_true(owner.get("ok") == true)
	assert_eq(owner.state.party[0].uid, before.party[0].uid)
	assert_true(owner.state.party[0].resting)
	assert_eq(int(owner.state.party[0].rest_bed_index), 2)
	assert_true(DELIVERY.owner_plan(owner.state, decoded, RECORD.errors).duplicate)

func test_den_index_rejects_fraction_boolean_negative_and_nonfinite_context() -> void:
	var before := DATA.new()._before()
	var intent := {"creature_uid": before.party[0].uid, "action": "rest", "action_id": DATA.TXN}
	for invalid: Variant in [true, false, -1, 0.5, NAN, INF, "2", 2147483647]:
		assert_false(ACTIONS.stage(before, 0, "den", intent, _context(invalid), RECORD.errors).get("ok", false), str(invalid))
	assert_true(ACTIONS.stage(before, 0, "den", intent, _context(2.0), RECORD.errors).get("ok") == true)
