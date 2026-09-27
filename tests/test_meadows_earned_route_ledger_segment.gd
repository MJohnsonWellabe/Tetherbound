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


func _row(stage: String, coin: int, potions: int, revives: int) -> Dictionary:
	return {"stage": stage, "items": {"coin": coin, "potion_small": potions, "revive": revives}}


func test_solvency_reserve_and_two_loss_per_stage() -> void:
	var rows := [_row("title", 0, 0, 0), _row("rested_team", 30, 1, 10), _row("south_bridge_crossed", 20, 0, 1)]
	var out: Dictionary = LEDGER.solvency(rows, [], 28, 80)
	assert_eq((out["stages"] as Array).size(), 2, "only gauntlet stages are scored")
	assert_true(bool(out["stages"][0]["reserve_ok"]), "1 potion + 30 coin buys a second heal")
	assert_false(bool(out["stages"][1]["reserve_ok"]), "0 potions and 20 coin is one heal short")
	assert_eq(int(out["stages"][1]["two_loss_restock"]), 28 * 4 + 80 * 1)
	assert_eq(str(out["two_loss_worst"]["stage"]), "south_bridge_crossed")
	assert_false(bool(out["two_loss_ok"]))


func test_solvency_counts_repeated_wild_fights_only() -> void:
	var beats := [{"kind": "fight_started", "detail": "Wild_bramblebun_0_2"},
		{"kind": "fight_started", "detail": "Wild_mudsnout_1_1"},
		{"kind": "fight_started", "detail": "Wild_bramblebun_0_2"},
		{"kind": "fight_started", "detail": "Trainer_captain"}]
	var out: Dictionary = LEDGER.solvency([], beats, 28, 80)
	assert_eq(int(out["wilds_fought"]), 2)
	assert_eq(out["repeated_wilds"], ["Wild_bramblebun_0_2"])
	assert_false(bool(out["reserve_ok"]), "no scored stage is not a pass")


func test_strict_beats_drop_repeated_verbs_controls_and_seen_species() -> void:
	var list := [{"kind": "offer", "detail": "Chop"}, {"kind": "offer", "detail": "Put Bud away"},
		{"kind": "offer", "detail": "Greet Mira"}, {"kind": "wild_within_radius", "detail": "Wild_a_1 bramblebun"},
		{"kind": "wild_within_radius", "detail": "Wild_a_2 bramblebun"}, {"kind": "fight_started", "detail": "Wild_a_1"},
		{"kind": "flag_set", "detail": "road_gate_open"}, {"kind": "offer", "detail": "Engage Bramblebun"}]
	var strict: Array = LEDGER.strict_beats(list)
	var kept: Array = []
	for beat: Dictionary in strict:
		kept.append(str(beat["detail"]))
	assert_eq(kept, ["Greet Mira", "Wild_a_1 bramblebun", "Wild_a_1", "road_gate_open"])


func test_strict_a7_reads_active_travel_between_beats() -> void:
	var strict := [{"detail": "a", "active_s": 10.0}, {"detail": "b", "active_s": 50.0}, {"detail": "c", "active_s": 200.0}]
	var out: Dictionary = LEDGER.strict_a7(strict, 120.0)
	assert_almost_eq(float(out["longest"]["seconds"]), 150.0)
	assert_eq((out["violations"] as Array).size(), 1)


func test_strict_beats_keep_map_reveals() -> void:
	# A7 counts "new vista/landmark reveal"; a map reveal is never a repeated verb.
	var strict: Array = LEDGER.strict_beats([{"kind": "reveal", "detail": "region:the_old_quarry"},
		{"kind": "offer", "detail": "Chop"}])
	assert_eq(strict.size(), 1)
	assert_eq(str(strict[0]["detail"]), "region:the_old_quarry")
