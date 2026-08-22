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
## OF26. Only for its `DEBUG_TELEPORT_CLEARANCE` const, the same "preload the
## script, read the const/static func off it" idiom `scripts/ui/tab_map.gd`
## already uses for `MAP_STATE.CELL`/`MAP_STATE.grid_x()`.
const GAME_STATE := preload("res://autoload/game_state.gd")
const SETTLE_FRAMES := 240

var _failures: Array[String] = []
var _menu: CanvasLayer = null
var _tab: Node = null
var _rows: Array = []

## OF26. The Game autoload, kept as a field so `_check_debug_teleport` can
## reach it the same way every other check reaches `_menu`/`_tab`.
var _game: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	# Real boot reaches this scene through the engine's own main-scene load, which
	# sets `current_scene` as a side effect. This harness adds the scene by hand
	# instead, so without this line `current_scene` stays null and anything that
	# walks it — OF26's debug teleport (`GameState.debug_teleport_to`'s own
	# `ground_height_at` lookup) included — silently finds nothing, whatever the
	# real state of the game is. Same fix tests/smoke_menu.gd already carries.
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var game: Node = root.get_node_or_null(^"Game")
	_game = game
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
	await _check_all_enabled_controls_are_reachable()
	await _check_a_key_can_be_rebound()
	await _check_a_capture_can_be_cancelled()
	await _check_a_gamepad_button_can_be_rebound()
	await _check_a_clash_is_named_out_loud()
	await _check_the_menu_survives_rebinding_its_own_close_button()
	await _check_one_row_can_be_put_back()
	await _check_everything_can_be_put_back()
	await _check_the_change_reached_the_file()
	await _check_debug_teleport()
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


func _tap_axis(axis: JoyAxis, value: float) -> void:
	var down := InputEventJoypadMotion.new()
	down.axis = axis
	down.axis_value = value
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	var up := InputEventJoypadMotion.new()
	up.axis = axis
	up.axis_value = 0.0
	Input.parse_input_event(up)
	for i in 3:
		await process_frame


func _pad_button_for(action: String) -> int:
	if not InputMap.has_action(action):
		return -1
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			return button.button_index
	return -1


func _focused() -> Control:
	var viewport := root.get_viewport()
	return viewport.gui_get_focus_owner() if viewport != null else null


## OP21-04. Is `control` actually inside `scroll`'s own on-screen rect, top and
## bottom, in global coordinates -- the check that catches a broken scroll-follow
## regardless of whether the list happened to fit the viewport already (which
## would make a plain "did scroll_vertical change" assertion pass for the wrong
## reason). A one-pixel epsilon absorbs float rounding in the layout pass.
func _fully_visible_in(control: Control, scroll: ScrollContainer) -> bool:
	var control_rect := control.get_global_rect()
	var scroll_rect := scroll.get_global_rect()
	const EPSILON := 1.0
	return control_rect.position.y >= scroll_rect.position.y - EPSILON \
		and control_rect.position.y + control_rect.size.y <= scroll_rect.position.y + scroll_rect.size.y + EPSILON


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
	await _tap_pad(_pad_button_for("inventory"))
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
		await _tap_pad(_pad_button_for("tool_cycle"))
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
	# Raw d-pad events, not InputEventAction: these must travel through the
	# shipped InputMap and Godot's Control focus machinery exactly as hardware.
	await _tap_pad(JOY_BUTTON_DPAD_RIGHT)
	var after_right := _focused()
	if after_right == start:
		_fail("D-pad Right moved nothing; the keyboard and gamepad columns cannot be reached")
	await _tap_pad(JOY_BUTTON_DPAD_DOWN)
	var after_dpad_down := _focused()
	if after_dpad_down == after_right:
		_fail("D-pad Down moved nothing; only one row could ever be rebound")
	await _tap_pad(JOY_BUTTON_DPAD_UP)
	if _focused() == after_dpad_down:
		_fail("D-pad Up could not return through the settings rows")

	# The left stick is a distinct physical path into the built-in ui_* map.
	# Prove both directions, including neutral release so held-repeat state does
	# not leak into the following capture tests.
	var before_stick := _focused()
	await _tap_axis(JOY_AXIS_LEFT_Y, 1.0)
	var after_stick_down := _focused()
	if after_stick_down == before_stick:
		_fail("left-stick Down moved nothing in Settings")
	await _tap_axis(JOY_AXIS_LEFT_Y, -1.0)
	if _focused() == after_stick_down:
		_fail("left-stick Up could not return through the settings rows")
	if _focused() == null:
		_fail("focus was lost while moving; the screen becomes undrivable")
	print("focus moves by raw D-pad and left-stick events across columns and rows")


