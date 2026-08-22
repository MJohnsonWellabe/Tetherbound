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


## Actions that deliberately ship with NO gamepad binding.
##
## The owner's 2026-08-22 controller map (ralph/OWNER_DIRECTIVES_2026-08-22.md
## section 1) is fourteen buttons wide and every one is spoken for, so six verbs
## came off the pad rather than being folded into a held-button chord, which the
## same directive bans. Each still has a keyboard key and each is still
## rebindable here -- a player who WANTS the torch on a button can put it there.
##
## Listed explicitly rather than the assertion being softened to "if it has
## one": a seventh action quietly losing its pad binding is a regression, and
## this list is the difference between that and a decision visible in review.
const PAD_UNBOUND_BY_DESIGN := {
	"use_tool": "chopping and mining are interact (X) now",
	"torch_toggle": "the torch is a hotbar tool -- the torch does not need a button",
	"torch_place": "same verb's fast-equip half",
	"build_open": "the build hammer is a hotbar tool: select it, press interact",
	"combat_throw": "the orb is selected on the bar and thrown with interact",
	"combat_run": "fleeing is RB -- putting your creature away IS disengaging",
}


func test_every_action_has_both_a_keyboard_and_a_gamepad_binding() -> void:
	# Every rebindable action ships with both, except the camera stick, which has
	# no keyboard half because mouse look is camera code rather than an action,
	# and the six verbs the authored pad map deliberately leaves keyboard-only.
	for group in _controls().get("groups", []):
		for action in (group as Dictionary).get("actions", []):
			var name := str(action)
			assert_true(bindings.has(name), "%s is not in the input map" % name)
			if PAD_UNBOUND_BY_DESIGN.has(name):
				assert_eq(bindings.binding(name, "gamepad"), null, "%s is listed as pad-unbound by design (%s) but has a gamepad binding -- update the list or the map" % [name, PAD_UNBOUND_BY_DESIGN[name]])
			else:
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
	# A missing label draws a row named `party_cycle`, and an action
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
	# jump AND menu confirm, because the world and a menu are different
	# contexts. Refusing duplicates would make the game's own defaults
	# unreachable from the settings screen.
	var on_a: Array = bindings.conflicts("jump", "gamepad", _pad(0))
	assert_true(on_a.has("menu_confirm"))


func test_the_shipped_defaults_share_triggers_between_combat_and_build() -> void:
	# D35 (Palworld parity): `combat_quick`/`combat_charged` moved onto the
	# triggers, the same ones `build_rotate_right`/`build_rotate_left` already
	# used -- a fight and an armed build ghost are mutually exclusive game
	# states (build_placer.gd only reads its actions while `pending_build` is
	# set; combat_manager.gd only reads these while State.ACTIVE), so this is
	# a deliberate dual-use, not an oversight.
	var rt := InputEventJoypadMotion.new()
	rt.axis = JOY_AXIS_TRIGGER_RIGHT
	rt.axis_value = 1.0
	var on_rt: Array = bindings.conflicts("combat_quick", "gamepad", rt)
	assert_true(on_rt.has("build_rotate_right"))

	var lt := InputEventJoypadMotion.new()
	lt.axis = JOY_AXIS_TRIGGER_LEFT
	lt.axis_value = 1.0
	var on_lt: Array = bindings.conflicts("combat_charged", "gamepad", lt)
	assert_true(on_lt.has("build_rotate_left"))


## OF21's world-context collision test USED TO LIVE HERE, over a hand-picked
## `WORLD_CONTEXT_ACTIONS` list. CONTROLLER-MAP replaced it with
## `tests/test_input_context_collisions.gd`, which does the same job for every
## context rather than only for exploration, and reads which actions are live
## together out of `data/config/input_contexts.json` instead of a const nobody
## remembered to update. The hand-picked list is what let the d-pad collision
## survive: `combat_switch_left` and `hotbar_2` were both on joypad 13 and both
## live in a fight, and no list here named the combat context at all.
##
## Deleted rather than left as a narrower duplicate, because two overlapping
## collision tests is how one of them goes stale unnoticed.


## OW1: the same rule as the world-context test above, for the three verbs
## `tab_backpack.gd` reads out of ONE `poll()` on the same frame.
##
## `backpack_drop` and `backpack_assign` both shipped on keyboard G. Because
## `poll()` calls `_read_drop()` before `_read_assign()` and the drop
## confirmation then gates the assign read out, pressing G could only ever open
## the drop confirmation -- the quick-bar assign verb was unreachable on a
## keyboard from the day it shipped. That is not a cross-context share the way
## A being both `jump` and `menu_confirm` is; these three are read by the same
## function, in the same state, on the same press.
##
## Both halves are checked. The gamepad half is now also covered, from the
## other direction, by `tests/test_input_context_collisions.gd`'s
## `menu_backpack` context.
const BACKPACK_VERB_ACTIONS := ["backpack_drop", "backpack_split", "backpack_assign"]


