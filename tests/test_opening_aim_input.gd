extends "res://tests/test_case.gd"

const DRIVE := preload("res://tests/helpers/gate_a_opening_drive.gd")

func test_look_release_reaches_native_axes_before_camera_process() -> void:
	var accumulated := Input.use_accumulated_input
	Input.use_accumulated_input = true
	for axis: JoyAxis in [JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y]:
		var event := InputEventJoypadMotion.new()
		event.axis = axis
		event.axis_value = 1.0
		Input.parse_input_event(event)
	Input.flush_buffered_events()
	assert_eq(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), 1.0)
	assert_eq(Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y), 1.0)
	DRIVE.new()._stop_right_stick()
	# Do not flush here: that would conceal the release's ordering defect.
	assert_eq(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), 0.0)
	assert_eq(Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y), 0.0)
	Input.use_accumulated_input = accumulated
