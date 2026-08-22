extends SceneTree

## OP21-02: does the Satchel own its own navigation, or does the hotbar hear
## it underneath?
##
##   godot --headless --path . --script tests/smoke_satchel_owns_hotbar.gd
##
## Owner report: "While the Satchel is open, the same controller input also
## moves/changes hotbar state." Recon before this test existed found the
## pause architecture already closes this one: `game_menu.gd::open()`
## (line ~319) sets `get_tree().paused = true`, and `PlaygroundHUD` is
## `PROCESS_MODE_PAUSABLE`, so `_read_hotbar_input()` (the HUD poll that
## reads `hotbar_2`) does not run at all while the menu is up -- unlike
## `build_menu.gd`, which deliberately does NOT pause (Valheim-style live
## build) and needed `input_owner.gd` to close the same hole
## (`smoke_menu_owns_dpad.gd`). The Satchel has no such special case to get
## wrong; the pause shell already stops the poll cold. This test is the
## regression the owner explicitly asked for regardless -- an evidence-backed
## "already fixed" still needs the proof on file, per `CLAUDE.md`.
##
## Both directions are checked, the same reason `smoke_menu_owns_dpad.gd`
## checks both: proving nothing fired under the menu would also pass if the
## hotbar binding were simply dead, and proving the d-pad reaches the Satchel
## grid at all is the second half of the owner's sentence ("the same
## controller input" has to land somewhere real, not just land nowhere).
##
## Real `InputEventJoypadButton`/`InputEventAction` through the live input
## surface, not method calls -- `ralph/conventions.md`: a poll-only press
## cannot move Control focus.

const HUD_SCENE := "res://scenes/ui/playground_hud.tscn"

## `hotbar_2` is d-pad LEFT (project.godot: joypad button 13) -- the same
## physical d-pad Godot's `ui_left` drives Control focus with, and the exact
## pair `smoke_menu_owns_dpad.gd` uses for Build.
const HOTBAR_ACTION := "hotbar_2"
const HOTBAR_INDEX := 1

## Same choice `smoke_menu_owns_dpad.gd` makes and for the same reason: a
## potion auto-targets and refuses with an empty party either way, which
## would make "did not fire" true in both the leak and the fixed case. A tool
## slot equips deterministically on press.
const TOOL_ID := "axe"

const SETTLE_FRAMES := 10

var _failures: Array[String] = []
var _game: Node = null
var _hud: Node = null
var _menu: CanvasLayer = null


func _init() -> void:
	_run()


func _run() -> void:
	for i in SETTLE_FRAMES:
		await process_frame

	_game = root.get_node_or_null(^"Game")
	if _game == null:
		print("FAIL: the Game autoload is not in the tree")
		quit(1)
		return
	_menu = _game.call("menu") as CanvasLayer
	if _menu == null:
		print("FAIL: Game has no mounted menu")
		quit(1)
		return

	var packed: PackedScene = load(HUD_SCENE)
	if packed == null:
		print("FAIL: could not load %s" % HUD_SCENE)
		quit(1)
		return
	_hud = packed.instantiate()
	root.add_child(_hud)
	for i in SETTLE_FRAMES:
		await process_frame

	if not await _stock_the_satchel():
		_report()
		return

	await _check_the_hotbar_actually_fires()
	await _check_the_satchel_takes_the_dpad()

	_report()


## The hotbar has to be live for this test to mean anything -- same reasoning
## as `smoke_menu_owns_dpad.gd::_stock_the_satchel()`.
func _stock_the_satchel() -> bool:
	var inventory: RefCounted = _game.get("inventory")
	if inventory == null:
		_fail("Game has no inventory -- nothing to reach for")
		return false
	inventory.call("add", TOOL_ID, 1)
	if int(inventory.call("count", TOOL_ID)) < 1:
		_fail("could not put a %s in the satchel" % TOOL_ID)
		return false
	var assignments: Array = _game.get("hotbar") as Array
	if assignments.size() <= HOTBAR_INDEX:
		_fail("the hotbar has no slot %d to assign" % HOTBAR_INDEX)
		return false
	assignments[HOTBAR_INDEX] = TOOL_ID
	_game.set("hotbar", assignments)
	print("  ..    %s assigned to bar slot %d (%s)" % [TOOL_ID, HOTBAR_INDEX, HOTBAR_ACTION])
	return true