## Walk the complete live focus graph from the tab's natural entry focus. Each
## binding row has three enabled actions (keyboard, gamepad, Default), plus the
## three always-visible Settings actions above the scroll list. Comparing the
## actual focused Control at every step catches a gap that a one-row movement
## check cannot: a row may draw correctly yet be skipped by automatic focus.
func _check_all_enabled_controls_are_reachable() -> void:
	if _rows.is_empty():
		return

	# The preceding D-pad/stick check ends on row 0's gamepad cell.
	await _tap_pad(JOY_BUTTON_DPAD_LEFT)
	if _focused() != (_rows[0] as Dictionary)["keyboard"]:
		_fail("could not return to the first keyboard binding from the natural Settings focus")
		return

	var scroll: ScrollContainer = _tab.get("_scroll")
	var start_scroll := scroll.scroll_vertical
	for i in range(1, _rows.size()):
		await _tap_pad(JOY_BUTTON_DPAD_DOWN)
		if _focused() != (_rows[i] as Dictionary)["keyboard"]:
			_fail("D-pad skipped keyboard binding row %d ('%s')" % [i, str((_rows[i] as Dictionary)["action"])])
			return
	await _tap_pad(JOY_BUTTON_DPAD_RIGHT)
	if _focused() != (_rows[-1] as Dictionary)["gamepad"]:
		_fail("D-pad could not cross to the gamepad binding column on the last row")
		return
	for i in range(_rows.size() - 2, -1, -1):
		await _tap_pad(JOY_BUTTON_DPAD_UP)
		if _focused() != (_rows[i] as Dictionary)["gamepad"]:
			_fail("D-pad skipped gamepad binding row %d ('%s')" % [i, str((_rows[i] as Dictionary)["action"])])
			return
	await _tap_pad(JOY_BUTTON_DPAD_RIGHT)
	if _focused() != (_rows[0] as Dictionary)["reset"]:
		_fail("D-pad could not cross to the per-action Default column")
		return
	for i in range(1, _rows.size()):
		await _tap_pad(JOY_BUTTON_DPAD_DOWN)
		if _focused() != (_rows[i] as Dictionary)["reset"]:
			_fail("D-pad skipped Default on row %d ('%s')" % [i, str((_rows[i] as Dictionary)["action"])])
			return
	if scroll.scroll_vertical <= start_scroll:
		_fail("focus reached the bottom Settings row but the ScrollContainer never followed it")

	# Return up the Default column, then continue through the three enabled
	# non-row actions. Debug destination buttons are hidden while their toggle
	# is off, so they are deliberately not part of this enabled-control count.
	for i in range(_rows.size() - 2, -1, -1):
		await _tap_pad(JOY_BUTTON_DPAD_UP)
		if _focused() != (_rows[i] as Dictionary)["reset"]:
			_fail("D-pad could not return through Default row %d" % i)
			return
	var settings_actions: Array[Button] = [
		_tab.get("_reset_all_button") as Button,
		_tab.get("_debug_teleport_button") as Button,
		_tab.get("_free_build_button") as Button,
	]
	for expected: Button in settings_actions:
		await _tap_pad(JOY_BUTTON_DPAD_UP)
		if _focused() != expected:
			_fail("D-pad could not reach Settings action '%s'" % expected.text.strip_edges())
			return

	print("physical D-pad reaches all %d binding actions plus all always-visible Settings actions; scrolling follows" % (_rows.size() * 3))


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
##
## OW5E: was asserting `contains("backpack")`, the tab's PRE-OW1-remainder
## name. `menu.json`'s own `_comment_ow1_remainder_label` renamed the label the
## clash message reads (`_label_of("inventory")`) from "Backpack" to
## "Open the satchel" — `tab_backpack.gd`'s own vocabulary, which the tab row
## label was changed to MATCH, not the other way around. The clash detection
## itself is correct (`inventory` really is bound to I and really does fire
## alongside a `map` rebound onto I); only this assertion still named the
## pre-rename tab.
func _check_a_clash_is_named_out_loud() -> void:
	await _open_capture("map", "keyboard")
	await _tap_key(KEY_I)
	if _code("map", "keyboard") != "key:%d" % KEY_I:
		_fail("the clashing binding was refused instead of taken")
	var said := _status()
	if not said.to_lower().contains("satchel"):
		_fail("the clash with the satchel was not named: '%s'" % said)
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


