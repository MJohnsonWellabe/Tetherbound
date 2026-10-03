extends SceneTree

## Real Build menu and the continuous campaign's native joypad selector.
## Inventory and open-menu setup are declared fixtures; no world placement,
## resource earning, combat or campaign claim.
const DRIVER := preload("res://tests/helpers/gate_b_tail_segment.gd")
const MENU := preload("res://scripts/ui/build_menu.gd")
var assertions := 0
var failures: Array[String] = []

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var game: Node = root.get_node("Game")
	game.reset_for_new_game()
	for item: String in ["wood", "stone", "fiber"]: game.inventory.add(item, 100)
	var menu := MENU.new()
	root.add_child(menu)
	menu.open()
	for frame in 16: await process_frame
	var driver := DRIVER.new()
	driver._tree = self
	driver._game = game
	var ids: Array = menu._cell_buttons.map(func(cell: Button) -> String: return driver._cell_id(cell))
	_check(ids == ["tent", "campfire", "bedroll", "forward_camp"], "actual parallel catalogue IDs remain distinct")
	var tent: TextureRect = menu._cell_buttons[0].find_children("*", "TextureRect", true, false)[0]
	var forward: TextureRect = menu._cell_buttons[3].find_children("*", "TextureRect", true, false)[0]
	_check(tent.texture.resource_path == forward.texture.resource_path, "negative-control pair really shares its thumbnail")
	_check(game.can_afford("tent") and not game.can_afford("forward_camp"), "stock can pay the tent and cannot pay a forward camp")
	_check(await driver._select_piece("tent"), "native selector presses the actual Tent button")
	_check(game.pending_build == "tent" and not menu.is_open(), "actual Tent pick arms Tent and closes the real menu")
	_check(driver.failures.is_empty(), "earned selector has no failure for payable Tent")
	game.pending_build = "" # Next isolated menu case, no placement fixture.
	menu.open()
	for frame in 16: await process_frame
	_check(not await driver._select_piece("forward_camp"), "same thumbnail cannot bypass the actual forward-camp cost")
	_check(game.pending_build == "" and menu.is_open(), "unpayable Forward Camp leaves no ghost armed")
	_check(menu._message.text.contains("Forward-camp kit"), "actual cost refusal names the missing kit")
	driver.failures.clear() # The preceding refusal is an explicit negative control.
	for need: Dictionary in game.build_cost_for("forward_camp"): game.inventory.add(need.id, need.n)
	_check(game.can_afford("forward_camp"), "declared kit fixture makes the separate item affordable")
	_check(await driver._select_piece("forward_camp"), "native selector can also choose the separate Forward Camp")
	_check(game.pending_build == "forward_camp" and not menu.is_open(), "actual Forward Camp pick arms its own canonical ID")
	_check(driver.failures.is_empty(), "paid Forward Camp choice introduces no selector failure")
	menu.free()
	print("F19 BUILD CATALOGUE IDENTITY " + JSON.stringify({"assertions": assertions, "failures": failures}))
	quit(0 if failures.is_empty() else 1)

func _check(value: bool, message: String) -> void:
	assertions += 1
	if not value: failures.append(message)
