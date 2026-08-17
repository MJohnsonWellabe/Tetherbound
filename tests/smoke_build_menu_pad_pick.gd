extends SceneTree

## Can a CONTROLLER choose a build piece?
##
##   godot --headless --path . --script tests/smoke_build_menu_pad_pick.gd
##
## UI-PAD1. The owner's OW11 report was that building "needs to work how Valheim
## does" and that the menu was unreadable. OW11 fixed the reading. It did not
## fix the pressing, and nothing caught that, because **no test in this repo
## chose a build piece through input**: `tests/smoke_free_build.gd` says so in
## its own header and arms `GameState.pending_build` directly, and
## `tests/smoke_build_menu_footprint.gd` calls `_select_category` directly.
##
## What they were both stepping over: `ui_accept` had no joypad event at all,
## and a Godot `Button` activates on `ui_accept`. The build menu's cells are
## plain Buttons. So on a pad the grid could be walked and never pressed —
## `pending_build` stayed empty, the menu stayed open, and a controller-first
## game shipped with no way to place a building.
##
## This presses a real `InputEventJoypadButton` and nothing else. An
## `InputEventAction` would name the action directly and never travel the
## InputMap, which is exactly the blind spot that let the bug through — see
## `tests/smoke_backpack_pad_target.gd`, which learned the same lesson on the
## potion picker.

const BUILD_MENU := preload("res://scripts/ui/build_menu.gd")
const SETTLE := 12

## Read out of the live InputMap rather than hardcoded, so a rebind moves this
## test with the game instead of leaving it pressing a button nobody uses.
const ACCEPT_ACTION := "ui_accept"

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	for i in SETTLE:
		await process_frame

	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("FAIL: the Game autoload is not in the tree")
		quit(1)
		return

	# Free build so `_pick` cannot refuse on cost — this test is about whether
	# the press lands, not about the affordability gate `smoke_free_build.gd`
	# already covers.
	game.set("free_build", true)
	game.set("pending_build", "")

	var accept_button := _pad_button_for(ACCEPT_ACTION)
	if accept_button < 0:
		_fail("%s has no joypad binding — a controller cannot press any Button in this game" % ACCEPT_ACTION)
		_report()
		return
	print("  ..    %s is joypad button %d" % [ACCEPT_ACTION, accept_button])

	var menu: CanvasLayer = BUILD_MENU.get_or_make(self)
	menu.call("open")
	for i in SETTLE:
		await process_frame
	if not bool(menu.call("is_open")):
		_fail("the build menu would not open — nothing was tested")
		_report()
		return

	# Focus has to be ON a cell for the press to mean anything. If this fails
	# the test below would pass or fail for reasons that have nothing to do
	# with the binding.
	var cells: Array = menu.get("_cell_buttons")
	var focused := root.gui_get_focus_owner()
	if cells.is_empty():
		_fail("the open category drew no cells")
		_report()
		return
	if not cells.has(focused):
		_fail("focus is not on a grid cell (it is on %s) — the press would have no target" % focused)
		_report()
		return
	print("  ..    focus is on grid cell %d of %d" % [cells.find(focused), cells.size()])

	var before := str(game.get("pending_build"))

	await _pad(accept_button)

	var after := str(game.get("pending_build"))
	var still_open := bool(menu.call("is_open"))

	if after == before:
		_fail("pad button %d did not arm anything: pending_build '%s' -> '%s', menu still open = %s" % [
			accept_button, before, after, still_open,
		])
	elif after.is_empty():
		_fail("pad button %d cleared pending_build instead of arming a piece ('%s' -> '')" % [
			accept_button, before,
		])
	else:
		print("  ok    pad armed a piece: pending_build '%s' -> '%s'" % [before, after])

	# Valheim shape, and the owner's own words: "you get a piece then the menu
	# disappears for you to place it." Arming that leaves the menu up is only
	# half the interaction.
	if still_open:
		_fail("the menu stayed open after a pad pick — the ghost is behind the selector")
	else:
		print("  ok    the menu closed on the pick, leaving the ghost visible")

	_report()


func _pad_button_for(action: String) -> int:
	if not InputMap.has_action(action):
		return -1
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			return button.button_index
	return -1


## A real controller button, the way hardware delivers it.
func _pad(button_index: int) -> void:
	var down := InputEventJoypadButton.new()
	down.button_index = button_index
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	var up := InputEventJoypadButton.new()
	up.button_index = button_index
	up.pressed = false
	Input.parse_input_event(up)
	for i in 6:
		await process_frame


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL  %s" % message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("build menu answers a controller: OK")
		quit(0)
		return
	print("%d failure(s)" % _failures.size())
	quit(1)
