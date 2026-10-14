extends "res://tests/test_case.gd"
const ADAPTER := preload("res://tools/earned_saves/wip_fights/meadows_master.gd")

func _party() -> Array:
	var party: Array = []
	for index in 5:
		party.append({"uid": "owned-%d" % index, "level": 10, "fainted": false, "resting": false})
	return party

func test_challenger_uses_exact_cap_and_owned_identity() -> void:
	var party := _party()
	party[0].fainted = true
	party[1].resting = true
	party[2].level = 20
	assert_eq(str(ADAPTER.select_challenger(party, 10, "").uid), "owned-3")
	assert_eq(str(ADAPTER.select_challenger(party, 20, "owned-2").uid), "owned-2")
	assert_true(ADAPTER.select_challenger(party, 10, "owned-2").is_empty())
	assert_true(ADAPTER.select_challenger(party, 10, "not-owned").is_empty())

func test_retained_five_is_checked_before_any_challenger_is_returned() -> void:
	var party := _party()
	party[4].uid = party[0].uid
	assert_true(ADAPTER.select_challenger(party, 10, "owned-0").is_empty())
	party = _party()
	party.pop_back()
	assert_true(ADAPTER.select_challenger(party, 10, "").is_empty())
