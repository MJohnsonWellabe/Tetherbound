extends "res://tests/test_case.gd"

const LEDGER := preload("res://tests/helpers/meadows_earned_route_ledger_segment.gd")


func _beat(kind: String, path_m: float) -> Dictionary:
	return {"kind": kind, "detail": "", "t": 0.0, "path_m": path_m, "pos": [0, 0, 0], "stage": "s"}


func test_spacing_gaps_are_walked_metres_between_consecutive_beats() -> void:
	var gaps: Array = LEDGER.spacing_gaps([_beat("offer", 0.0), _beat("flag_set", 180.0), _beat("fight_started", 460.5)])
	assert_eq(gaps.size(), 2)
	assert_almost_eq(float(gaps[0]["metres"]), 180.0)
	assert_almost_eq(float(gaps[1]["metres"]), 280.5)
	assert_eq(str(gaps[1]["from"]), "flag_set")
	assert_eq(str(gaps[1]["to"]), "fight_started")


func test_one_or_no_beats_have_no_gap() -> void:
	assert_eq(LEDGER.spacing_gaps([]).size(), 0)
	assert_eq(LEDGER.spacing_gaps([_beat("offer", 12.0)]).size(), 0)


func test_contract_matches_world_3_1_and_a7() -> void:
	# WORLD §3.1: "no 250 m route window should lack a beat within 40 m";
	# ACCEPTANCE A7: "no >120s active travel" without one.
	assert_almost_eq(LEDGER.WINDOW_M, 250.0)
	assert_almost_eq(LEDGER.BEAT_RADIUS_M, 40.0)
	assert_almost_eq(LEDGER.A7_LIMIT_S, 120.0)