## OF26. Off by default and its list hidden; the toggle shows it; a region and
## a spoke road-end both compute the promised `ground_height_at(x,z) +
## DEBUG_TELEPORT_CLEARANCE` position exactly; pressing a row's button also
## teleports and closes the menu; the toggle hides the list again.
## `debug_teleport` is checked, not read through code — every assertion below
## is against `GameState`/the live `Player`, the same "the game agrees, not
## just the model" standard `_check_a_key_can_be_rebound` already holds
## itself to for key bindings.
##
## The precise position/y math is checked by calling `debug_teleport_to`
## DIRECTLY, still inside the (paused) menu, not through a button press: the
## menu closing on a successful teleport (brief's own "press A = teleport,
## close the menu") unpauses the tree, and `_press()`'s own several-frame
## settle then gives real gravity real physics ticks to run before this test
## can look — a player teleported 2m above ground legitimately falls the rest
## of the way once play resumes, which is correct in-game behaviour, not a
## bug in the math it started from. Confirmed live: the same "River Road"
## spoke end used here, checked a few frames after a button press instead of
## synchronously, showed the world's own carve failsafe relocating the player
## entirely (`severed_spokes.gd`'s "went over the edge ... back to the road")
## — a real system doing its real job, and exactly why this test does not
## try to pin an exact position down once physics has had a turn.
func _check_debug_teleport() -> void:
	if _game == null:
		_fail("no Game autoload to test debug teleport against")
		return

	await _ensure_on_settings()

	if bool(_game.get("debug_teleport")):
		_fail("debug_teleport was already on; earlier checks left it on")
	var section: Control = _tab.get("_teleport_section")
	if section == null or section.visible:
		_fail("the teleport list is visible while the toggle is off")

	var village := _teleport_entry("The Village")
	if not village.is_empty():
		_fail("'The Village' should have been deduped into 'Grandpa's Village'")

	var toggle: Button = _tab.get("_debug_teleport_button")
	if toggle == null:
		_fail("there is no debug teleport toggle")
		return
	toggle.grab_focus()
	await process_frame
	await _press("ui_accept")
	if not bool(_game.get("debug_teleport")):
		_fail("pressing the debug teleport toggle did not turn it on")
		return
	section = _tab.get("_teleport_section")
	if section == null or not section.visible:
		_fail("the teleport list stayed hidden after the toggle turned on")
		return
	print("debug teleport toggles on and its list appears")

	# The toggle remains focused after activation. Every now-visible destination
	# must join its D-pad Down chain in authored order; hidden controls are not
	# allowed to appear between them or steal focus.
	#
	# OP21-04: focus reaching a row is not the same as the player being able to
	# SEE it — Godot moves logical focus through an off-screen Control exactly
	# as readily as an on-screen one, which is the false-positive shape this
	# test used to have (it drove every row and never once looked at whether
	# anything actually scrolled). At the project's authored 1920x1080 test
	# resolution the 18-destination list fits without scrolling at all, so
	# proving scroll-follow here means shrinking to the ROG Ally's actual
	# handheld viewport (1280x800, the acceptance target this task names) for
	# the walk, the same `root.size = ...` pattern
	# tests/smoke_build_menu_footprint.gd already uses to pin a viewport size.
	var handheld_size := Vector2i(1280, 800)
	var desktop_size := root.size
	root.size = handheld_size
	await process_frame
	await process_frame

	var scroll: ScrollContainer = _tab.get("_scroll")
	var visible_destinations: Array = _tab.get("_teleport_rows")
	for i in visible_destinations.size():
		await _tap_pad(JOY_BUTTON_DPAD_DOWN)
		var expected: Button = (visible_destinations[i] as Dictionary)["button"]
		if _focused() != expected:
			_fail("D-pad could not reach visible debug destination %d ('%s')" % [
				i, str((visible_destinations[i] as Dictionary).get("display_name", "?"))
			])
			root.size = desktop_size
			return
		# The strongest form of "the player can see this": the focused row's own
		# rect actually overlaps the scroll container's visible viewport, not
		# just "some scroll value changed" (which proves nothing if the list
		# happened to already fit). `ensure_control_visible` keeps a control at
		# least partially onscreen; require full containment on the vertical
		# axis, since a control that is merely clipped at its very edge is a
		# real regression on a 7-inch handheld held at arm's length.
		if not _fully_visible_in(expected, scroll):
			_fail("debug destination %d ('%s') has focus but is scrolled out of view at %s" % [
				i, str((visible_destinations[i] as Dictionary).get("display_name", "?")), handheld_size
			])
			root.size = desktop_size
			return
	root.size = desktop_size
	await process_frame
	print("physical D-pad reaches all %d enabled debug destinations at %s; scrolling follows" % [
		visible_destinations.size(), handheld_size
	])

	# One region + one spoke end, checked exactly, synchronously, while the
	# menu (and so the world) is still paused.
	#
	# OW5E: expectations are DERIVED from the same config the corridor's own
	# relocation table (docs/MEADOWS_MACRO_LAYOUT.md section 10) moves — the
	# `the_pond` region's centre and the `river_gorge` spoke's own road-end —
	# rather than a pasted-in coordinate. A pasted literal is exactly what went
	# stale here once already (the pre-corridor (-92,100)/(-90.1,169.5) this
	# replaced); deriving it means the next re-siting (OW6 or later) cannot
	# break this assertion just by moving a place, the way `test_map_state.gd`
	# derives its fog-count expectation from `map.reveal_radius` instead of a
	# magic number.
	var pond := _teleport_entry("The Pond")
	if pond.is_empty():
		_fail("'The Pond' is not in the teleport list")
	else:
		_check_teleport_math(pond.get("position", Vector2.ZERO), _expected_region_centre("the_pond"), "The Pond")

	var river := _teleport_entry("River Road")
	if river.is_empty():
		_fail("'River Road' is not in the teleport list")
	else:
		_check_teleport_math(river.get("position", Vector2.ZERO), _expected_spoke_end("River Road"), "River Road")

	if not bool(_menu.call("is_open")):
		_fail("the direct teleport calls above closed the menu; they should only move the player")

	# One real button press end to end: a spoke with no carve/failsafe of its
	# own (mountain_trail's blocker is a rockslide -- props and collision
	# only, per terrain_playground.json's own blocker-kind comment), so a few
	# settling frames of real gravity cannot also trigger a relocation and
	# muddy what this is actually checking: that the ROW works and closes
	# the menu, landing at the right (x, z) -- gravity only ever moves y.
	var mountain := _teleport_entry("Mountain Road")
	if mountain.is_empty():
		_fail("'Mountain Road' is not in the teleport list")
	else:
		await _check_teleport_button(mountain, _expected_spoke_end("Mountain Road"), "Mountain Road")
	await _ensure_on_settings()

	var toggle_off: Button = _tab.get("_debug_teleport_button")
	if toggle_off == null:
		_fail("the debug teleport toggle did not survive a rebuild")
		return
	toggle_off.grab_focus()
	await process_frame
	await _press("ui_accept")
	if bool(_game.get("debug_teleport")):
		_fail("pressing the debug teleport toggle a second time did not turn it off")
	var section_off: Control = _tab.get("_teleport_section")
	if section_off != null and section_off.visible:
		_fail("the teleport list stayed visible after the toggle turned off")
	else:
		print("debug teleport toggles off and its list hides")


