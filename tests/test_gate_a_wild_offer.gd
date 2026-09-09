extends "res://tests/test_case.gd"

const OPENING := preload("res://tests/helpers/gate_a_opening_drive.gd")

class Director extends Node:
	var candidate: Node3D
	func _engageable() -> Node3D:
		return candidate

class Arbiter extends Node:
	var provider: Node
	var actionable := true
	var available := true
	func enabled() -> bool:
		return available
	func winning_provider() -> Node:
		return provider
	func winner() -> Dictionary:
		return {"actionable": actionable}

func test_shared_provider_does_not_make_a_neighbour_the_requested_target() -> void:
	var expected := Node3D.new()
	var neighbour := Node3D.new()
	var director := Director.new()
	var arbiter := Arbiter.new()
	var drive := OPENING.new()
	drive._encounter = director
	drive._arbiter = arbiter
	arbiter.provider = director
	director.candidate = neighbour
	assert_false(drive._wild_offer_ready(expected),
		"a shared EncounterDirector offer cannot authorize engaging a different creature")
	director.candidate = expected
	assert_true(drive._wild_offer_ready(expected))
	# This is the second observation after movement settles: the same provider
	# can now offer another body, including one of the same species.
	director.candidate = neighbour
	assert_false(drive._wild_offer_ready(expected))
	assert_eq(director.candidate, neighbour, "readiness must not retarget the real provider")
	director.candidate = expected
	arbiter.actionable = false
	assert_false(drive._wild_offer_ready(expected))
	arbiter.actionable = true
	arbiter.available = false
	assert_false(drive._wild_offer_ready(expected), "disabled interaction cannot use a stale offer")
	arbiter.available = true
	arbiter.provider = neighbour
	assert_false(drive._wild_offer_ready(expected))
	director.candidate = null
	arbiter.provider = director
	assert_false(drive._wild_offer_ready(expected))
	arbiter.free()
	director.free()
	neighbour.free()
	expected.free()