## UI-PAD1 widened this from keyboard-only to keyboard AND joypad. It used to
## do `var key := event as InputEventKey` and `continue` on everything else, so
## a pair of verbs sharing a controller button was invisible to it -- and a
## missing/duplicated pad binding is precisely the class of bug that shipped a
## game whose menus no controller could press.
##
## All three verbs now have BOTH halves bound (G/H/J and Menu/R3/X), so the
## joypad branch has something real to compare -- it did not when UI-PAD1 wrote
## this note, and `backpack_assign` moving off Y in CONTROLLER-MAP is the change
## that gave it teeth.
func test_no_two_menu_context_actions_share_a_button() -> void:
	var claimed: Dictionary = {}
	for action in BACKPACK_VERB_ACTIONS:
		assert_true(InputMap.has_action(str(action)), "%s is not a real action" % action)
		for event in InputMap.action_get_events(str(action)):
			var code := ""
			var human := ""
			var key := event as InputEventKey
			var pad := event as InputEventJoypadButton
			if key != null:
				code = "key:%d" % key.physical_keycode
				human = "keyboard %s" % key.as_text()
			elif pad != null:
				code = "joy:%d" % pad.button_index
				human = "joypad button %d" % pad.button_index
			else:
				continue
			assert_false(
				claimed.has(code),
				"%s and %s both claim %s -- tab_backpack.gd reads both from one poll(), so the first one read wins and the other verb is dead" % [
					claimed.get(code), action, human
				]
			)
			claimed[code] = action


## The regression guard for UI-PAD1 itself, and the one assertion here that
## fails on the code as it shipped.
##
## `ui_accept` is what a focused `Button` activates on. It is a Godot built-in,
## it was not listed in project.godot, and the engine defaults it fell back to
## carried no joypad event -- so on a controller every menu in the game could be
## navigated and nothing in it could be pressed. Measured, not inferred: the
## build menu's grid took focus correctly and neither A nor X armed a piece.
##
## This is a project-wide property, so it belongs here rather than in any one
## screen's smoke test.
func test_ui_accept_can_be_pressed_with_a_controller() -> void:
	assert_true(InputMap.has_action("ui_accept"), "ui_accept is not a real action")
	var pad_buttons: Array[int] = []
	for event in InputMap.action_get_events("ui_accept"):
		var pad := event as InputEventJoypadButton
		if pad != null:
			pad_buttons.append(pad.button_index)
	assert_false(
		pad_buttons.is_empty(),
		"ui_accept has no joypad event, so no focused Button anywhere in this controller-first game can be pressed with a pad -- see ralph/NOTES.md and project.godot's own note on this action"
	)


## Listing `ui_accept` in project.godot REPLACES the engine defaults instead of
## adding to them, so the keyboard events only exist because UI-PAD1 restated
## them by hand. Dropping one would quietly take Enter or Space away from every
## menu in the game, and no other test would notice.
func test_ui_accept_still_answers_the_keyboard() -> void:
	var keycodes: Array[int] = []
	for event in InputMap.action_get_events("ui_accept"):
		var key := event as InputEventKey
		if key != null:
			keycodes.append(key.keycode if key.keycode != 0 else key.physical_keycode)
	for wanted in [KEY_ENTER, KEY_SPACE]:
		assert_true(
			keycodes.has(wanted),
			"ui_accept lost %s -- defining the action in project.godot replaces the engine defaults, so every keyboard event has to be restated there" % OS.get_keycode_string(wanted)
		)


func test_a_clash_is_allowed_and_then_visible_from_both_sides() -> void:
	bindings.set_binding("map", "keyboard", _key(KEY_I))
	assert_true(bindings.current_conflicts("map").has("inventory"))
	assert_true(bindings.current_conflicts("inventory").has("map"), "only one row would be flagged")


func test_the_defaults_clash_with_themselves_and_that_is_not_a_warning() -> void:
	# A row is marked on clashes the PLAYER made. If the shipped defaults counted,
	# rows would be amber on a fresh install and the colour would stop meaning
	# anything.
	assert_true(bindings.current_conflicts("jump").has("menu_confirm"))
	assert_eq(bindings.new_conflicts("jump").size(), 0, "a fresh install is already warning")
	bindings.set_binding("jump", "keyboard", _key(KEY_I))
	assert_true(bindings.new_conflicts("jump").has("inventory"))
	assert_false(bindings.new_conflicts("jump").has("menu_confirm"), "a shipped clash was reported as new")


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
	bindings.set_binding("menu_tab_left", "keyboard", mouse)
	assert_true(bindings.save())

	var reloaded: RefCounted = KEY_BINDINGS.new(path)
	reloaded.reset_all()
	assert_eq(reloaded.load_overrides(), KEY_BINDINGS.LOAD_OK)
	assert_eq(KEY_BINDINGS.code(reloaded.binding("jump", "keyboard")), "key:%d" % KEY_J)
	assert_eq(KEY_BINDINGS.code(reloaded.binding("interact", "gamepad")), "pad:9")
	assert_eq(KEY_BINDINGS.code(reloaded.binding("map", "gamepad")), "axis:2:+")
	assert_eq(KEY_BINDINGS.code(reloaded.binding("menu_tab_left", "keyboard")), "mouse:%d" % MOUSE_BUTTON_MIDDLE)
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