## A region's authored centre, read straight off the live `MapState` (the same
## object `debug_teleport_destinations()` itself reads regions from) rather
## than a coordinate pasted into this file. `data/config/map_landmarks.json`
## is the one source of truth for where a region sits; this reads it back
## through `map.regions()` instead of duplicating it, so re-siting a region
## only ever means editing that JSON.
func _expected_region_centre(region_id: String) -> Vector2:
	var map: RefCounted = _game.get("map") if _game != null else null
	if map == null:
		return Vector2.ZERO
	for region: Dictionary in (map.call("regions") as Array):
		if str(region.get("id", "")) == region_id:
			return region.get("centre", Vector2.ZERO)
	return Vector2.ZERO


## A severed spoke's own road-end, read straight from
## `data/config/terrain_playground.json` — the same file and the same
## "road[].back(), labelled from its own sign" rule
## `GameState._debug_teleport_spokes()` uses, kept independent of that private
## method rather than calling it, so this is still checking the destination
## list against the source data and not just against itself.
func _expected_spoke_end(sign_label: String) -> Vector2:
	var file := FileAccess.open(GAME_STATE.TERRAIN_PLAYGROUND_PATH, FileAccess.READ)
	if file == null:
		return Vector2.ZERO
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return Vector2.ZERO
	var spokes: Variant = (parsed as Dictionary).get("spokes", {})
	if typeof(spokes) != TYPE_DICTIONARY:
		return Vector2.ZERO
	var routes: Variant = (spokes as Dictionary).get("routes", [])
	if typeof(routes) != TYPE_ARRAY:
		return Vector2.ZERO
	for entry: Variant in routes as Array:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var route := entry as Dictionary
		var sign: Dictionary = route.get("sign", {}) as Dictionary
		if str(sign.get("label", route.get("id", ""))) != sign_label:
			continue
		var road: Variant = route.get("road", [])
		if typeof(road) != TYPE_ARRAY or (road as Array).is_empty():
			continue
		var end: Variant = (road as Array).back()
		if typeof(end) != TYPE_ARRAY or (end as Array).size() < 2:
			continue
		return Vector2(float((end as Array)[0]), float((end as Array)[1]))
	return Vector2.ZERO


