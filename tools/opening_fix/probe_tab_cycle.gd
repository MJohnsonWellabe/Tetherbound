extends SceneTree
## Developer-lane probe. Does `menu_tab_right` cycle the pause-shell tab?
## S02 attempt 5: the shell opened on `menu_backpack` with focus on 'Drop it',
## and five RB presses left it on `menu_backpack`, so the Save tab was never
## reached and no handoff save was written.

const WORLD := "res://scenes/world/meadows_playground.tscn"

func _initialize() -> void:
	_run()

func _run() -> void:
	var world: Node = (load(WORLD) as PackedScene).instantiate()
	root.add_child(world)
	for i in 400:
		await physics_frame
	var menu := _find(root, "game_menu.gd")
	print("=== tab cycle probe ===  menu=%s" % (menu != null))
	if menu == null:
		quit()
		return

	await _tap("game_menu")
	print("after game_menu: open=%s tab=%s deaf=%s" % [
		str(menu.call("is_open")), str(menu.call("current_tab_id")), str(menu.get("_deaf"))])

	for i in 7:
		await _tap("menu_tab_right")
		print("  tab_right %d -> tab=%s focus=%s" % [i + 1, str(menu.call("current_tab_id")),
			str(root.get_viewport().gui_get_focus_owner())])
	quit()

func _tap(action: String) -> void:
	var pad: InputEvent = null
	for e in InputMap.action_get_events(StringName(action)):
		if e is InputEventJoypadButton:
			pad = e
			break
	if pad == null:
		print("  (no pad binding for %s)" % action)
		return
	var b := InputEventJoypadButton.new()
	b.button_index = (pad as InputEventJoypadButton).button_index
	b.pressed = true
	Input.parse_input_event(b)
	await process_frame
	await physics_frame
	var u := InputEventJoypadButton.new()
	u.button_index = b.button_index
	u.pressed = false
	Input.parse_input_event(u)
	await process_frame
	for i in 20:
		await physics_frame

func _find(from: Node, tail: String) -> Node:
	if from.get_script() != null and str(from.get_script().resource_path).ends_with(tail):
		return from
	for c in from.get_children():
		var r := _find(c, tail)
		if r != null:
			return r
	return null
