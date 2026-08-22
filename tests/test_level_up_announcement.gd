extends "res://tests/test_case.gd"

## OP11: a level-up must announce identity, level, and unlock.
##
## The owner's 2026-08-21 playtest asked for all three. The line
## `combat_hud.gd::_set_xp_line()` built announced NONE of them:
##
##     "+12 XP   ·   Lv up!"
##
## Whose level went up is the question a five-creature team makes urgent --
## `combat_manager.gd::_award_xp()` splits the award across everyone who fought
## and writes `last_xp_award` keyed by `label()`, so "Lv up!" floating over a
## shared party strip names nobody. And the new NUMBER is the thing a player is
## actually tracking. Both were already in hand: `creature.label()` and
## `creature.level` sit one line above the string and were not being read.
##
## The 2026-08-22 reconciliation marked OP11 **NOT VERIFIED THIS PASS** -- "no
## harness drove a level-up to read its on-screen text. Do not treat as closed."
## This file is the half of that which can be answered without booting a fight:
## the STRING BUILDER's contract. `tests/smoke_level_up_banner.gd` would be the
## other half, and the note above is why it is worth having.

const HUD_PATH := "res://scripts/ui/combat_hud.gd"
const PROGRESSION := preload("res://scripts/creatures/progression.gd")


func _xp_line_source() -> String:
	var file := FileAccess.open(HUD_PATH, FileAccess.READ)
	assert_true(file != null, "combat_hud.gd is missing")
	if file == null:
		return ""
	var source := file.get_as_text()
	var start := source.find("func _set_xp_line(")
	assert_true(start >= 0, "combat_hud.gd has no _set_xp_line")
	if start < 0:
		return ""
	var end := source.find("\nfunc ", start + 1)
	return source.substr(start, (end - start) if end > start else -1)


func test_the_level_up_line_names_which_creature_levelled() -> void:
	var body := _xp_line_source()
	assert_true(body.contains("creature.label()"),
		"the level-up line does not name the creature; the XP award is SPLIT across "
		+ "everyone who fought, so an unnamed 'Lv up!' tells a five-creature team nothing")


func test_the_level_up_line_names_the_new_level() -> void:
	var body := _xp_line_source()
	assert_true(body.contains("creature.level"),
		"the level-up line does not report the new level number, which is the value "
		+ "a player is actually tracking")


func test_the_level_up_line_reports_an_unlock_when_there_is_one() -> void:
	var body := _xp_line_source()
	assert_true(body.contains("trait_unlocked"),
		"the level-up line never mentions an unlock; OP11 asks for identity, level "
		+ "AND unlock, and trait_unlocked() is the only thing progression opens")


func test_a_plain_xp_gain_does_not_claim_a_level_up() -> void:
	# The other half of the contract, and the easier one to regress: most fights
	# award XP without a level, and those must not print a level line.
	var body := _xp_line_source()
	assert_true(body.contains("levels <= 0") or body.contains("levels > 0"),
		"the line does not branch on whether a level was actually gained")


func test_the_unlock_threshold_is_data_driven() -> void:
	# Guards the claim the announcement makes. If the threshold moved into code,
	# the line could report an unlock the player has not actually earned.
	var cfg := PROGRESSION.config()
	var trait_cfg: Dictionary = cfg.get("trait", {})
	assert_true(trait_cfg.has("unlock_bond_nodes"),
		"progression config has no trait.unlock_bond_nodes; the announcement's "
		+ "unlock claim rests on a threshold that is not in data")


func test_the_threshold_actually_gates_the_unlock() -> void:
	var cfg := PROGRESSION.config()
	var required := int(cfg.get("trait", {}).get("unlock_bond_nodes", 5))
	assert_false(PROGRESSION.trait_unlocked(required - 1, cfg),
		"trait_unlocked() reports true one node BELOW the configured threshold")
	assert_true(PROGRESSION.trait_unlocked(required, cfg),
		"trait_unlocked() reports false AT the configured threshold")
