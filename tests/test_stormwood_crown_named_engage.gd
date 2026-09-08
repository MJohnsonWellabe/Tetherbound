extends "res://tests/test_case.gd"

const SEGMENT := preload("res://tests/helpers/stormwood_crown_build_segment.gd")


func test_missing_named_body_is_not_dereferenced_by_admission_diagnostics() -> void:
	var segment := SEGMENT.new()
	assert_false(segment._named_engage_ready(null))
	assert_eq(segment._alpha_admission_snapshot(null), {"body": "<retired>"})

class Director extends Node:
	var candidate: Node3D
	func _engageable() -> Node3D:
		return candidate

class Arbiter extends Node:
	var provider: Node
	var actionable := true
	func winning_provider() -> Node:
		return provider
	func winner() -> Dictionary:
		return {"label": "Engage Voltarach", "actionable": actionable}


func test_explicit_engage_requires_exact_body_and_actionable_director_offer() -> void:
	var segment := SEGMENT.new()
	var director := Director.new()
	var arbiter := Arbiter.new()
	var alpha := Node3D.new()
	var other_voltarach := Node3D.new()
	segment._director = director
	segment._arbiter = arbiter
	director.candidate = alpha
	arbiter.provider = director
	assert_true(segment._named_engage_ready(alpha))
	director.candidate = other_voltarach
	assert_false(segment._named_engage_ready(alpha), "same species label is not the named body")
	director.candidate = alpha
	arbiter.provider = other_voltarach
	assert_false(segment._named_engage_ready(alpha), "a competing provider must never receive Engage input")
	arbiter.provider = director
	arbiter.actionable = false
	assert_false(segment._named_engage_ready(alpha), "status-only offers cannot admit a fight")
	director.candidate = null
	assert_false(segment._named_engage_ready(alpha), "refused production admission stays refused")
	alpha.free()
	other_voltarach.free()
	arbiter.free()
	director.free()