## `_teleport_rows` is torn down and rebuilt every time the Settings tab's
## `build()` reruns (forced on every `open()`/`select()`), so this always
## reads the CURRENT rows rather than a set captured once and gone stale.
func _teleport_entry(display_name: String) -> Dictionary:
	var rows: Array = _tab.get("_teleport_rows")
	for record: Variant in rows:
		if str((record as Dictionary).get("display_name", "")) == display_name:
			return record as Dictionary
	return {}


## Calls `GameState.debug_teleport_to` directly — no button, no awaited
## frame — and checks the result immediately: with the menu still open (the
## tree still paused), nothing else can move the player between the call and
## this read. Exactly the "assert player position matches expected coords, y
## is at ground+clearance" check the brief asks for, pinned to the one moment
## it is actually true.
func _check_teleport_math(entry_pos: Vector2, expected_xz: Vector2, label: String) -> void:
	if not entry_pos.is_equal_approx(expected_xz):
		_fail("%s is listed at (%.1f,%.1f), expected (%.1f,%.1f)" % [
			label, entry_pos.x, entry_pos.y, expected_xz.x, expected_xz.y
		])

	if not bool(_game.call("debug_teleport_to", expected_xz.x, expected_xz.y)):
		_fail("debug_teleport_to refused %s" % label)
		return

	var player: Node3D = _game.call("find_player") as Node3D
	if player == null:
		_fail("teleporting to %s: no Player to check" % label)
		return
	var pos: Vector3 = player.global_position
	if not is_equal_approx(pos.x, expected_xz.x) or not is_equal_approx(pos.z, expected_xz.y):
		_fail("teleporting to %s landed at (%.1f,%.1f), expected (%.1f,%.1f)" % [
			label, pos.x, pos.z, expected_xz.x, expected_xz.y
		])

	var world: Node = current_scene
	var ground: float = float(world.call("ground_height_at", expected_xz.x, expected_xz.y))
	var expected_y := ground + float(GAME_STATE.DEBUG_TELEPORT_CLEARANCE)
	if not is_equal_approx(pos.y, expected_y):
		_fail("teleporting to %s landed at y=%.2f, expected ground(%.2f) + clearance(%.2f) = %.2f" % [
			label, pos.y, ground, GAME_STATE.DEBUG_TELEPORT_CLEARANCE, expected_y
		])
	print("debug_teleport_to(%s): (%.1f, %.2f, %.1f), exactly ground + clearance" % [label, pos.x, pos.y, pos.z])


