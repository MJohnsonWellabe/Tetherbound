extends "res://tests/test_case.gd"

const SKILLS := preload("res://scripts/player/player_skills.gd")


func test_meadows_xp_accumulates_before_cloudreach_reveal() -> void:
	var skills := SKILLS.new()
	skills.enter_realm("meadows")
	assert_false(skills.revealed)
	assert_true(skills.add_xp("swimming", 150.0))
	assert_eq(skills.level("swimming"), 1)
	skills.enter_realm("cloudreach")
	assert_true(skills.revealed)
	assert_almost_eq(skills.fraction("swimming"), 50.0 / 130.0, 0.0001)


func test_candy_preserves_fraction_and_rejects_full_tier_over_cap() -> void:
	var skills := SKILLS.new()
	skills.add_xp("running", 50.0)
	assert_true(skills.use_candy("running", "skill_candy_iii"))
	assert_eq(skills.level("running"), 3)
	assert_almost_eq(skills.fraction("running"), 0.5, 0.0001)
	skills.load_data({"levels":{"running":29},"xp":{"running":50.0}})
	var before: Dictionary = skills.save_data()
	assert_false(skills.use_candy("running", "skill_candy_ii"))
	assert_eq(skills.save_data(), before)
	assert_true(skills.use_candy("running", "skill_candy_i"))
	assert_eq(skills.level("running"), 30)


func test_save_roundtrip_keeps_personal_progress_independent() -> void:
	var first := SKILLS.new()
	first.add_xp("flying", 777.0)
	first.enter_realm("stormwood")
	var second := SKILLS.new()
	second.load_data(first.save_data())
	assert_eq(second.save_data(), first.save_data())
	second.use_candy("flying", "skill_candy_i")
	assert_eq(second.level("flying"), first.level("flying") + 1)


func test_invalid_and_missing_save_data_cannot_grant_skills() -> void:
	var skills := SKILLS.new()
	skills.load_data({"levels":{"running":NAN,"flying":"30"},"xp":{"catching":INF}})
	assert_eq(skills.level("running"), 0)
	assert_eq(skills.level("flying"), 0)
	assert_eq(skills.fraction("catching"), 0.0)
	assert_false(skills.add_xp("gathering", 1000.0))
	assert_false(skills.add_xp("running", INF))
	assert_false(skills.add_xp("running", -50.0))
	skills.load_data({})
	assert_false(skills.revealed)


func test_efficiency_and_catching_bonuses_remain_bounded() -> void:
	var skills := SKILLS.new()
	for id: String in SKILLS.IDS:
		skills.add_xp(id, 1000000.0)
		assert_eq(skills.level(id), 30)
	assert_almost_eq(skills.efficiency("swimming"), 0.65, 0.0001)
	assert_almost_eq(skills.catch_bonus(), 0.05, 0.0001)
	assert_almost_eq(skills.handling_bonus(), 0.15, 0.0001)
