extends "res://tests/test_case.gd"

const RECEIPT := preload("res://tests/helpers/captured_character_receipt.gd")
const DOCUMENT := preload("res://scripts/save/save_document.gd")

func _owner() -> Dictionary:
	var owner := {"character_id": "guest", "realm": "stormwood", "flags": {"flags": ["home_key"]}}
	for field: String in RECEIPT.CHARACTER.STATE_KEYS: owner[field] = {}
	owner.party = [{"uid": "one", "xp": 228}, {"uid": "two", "xp": 184}]
	owner.inventory = [{"id": "coin", "n": 20}]
	owner.redesign_character = {"transaction_receipts": ["reward", "feast"], "creatures": {"one": {"cap_level": 20}}}
	return owner

func test_copied_character_roundtrip_and_wrong_owner() -> void:
	var expected := _owner()
	var saved: Dictionary = DOCUMENT.parse(DOCUMENT.stringify(expected))
	assert_eq(RECEIPT.error(saved, expected, "guest"), "")
	assert_false(RECEIPT.error(saved, expected, "other").is_empty())
	assert_false(RECEIPT.error({}, expected, "guest").is_empty())
	assert_false(RECEIPT.error(saved, expected, "").is_empty())

func test_missing_fields_stale_rewards_caps_and_order_refuse() -> void:
	var expected := _owner()
	for field: String in expected:
		var missing := expected.duplicate(true)
		missing.erase(field)
		assert_false(RECEIPT.error(missing, expected, "guest").is_empty(), field)
	var stale := expected.duplicate(true)
	stale.inventory[0].n = 0
	assert_false(RECEIPT.error(stale, expected, "guest").is_empty())
	stale = expected.duplicate(true)
	stale.redesign_character.transaction_receipts.pop_back()
	assert_false(RECEIPT.error(stale, expected, "guest").is_empty())
	stale = expected.duplicate(true)
	stale.redesign_character.creatures.one.cap_level = 10
	assert_false(RECEIPT.error(stale, expected, "guest").is_empty())
	stale = expected.duplicate(true)
	stale.party.reverse()
	assert_false(RECEIPT.error(stale, expected, "guest").is_empty())
