extends "res://tests/test_case.gd"

## The C2 reader's two low-Wind hold rules (tests/helpers/f22_pattern_pilot.gd
## header; coordinator 2026-10-11): it never backs into a field or fan it
## remembers, and it does not hold off a foe that out-reaches its quick by
## more than HOLD_REACH_MARGIN_M.
const PILOT := preload("res://tests/helpers/f22_pattern_pilot.gd")
const RUNS_IN_INITIALIZED_TREE := true


class StubBody extends CharacterBody3D:
	func body_radius() -> float:
		return 1.0


var _pilot: RefCounted
var _ally: CharacterBody3D


func before_each() -> void:
	_pilot = PILOT.new()
	_ally = StubBody.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(_ally)
	_ally.global_position = Vector3.ZERO
	_pilot.set("_ally", _ally)


func after_each() -> void:
	if is_instance_valid(_ally):
		_ally.free()


func _remember_field(at: Vector3) -> void:
	var fields: Array[Dictionary] = [{"profile": {"telegraph_shape": "field", "marker_radius_m": 2.5},
		"origin": at, "heading": Vector3.FORWARD, "marker": at, "until": 1 << 30}]
	_pilot.set("_fields", fields)


func test_no_hold_against_a_foe_that_out_reaches_the_quick() -> void:
	assert_true(PILOT.holds_out_of_reach(4.0, 3.0), "a foe within quick reach + 2 m is held off")
	assert_true(PILOT.holds_out_of_reach(5.0, 3.0), "exactly at the margin still holds")
	assert_false(PILOT.holds_out_of_reach(8.1, 3.0), "a CURRENT-reach foe is not held off")
	assert_false(PILOT.holds_out_of_reach(7.2, 3.4), "the spaced guardian WALL is not held off")


func test_hold_steps_straight_back_when_nothing_is_remembered() -> void:
	_pilot.set("_fields", [] as Array[Dictionary])
	var toward := Vector3(0, 0, -1)
	assert_eq(_pilot.hold_back_step(toward), -toward, "open floor: straight back")


func test_hold_never_backs_into_a_remembered_field() -> void:
	var toward := Vector3(0, 0, -1)
	# Field 4 m behind (radius 2.5 + the reader's 1.3 margin): the step back
	# enters it, a step to either side does not.
	_remember_field(Vector3(0, 0, 4.0))
	var step: Vector3 = _pilot.hold_back_step(toward)
	assert_ne(step, -toward, "the step back would enter the remembered field")
	assert_ne(step, Vector3.ZERO, "a side is clear, so the reader still gives ground")
	assert_almost_eq(step.z, 0.0, 0.001, "it steps sideways, not into the field")


func test_hold_stands_when_every_step_is_inside_remembered_shapes() -> void:
	var toward := Vector3(0, 0, -1)
	_remember_field(Vector3(0, 0, 2.5))
	assert_eq(_pilot.hold_back_step(toward), Vector3.ZERO, "covered on all sides: stand, never back in")
