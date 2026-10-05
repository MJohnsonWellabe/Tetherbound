extends "res://tests/test_case.gd"

## A host-side simulation shell (realm_shells.gd) strips the SequenceDirector
## in its world root's _ready. The director must not start its story there: a
## suspended _ready continuation and a ledger listener on the freed node
## leaked ObjectDB instances at host exit (smoke_net_f18_travel host B,
## smoke_net_split_realms host). The sandbox starter stays suspended.
const DIRECTOR := preload("res://scripts/story/sequence_director.gd")

class ShellRoot extends Node3D:
	var simulation_only := true

class EncounterDouble extends Node:
	var default_starter := "terrapup"
	func suspend_default_starter() -> void: default_starter = ""

func test_director_in_a_simulation_shell_suspends_the_starter_and_starts_nothing() -> void:
	var world := ShellRoot.new()
	var encounter := EncounterDouble.new()
	encounter.name = "EncounterDirector"
	world.add_child(encounter)
	var director: Node = DIRECTOR.new()
	director.set("encounter_path", NodePath("../EncounterDirector"))
	world.add_child(director)
	var beat_before: Variant = director.get("_beat")
	director.call("_ready") # Returns before any await, group or listener.
	assert_true(director.call("_in_simulation_shell"))
	assert_eq(encounter.default_starter, "", "a shell never adopts a sandbox starter")
	assert_false(director.is_in_group("story_modal"), "no story modal registered in a shell")
	assert_false(director.is_in_group("progression_restore"))
	assert_eq(director.get("_beat"), beat_before, "beat state untouched")
	assert_eq(director.get("_encounter"), null, "no wiring taken in a shell")
	world.free()

func test_director_outside_a_shell_takes_the_full_path() -> void:
	var world := Node3D.new()
	var director: Node = DIRECTOR.new()
	world.add_child(director)
	assert_false(director.call("_in_simulation_shell"))
	world.free()
