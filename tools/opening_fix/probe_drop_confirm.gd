extends SceneTree
## Reproduce the S02 drop-confirmation from the RUN'S OWN SAVE, not a synthetic one.
## An isolated "stock the satchel and tap Start" test does not reproduce it, so
## this loads the actual S02 exit state and taps Start the way the run did.

const WORLD := "res://scenes/world/meadows_playground.tscn"
const SRC := "/tmp/S02-exit.json"

func _initialize() -> void:
	_run()

func _run() -> void:
	# Autoloads are added after _initialize() returns; give the tree a frame.
	await process_frame
	await physics_frame
	var game := root.get_node_or_null(^"/root/Game")
	if game == null:
		print("no Game autoload"); quit(1); return

	var save: Object = game.get("save_system")
	var dst := ""
	if save != null and save.has_method("slot_path"):
		dst = str(save.call("slot_path", 4))
	if dst.is_empty():
		print("no slot path"); quit(1); return
	DirAccess.make_dir_recursive_absolute(dst.get_base_dir())
	var bytes := FileAccess.get_file_as_bytes(SRC)
	var out := FileAccess.open(dst, FileAccess.WRITE)
	out.store_buffer(bytes); out.close()
	print("seeded slot 4 (%d bytes) -> %s" % [bytes.size(), dst])

	var world: Node = (load(WORLD) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in 400:
		await physics_frame

	if not bool(game.call("load_game", 4)):
		print("load_game(4) FAILED"); quit(1); return
	for i in 240:
		await physics_frame
	print("loaded. party=%s" % str(game.call("party_size") if game.has_method("party_size") else "?"))

	var menu: Node = game.call("menu")
	var tab := _find(menu, "tab_backpack.gd")
	print("before tap: confirming=%s guard=%s open=%s" % [
		str(tab.get("_confirming")), str(tab.get("_ignore_drop_until_release")),
		str(menu.call("is_open"))])

	await _tap("game_menu")
	for i in 40:
		await physics_frame

	var fo := root.get_viewport().gui_get_focus_owner()
	print("AFTER TAP: open=%s tab=%s confirming=%s guard=%s focus=%s" % [
		str(menu.call("is_open")), str(menu.call("current_tab_id")),
		str(tab.get("_confirming")), str(tab.get("_ignore_drop_until_release")),
		str(fo.text) if fo != null and "text" in fo else "-"])

	for i in 5:
		await _tap("menu_tab_right")
	print("AFTER 5x tab_right: tab=%s" % str(menu.call("current_tab_id")))
	quit(0)

func _tap(action: String) -> void:
	var pad: InputEvent = null
	for e in InputMap.action_get_events(StringName(action)):
		if e is InputEventJoypadButton: pad = e; break
	var d := InputEventJoypadButton.new()
	d.button_index = (pad as InputEventJoypadButton).button_index
	d.pressed = true
	Input.parse_input_event(d)
	await process_frame
	await physics_frame
	var u := InputEventJoypadButton.new()
	u.button_index = d.button_index
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
		if r != null: return r
	return null