func _check_the_hotbar_actually_fires() -> void:
	_game.set("equipped_tool", "")
	await _press(HOTBAR_ACTION)
	var equipped := str(_game.get("equipped_tool"))
	if equipped != TOOL_ID:
		_fail("with no menu up, %s equipped nothing (equipped_tool %s) -- the Satchel check below would prove nothing" % [
			HOTBAR_ACTION, "empty" if equipped.is_empty() else equipped,
		])
	else:
		print("  ok    no menu: %s put the %s in hand" % [HOTBAR_ACTION, TOOL_ID])


func _check_the_satchel_takes_the_dpad() -> void:
	if not bool(_menu.call("open", "backpack")):
		_fail("the Satchel would not open -- nothing was tested")
		return
	for i in SETTLE_FRAMES:
		await process_frame
	if not bool(_menu.call("is_open")) or str(_menu.call("current_tab_id")) != "backpack":
		_fail("the Satchel tab did not become current")
		_menu.call("close")
		return
	if not paused:
		_fail("Satchel open without the tree pausing -- the architecture this test pins is gone")

	# Cleared first so the check below cannot pass on a stale value from the
	# press above.
	_game.set("equipped_tool", "")
	var bodies: Array = _menu.get("_bodies")
	var backpack_tab: Control = bodies[int(_menu.get("_index"))] as Control
	var buttons: Array = backpack_tab.get("_buttons") if backpack_tab != null else []

	# Start one slot in from the grid's left edge (slot 1, not slot 0) so the
	# d-pad-left press below has somewhere unambiguous to land inside the
	# grid. Moved directly rather than through input -- this is test setup,
	# not part of what is being proven, and slot 0's own focus_neighbor_left
	# legitimately hands off to the quick-bar row above it, which would make
	# the assertion below fail for the wrong reason.
	if buttons.size() < 2:
		_fail("Satchel open: the backpack grid has fewer than 2 slots -- cannot test moving off the edge")
		_menu.call("close")
		return
	(buttons[1] as Button).grab_focus()
	for i in SETTLE_FRAMES:
		await process_frame
	var focus_before := root.gui_get_focus_owner()
	if focus_before != buttons[1]:
		_fail("Satchel open: could not seat focus on slot 1 to set up the check")
		_menu.call("close")
		return

	await _press(HOTBAR_ACTION)

	var equipped := str(_game.get("equipped_tool"))
	if not equipped.is_empty():
		_fail("Satchel open: %s still fired the hotbar (equipped_tool %s) -- the menu does not own the d-pad" % [
			HOTBAR_ACTION, equipped,
		])
	else:
		print("  ok    Satchel open: %s fired nothing" % HOTBAR_ACTION)

	# The other half of the owner's sentence: the same physical press should
	# land on the Satchel's own navigation. Sent as `ui_left` -- that is what
	# Godot's focus navigation actually listens for, and it is the exact
	# built-in action `hotbar_2` shares its physical d-pad-left button with
	# (project.godot: joypad button 13). Starting from slot 1 (set up above)
	# keeps the expected destination, slot 0, inside the grid.
	await _press("ui_left")
	var focus_after := root.gui_get_focus_owner()
	if focus_before == null:
		_fail("Satchel open: nothing had focus, so the d-pad had nothing to move")
	elif focus_after == null:
		_fail("Satchel open: focus was lost entirely after a d-pad press")
	elif buttons.is_empty():
		_fail("Satchel open: the backpack tab exposed no slot buttons to check focus against")
	elif not buttons.has(focus_after):
		_fail("Satchel open: focus left the satchel grid, landing on %s" % focus_after)
	elif focus_after == focus_before:
		_fail("Satchel open: d-pad right reached the grid but did not move its focus")
	else:
		print("  ok    Satchel open: the d-pad moved focus to slot %d" % buttons.find(focus_after))

	_menu.call("close")
	for i in SETTLE_FRAMES:
		await process_frame


## `Input.action_press` sets the action state the HUD's polling reads but
## never enters the tree, so on its own it cannot move Control focus.
## `parse_input_event` supplies that half. Both are sent because this test
## asserts on both from the same press -- learned on `tests/smoke_menu.gd`.
func _press(action: String) -> void:
	Input.action_press(action)
	_send(action, true)
	await process_frame
	await process_frame
	Input.action_release(action)
	_send(action, false)
	for i in 4:
		await process_frame


func _send(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL  %s" % message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("Satchel owns the d-pad: OK")
		quit(0)
		return
	print("%d failure(s)" % _failures.size())
	quit(1)
