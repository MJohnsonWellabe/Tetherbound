extends SceneTree

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := root.get_node("Game")
	game.call("reset_for_new_game")
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var inventory: RefCounted = game.get("inventory")
	inventory.call("add", "insulated_vest", 1)
	var menu: CanvasLayer = game.call("menu")
	menu.call("open", "backpack")
	for i in 8:
		await process_frame
	var tabs: Array = menu.get("_tabs")
	var bodies: Array = menu.get("_bodies")
	var body: Node
	for i in tabs.size():
		if str(tabs[i].get("id", "")) == "backpack":
			body = bodies[i]
	_check(body != null, "Satchel opened")
	if body == null:
		quit(1)
		return
	var buttons: Array = body.get("_buttons")
	buttons[int(inventory.call("find_slot", "insulated_vest"))].grab_focus()
	await process_frame
	_check(str(body.get("_detail_hint").text).contains("Equip"), "carried armor advertises Equip")
	await _pad("interact")
	var gear: RefCounted = game.get("player_equipment")
	_check(str(gear.call("equipped_in", "upper_body")) == "insulated_vest", "controller Use equips vest")
	_check(int(inventory.call("count", "insulated_vest")) == 0, "worn vest left carried inventory")
	var saver: RefCounted = load("res://scripts/save/save_game.gd").new("user://equipment_controller_saves/")
	_check(bool(saver.call("save", game, 1)), "real Game saved worn equipment to disk")
	gear.call("unequip_to_inventory", "upper_body", inventory)
	_check(bool(saver.call("load_slot", game, 1)), "real Game loaded saved equipment")
	_check(str(gear.call("equipped_in", "upper_body")) == "insulated_vest", "disk reload restored worn vest")
	_check(int(inventory.call("count", "insulated_vest")) == 0, "disk reload did not duplicate vest into bag")
	var gear_buttons: Dictionary = body.get("_equipment_buttons")
	_check(gear_buttons.size() == 5, "all five worn slots are exposed")
	gear_buttons.upper_body.grab_focus()
	await process_frame
	_check(str(body.get("_detail_hint").text).contains("Unequip"), "worn slot advertises Unequip")
	await _pad("menu_confirm")
	_check(str(gear.call("equipped_in", "upper_body")) == "", "controller Confirm unequips")
	_check(int(inventory.call("count", "insulated_vest")) == 1, "unequip returned one vest")
	menu.call("close")
	world.queue_free()
	for i in 3:
		await process_frame
	print("BACKPACK EQUIPMENT: %d checks, %d failed" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func _pad(action: String) -> void:
	var index := -1
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			index = event.button_index
			break
	_check(index >= 0, "%s has a controller binding" % action)
	if index < 0:
		return
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
	for i in 4:
		await process_frame

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
	print("%s %s" % ["ok" if ok else "FAIL", message])
