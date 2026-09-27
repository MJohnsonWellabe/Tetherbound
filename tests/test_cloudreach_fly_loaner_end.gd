extends "res://tests/test_case.gd"

## Maela's Galecrest loaner ends at chapter completion (#356 Question A,
## coordinator ruling: spec conformance with CREATURES/SYSTEMS "temporary",
## "not permanent free traversal inventory"). Config:
## `fly_traversal.json` `mentor_loaner.ends_at_flag`.

const FLY := preload("res://scripts/player/fly_controller.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PARTY := preload("res://autoload/party.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")

class FlyGame extends Node:
	var party: RefCounted = PARTY.new()
	var progression: RefCounted = PROGRESSION.new()
	var current_realm := "cloudreach"
	var realm_hearts: RefCounted = null

var fly: Node
var game: Node


func before_each() -> void:
	fly = FLY.new()
	game = FlyGame.new()
	fly._game = game
	fly.config = JSON.parse_string(FileAccess.get_file_as_string(FLY.CONFIG_PATH))


func after_each() -> void:
	fly.free()
	game.free()


func test_the_end_flag_is_config() -> void:
	assert_eq(str(fly.config.get("mentor_loaner", {}).get("ends_at_flag", "")), "cloudreach_chapter_complete")


func test_rule_table() -> void:
	var loaner := {"available_during_trial": true, "available_after_unlock": true}
	assert_true(FLY.mentor_loaner_available(loaner, true, false, false), "trial")
	assert_true(FLY.mentor_loaner_available(loaner, false, true, false), "after unlock, during the chapter")
	assert_false(FLY.mentor_loaner_available(loaner, false, false, false), "neither")
	assert_false(FLY.mentor_loaner_available(loaner, false, true, true), "chapter complete ends it")
	assert_false(FLY.mentor_loaner_available(loaner, true, true, true), "ended even with a trial box set")


func test_a_non_fly_team_loses_the_loaner_at_chapter_completion() -> void:
	for species: String in ["bramblebun", "mudsnout", "terrapup", "brooktail", "sparkit"]:
		game.party.add(SPECIES.spawn(species))
	game.progression.set_flag("fly_traversal_unlocked")
	var carrier: RefCounted = fly.eligible_creature()
	assert_ne(carrier, null, "the loaner serves the chapter's routes after the unlock")
	game.progression.set_flag("cloudreach_chapter_complete")
	assert_eq(fly.eligible_creature(), null, "no loaner once the chapter is complete")
	assert_eq(game.party.size(), 5, "and nothing was ever added to the party")


func test_an_owned_carrier_still_flies_after_the_chapter() -> void:
	for species: String in ["bramblebun", "mudsnout", "terrapup", "brooktail", "galecrest"]:
		game.party.add(SPECIES.spawn(species))
	game.party.set_active(4)
	game.progression.set_flag("fly_traversal_unlocked")
	game.progression.set_flag("cloudreach_chapter_complete")
	var carrier: RefCounted = fly.eligible_creature()
	assert_ne(carrier, null, "the ending applies to the loaner only")
	if carrier != null:
		assert_true((game.party.members() as Array).has(carrier), "the owned Galecrest carries")
