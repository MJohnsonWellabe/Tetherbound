extends SceneTree

## Controller contract for the real code-built Craft panel. All primary input
## begins as a physical joypad event and travels through the live InputMap.

const CRAFT_PANEL := preload("res://scripts/ui/craft_panel.gd")

var _failures: Array[String] = []
var _game: Node = null
var _panel: CanvasLayer = null


func _init() -> void:
	_run()


func _run() -> void:
	for i in 10:
		await physics_frame
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_fail("Game autoload is missing")
		_report()
		return
	var inventory: RefCounted = _game.get("inventory")
	inventory.call("add", "wood", 12)
	inventory.call("add", "stone", 12)
	inventory.call("add", "berries", 8)
	inventory.call("add", "fiber", 4)

	_panel = CRAFT_PANEL.new()
	root.add_child(_panel)
	for i in 8:
		await physics_frame
	_panel.call("open")
	for i in 6:
		await physics_frame

	var rows: Array = _panel.get("_rows")
	var ids: Array = _panel.get("_recipe_ids")
	if rows.is_empty() or ids.is_empty():
		_fail("Craft opened with no recipe rows")
		_report()
		return
	if root.get_viewport().gui_get_focus_owner() != rows[0]:
		_fail("Craft did not focus its first recipe on entry")

	if rows.size() > 1:
		await _tap_pad(JOY_BUTTON_DPAD_DOWN)
		if root.get_viewport().gui_get_focus_owner() != rows[1]:
			_fail("physical D-pad Down did not move between Craft recipes")
		await _tap_pad(JOY_BUTTON_DPAD_UP)
		if root.get_viewport().gui_get_focus_owner() != rows[0]:
			_fail("physical D-pad Up did not return to the first Craft recipe")

	var potion_index := ids.find("potion_small")
	if potion_index < 0:
		_fail("baseline Small Potion is absent from the known Craft recipes")
	else:
		for i in potion_index:
			await _tap_pad(JOY_BUTTON_DPAD_DOWN)
		if root.get_viewport().gui_get_focus_owner() != rows[potion_index]:
			_fail("physical D-pad could not reach the Small Potion recipe")
		var potion_before := int(inventory.call("count", "potion_small"))
		var berries_before := int(inventory.call("count", "berries"))
		await _tap_pad(JOY_BUTTON_A)
		if int(inventory.call("count", "potion_small")) != potion_before + 1:
			_fail("physical A on Small Potion produced no potion")
		if int(inventory.call("count", "berries")) >= berries_before:
			_fail("physical A crafted a potion without spending berries")
		if root.get_viewport().gui_get_focus_owner() != rows[potion_index]:
			_fail("Craft lost focus after inventory/cost labels refreshed")

	await _tap_pad(JOY_BUTTON_B)
	if bool(_panel.call("is_open")):
		_fail("physical B did not close Craft")
	if paused:
		_fail("closing Craft left the tree paused")

	_report()


func _tap_pad(button_index: int) -> void:
	var down := InputEventJoypadButton.new()
	down.button_index = button_index
	down.pressed = true
	Input.parse_input_event(down)
	for i in 3:
		await physics_frame
	var up := InputEventJoypadButton.new()
	up.button_index = button_index
	up.pressed = false
	Input.parse_input_event(up)
	for i in 5:
		await physics_frame


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("craft panel controller: OK -- navigate, craft, refresh focus, and close use physical pad input.")
		quit(0)
		return
	for line in _failures:
		print("craft panel controller FAIL: %s" % line)
	quit(1)
