extends "res://tests/test_case.gd"

## Remappable controls: the model, the conflicts, and the file.
##
## This is the project's first thing that writes to `user://`, so the file half
## matters as much as the binding half. A settings file that is missing, corrupt
## or written by a newer build must end with default controls and a running
## game — never with a game that will not start — and none of those three cases
## can be reached by playing, which is exactly why they are tested here.
##
## Every test restores the input map in `after_each`. The runner runs every
## test file in one process, and an action left rebound here would show up as an
## unrelated failure somewhere else entirely.

const KEY_BINDINGS := preload("res://scripts/ui/key_bindings.gd")
const MENU_CONFIG := "res://data/config/menu.json"

var bindings: RefCounted = null
var path: String = ""

## Counts up so no two tests can ever be looking at the same file, whatever
## order they run in or whatever a previous failure left behind.
static var _serial: int = 0


func before_each() -> void:
	_serial += 1
	path = "user://test_controls_%d.json" % _serial
	bindings = KEY_BINDINGS.new(path)


func after_each() -> void:
	if bindings != null:
		bindings.reset_all()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	return event


func _pad(index: int) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	return event


func _write(text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file = null


func _read() -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}


func _config() -> Dictionary:
	var file := FileAccess.open(MENU_CONFIG, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}


func _controls() -> Dictionary:
	var settings: Dictionary = _config().get("settings", {}) as Dictionary
	return settings.get("controls", {}) as Dictionary


# --- the defaults come from project.godot ------------------------------------


func test_defaults_are_read_out_of_the_input_map() -> void:
	# project.godot is the defaults and is never written to. If this ever stops
	# matching, the settings screen is describing a game nobody is playing.
	assert_true(bindings.has("jump"), "jump is not in the snapshot")
	assert_eq(KEY_BINDINGS.code(bindings.binding("jump", "keyboard")), "key:%d" % KEY_SPACE)
	assert_eq(KEY_BINDINGS.code(bindings.binding("jump", "gamepad")), "pad:0")


func test_every_action_has_both_a_keyboard_and_a_gamepad_binding() -> void:
	# Every rebindable action ships with both, except the camera stick, which has
	# no keyboard half because mouse look is camera code rather than an action.
	for group in _controls().get("groups", []):
		for action in (group as Dictionary).get("actions", []):
			var name := str(action)
			assert_true(bindings.has(name), "%s is not in the input map" % name)
			assert_ne(bindings.binding(name, "gamepad"), null, "%s has no gamepad binding" % name)
			if not name.begins_with("look_"):
				assert_ne(bindings.binding(name, "keyboard"), null, "%s has no keyboard binding" % name)


func test_the_navigation_actions_can_never_be_rebound() -> void:
	# `ui_*` is Godot's focus navigation and is what drives the settings screen
	# itself with a stick. A player who rebound `ui_down` could not reach the
	# control that would undo it, so those actions are not in the model at all
	# and must never be listed in the JSON either.
	for action in InputMap.get_actions():
		if str(action).begins_with("ui_"):
			assert_false(bindings.has(str(action)), "%s is rebindable" % action)
	for group in _controls().get("groups", []):
		for action in (group as Dictionary).get("actions", []):
			assert_false(str(action).begins_with("ui_"), "%s is listed as rebindable" % action)


func test_every_listed_action_has_a_label_and_appears_once() -> void:
	# A missing label draws a row named `combat_switch_left`, and an action
	# listed in two groups draws two rows that fight over the same binding.
	var labels: Dictionary = _controls().get("labels", {}) as Dictionary
	var seen: Array[String] = []
	for group in _controls().get("groups", []):
		assert_false(str((group as Dictionary).get("name", "")).is_empty(), "a group has no name")
		for action in (group as Dictionary).get("actions", []):
			var name := str(action)
			assert_true(labels.has(name), "%s has no label" % name)
			assert_false(seen.has(name), "%s is listed twice" % name)
			seen.append(name)


func test_every_rebindable_action_is_on_the_screen() -> void:
	# The reverse check. An action in the input map that no group lists is one
	# the player cannot move, which is the thing the owner asked for.
	var listed: Array[String] = []
	for group in _controls().get("groups", []):
		for action in (group as Dictionary).get("actions", []):
			listed.append(str(action))
	for action in bindings.actions():
		assert_true(listed.has(str(action)), "%s is bindable but not on the settings screen" % action)


# --- changing a binding ------------------------------------------------------


func test_rebinding_changes_the_input_map() -> void:
	assert_true(bindings.set_binding("jump", "keyboard", _key(KEY_J)))
	var events := InputMap.action_get_events("jump")
	var found := false
	for event in events:
		if KEY_BINDINGS.code(event) == "key:%d" % KEY_J:
			found = true
	assert_true(found, "the input map still does not know about the new key")
	assert_true(bindings.is_overridden("jump", "keyboard"))
	assert_false(bindings.is_overridden("jump", "gamepad"), "the other slot was disturbed")


