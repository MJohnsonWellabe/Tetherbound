extends SceneTree

## Exercise the earned driver's real controller edge against the production
## exploration input reader and Party. No world, save or campaign prerequisite.
const PARTY := preload("res://autoload/party.gd")
const TEAM := preload("res://tests/helpers/meadows_earned_team_segment.gd")
var checks := 0
var failures: Array[String] = []

class Member extends RefCounted:
	var fainted := false
	var resting := false
	func label() -> String: return "native cycle fixture"

class Director extends "res://scripts/combat/encounter_director.gd":
	var fixture: RefCounted
	var observations: Array[int] = []
	func _ready() -> void:
		set_process(false)
	func _party() -> RefCounted: return fixture
	func _physics_process(_delta: float) -> void:
		var before := int(fixture.active_index())
		_read_creature_control_input()
		if before != int(fixture.active_index()):
			observations.append(int(fixture.active_index()))

func _initialize() -> void: _run.call_deferred()

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
	print("PASS: " if value else "FAIL: ", message)

func _run() -> void:
	var party := PARTY.new()
	for index in 5:
		party.add(Member.new())
	var director := Director.new()
	director.fixture = party
	root.add_child(director)
	var helper := TEAM.new()
	helper._tree = self
	for index in 5:
		_check(await helper._tap_party_cycle(), "bound controller cycle dispatched")
		_check(party.active_index() == (index + 1) % 5, "cycle selects exactly the next member")
		_check(director.observations.size() == index + 1, "one physical press produces exactly one transition")
	_check(not Input.is_action_pressed("party_cycle"), "cycle button is released")
	director.queue_free()
	await process_frame
	print("earned party cycle checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
