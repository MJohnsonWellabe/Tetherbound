extends "res://tests/test_case.gd"

## `HD1`'s last-used-input-device tracker (autoload/game_state.gd), which
## input_glyph.gd's `using_gamepad()` reads instead of "is a pad merely
## connected" -- the owner's own reproduction case was a keyboard/mouse
## player who still saw gamepad glyphs because that was the only signal.
##
## `GAME_STATE` is instantiated directly, bypassing `_ready()`/the scene
## tree, same as test_recipes.gd -- `_input()` is a plain method here, not
## something that needs a live viewport to dispatch to it. It is a `Node`,
## not `RefCounted`, so `after_each()` frees it explicitly the same way
## test_recipes.gd does; nothing here else leaks it.

const GAME_STATE := preload("res://autoload/game_state.gd")

var game: Node = null


func before_each() -> void:
	game = GAME_STATE.new()


func after_each() -> void:
	if game != null:
		game.free()


func test_starts_gamepad_when_a_pad_is_already_connected() -> void:
	# Input.get_connected_joypads() is empty in this headless test run, so the
	# real behaviour this locks in is the OTHER branch -- starts false when
	# nothing is connected, matching a keyboard-and-mouse desktop session.
	assert_false(bool(game.call("last_input_was_gamepad")),
		"no pad is connected in this test harness, so it should start false")


func test_a_gamepad_button_press_flips_it_to_gamepad() -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_A
	event.pressed = true
	game.call("_input", event)
	assert_true(bool(game.call("last_input_was_gamepad")))


func test_a_key_press_flips_it_to_keyboard() -> void:
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_A
	button.pressed = true
	game.call("_input", button)
	assert_true(bool(game.call("last_input_was_gamepad")))

	var key := InputEventKey.new()
	key.keycode = KEY_F
	key.pressed = true
	game.call("_input", key)
	assert_false(bool(game.call("last_input_was_gamepad")))


func test_a_mouse_click_flips_it_to_keyboard() -> void:
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_A
	button.pressed = true
	game.call("_input", button)
	assert_true(bool(game.call("last_input_was_gamepad")))

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	game.call("_input", click)
	assert_false(bool(game.call("last_input_was_gamepad")))


func test_mouse_motion_flips_it_to_keyboard() -> void:
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_A
	button.pressed = true
	game.call("_input", button)
	assert_true(bool(game.call("last_input_was_gamepad")))

	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(12.0, 3.0)
	game.call("_input", motion)
	assert_false(bool(game.call("last_input_was_gamepad")))


func test_joypad_stick_motion_past_the_deadzone_flips_it_to_gamepad() -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_F
	key.pressed = true
	game.call("_input", key)
	assert_false(bool(game.call("last_input_was_gamepad")))

	var motion := InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_RIGHT_X
	motion.axis_value = 0.8
	game.call("_input", motion)
	assert_true(bool(game.call("last_input_was_gamepad")))


func test_joypad_stick_drift_under_the_deadzone_does_not_flip_it() -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_F
	key.pressed = true
	game.call("_input", key)
	assert_false(bool(game.call("last_input_was_gamepad")))
	var motion := InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_RIGHT_X
	motion.axis_value = 0.1
	game.call("_input", motion)
	assert_false(bool(game.call("last_input_was_gamepad")))


func test_zero_mouse_motion_does_not_replace_controller_intent() -> void:
	var press := InputEventJoypadButton.new()
	press.button_index = JOY_BUTTON_X
	press.pressed = true
	game.call("_input", press)
	game.call("_input", InputEventMouseMotion.new())
	assert_true(bool(game.call("last_input_was_gamepad")), "a cursor refresh is not keyboard/mouse intent")


func test_releasing_an_old_device_does_not_replace_the_new_device() -> void:
	var press := InputEventJoypadButton.new()
	press.button_index = JOY_BUTTON_X
	press.pressed = true
	game.call("_input", press)
	var key_release := InputEventKey.new()
	key_release.physical_keycode = KEY_E
	game.call("_input", key_release)
	assert_true(bool(game.call("last_input_was_gamepad")), "old key release must not erase the controller press")
	var key_press := key_release.duplicate() as InputEventKey
	key_press.pressed = true
	game.call("_input", key_press)
	press.pressed = false
	game.call("_input", press)
	assert_false(bool(game.call("last_input_was_gamepad")), "old controller release must not erase keyboard intent")
