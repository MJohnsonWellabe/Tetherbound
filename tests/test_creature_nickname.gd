extends "res://tests/test_case.gd"

## Nicknames, and the difference between "never renamed" and "renamed to its
## own species name".
##
## GAME_DESIGN.md 10: "New captures can keep species name by default." The
## release ceremony (M5) has to be able to tell those two apart — one is a creature
## the player never looked at twice, the other is a creature they deliberately
## christened — and copying the species name into `nickname` on capture would
## erase that difference permanently, with no way to recover it from a save.

const CREATURE := preload("res://scripts/creatures/creature_instance.gd")

const DEFINITION := {
	"display_name": "Terrapup", "type": "ground",
	"base_hp": 120.0, "base_attack": 22.0, "base_defence": 20.0,
}


func test_a_fresh_creature_has_no_nickname() -> void:
	var creature: RefCounted = CREATURE.from_species("terrapup", DEFINITION)
	assert_eq(creature.nickname, "", "a capture must not be born pre-named")


func test_an_unnamed_creature_shows_its_species_name() -> void:
	var creature: RefCounted = CREATURE.from_species("terrapup", DEFINITION)
	assert_eq(creature.label(), "Terrapup")


func test_a_nickname_replaces_the_species_name_on_screen() -> void:
	var creature: RefCounted = CREATURE.from_species("terrapup", DEFINITION)
	creature.nickname = "Biscuit"
	assert_eq(creature.label(), "Biscuit")
	assert_eq(creature.display_name, "Terrapup", "the species name must survive being nicknamed over")


func test_whitespace_is_not_a_nickname() -> void:
	# A player who opens the rename field and presses confirm on an empty one
	# should get their creature's name back, not a blank nameplate.
	var creature: RefCounted = CREATURE.from_species("terrapup", DEFINITION)
	creature.nickname = "   "
	assert_eq(creature.label(), "Terrapup")


func test_a_creature_named_after_its_species_is_still_a_named_creature() -> void:
	var creature: RefCounted = CREATURE.from_species("terrapup", DEFINITION)
	creature.nickname = "Terrapup"
	assert_eq(creature.label(), "Terrapup")
	assert_ne(creature.nickname, "", "the ceremony must be able to see this was a choice")
