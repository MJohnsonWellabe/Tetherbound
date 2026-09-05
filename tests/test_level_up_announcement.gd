extends "res://tests/test_case.gd"

const HUD := preload("res://scripts/ui/combat_hud.gd")
const FEED := preload("res://scripts/creatures/progression_feed.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")

class Manager extends Node:
	var creature: RefCounted
	func active_creature() -> RefCounted:
		return creature


func _line(level_up: bool, connected: bool = true) -> String:
	var feed := FEED.new()
	var creature := SPECIES.spawn("mudsnout")
	creature.set_meta("progression_sink", feed.push_event)
	creature.gain_xp(creature.xp_to_next(PROGRESSION.config()) if level_up else 12, PROGRESSION.config())
	var manager := Manager.new()
	manager.creature = creature
	var hud := HUD.new()
	var label := Label.new()
	hud._manager = manager
	hud._xp_line = label
	hud.progression_feed = feed if connected else FEED.new()
	hud._set_xp_line()
	var text := label.text
	label.free()
	hud.free()
	manager.free()
	return text


func test_level_transition_renders_identity_and_new_level_from_shared_feed() -> void:
	var text := _line(true)
	assert_true(text.contains("Mudsnout"))
	assert_true(text.contains("reached Lv"))
	assert_true(text.contains("XP"))


func test_ordinary_award_renders_amount_and_current_exp_progress() -> void:
	var text := _line(false)
	assert_true(text.contains("+12 XP"))
	assert_true(text.contains("Mudsnout"))
	assert_true(text.contains("EXP 12/"))


func test_disconnecting_feed_removes_the_announcement() -> void:
	assert_false(_line(true).is_empty())
	assert_eq(_line(true, false), "", "negative control fails visibly when the real event path is disconnected")
