extends TestCase

const HARNESS := preload("res://tools/gate_f/operator_harness.gd")

class ContextProbe extends RefCounted:
	var context := "world"
	func input_context() -> String:
		return context

class ExitingWalk extends "res://tools/gate_f/operator_harness.gd":
	var result := ""
	func _walk_loop_impl(_args: Dictionary, _target: Callable) -> String:
		_stick_left = Vector2(0.5, -0.75)
		_drive_sticks()
		var error := _set_walk_sprint(true)
		return result if error.is_empty() else error

func test_sprint_uses_physical_action_and_releases_after_context_change() -> void:
	var harness := HARNESS.new()
	var probe := ContextProbe.new()
	harness._probe = probe
	assert_eq(harness._set_walk_sprint(true), "")
	assert_true(Input.is_action_pressed("sprint"))
	probe.context = "menu_map"
	assert_eq(harness._set_walk_sprint(false), "")
	assert_false(Input.is_action_pressed("sprint"))
	assert_true(harness._set_walk_sprint(true).begins_with("FAIL"))
	assert_false(Input.is_action_pressed("sprint"))
	harness.free()

func test_walk_boundary_releases_sprint_for_success_and_failure() -> void:
	var harness := ExitingWalk.new()
	harness._probe = ContextProbe.new()
	for result in ["walked to target", "FAIL lost target", "FAIL no passage", "FAIL budget exhausted"]:
		harness.result = result
		assert_eq(await harness._walk_loop({}, Callable()), result)
		assert_false(Input.is_action_pressed("sprint"))
		assert_false(harness._walk_sprint_held)
		assert_eq(harness._stick_left, Vector2.ZERO)
		assert_false(Input.is_action_pressed("move_forward"))
		assert_false(Input.is_action_pressed("move_right"))
	harness.free()