func test_a_binding_cannot_be_filed_under_the_wrong_column() -> void:
	assert_false(bindings.set_binding("jump", "keyboard", _pad(3)), "a pad button went in the keyboard slot")
	assert_false(bindings.set_binding("jump", "gamepad", _key(KEY_J)), "a key went in the gamepad slot")


func test_a_captured_binding_works_on_every_pad() -> void:
	# A captured event arrives from one physical device. Stored as-is it would
	# work on that pad and no other, which is invisible until the day the owner
	# plugs in a second controller.
	var event := _pad(4)
	event.device = 3
	bindings.set_binding("jump", "gamepad", event)
	assert_eq(bindings.binding("jump", "gamepad").device, -1)


func test_a_stick_push_is_stored_as_a_whole_direction() -> void:
	var motion := InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_RIGHT_Y
	motion.axis_value = -0.71
	bindings.set_binding("jump", "gamepad", motion)
	assert_eq(bindings.binding("jump", "gamepad").axis_value, -1.0)
	assert_eq(KEY_BINDINGS.code(bindings.binding("jump", "gamepad")), "axis:3:-")


func test_a_third_binding_on_an_action_survives_a_rebind() -> void:
	# The model holds one binding per column. Anything else already on an action
	# is kept verbatim rather than being eaten the first time the player changes
	# something, because silently dropping a binding is not a thing a settings
	# screen may do.
	InputMap.action_add_event("jump", _key(KEY_K))
	var fresh: RefCounted = KEY_BINDINGS.new(path)
	fresh.set_binding("jump", "keyboard", _key(KEY_J))
	var codes: Array[String] = []
	for event in InputMap.action_get_events("jump"):
		codes.append(KEY_BINDINGS.code(event))
	assert_true(codes.has("key:%d" % KEY_K), "the extra binding was thrown away")
	fresh.reset_all()
	InputMap.action_erase_event("jump", _key(KEY_K))


# --- conflicts ---------------------------------------------------------------


func test_a_clash_names_the_action_it_clashes_with() -> void:
	var clashes: Array = bindings.conflicts("jump", "keyboard", _key(KEY_I))
	assert_true(clashes.has("inventory"), "binding jump to I did not report the backpack")


func test_the_shipped_defaults_already_share_buttons() -> void:
	# This is why a clash is reported rather than refused. Out of the box, A is
	# jump AND quick attack AND menu confirm, because the world, a fight and a
	# menu are different contexts. Refusing duplicates would make the game's own
	# defaults unreachable from the settings screen.
	var on_a: Array = bindings.conflicts("jump", "gamepad", _pad(0))
	assert_true(on_a.has("combat_quick"))
	assert_true(on_a.has("menu_confirm"))


func test_a_clash_is_allowed_and_then_visible_from_both_sides() -> void:
	bindings.set_binding("map", "keyboard", _key(KEY_I))
	assert_true(bindings.current_conflicts("map").has("inventory"))
	assert_true(bindings.current_conflicts("inventory").has("map"), "only one row would be flagged")


func test_an_unbound_slot_is_not_a_clash() -> void:
	# look_up has no keyboard binding. Every other unbound keyboard slot would
	# otherwise read as clashing with it.
	assert_eq(bindings.conflicts("look_up", "keyboard", null).size(), 0)
	assert_eq(bindings.current_conflicts("look_up").size(), 0)


# --- resetting ---------------------------------------------------------------


func test_one_action_can_be_put_back() -> void:
	bindings.set_binding("jump", "keyboard", _key(KEY_J))
	bindings.set_binding("sprint", "keyboard", _key(KEY_L))
	bindings.reset_action("jump")
	assert_false(bindings.is_overridden("jump", "keyboard"))
	assert_true(bindings.is_overridden("sprint", "keyboard"), "resetting one reset another")
	assert_eq(KEY_BINDINGS.code(InputMap.action_get_events("jump")[0]), "key:%d" % KEY_SPACE)


func test_everything_can_be_put_back() -> void:
	# The safety net. A player can rebind themselves out of opening the menu at
	# all, and this is what the panic chord in scripts/ui/game_menu.gd calls.
	bindings.set_binding("menu_cancel", "gamepad", _pad(9))
	bindings.set_binding("inventory", "keyboard", _key(KEY_J))
	assert_true(bindings.any_overridden())
	bindings.reset_all()
	assert_false(bindings.any_overridden())
	assert_eq(KEY_BINDINGS.code(InputMap.action_get_events("menu_cancel")[1]), "pad:1")


# --- the file ----------------------------------------------------------------


