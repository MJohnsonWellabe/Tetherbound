extends "res://tests/test_case.gd"

## OP11 / PROGRESSION-VISIBLE: a level-up must announce identity, level, and
## what changed -- and this file must PROVE it by running the builder.
##
## The first version of this test read the SOURCE TEXT of
## `combat_hud.gd::_set_xp_line()` and asserted substrings; that is prompt
## 33's false-positive shape, and it cost exactly what that costs (GATE-E: the
## unlock clause aborted on every level-up in every fight while three source
## assertions stayed green). Rewritten for prompt 73 §4: every test here
## drives `_set_xp_line()` against a stub manager with a REAL creature that
## was REALLY awarded through `creature_instance.gain_xp()`, and reads the
## rendered Label text back. With the progression feed disconnected (gain_xp
## not pushing) the level-up line is empty and this file is red.

const HUD_PATH := "res://scripts/ui/combat_hud.gd"
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const FEED := preload("res://scripts/creatures/progression_feed.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")


## The only two things `_set_xp_line()` asks a manager: who is active.
class FakeManager extends Node:
	var creature: RefCounted = null

	func active_creature() -> RefCounted:
		return creature


func before_each() -> void:
	FEED.clear()


func _mudsnout(level: int) -> RefCounted:
	var creature: RefCounted = TRAINERS.creature_for({"species": "mudsnout", "level": level})
	assert_true(creature != null, "no mudsnout in species.json; the announcement cannot be built")
	return creature


## Award `xp` to a real creature through the real path, then render the line.
func _line_after_award(creature: RefCounted, xp: int) -> String:
	FEED.clear()
	if xp > 0:
		creature.call("gain_xp", xp, PROGRESSION.config())
	var manager := FakeManager.new()
	manager.creature = creature
	var hud: Object = load(HUD_PATH).new()
	var label := Label.new()
	hud.set("_manager", manager)
	hud.set("_xp_line", label)
	hud.call("_set_xp_line")
	var text: String = label.text
	label.free()
	hud.free()
	manager.free()
	return text


func _xp_for_one_level(creature: RefCounted) -> int:
	return int(creature.call("xp_to_next", PROGRESSION.config())) - int(creature.get("xp"))


func test_an_ordinary_award_produces_the_plain_xp_line() -> void:
	var creature := _mudsnout(12)
	assert_eq(_line_after_award(creature, 12), "+12 XP")


func test_the_level_up_line_names_the_creature_and_its_new_level() -> void:
	var creature := _mudsnout(12)
	var line := _line_after_award(creature, _xp_for_one_level(creature))
	assert_eq(int(creature.get("level")), 13, "sanity: exactly one level was gained")
	assert_false(line.is_empty(),
		"running _set_xp_line() on a real level-up produced no text at all")
	assert_true(line.contains(str(creature.call("label"))),
		"the level-up line does not name the creature; the award is SPLIT across "
		+ "everyone who fought, so an unnamed line tells a five-creature team nothing: '%s'" % line)
	assert_true(line.contains("reached Lv 13"),
		"the level-up line does not report the new level: '%s'" % line)


func test_the_level_up_line_says_what_changed() -> void:
	var creature := _mudsnout(12)
	var line := _line_after_award(creature, _xp_for_one_level(creature))
	assert_true(line.contains("HP") and line.contains("ATK") and line.contains("DEF"),
		"prompt 73 §2.2: a Moment names what changed (stat deltas): '%s'" % line)


func test_a_multi_level_jump_is_one_line_naming_the_levels_gained() -> void:
	var creature := _mudsnout(12)
	var cfg := PROGRESSION.config()
	var needed := 0
	var probe := _mudsnout(12)
	for i in 3:
		needed += int(probe.call("xp_to_next", cfg))
		probe.call("set_level", 12 + i + 1, cfg)
	var line := _line_after_award(creature, needed)
	assert_eq(int(creature.get("level")), 15, "sanity: three levels")
	assert_true(line.contains("reached Lv 15"), line)
	assert_true(line.contains("+3 levels"), "a three-level jump says so once: '%s'" % line)


func test_the_line_reports_the_evolution_level_when_the_jump_crosses_it() -> void:
	var cfg := PROGRESSION.config()
	var gate := int(cfg.get("evolution", {}).get("mudsnout", {}).get("level", 0))
	assert_true(gate > 0, "progression.json has no mudsnout evolution level")
	var creature := _mudsnout(gate - 1)
	var line := _line_after_award(creature, _xp_for_one_level(creature))
	assert_eq(int(creature.get("level")), gate)
	assert_true(line.contains("evolution level reached") or line.contains("evolution ready"),
		"crossing Mudsnout's evolution level must be said on the line: '%s'" % line)


func test_another_creatures_award_does_not_write_the_active_creatures_line() -> void:
	var active := _mudsnout(12)
	var bench := _mudsnout(12)
	FEED.clear()
	bench.call("gain_xp", 12, PROGRESSION.config())
	var manager := FakeManager.new()
	manager.creature = active
	var hud: Object = load(HUD_PATH).new()
	var label := Label.new()
	hud.set("_manager", manager)
	hud.set("_xp_line", label)
	hud.call("_set_xp_line")
	assert_eq(label.text, "", "the bench member's award is the party strip's to show, not this line's")
	label.free()
	hud.free()
	manager.free()


func test_the_previous_fights_award_is_not_re_announced() -> void:
	var creature := _mudsnout(12)
	FEED.clear()
	creature.call("gain_xp", 12, PROGRESSION.config())
	var manager := FakeManager.new()
	manager.creature = creature
	var hud: Object = load(HUD_PATH).new()
	var label := Label.new()
	hud.set("_manager", manager)
	hud.set("_xp_line", label)
	# A new fight begins: the cursor moves past the old award.
	hud.call("_mark_feed_at_fight_start")
	hud.call("_set_xp_line")
	assert_eq(label.text, "", "an award from before this fight began must not be shown again")
	label.free()
	hud.free()
	manager.free()


func test_the_unlock_threshold_is_data_driven_and_gates() -> void:
	# The announcement's "second trait revealed" rests on
	# `traits.unlock_bond_nodes` in data; if that moved into code the line could
	# claim an unlock the player has not earned.
	var cfg := PROGRESSION.config()
	var trait_cfg: Dictionary = cfg.get("traits", {})
	assert_true(trait_cfg.has("unlock_bond_nodes"))
	var required := int(trait_cfg.get("unlock_bond_nodes", 5))
	assert_false(PROGRESSION.trait_unlocked(required - 1, cfg))
	assert_true(PROGRESSION.trait_unlocked(required, cfg))
