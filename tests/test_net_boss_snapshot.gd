extends "res://tests/test_case.gd"

const PEER := preload("res://tools/net/peer_runner.gd")


class Creature extends RefCounted:
	var hp := 124.403


class Director extends RefCounted:
	var creature := Creature.new()
	var record := {"struck_counts": {1: 1}, "opponent": {"hp": 194.787}}

	func encounter_record() -> Dictionary:
		return record

	func ally_instance() -> RefCounted:
		return creature

	func boss_hit() -> void:
		creature.hp = 109.718
		record["struck_counts"][1] += 1


func test_hit_in_old_opening_gap_is_in_atomic_window() -> void:
	var director := Director.new()
	var pre := PEER.boss_combat_snapshot(director)
	# Previously HP was read before this hit, but the opening count after it.
	director.boss_hit()
	var legacy_opening_count := int(director.record["struck_counts"][1])
	var post := PEER.boss_combat_snapshot(director)
	assert_eq(legacy_opening_count, int(post["record"]["struck_counts"][1]),
		"negative control: the old inner counter window misses the hit")
	assert_true(float(pre["my_creature_hp"]) > float(post["my_creature_hp"]))
	assert_eq(int(post["record"]["struck_counts"][1]) - int(pre["record"]["struck_counts"][1]), 1,
		"atomic samples correctly reject the boss-contaminated window")


func test_hit_after_closing_sample_does_not_change_frozen_window() -> void:
	var director := Director.new()
	var pre := PEER.boss_combat_snapshot(director)
	var post := PEER.boss_combat_snapshot(director)
	# Previously the closing count was read before this hit and HP after it.
	director.boss_hit()
	assert_true(float(post["my_creature_hp"]) > director.creature.hp,
		"negative control: a later HP probe would widen the window")
	assert_eq(pre["my_creature_hp"], post["my_creature_hp"], "quiet-window HP remains exact")
	assert_eq(pre["record"]["struck_counts"], post["record"]["struck_counts"])
	assert_eq(int(post["record"]["struck_counts"][1]), 1, "later combat cannot mutate the sample")


func test_unexplained_hp_loss_still_fails_unchanged_hp_criterion() -> void:
	var director := Director.new()
	var pre := PEER.boss_combat_snapshot(director)
	director.creature.hp -= 5.0
	var post := PEER.boss_combat_snapshot(director)
	assert_eq(pre["record"]["struck_counts"], post["record"]["struck_counts"])
	assert_true(absf(float(post["my_creature_hp"]) - float(pre["my_creature_hp"])) >= 0.001,
		"a friendly-fire defect with no boss hit remains a failure")
