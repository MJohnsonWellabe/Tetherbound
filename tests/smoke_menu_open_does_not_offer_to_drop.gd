extends SceneTree

## Opening the pause menu with a full satchel must not offer to destroy an item.
##
##   godot --headless --path . --script tests/smoke_menu_open_does_not_offer_to_drop.gd
##
## Gamepad Start is two live actions at once: `game_menu`, which opens the pause
## shell, and `backpack_drop` on the satchel tab (project.godot;
## data/config/menu.json's Backpack group note explains why drop sits there).
## `game_menu.gd` had worked out one half of that collision -- that Menu must
## not ALSO close the shell -- and missed the other. The press that OPENS the
## shell is still down when the satchel tab becomes visible, so
## `tab_backpack.gd::_read_drop()` read it and opened a "Drop it?" confirmation
## on whatever slot held focus. That confirmation calls `hold_input(true)`, so
## the shell then stopped reading its own actions: the player's next B cancelled
## a drop they never asked for instead of closing the menu, and RB would not
## change tab either. One stray A and an item they never selected is gone.
##
## Two assertions, because either alone passes for the wrong reason: an empty
## satchel has nothing to drop, and a shell that refuses to open has nothing to
## confirm. So this stocks the satchel first, and checks BOTH that no
## confirmation appeared AND that one B closes the menu.
##
## Real `InputEventJoypadButton` through the live InputMap, per
## docs/AGENT_WORKFLOW.md -- an `Input.action_press` of `game_menu` alone would
## never reproduce this at all, because the whole bug is one physical button
## resolving to two actions.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _button_for(action: String) -> int:
	if not InputMap.has_action(action):
		return -1
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			return button.button_index
	return -1


func _pad(index: int) -> void:
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
	for _i in 10:
		await process_frame


func _backpack_tab(menu: Node) -> Node:
	for node in menu.find_children("*", "", true, false):
		var script := node.get_script() as Script
		if script != null and str(script.resource_path).ends_with("tab_backpack.gd"):
			return node
	return null


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for _i in SETTLE_FRAMES:
		await physics_frame

	var game: Node = root.get_node_or_null(^"Game")
	var menu: Node = game.get_node_or_null(^"GameMenu") if game != null else null
	if game == null or menu == null:
		_fail("real Meadows boot is missing Game/GameMenu")
		_report()
		return

	# The condition. An empty satchel cannot reproduce this: `_read_drop()`
	# says "Nothing there to drop" and returns before the confirmation.
	var inventory: RefCounted = game.get("inventory")
	for id in ["wood", "stone", "fiber"]:
		inventory.call("add", id, 5)
	for _i in 30:
		await process_frame

	var open_button := _button_for("game_menu")
	var close_button := _button_for("menu_cancel")
	if open_button < 0 or close_button < 0:
		_fail("game_menu or menu_cancel has no joypad button; a pad cannot drive this at all")
		_report()
		return

	var tab := _backpack_tab(menu)
	if tab == null:
		_fail("the shell has no backpack tab, so this proves nothing")
		_report()
		return

	for round_index in 2:
		await _pad(open_button)
		if not bool(menu.call("is_open")):
			_fail("round %d: Menu did not open the shell" % (round_index + 1))
			_report()
			return
		if int(tab.get("_confirming")) >= 0:
			_fail("round %d: opening the shell raised a drop confirmation on slot %d -- the opening press reached backpack_drop"
				% [round_index + 1, int(tab.get("_confirming"))])
		if bool(menu.get("_deaf")):
			_fail("round %d: the shell opened deaf, so its own buttons do nothing" % (round_index + 1))

		await _pad(close_button)
		if bool(menu.call("is_open")):
			_fail("round %d: one B did not close the shell -- something ate the press" % (round_index + 1))
			_report()
			return

	if _failures.is_empty():
		print("pause menu opens on a full satchel without offering to drop anything, and closes on one B")
	_report()


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL: %s" % message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		quit(0)
		return
	print("%d failure(s)" % _failures.size())
	quit(1)
