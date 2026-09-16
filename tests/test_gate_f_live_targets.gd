extends TestCase

const HARNESS := preload("res://tools/gate_f/operator_harness.gd")

class Wild extends Node3D:
	var alive := true
	func is_alive() -> bool:
		return alive


func test_caught_defeated_and_hidden_bodies_are_not_live_approach_targets() -> void:
	var wild := Wild.new()
	assert_true(HARNESS._available_live_target(wild))
	wild.alive = false
	assert_false(HARNESS._available_live_target(wild), "caught/defeated nodes can remain in the scene")
	wild.alive = true
	wild.visible = false
	assert_false(HARNESS._available_live_target(wild))
	wild.free()
	var prop := Node3D.new()
	assert_false(HARNESS._available_live_target(prop), "named scenery cannot satisfy an alive creature request")
	prop.free()
