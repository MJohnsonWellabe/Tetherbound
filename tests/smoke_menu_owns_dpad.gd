extends SceneTree

## When a menu is up, does the d-pad belong to the menu?
##
##   godot --headless --path . --script tests/smoke_menu_owns_dpad.gd
##
## OW10, from the owner: *"if I have a menu up and hit a dpad button, it still
## reads the hot bar control not to the menu. it tries to use a potion or
## whatever rather than move on the menu."*
##
## The panel is `build_menu.gd`, and naming it took measuring rather than
## guessing. The pause shell does NOT leak: it pauses the tree and
## `PlaygroundHUD` is `PAUSABLE`, so the hotbar poll does not run at all. Six
## panels pause that way. The build menu is the one that deliberately does not —
## the world stays live behind it, which is the Valheim feel it exists for — so
## the HUD keeps polling underneath it, and `hotbar_2`/`hotbar_3`/`hotbar_4` are
## bound to d-pad left/right/down (project.godot: joypad buttons 13/14/12), the
## same d-pad Godot's `ui_*` actions drive grid focus with.
##
## Both directions are checked, because a test that only proves nothing fired
## under the menu would also pass if the hotbar were broken outright:
##
##   1. with no menu up, a `hotbar_2` press FIRES the hotbar — the leak this is
##      about is a real, working hotbar going off at the wrong time, and a dead
##      one would satisfy step 2 for entirely the wrong reason
##   2. with the build menu up, the same press fires NOTHING
##   3. and the d-pad the menu swallowed actually moves the menu's own focus,
##      which is the half the owner asked for ("rather than move on the menu")
##
## Input goes through `Input.parse_input_event` as well as `Input.action_press`.
## Actions set state the HUD's polling reads, but never enter the tree, so on
## their own they cannot move Control focus — a poll-only test would report a
## working menu while the stick moved nothing. Learned on `tests/smoke_menu.gd`.
##
## No world scene: the HUD is its own scene, `Game` is an autoload, and booting
## the meadow costs ten minutes under software GL for a check about one gate.

const HUD_SCENE := "res://scenes/ui/playground_hud.tscn"
const BUILD_MENU := preload("res://scripts/ui/build_menu.gd")

## The bar slot the test fires, and the action bound to it. `hotbar_2` is d-pad
## LEFT (joypad button 13) — the same press that moves a grid selection left.
const HOTBAR_ACTION := "hotbar_2"
const HOTBAR_INDEX := 1

## An axe rather than the potion the owner named, for one reason: the effect has
## to be deterministic with no party standing up. A potion pressed from the bar
## auto-targets the worst-wounded creature and, with an empty party, refuses and
## consumes nothing — so it would read as "did not fire" in BOTH cases and the
## test would pass without proving anything. A tool slot equips on press
## ("press slot, tool in hand"), which is the same `_use_hotbar_slot` path, the
## same poll and the same gate, with a state change that either happened or did
## not.
const TOOL_ID := "axe"

const SETTLE_FRAMES := 10

var _failures: Array[String] = []
var _game: Node = null
var _hud: Node = null


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
	await _check_the_build_menu_takes_the_dpad()

	_report()


## The hotbar has to be live for this test to mean anything. An empty satchel,
## an unassigned bar slot, or a HUD that never wired itself to `Game` would all
## make the menu check pass for the wrong reason — so the item goes in the
## satchel AND onto the bar, and the check above proves the press lands.
func _stock_the_satchel() -> bool:
	var inventory: RefCounted = _game.get("inventory")
	if inventory == null:
		_fail("Game has no inventory — nothing to reach for")
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
		_fail("with no menu up, %s equipped nothing (equipped_tool %s) — the hotbar is not live, so the menu check below would prove nothing" % [
			HOTBAR_ACTION, "empty" if equipped.is_empty() else equipped,
		])
	else:
		print("  ok    no menu: %s put the %s in hand" % [HOTBAR_ACTION, TOOL_ID])


## The report itself. The build menu is open, the world is still running behind
## it, and the d-pad press must reach the menu and nothing else.
func _check_the_build_menu_takes_the_dpad() -> void:
	var menu: CanvasLayer = BUILD_MENU.get_or_make(self)
	menu.call("open")
	for i in SETTLE_FRAMES:
		await process_frame
	if not bool(menu.call("is_open")):
		_fail("the build menu would not open — nothing was tested")
		return

	# Cleared first so the check below cannot pass on a stale value from the
	# press above.
	_game.set("equipped_tool", "")
	var focus_before := root.gui_get_focus_owner()

	await _press(HOTBAR_ACTION)

	var equipped := str(_game.get("equipped_tool"))
	if not equipped.is_empty():
		_fail("build menu open: %s still fired the hotbar (equipped_tool %s) — the menu does not own the d-pad" % [
			HOTBAR_ACTION, equipped,
		])
	else:
		print("  ok    build menu open: %s fired nothing" % HOTBAR_ACTION)

	# The other half of the owner's sentence: the press should MOVE ON THE MENU.
	# Sent as `ui_left` because that is what a d-pad press is to a focused
	# Control — `hotbar_2` shares the physical button, but only `ui_left` is
	# what Godot's focus navigation listens for.
	await _press("ui_left")
	var focus_after := root.gui_get_focus_owner()
	if focus_before == null:
		_fail("build menu open: nothing had focus, so the d-pad had nothing to move")
	elif focus_after == null:
		_fail("build menu open: focus was lost entirely after a d-pad press")
	else:
		var cells: Array = menu.get("_cell_buttons")
		if not cells.has(focus_after):
			_fail("build menu open: focus left the grid, landing on %s" % focus_after)
		else:
			print("  ok    build menu open: the d-pad moved focus to cell %d" % cells.find(focus_after))

	menu.call("close")
	for i in SETTLE_FRAMES:
		await process_frame


## `Input.action_press` sets the action state, which is what the HUD's own
## polling reads. It does NOT put an event through the tree, so on its own it
## cannot move Control focus. `parse_input_event` supplies that half. Both are
## needed here because this test asserts on both at once — the poll must not
## fire and the focus must move, from the same press.
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
		print("menu owns the d-pad: OK")
		quit(0)
		return
	print("%d failure(s)" % _failures.size())
	quit(1)
