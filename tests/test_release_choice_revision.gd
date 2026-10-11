extends "res://tests/test_case.gd"

## The five-slot release ceremony (scripts/ui/tab_creatures.gd) re-quotes the
## typed release when the player presses "Let them go". A hosted session's
## character revision moves on its own between the farewell question and that
## press, so the re-quote must still be the same choice; anything the player
## actually read (who leaves, who joins, the payout) changing sends them back.
## Two-peer regression: tools/net/proof_scenarios/stormwood_f11_capacity_*.json.
const TAB := preload("res://scripts/ui/tab_creatures.gd")


func _quote(revision: int, released: String = "creature-a", payout: Array = [{"id": "essence_ground", "n": 3}]) -> Dictionary:
	return {"ok": true, "pending_uid": "creature-new", "released_uid": released,
		"ceremony_id": "release_ceremony:creature-new", "expected_character_revision": revision, "payout": payout}


func test_a_moved_revision_is_still_the_confirmed_choice() -> void:
	assert_true(TAB._same_release_choice(_quote(42), _quote(41)), "only the host revision moved")
	assert_true(TAB._same_release_choice(_quote(9, ""), _quote(3, "")), "letting the newcomer go survives a moved revision")


func test_a_changed_choice_or_payout_is_not() -> void:
	assert_false(TAB._same_release_choice(_quote(41, "creature-b"), _quote(41)), "a different creature would leave")
	assert_false(TAB._same_release_choice(_quote(41, "creature-a", [{"id": "essence_ground", "n": 2}]), _quote(41)),
		"the payout the player read changed")
	var unpaid := _quote(41)
	unpaid.unpaid_reason = "the host has not saved this creature with your team"
	assert_false(TAB._same_release_choice(unpaid, _quote(41)), "an unpaid release is not the paid one confirmed")
	assert_false(TAB._same_release_choice(_quote(41), {}), "nothing confirmed is never a match")
