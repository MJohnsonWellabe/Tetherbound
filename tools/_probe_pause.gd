extends SceneTree

## Does B close the pause shell after Menu opens it?
const SCENE := "res://scenes/world/meadows_playground.tscn"

func _init() -> void:
	_run()

func _pad(index: int) -> void:
	var down := InputEventJoypadButton.new()
	down.device = 0
	down.button_index = index
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	var up := InputEventJoypadButton.new()
	up.device = 0
	up.button_index = index
	up.pressed = false
	Input.parse_input_event(up)
	for _i in 8:
		await process_frame

func _button_for(action: String) -> int:
	for e in InputMap.action_get_events(action):
		var b := e as InputEventJoypadButton
		if b != null:
			return b.button_index
	return -1

func _state(menu: Node, label: String) -> void:
	# Which backpack sub-mode, if any, is holding the shell deaf. _held is a
	# picked-up stack, _targeting is the Use picker, _confirming is the drop
	# confirmation -- three different callers of menu.hold_input(true).
	var tab: Node = null
	for n in menu.find_children("*", "", true, false):
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("tab_backpack.gd"):
			tab = n
			break
	print("%-22s open=%s deaf=%s tab='%s' paused=%s | held=%s targeting=%s confirming=%s guard=%s" % [
		label, str(menu.call("is_open")), str(menu.get("_deaf")),
		str(menu.call("current_tab_id")), str(paused),
		str(tab.get("_held")) if tab != null else "?",
		str(tab.get("_targeting")) if tab != null else "?",
		str(tab.get("_confirming")) if tab != null else "?",
		str(tab.get("_open_guard")) if tab != null else "?"])

func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for _i in 240:
		await physics_frame
	var game: Node = root.get_node_or_null(^"Game")
	var menu: Node = game.get_node_or_null(^"GameMenu")
	print("menu node=", menu, " process_mode=", menu.process_mode if menu != null else "n/a")
	# The clean-state round trip already passed. What the post-modal stress run
	# has that the clean state does not is a satchel with things in it: its
	# backpack grid then builds focusable slot buttons, and the shell opens
	# with focus inside that grid. Seed the same condition and ask again.
	var inv: RefCounted = game.get("inventory")
	for id in ["wood", "stone", "fiber", "berry", "axe", "pickaxe"]:
		inv.call("add", id, 5)
	for _i in 30:
		await process_frame
	var open_b := _button_for("game_menu")
	var close_b := _button_for("menu_cancel")
	print("game_menu button=%d  menu_cancel button=%d" % [open_b, close_b])
	_state(menu, "before")
	await _pad(open_b)
	_state(menu, "after Menu (open)")
	await _pad(close_b)
	_state(menu, "after B (close)")
	# second round trip, to see whether it is only the first that sticks
	await _pad(open_b)
	_state(menu, "after Menu #2")
	await _pad(close_b)
	_state(menu, "after B #2")
	quit(0)
