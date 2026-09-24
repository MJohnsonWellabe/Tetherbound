extends "res://tests/test_case.gd"

## UX §8/§10: shown glyphs follow the player's rebinding. An action still on
## its default draws exactly what `GLYPHS` always drew.

const GLYPH := preload("res://scripts/ui/input_glyph.gd")

var _saved: Dictionary = {}


func before_each() -> void:
	_saved.clear()
	for id: String in ["interact", "inventory"]:
		_saved[id] = InputMap.action_get_events(id).duplicate()


func after_each() -> void:
	for id: String in _saved.keys():
		InputMap.action_erase_events(id)
		for event: InputEvent in (_saved[id] as Array):
			InputMap.action_add_event(id, event)


func _rebind(id: String, device: String, event: InputEvent) -> void:
	for existing: InputEvent in InputMap.action_get_events(id):
		var pad := existing is InputEventJoypadButton or existing is InputEventJoypadMotion
		if (device == "gamepad") == pad:
			InputMap.action_erase_event(id, existing)
	InputMap.action_add_event(id, event)


func test_every_default_binding_keeps_its_authored_glyph() -> void:
	for id: String in GLYPH.GLYPHS.keys():
		if not InputMap.has_action(id):
			continue
		for device: String in ["keyboard", "gamepad"]:
			assert_eq(GLYPH.rebound_glyph(id, device), {},
				"'%s' on %s is on its default binding and must keep its authored glyph" % [id, device])


func test_a_rebound_key_draws_the_key_the_player_chose() -> void:
	var f := InputEventKey.new()
	f.physical_keycode = KEY_F
	_rebind("interact", "keyboard", f)
	var drawn := GLYPH.icon("interact", 36, Color.WHITE, "keyboard")
	assert_true(drawn.contains("keyboard_f.png"), "interact rebound to F must draw F, drew %s" % drawn)
	assert_false(drawn.contains("keyboard_e.png"))


func test_a_rebound_pad_button_draws_that_button() -> void:
	var y := InputEventJoypadButton.new()
	y.button_index = JOY_BUTTON_Y
	_rebind("interact", "gamepad", y)
	var drawn := GLYPH.icon("interact", 36, Color.WHITE, "gamepad")
	assert_true(drawn.contains("xbox_button_y.png"), "interact rebound to Y must draw Y, drew %s" % drawn)


func test_a_rebound_key_with_no_art_is_named_in_text() -> void:
	var k := InputEventKey.new()
	k.physical_keycode = KEY_K
	_rebind("inventory", "keyboard", k)
	var drawn := GLYPH.icon("inventory", 36, Color.WHITE, "keyboard")
	assert_false(drawn.contains("[img"), "no vendored keycap for K; it must not borrow the default's art")
	assert_true(drawn.contains("K"), "the bound key is named instead, got %s" % drawn)


## The authored art must be the art for the button actually bound by default.
## `build_dismantle`'s keyboard half drew B while X was bound. The two build
## rotations are bound to the mouse wheel, which the pack has no art for; their
## arrows are the documented closest shape (see the GLYPHS comment).
const WHEEL_STAND_INS := ["build_rotate_left/keyboard", "build_rotate_right/keyboard"]


func test_authored_glyphs_match_the_default_bindings() -> void:
	for id: String in GLYPH.GLYPHS.keys():
		if not InputMap.has_action(id):
			continue
		var entry: Dictionary = GLYPH.GLYPHS[id]
		for device: String in ["keyboard", "gamepad"]:
			if not entry.has(device) or entry[device] is Array or WHEEL_STAND_INS.has("%s/%s" % [id, device]):
				continue
			var bound := GLYPH._first_event_for(InputMap.action_get_events(id), device)
			if bound == null:
				continue
			assert_eq(GLYPH.glyph_file_for_event(bound), str(entry[device]),
				"'%s' on %s draws %s but is bound to another button" % [id, device, entry[device]])


func test_dismantle_names_its_real_key() -> void:
	var drawn := GLYPH.icon("build_dismantle", 36, Color.WHITE, "keyboard")
	assert_false(drawn.contains("keyboard_b.png"))
	assert_true(drawn.contains("X"), "dismantle is X on a keyboard, got %s" % drawn)
