extends "res://tests/test_case.gd"

const OPENING := preload("res://tests/helpers/fresh_opening_segment.gd")

class Body extends Node3D:
	var species_id := "bramblebun"

class Combat extends Node:
	var admitted: Node3D
	func enemy_body() -> Node3D:
		return admitted

class Probe extends OPENING:
	func _fail(message: String) -> void:
		_failures.append(message)


func test_offered_creature_cannot_be_replaced_by_another_body_of_the_same_species() -> void:
	var expected := Body.new()
	var neighbour := Body.new()
	var combat := Combat.new()
	var opening := Probe.new()
	opening._combat = combat
	combat.admitted = neighbour
	assert_false(opening._engaged_expected_body(expected))
	assert_eq(opening._failures.size(), 1)
	assert_eq(combat.admitted, neighbour, "rejection cannot change the admitted fight")
	combat.free()
	neighbour.free()
	expected.free()


func test_exact_admitted_body_is_accepted_and_absent_body_is_rejected() -> void:
	var expected := Body.new()
	var combat := Combat.new()
	var opening := Probe.new()
	opening._combat = combat
	combat.admitted = expected
	assert_true(opening._engaged_expected_body(expected))
	assert_true(opening._failures.is_empty())
	combat.admitted = null
	assert_false(opening._engaged_expected_body(expected))
	combat.free()
	expected.free()
