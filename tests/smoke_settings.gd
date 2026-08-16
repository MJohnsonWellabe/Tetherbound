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

	# One region + one spoke end, checked exactly, synchronously, while the
	# menu (and so the world) is still paused.
	var pond := _teleport_entry("The Pond")
	if pond.is_empty():
		_fail("'The Pond' is not in the teleport list")
	else:
		_check_teleport_math(pond.get("position", Vector2.ZERO), Vector2(-92.0, 100.0), "The Pond")

	var river := _teleport_entry("River Road")
	if river.is_empty():
		_fail("'River Road' is not in the teleport list")
	else:
		_check_teleport_math(river.get("position", Vector2.ZERO), Vector2(-90.1, 169.5), "River Road")

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
		await _check_teleport_button(mountain, Vector2(-118.9, -107.0), "Mountain Road")
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
