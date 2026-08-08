extends SceneTree

## Can the settings screen actually be driven, and rebound, with a pad alone?
##
##   godot --headless --path . --script tests/smoke_settings.gd
##
## tests/test_controls.gd proves the binding model and the file. None of that
## can see the things that decide whether this ships:
##
##   - reaching the tab at all. It has to be walkable to from the tab row with
##     the same buttons the rest of the menu uses.
##   - focus. This is the screen a player goes to BECAUSE their controls are
##     wrong, so it is the last screen allowed to need a mouse.
##   - the capture. It reads raw events in `_input`, ahead of the Control tree,
##     which is a path no unit test touches. A focused Button swallows the
##     confirm button, so a capture that read actions would never see anything.
##   - the shell going deaf. Binding `menu_cancel` to A must not close the menu
##     on the very press that bound it.
##   - the panic chord, which reads the DEVICE rather than the input map,
##     because it has to work when the input map is what is broken.
##
## Input is injected with `Input.parse_input_event` rather than
## `Input.action_press`. Actions set state but never enter the tree, so they
## cannot move focus and cannot reach `_input` — a poll-only test would report a
## working screen while the stick moved nothing. Learned on tests/smoke_menu.gd.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const KEY_BINDINGS := preload("res://scripts/ui/key_bindings.gd")
const SETTLE_FRAMES := 240

