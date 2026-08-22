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
	print("%-22s open=%s deaf=%s tab='%s' paused=%s" % [
		label, str(menu.call("is_open")), str(menu.get("_deaf")),
		str(menu.call("current_tab_id")), str(paused)])

func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for _i in 240:
		await physics_frame
	var game: Node = root.get_node_or_null(^"Game")
	var menu: Node = game.get_node_or_null(^"GameMenu")
	print("menu node=", menu, " process_mode=", menu.process_mode if menu != null else "n/a")
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
