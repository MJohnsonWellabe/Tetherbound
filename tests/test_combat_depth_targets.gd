extends "res://tests/test_case.gd"

const MATRIX := preload("res://tests/helpers/combat_depth_matrix.gd")
const CURVE := preload("res://scripts/creatures/chapter_curve.gd")


func _summary(cost: float, wins: int = 4) -> Dictionary:
	return {"wins": wins, "lead_cost": cost, "party_wipes": 0,
		"lead_faints": 0, "seconds": 20.0, "max_hit": 0.2}


func _judge(kind: String, masher: Dictionary, reader: Dictionary, band: int = 1) -> Dictionary:
	return MATRIX.threshold_verdict({"kind": kind, "band": band}, masher, reader,
		4, CURVE.config().difficulty)


func test_zero_damage_floor_cannot_pass_ratio_by_vacuity() -> void:
	var verdict := _judge("floor", _summary(0.0), _summary(0.0))
	assert_false(verdict.depth_failures.is_empty(), "identical harmless policies fail depth")
	assert_false(verdict.baseline_failures.is_empty(), "D77 floor cost remains a separate requirement")


func test_reader_floor_must_win_and_ratio_boundary_is_inclusive() -> void:
	var verdict := _judge("floor", _summary(0.4), _summary(0.22))
	assert_true(verdict.depth_failures.is_empty(), "exactly 55 percent qualifies")
	assert_true(verdict.baseline_failures.is_empty())
	verdict = _judge("floor", _summary(0.4), _summary(0.221))
	assert_false(verdict.depth_failures.is_empty())
	verdict = _judge("floor", _summary(0.4), _summary(0.0, 2))
	assert_false(verdict.depth_failures.is_empty(), "low cost from losing cannot qualify")


func test_top_requires_wipes_from_band_three_and_reader_wins() -> void:
	var masher := _summary(1.0, 3)
	masher.lead_faints = 4
	var reader := _summary(0.3, 3)
	assert_true(_judge("top", masher, reader, 2).depth_failures.is_empty())
	assert_false(_judge("top", masher, reader, 3).depth_failures.is_empty())
	masher.party_wipes = 1
	assert_true(_judge("top", masher, reader, 3).depth_failures.is_empty())
	reader.wins = 2
	assert_false(_judge("top", masher, reader, 3).depth_failures.is_empty())


func test_wild_cost_and_single_hit_limits_are_not_softened() -> void:
	var masher := _summary(0.25)
	var reader := _summary(0.1)
	assert_true(_judge("wild", masher, reader).depth_failures.is_empty())
	masher.lead_cost = 0.249
	assert_false(_judge("wild", masher, reader).depth_failures.is_empty())
	masher.lead_cost = 0.25
	reader.max_hit = 0.5
	assert_false(_judge("wild", masher, reader).depth_failures.is_empty(), "ceiling is strict")


func test_missing_targets_fail_closed_and_authored_values_match_spec() -> void:
	var cfg: Dictionary = CURVE.config().difficulty
	var targets: Dictionary = cfg.combat_depth
	assert_eq(targets.floor_reader_max_cost_ratio, 0.55)
	assert_eq(targets.top_masher_min_lead_faint_rate, 1.0)
	assert_eq(targets.top_masher_min_party_wipe_rate, 0.25)
	assert_eq(targets.top_party_wipe_from_band, 3.0)
	assert_eq(targets.top_reader_min_win_rate, 0.75)
	assert_eq(targets.wild_masher_min_win_rate, 1.0)
	assert_eq(targets.wild_masher_min_lead_hp_cost, 0.25)
	cfg = cfg.duplicate(true)
	cfg.erase("combat_depth")
	var verdict := MATRIX.threshold_verdict({"kind": "floor"}, _summary(0.4), _summary(0.1), 4, cfg)
	assert_false(verdict.depth_failures.is_empty())