## Presses the row's own button — the real controller path, `ui_accept` on a
## focused row — and checks what that path can still promise once gravity has
## had a few real ticks: the same (x, z) the row named, and a closed menu.
func _check_teleport_button(entry: Dictionary, expected_xz: Vector2, label: String) -> void:
	var button: Button = entry.get("button")
	if button == null:
		_fail("%s has no row button" % label)
		return
	button.grab_focus()
	await process_frame
	await _press("ui_accept")
	for i in 6:
		await process_frame

	if bool(_menu.call("is_open")):
		_fail("pressing %s's row did not close the menu" % label)

	var world: Node = current_scene
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D if world != null else null
	if player == null:
		_fail("pressing %s's row: no Player to check" % label)
		return
	var pos: Vector3 = player.global_position
	if not is_equal_approx(pos.x, expected_xz.x) or not is_equal_approx(pos.z, expected_xz.y):
		_fail("pressing %s's row landed at (%.1f,%.1f), expected (%.1f,%.1f)" % [
			label, pos.x, pos.z, expected_xz.x, expected_xz.y
		])
	print("pressing %s's row teleported to (%.1f, %.2f, %.1f) and closed the menu" % [
		label, pos.x, pos.y, pos.z
	])


## Reopens the pause menu on the Settings tab if a teleport (or anything else)
## just closed it, and re-selects it if some other tab is current — so every
## caller here can assume the menu is open on Settings and `_tab`'s handles
## are fresh, without repeating the tab-row walk
## `_check_the_tab_is_reachable_with_a_pad` already did once.
func _ensure_on_settings() -> void:
	if not bool(_menu.call("is_open")):
		_menu.call("open", "settings")
		for i in 6:
			await process_frame
		return
	var tabs: Array = _menu.get("_tabs")
	var wanted := -1
	for i in tabs.size():
		if str((tabs[i] as Dictionary).get("id", "")) == "settings":
			wanted = i
	if wanted >= 0 and int(_menu.get("_index")) != wanted:
		_menu.call("select", wanted)
		for i in 6:
			await process_frame


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
