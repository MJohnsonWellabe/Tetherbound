extends "res://tests/test_case.gd"

## F01#6a. `essence.merge_owner_passive` carries the owner's passive-care drift
## into a decided row's after-state, and `character_action_owner.apply_owner`
## then compares the installed record with that target EXACTLY. For a field the
## row did not decide (after == before), `after + now - before` is `now` in exact
## arithmetic but not in floats -- 0.7 + 0.4 - 0.7 is 0.39999999999999997 -- so a
## duplicate install after any drift reported owner_action_install_conflict and
## the guest's opening never finished. The merge must return the owner's own
## value for such a field, and still add the drift to a field the row decided.

const ESSENCE := preload("res://scripts/creatures/essence.gd")


func _record(nourishment: float, happiness: float) -> Dictionary:
	return {"party": [{"uid": "creature-a", "nourishment": nourishment, "happiness": happiness}]}


func test_an_undecided_field_takes_the_owners_value_exactly() -> void:
	var before := _record(0.7, 50.0)
	var current := _record(0.4, 50.0)
	assert_ne(0.7 + 0.4 - 0.7, 0.4, "the float identity this test guards really does fail")
	var merged := ESSENCE.merge_owner_passive(before.duplicate(true), before, current)
	assert_true(merged.party[0].nourishment == 0.4,
		"the owner's drifted value comes back bit for bit (%s)" % str(merged.party[0].nourishment))
	assert_true(ESSENCE._equivalent(merged, current), "a duplicate after drift merges to exactly the owner's record")


func test_a_field_the_row_decided_still_carries_the_owners_drift() -> void:
	var before := _record(0.7, 50.0)
	var after := _record(0.7, 60.0)
	var current := _record(0.7, 55.0)
	var merged := ESSENCE.merge_owner_passive(after, before, current)
	assert_almost_eq(float(merged.party[0].happiness), 65.0, 0.0001,
		"a victory's mood plus the owner's own later drift both stand")


## The coordinator's follow-up: a field the row DID decide, while another field
## drifts in the same round trip. The decided field keeps exact `after + drift`
## arithmetic (it is not the owner's value), the drifting undecided one is the
## owner's own value, and the whole merge is deterministic: the installer writes
## these target values onto the live instance, so installed == target holds.
func test_a_decided_field_and_an_undecided_drift_in_one_round_trip() -> void:
	var before := _record(0.7, 50.0)
	var after := _record(0.7, 60.25)
	var current := _record(0.4, 53.1)
	var merged := ESSENCE.merge_owner_passive(after, before, current)
	assert_true(merged.party[0].nourishment == 0.4, "the undecided drifting field is the owner's value exactly")
	assert_true(merged.party[0].happiness == 60.25 + 53.1 - 50.0,
		"the decided field is exactly after + the owner's drift (%s)" % str(merged.party[0].happiness))
	var again := ESSENCE.merge_owner_passive(after, before, current)
	assert_true(ESSENCE._equivalent(again, merged), "the same inputs always merge to the same exact target")


func test_portable_card_is_the_one_energy_rule() -> void:
	var record_rules := preload("res://scripts/net/character_record_rules.gd")
	var card := {"uid": "creature-a", "energy": 37.5, "hp": 10.0}
	assert_eq(record_rules.portable_card(card), {"uid": "creature-a", "hp": 10.0})
	assert_true(card.has("energy"), "the caller's card is never mutated")
	var projected := ESSENCE.training_projection({"party": [card], "inventory": [], "redesign_character": {}})
	assert_false((projected.party[0] as Dictionary).has("energy"), "training_projection uses the same rule")
	var portable := record_rules.portable_projection({"character_id": "c", "party": [card]})
	assert_false((portable.party[0] as Dictionary).has("energy"), "portable_projection uses the same rule")
