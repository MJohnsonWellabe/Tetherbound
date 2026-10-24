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

## Mira stands on the Ironwood ridge past the Old Mill Crossing. From home the
## route crosses the South Bridge, then follows the north spine through the
## mill crossing; from beside her it is one short leg to a stand 4 m away.
func test_mira_route_follows_the_north_spine_through_the_mill_crossing() -> void:
	var terrain: Variant = JSON.parse_string(FileAccess.get_file_as_string(ADAPTER.TERRAIN))
	var mira := Vector2(-405.0, 5050.0)
	var legs: Array[Vector2] = ADAPTER.mira_legs(Vector2(-22.7, 22.7), mira, terrain)
	assert_eq(legs[0], ADAPTER.FAR_BANK, "home first crosses the South Bridge")
	assert_true(legs.has(Vector2(-152.0, 4170.0)) and legs.has(Vector2(-152.0, 4235.0)), "crosses on the Old Mill Crossing")
	assert_true(absf(legs[-1].distance_to(mira) - 4.0) < 0.01, "ends on a stand 4 m short of Mira")
	for index in range(1, legs.size()):
		assert_true(legs[index].y >= legs[index - 1].y - 260.0, "never doubles back south along the spine")
	var near: Array[Vector2] = ADAPTER.mira_legs(Vector2(-330.0, 5030.0), mira, terrain)
	assert_eq(near.size(), 1, "the boundary beside her walks one leg")
	assert_true(absf(near[0].distance_to(mira) - 4.0) < 0.01)
