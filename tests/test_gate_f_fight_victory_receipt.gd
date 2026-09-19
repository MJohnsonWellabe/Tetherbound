extends TestCase

const RECEIPT := preload("res://tools/gate_f/fight_victory_receipt.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")

class ManagerFixture extends Node:
	signal exited(outcome: String)
	var _party: Array = []


func _manager() -> ManagerFixture:
	var manager := ManagerFixture.new()
	manager._party.append(CREATURE.from_species("bramblebun", {"display_name": "Bramblebun",
		"type": "ground", "base_hp": 95.0, "base_attack": 18.0, "base_defence": 16.0}))
	return manager


func test_real_signal_and_live_gain_xp_verify_win_including_level_rollover() -> void:
	var manager := _manager()
	var receipt := RECEIPT.new()
	assert_true(receipt.begin(manager))
	manager._party[0].gain_xp(500, PROGRESSION.config())
	manager.exited.emit("won")
	var result := receipt.finish(false)
	assert_true(result.ok)
	assert_eq(result.outcomes, ["won"])
	assert_eq(result.xp_progress.size(), 1)
	assert_eq(manager.get_signal_connection_list("exited").size(), 0)
	manager.free()


func test_loss_catch_flee_and_missing_exit_fail_even_if_xp_changed() -> void:
	for outcome in ["lost", "caught", "fled", ""]:
		var manager := _manager()
		var receipt := RECEIPT.new()
		receipt.begin(manager)
		manager._party[0].gain_xp(62, PROGRESSION.config())
		if not outcome.is_empty(): manager.exited.emit(outcome)
		assert_false(receipt.finish(false).ok, outcome)
		assert_eq(manager.get_signal_connection_list("exited").size(), 0)
		manager.free()


func test_live_fight_at_budget_end_and_win_without_xp_fail() -> void:
	var manager := _manager()
	var receipt := RECEIPT.new()
	receipt.begin(manager)
	manager.exited.emit("won")
	assert_false(receipt.finish(false).ok)
	receipt = RECEIPT.new()
	receipt.begin(manager)
	manager._party[0].gain_xp(62, PROGRESSION.config())
	manager.exited.emit("won")
	assert_false(receipt.finish(true).ok)
	manager.free()


func test_all_capped_roster_does_not_require_impossible_level_increase() -> void:
	var manager := _manager()
	manager._party[0].level = int(PROGRESSION.config().get("level", {}).get("cap", 100))
	var receipt := RECEIPT.new()
	receipt.begin(manager)
	manager.exited.emit("won")
	assert_true(receipt.finish(false).ok)
	manager.free()


func test_roster_replacement_and_mixed_win_loss_do_not_pass() -> void:
	var manager := _manager()
	var receipt := RECEIPT.new()
	receipt.begin(manager)
	manager._party[0].gain_xp(62, PROGRESSION.config())
	manager.exited.emit("won")
	manager.exited.emit("lost")
	assert_false(receipt.finish(false).ok)
	receipt = RECEIPT.new()
	receipt.begin(manager)
	manager._party.clear()
	manager.exited.emit("won")
	assert_false(receipt.finish(false).ok)
	manager.free()