func test_a_binding_survives_being_written_and_read_back() -> void:
	bindings.set_binding("jump", "keyboard", _key(KEY_J))
	bindings.set_binding("interact", "gamepad", _pad(9))
	var motion := InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_RIGHT_X
	motion.axis_value = 1.0
	bindings.set_binding("map", "gamepad", motion)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_MIDDLE
	bindings.set_binding("tool_cycle", "keyboard", mouse)
	assert_true(bindings.save())

	var reloaded: RefCounted = KEY_BINDINGS.new(path)
	reloaded.reset_all()
	assert_eq(reloaded.load_overrides(), KEY_BINDINGS.LOAD_OK)
	assert_eq(KEY_BINDINGS.code(reloaded.binding("jump", "keyboard")), "key:%d" % KEY_J)
	assert_eq(KEY_BINDINGS.code(reloaded.binding("interact", "gamepad")), "pad:9")
	assert_eq(KEY_BINDINGS.code(reloaded.binding("map", "gamepad")), "axis:2:+")
	assert_eq(KEY_BINDINGS.code(reloaded.binding("tool_cycle", "keyboard")), "mouse:%d" % MOUSE_BUTTON_MIDDLE)
	reloaded.reset_all()


func test_the_file_is_versioned_and_holds_only_what_the_player_changed() -> void:
	# Only differences are written, so a default that changes later still
	# reaches a player who already has a settings file.
	bindings.set_binding("jump", "keyboard", _key(KEY_J))
	bindings.save()
	var data := _read()
	assert_eq(int(data.get("version", 0)), KEY_BINDINGS.FORMAT_VERSION)
	var controls: Dictionary = data.get("controls", {}) as Dictionary
	assert_eq(controls.size(), 1, "the file holds actions the player never touched")
	assert_true(controls.has("jump"))
	assert_false((controls["jump"] as Dictionary).has("gamepad"), "an untouched column was written")


func test_the_file_is_a_settings_file_and_has_room_for_more_than_controls() -> void:
	# Display and audio join this file rather than each inventing one. Named
	# sections from the first write is what makes that a JSON key rather than a
	# migration.
	bindings.save()
	assert_true(_read().has("controls"))
	assert_true(bindings.path().begins_with("user://"), "settings must not be written into the project")


func test_no_file_at_all_is_the_normal_first_run() -> void:
	assert_eq(bindings.load_overrides(), KEY_BINDINGS.LOAD_MISSING)
	assert_false(bindings.any_overridden())
	assert_eq(KEY_BINDINGS.code(InputMap.action_get_events("jump")[0]), "key:%d" % KEY_SPACE)


func test_a_corrupt_file_falls_back_to_defaults_and_carries_on() -> void:
	_write("{ this is not json at all")
	assert_eq(bindings.load_overrides(), KEY_BINDINGS.LOAD_UNREADABLE)
	assert_false(bindings.any_overridden(), "a truncated file left the controls in a made-up state")


func test_a_file_from_a_newer_build_is_left_alone() -> void:
	# Read nothing rather than guess at a shape this build does not know, and do
	# not overwrite it either: the player may go back to the build that wrote it.
	_write('{"version": 99, "controls": {"jump": {"keyboard": "key:%d"}}}' % KEY_J)
	assert_eq(bindings.load_overrides(), KEY_BINDINGS.LOAD_FUTURE)
	assert_false(bindings.is_overridden("jump", "keyboard"))
	assert_eq(int(_read().get("version", 0)), 99, "the newer file was clobbered on load")


func test_a_file_with_no_version_is_not_trusted() -> void:
	_write('{"controls": {"jump": {"keyboard": "key:%d"}}}' % KEY_J)
	assert_eq(bindings.load_overrides(), KEY_BINDINGS.LOAD_UNREADABLE)
	assert_false(bindings.any_overridden())


func test_an_action_that_no_longer_exists_is_skipped_not_fatal() -> void:
	# Renaming an action must not brick everyone's settings, and neither must a
	# binding string this build cannot parse.
	_write('{"version": %d, "controls": {"pet_the_dog": {"keyboard": "key:%d"}, "jump": {"keyboard": "nonsense"}, "sprint": {"keyboard": "key:%d"}}}' % [
		KEY_BINDINGS.FORMAT_VERSION, KEY_J, KEY_L
	])
	assert_eq(bindings.load_overrides(), KEY_BINDINGS.LOAD_OK)
	assert_false(bindings.is_overridden("jump", "keyboard"), "an unparseable code was applied anyway")
	assert_eq(KEY_BINDINGS.code(bindings.binding("sprint", "keyboard")), "key:%d" % KEY_L)


# --- what the player reads ---------------------------------------------------


func test_every_binding_reads_as_words() -> void:
	# Never a bare number and never blank: a row that says "button 9" is a row
	# the player has to go and look up, and a blank one looks like a bug.
	bindings.glyphs = _controls().get("glyphs", {}) as Dictionary
	for action in bindings.actions():
		for slot in ["keyboard", "gamepad"]:
			var text := str(bindings.describe(bindings.binding(str(action), str(slot))))
			assert_false(text.is_empty(), "%s/%s describes as nothing" % [action, slot])
			assert_false(
				text.begins_with("button ") or text.begins_with("axis ") or text.begins_with("mouse "),
				"%s/%s has no glyph in menu.json: %s" % [action, slot, text]
			)
	assert_eq(bindings.describe(null), "unbound")
	assert_eq(bindings.describe(_pad(0)), "A")
	assert_eq(bindings.describe(_key(KEY_SPACE)), "Space")
