extends "res://tests/test_case.gd"

const SKILLS := preload("res://scripts/player/player_skills.gd")
const ACTIVITY := preload("res://scripts/player/skills_activity.gd")

class CandyInventory extends RefCounted:
	var count: int = 1
	func remove(_id: String, amount: int) -> bool:
		if count < amount:
			return false
		count -= amount
		return true


func test_idle_current_teleport_and_paused_motion_award_nothing() -> void:
	var skills := SKILLS.new()
	var activity := ACTIVITY.new(skills)
	assert_false(activity.record_movement("swimming", Vector3(0, 0, 1), Vector3.ZERO, 1.0, 4.0))
	assert_false(activity.record_movement("swimming", Vector3(0, 0, 100), Vector3.BACK, 1.0, 4.0))
	assert_false(activity.record_movement("swimming", Vector3(0, 0, 1), Vector3.BACK, 1.0, 4.0, true))
	assert_eq(skills.fraction("swimming"), 0.0)
	assert_true(activity.record_movement("swimming", Vector3(0, 0, 3), Vector3.BACK, 1.0, 4.0))
	assert_almost_eq(skills.fraction("swimming"), 0.09, 0.0001)


func test_catch_credit_is_owned_successful_and_deduplicated() -> void:
	var skills := SKILLS.new()
	var activity := ACTIVITY.new(skills)
	assert_false(activity.record_catch("a", true, false))
	assert_false(activity.record_catch("b", false, true))
	assert_true(activity.record_catch("a", true, true))
	assert_false(activity.record_catch("a", true, true))
	assert_almost_eq(skills.fraction("catching"), 0.8, 0.0001)


func test_candy_is_not_removed_when_tier_would_be_wasted() -> void:
	var skills := SKILLS.new()
	skills.load_data({"levels":{"running":29}})
	var inventory := CandyInventory.new()
	var activity := ACTIVITY.new(skills)
	assert_false(activity.consume_candy(inventory, "skill_candy_iii", "running"))
	assert_eq(inventory.count, 1)
	assert_true(activity.consume_candy(inventory, "skill_candy_i", "running"))
	assert_eq(inventory.count, 0)
	assert_eq(skills.level("running"), 30)