var _failures: Array[String] = []
var _menu: CanvasLayer = null
var _tab: Node = null
var _rows: Array = []


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var game: Node = root.get_node_or_null(^"Game")
	_menu = game.call("menu") if game != null else null
	if _menu == null:
		print("FAIL: the autoload did not stand up the menu")
		quit(1)
		return
	if _menu.get("bindings") == null:
		print("FAIL: the menu has no binding table; controls were never loaded")
		quit(1)
		return

	await _check_the_tab_is_reachable_with_a_pad()
	if _tab == null:
		print("FAIL: there is no settings tab")
		_cleanup()
		quit(1)
		return

	await _check_focus_can_be_driven()
	await _check_a_key_can_be_rebound()
	await _check_a_capture_can_be_cancelled()
	await _check_a_gamepad_button_can_be_rebound()
	await _check_a_clash_is_named_out_loud()
	await _check_the_menu_survives_rebinding_its_own_close_button()
	await _check_one_row_can_be_put_back()
	await _check_everything_can_be_put_back()
	await _check_the_change_reached_the_file()
	await _check_the_panic_chord()

	_cleanup()

	print("")
	if _failures.is_empty():
		print("settings smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


func _fail(message: String) -> void:
	_failures.append(message)


## Leave nothing behind. This is the only test that writes the REAL settings
## file, and a stray override here would follow the player — and every other CI
## step — into the next run.
func _cleanup() -> void:
	var bindings: RefCounted = _menu.get("bindings")
	if bindings != null:
		bindings.call("reset_all")
	var path := str(bindings.call("path")) if bindings != null else ""
	if not path.is_empty() and FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


# --- input ------------------------------------------------------------------


## An action, sent both ways: as state for whatever polls, and as an event for
## the Control tree. See the note at the top.
func _press(action: String) -> void:
	Input.action_press(action)
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	Input.action_release(action)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	for i in 4:
		await process_frame


## A raw key, the way a keyboard sends one. Both keycode and physical_keycode
## are set: the capture stores the physical one and the panic chord reads the
## logical one.
func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func _tap_key(code: Key) -> void:
	_key(code, true)
	await process_frame
	await process_frame
	_key(code, false)
	for i in 3:
		await process_frame


func _tap_pad(index: int) -> void:
	var down := InputEventJoypadButton.new()
	down.button_index = index
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	var up := InputEventJoypadButton.new()
	up.button_index = index
	up.pressed = false
	Input.parse_input_event(up)
	for i in 3:
		await process_frame


func _focused() -> Control:
	var viewport := root.get_viewport()
	return viewport.gui_get_focus_owner() if viewport != null else null


func _code(action: String, slot: String) -> String:
	var bindings: RefCounted = _menu.get("bindings")
	return KEY_BINDINGS.code(bindings.call("binding", action, slot))


func _row(action: String) -> Dictionary:
	for record in _rows:
		if str((record as Dictionary)["action"]) == action:
			return record
	return {}


func _status() -> String:
	return str(_menu.get("_status").text)


## Put the cursor on a cell and press confirm the way a pad does.
func _open_capture(action: String, slot: String) -> void:
	var cell: Button = _row(action)[slot]
	cell.grab_focus()
	await process_frame
	await _press("ui_accept")


# --- the checks -------------------------------------------------------------


## Reachable by pressing the same button that changes tab everywhere else. A
## settings screen you can only get to by calling `select(3)` is not a screen.
func _check_the_tab_is_reachable_with_a_pad() -> void:
	await _press("inventory")
	if not bool(_menu.call("is_open")):
		_fail("the menu did not open")
		return

	var tabs: Array = _menu.get("_tabs")
	var wanted := -1
	for i in tabs.size():
		if str((tabs[i] as Dictionary).get("id", "")) == "settings":
			wanted = i
	if wanted < 0:
		return

	for step in tabs.size() + 1:
		if int(_menu.get("_index")) == wanted:
			break
		await _press("tool_cycle")
	if int(_menu.get("_index")) != wanted:
		_fail("`tool_cycle` never reached the settings tab")
		return

	_tab = _menu.get("_bodies")[wanted]
	_rows = _tab.get("_rows")
	if _rows.is_empty():
		_fail("the settings tab drew no rows")
		return
	print("settings reached on `tool_cycle`: %d rebindable rows" % _rows.size())


func _check_focus_can_be_driven() -> void:
	var start := _focused()
	if start == null:
		_fail("nothing holds focus on the settings tab; a stick would move nothing")
		return
	await _press("ui_right")
	var after_right := _focused()
	if after_right == start:
		_fail("ui_right moved nothing; the keyboard and gamepad columns cannot be reached")
	await _press("ui_down")
	if _focused() == after_right:
		_fail("ui_down moved nothing; only one row could ever be rebound")
	if _focused() == null:
		_fail("focus was lost while moving; the screen becomes undrivable")
	print("focus moves across columns and down rows")


func _check_a_key_can_be_rebound() -> void:
	await _open_capture("jump", "keyboard")
	if not bool(_tab.get("_capturing")):
		_fail("confirm on a binding did not start a capture")
		return
	if not str(_row("jump")["keyboard"].text).begins_with("Press"):
		_fail("the row does not say it is waiting: %s" % _row("jump")["keyboard"].text)

	await _tap_key(KEY_J)
	if bool(_tab.get("_capturing")):
		_fail("the capture never ended")
		return
	if _code("jump", "keyboard") != "key:%d" % KEY_J:
		_fail("jump is bound to %s, not J" % _code("jump", "keyboard"))
	# And the game itself agrees, not just the model.
	var live := false
	for event in InputMap.action_get_events("jump"):
		if KEY_BINDINGS.code(event) == "key:%d" % KEY_J:
			live = true
	if not live:
		_fail("the input map never heard about the new binding")
	print("a key rebinds: jump is now %s" % _row("jump")["keyboard"].text)


func _check_a_capture_can_be_cancelled() -> void:
	var before := _code("sprint", "gamepad")
	await _open_capture("sprint", "gamepad")
	if not bool(_tab.get("_capturing")):
		_fail("confirm on the gamepad column did not start a capture")
		return
	await _tap_pad(JOY_BUTTON_B)
	if bool(_tab.get("_capturing")):
		_fail("B did not cancel the capture")
	if _code("sprint", "gamepad") != before:
		_fail("cancelling changed the binding anyway: %s" % _code("sprint", "gamepad"))
	print("B cancels a capture and changes nothing")


func _check_a_gamepad_button_can_be_rebound() -> void:
	await _open_capture("sprint", "gamepad")
	await _tap_pad(JOY_BUTTON_RIGHT_SHOULDER)
	if _code("sprint", "gamepad") != "pad:%d" % JOY_BUTTON_RIGHT_SHOULDER:
		_fail("sprint is on %s, not RB" % _code("sprint", "gamepad"))
	print("a pad button rebinds: sprint is now %s" % _row("sprint")["gamepad"].text)


## A duplicate is allowed and SAID. Refusing silently is the one thing this
## screen may not do; the shipped defaults themselves share four buttons.
func _check_a_clash_is_named_out_loud() -> void:
	await _open_capture("map", "keyboard")
	await _tap_key(KEY_I)
	if _code("map", "keyboard") != "key:%d" % KEY_I:
		_fail("the clashing binding was refused instead of taken")
	var said := _status()
	if not said.to_lower().contains("backpack"):
		_fail("the clash with the backpack was not named: '%s'" % said)
	var flagged: Color = _row("map")["name_label"].get_theme_color("font_color")
	if flagged == Color(0.87, 0.89, 0.84):
		_fail("the clashing row is not marked, so the clash vanishes with the status line")
	print("a clash is allowed and named: '%s'" % said)


## The nastiest case in the whole screen. `menu_cancel` closes the menu and the
## shell polls it every frame, so binding it to a button leaves that button
## physically down at the instant it starts meaning "close".
func _check_the_menu_survives_rebinding_its_own_close_button() -> void:
	await _open_capture("menu_cancel", "gamepad")
	await _tap_pad(JOY_BUTTON_A)
	if _code("menu_cancel", "gamepad") != "pad:%d" % JOY_BUTTON_A:
		_fail("menu_cancel did not take the new button")
	for i in 10:
		await process_frame
	if not bool(_menu.call("is_open")):
		_fail("the menu closed itself on the press that rebound its close button")
		_menu.call("open", "settings")
		for i in 4:
			await process_frame
	print("rebinding the close button did not close the menu")


func _check_one_row_can_be_put_back() -> void:
	var reset: Button = _row("jump")["reset"]
	reset.grab_focus()
	await process_frame
	await _press("ui_accept")
	if _code("jump", "keyboard") != "key:%d" % KEY_SPACE:
		_fail("Default left jump on %s" % _code("jump", "keyboard"))
	var bindings: RefCounted = _menu.get("bindings")
	if not bool(bindings.call("is_overridden", "sprint", "gamepad")):
		_fail("resetting one row reset another")
	print("one row goes back to its default on its own")


## Two presses, and it must be reachable from the top of the screen rather than
## the bottom of a list a broken layout may not be able to scroll.
func _check_everything_can_be_put_back() -> void:
	var button: Button = _tab.get("_reset_all_button")
	if button == null:
		_fail("there is no global reset")
		return
	button.grab_focus()
	await process_frame
	await _press("ui_accept")
	var bindings: RefCounted = _menu.get("bindings")
	if not bool(bindings.call("any_overridden")):
		_fail("one press wiped every control; that is a footgun, not a safety net")
	await _press("ui_accept")
	if bool(bindings.call("any_overridden")):
		_fail("two presses did not put everything back")
	if _code("menu_cancel", "gamepad") != "pad:%d" % JOY_BUTTON_B:
		_fail("menu_cancel did not come back to B")
	print("two presses on the global reset put everything back")


func _check_the_change_reached_the_file() -> void:
	await _open_capture("interact", "keyboard")
	await _tap_key(KEY_G)
	var bindings: RefCounted = _menu.get("bindings")
	var path := str(bindings.call("path"))
	if not FileAccess.file_exists(path):
		_fail("nothing was written to %s" % path)
		return

	# Read it back the way the next launch will: a fresh table, defaults, then
	# the file laid on top.
	var reloaded: RefCounted = KEY_BINDINGS.new(path)
	reloaded.call("reset_all")
	var status: int = int(reloaded.call("load_overrides"))
	if status != KEY_BINDINGS.LOAD_OK:
		_fail("the settings file did not reload (status %d)" % status)
	if KEY_BINDINGS.code(reloaded.call("binding", "interact", "keyboard")) != "key:%d" % KEY_G:
		_fail("the rebind did not survive a reload")
	print("the rebind survives a reload from %s" % path)


## The way back when the input map itself is the problem.
##
## Rebinds the menu's own open button to something nothing will ever press, then
## gets out of it with the chord — which reads the device directly and so is the
## only thing on this screen that cannot be broken from this screen.
func _check_the_panic_chord() -> void:
	await _open_capture("inventory", "keyboard")
	await _tap_key(KEY_F7)
	_menu.call("close")
	for i in 4:
		await process_frame

	var bindings: RefCounted = _menu.get("bindings")
	if not bool(bindings.call("any_overridden")):
		_fail("the test could not break the controls, so it cannot test the way back")
		return

	_key(KEY_F10, true)
	var frames := 0
	while bool(bindings.call("any_overridden")) and frames < 4000:
		await process_frame
		frames += 1
	_key(KEY_F10, false)
	for i in 4:
		await process_frame

	if bool(bindings.call("any_overridden")):
		_fail("holding the panic key did not put the controls back")
		return
	if not bool(_menu.call("is_open")):
		_fail("the panic reset did not show the player where it happened")
	print("the panic chord put everything back after %d frames" % frames)
