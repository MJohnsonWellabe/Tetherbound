extends "res://tests/test_case.gd"

const RECEIPT := preload("res://tests/helpers/stormwood_checkpoint_receipt.gd")

func _owner() -> Dictionary:
	return {"character_id": "owner", "party": [{"uid": "stormheart", "level": 55, "xp": 0}],
		"inventory": [{"id": "home_key", "n": 1}], "flags": {"homecoming": true},
		"realm": "meadows", "pending_realm_entry": "", "realm_hearts": {"stormwood": "hung"},
		"redesign_character": {"creatures": {"stormheart": {"cap_level": 60, "breakthroughs": [1, 2, 3, 4, 5]}},
			"transaction_receipts": ["home-return", "relic-hung", "credits-seen"]}}

func _pair(owner: Dictionary) -> Dictionary:
	return {"state": "split", "character_id": "owner", "character": owner.duplicate(true)}

func test_copied_owner_matches_after_disk_json_roundtrip() -> void:
	var expected := _owner()
	var pair: Dictionary = JSON.parse_string(JSON.stringify(_pair(expected)))
	assert_eq(RECEIPT.saved_owner_error(pair, expected), "")
	# An old, already-owned L55/cap10 save must be preserved, not repaired by
	# a Home Key trip. New volunteer admission is a separate witness.
	expected.redesign_character.creatures.stormheart.cap_level = 10
	expected.redesign_character.creatures.stormheart.breakthroughs = []
	assert_eq(RECEIPT.saved_owner_error(_pair(expected), expected), "")

func test_stale_or_incomplete_saved_owner_refuses() -> void:
	var expected := _owner()
	for field: String in RECEIPT.OWNER_FIELDS:
		var missing := _pair(expected)
		missing.character.erase(field)
		assert_false(RECEIPT.saved_owner_error(missing, expected).is_empty(), field)
	for field: String in ["party", "inventory", "flags", "realm_hearts", "redesign_character"]:
		var stale := _pair(expected)
		stale.character[field] = [] if field in ["party", "inventory"] else {}
		assert_false(RECEIPT.saved_owner_error(stale, expected).is_empty(), field)
	var lost_receipt := _pair(expected)
	lost_receipt.character.redesign_character.transaction_receipts.pop_back()
	assert_false(RECEIPT.saved_owner_error(lost_receipt, expected).is_empty())
	var regressed_cap := _pair(expected)
	regressed_cap.character.redesign_character.creatures.stormheart.cap_level = 10
	assert_false(RECEIPT.saved_owner_error(regressed_cap, expected).is_empty())

func test_legacy_refused_or_wrong_character_pair_cannot_pass() -> void:
	var expected := _owner()
	for state: String in ["legacy", "refuse", ""]:
		var pair := _pair(expected)
		pair.state = state
		assert_false(RECEIPT.saved_owner_error(pair, expected).is_empty())
	var other := _pair(expected)
	other.character_id = "other-owner"
	assert_false(RECEIPT.saved_owner_error(other, expected).is_empty())
	assert_false(RECEIPT.saved_owner_error({}, {}).is_empty())
