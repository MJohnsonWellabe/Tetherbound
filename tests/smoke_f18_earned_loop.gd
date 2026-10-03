extends SceneTree

## Fresh title/opening, earned tools/materials, paid homestead Workbench,
## ordinary walk/touch -> Satchel Home Key -> station Craft -> Save/Load UI
## -> home portal -> original stone. Parsed harness input is disclosed.
## Isolated save-system path is harness setup. Gameplay uses no grants,
## fixtures, actor transforms, private gameplay calls or state edits.
const MATERIALS := preload("res://tests/helpers/gate_a_material_route.gd")
const TRAVEL := preload("res://tests/helpers/f49_portal_travel.gd")
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const GUARDS := preload("res://tests/helpers/f18_player_guards.gd")
const STONE_ID := "meadows_trail_camp"
var game: Node
var failures: Array[String] = []
var travel: RefCounted
var receipts: Array[Dictionary] = []
var _presentation: Node
var _guards: RefCounted

class OpeningDriver extends "res://tests/helpers/fresh_opening_segment.gd":
	var prepare_guards: Callable
	var guards: RefCounted
	func _complete_home_key_lesson() -> bool:
		if not await super._complete_home_key_lesson(): return false
		guards = prepare_guards.call()
		if guards == null or not await guards.protected_drop_and_assign():
			_fail("F18 earned key Drop/binding: " + str(guards.failures) if guards != null else "F18 guards missing")
			return false
		return true
	func _walk_to_and_engage_wild(target: Node3D, budget: int) -> bool:
		if not await super._walk_to_and_engage_wild(target, budget): return false
		if guards == null or not await guards.bound_refusal("combat", _combat):
			_fail("F18 actual tutorial fight key refusal: " + str(guards.failures) if guards != null else "F18 guards missing")
			return false
		return true

class VillageDriver extends "res://tests/helpers/gate_a_npc_gather_segment.gd":
	var guards: RefCounted
	var dialogue_proven := false
	func _wait_dialogue_open(budget: int) -> bool:
		if not await super._wait_dialogue_open(budget): return false
		if dialogue_proven: return true
		if str(_dialogue.get("_runner").call("conversation_id")) != "village_mira_shop_intro":
			_fail("F18 first actual village dialogue was not Mira's earned introduction")
			return false
		if guards == null or not await guards.bound_refusal("dialogue", _dialogue):
			_fail("F18 actual Mira dialogue key refusal: " + str(guards.failures) if guards != null else "F18 guards missing")
			return false
		dialogue_proven = true
		return true

class BuildDriver extends "res://tests/helpers/gate_a_build_segment.gd":
	var open_ui: Callable
	func _open_the_catalogue() -> Node:
		return await open_ui.call()

func _initialize() -> void:
	_run.call_deferred()

func _fail(message: String) -> bool:
	failures.append(message)
	return false

func _report() -> void:
	# Keep earlier protection/refusal evidence even if a later earned step fails.
	if _guards != null:
		receipts.append_array(_guards.receipts)
		_guards.receipts.clear()
	if is_instance_valid(_presentation): _presentation.call("finish")
	print("F18_EARNED_LOOP " + JSON.stringify({"failures": failures, "receipts": receipts,
		"input": "parsed harness actions/joypad axes through production UI", "fixtures": false,
		"setup": "private save-system directory, preserving developer saves"}))
	quit(0 if failures.is_empty() else 1)

func _run() -> void:
	await process_frame
	game = root.get_node(^"Game")
	game.set("save_system", SAVE.new("user://f18_earned_loop_%d/" % Time.get_ticks_usec()))
	var opening_driver := OpeningDriver.new()
	opening_driver.prepare_guards = _prepare_guards
	var opening: Dictionary = await opening_driver.run(self)
	if opening.get("passed") != true:
		_fail("fresh earned opening: " + str(opening.get("failures")))
		_report()
		return
	receipts.append({"phase": "opening", "home_keys": game.get("inventory").count("home_key"),
		"transcript": opening.get("transcript", [])})
	if game.get("inventory").count("home_key") != 1:
		_fail("Grandpa's actual opening did not give exactly one protected Home Key")
		_report()
		return
	if _guards == null or travel == null:
		_fail("earned opening did not initialize its actual-world F18 guards")
		_report()
		return
	receipts.append_array(_guards.receipts)
	_guards.receipts.clear()
	var village_driver := VillageDriver.new()
	village_driver.guards = _guards
	var village: Array[String] = await village_driver.run(self, current_scene, game,
		current_scene.get_node(^"Player"), current_scene.get_node(^"CameraRig"))
	if not village.is_empty():
		_fail("earned village/tools: " + str(village))
		_report()
		return
	if not village_driver.dialogue_proven or int(game.call("hotbar_slot_of", "home_key")) != 4:
		_fail("earned village lost the actual dialogue proof or retained slot-5 Home Key binding")
		_report()
		return
	var stock: Dictionary = await MATERIALS.new().run(self, current_scene, game,
		current_scene.get_node(^"Player"), current_scene.get_node(^"CameraRig"))
	if stock.get("passed") != true:
		_fail("earned material route: " + str(stock.get("failures")))
		_report()
		return
	if not await _build_workbench() or not await _loop():
		_report()
		return
	_report()

func _prepare_guards() -> RefCounted:
	# Called only after the original lesson releases input in the real world;
	# FreshOpening starts on the title, where these dependencies do not exist.
	if current_scene == null or current_scene.get_node_or_null(^"Player") == null: return null
	travel = TRAVEL.new(self, game)
	_guards = GUARDS.new(self, game, travel)
	return _guards

func _walk(target: Vector3, tolerance: float = 2.0) -> bool:
	var player: CharacterBody3D = current_scene.get_node(^"Player")
	var rig: Node3D = current_scene.get_node(^"CameraRig")
	var distance := player.global_position.distance_to(target)
	var nav := NAV.new(self, player, rig, _stick)
	var before: int = player.get("_unstick_count")
	var ok: bool = await nav.walk_to(target, maxi(3600, int(distance * 100.0)), tolerance)
	_stick(0, 0)
	return (ok and player.is_on_floor() and int(player.get("_unstick_count")) == before) \
		or _fail("ordinary grounded walk failed: target=" + str(target) + " actual=" + str(player.global_position))

func _tab(id: String) -> Node:
	var menu: Node = game.call("menu")
	if menu == null or menu.call("is_open") != true:
		await travel.tap("inventory")
		menu = game.call("menu")
	for step in 12:
		if menu.call("current_tab_id") == id:
			return menu.get("_bodies")[int(menu.get("_index"))]
		await travel.tap("menu_tab_right")
	_fail("ordinary menu tabs could not reach " + id)
	return null

func _open_build() -> Node:
	var tab := await _tab("build")
	if tab == null: return null
	await travel.tap("ui_accept")
	for frame in 60:
		await process_frame
		for menu: Node in get_nodes_in_group(&"build_menu"):
			if menu.call("is_open") == true: return menu
	_fail("Build tab input did not open catalogue")
	return null

func _build_workbench() -> bool:
	if game.get("free_build") == true: return _fail("paid build required")
	var stance := Vector3(-6.0, current_scene.get_node(^"Player").global_position.y, 22.0)
	if not await _walk(stance, 0.5): return false
	var driver := BuildDriver.new()
	driver.set("_tree", self)
	driver.set("_game", game)
	driver.set("_world", current_scene)
	driver.set("_player", current_scene.get_node(^"Player"))
	driver.set("_camera_rig", current_scene.get_node(^"CameraRig"))
	driver.open_ui = _open_build
	driver.call("_resolve_move_bindings")
	if not await driver.call("_turn_camera_toward", Vector3(0, 0, -1)) \
		or not await driver.call("_select_piece", "workbench"):
		return _fail("controller Workbench catalogue: " + str(driver.failures))
	for frame in 20: await physics_frame
	var before: Dictionary = {"wood": game.get("inventory").count("wood"), "stone": game.get("inventory").count("stone")}
	var placed: Variant = await driver.call("_place_current", "workbench")
	if placed == null: return _fail("paid Workbench placement: " + str(driver.failures))
	if not await driver.call("_stow_piece_for_travel"): return _fail("cannot stow placed Workbench ghost")
	for frame in 180: await physics_frame
	if game.get("inventory").count("wood") != int(before.wood) - 10 \
		or game.get("inventory").count("stone") != int(before.stone) - 4:
		return _fail("Workbench did not spend actual catalogue price")
	receipts.append({"phase": "paid_workbench", "position": str(placed), "before": before})
	return true

func _loop() -> bool:
	var stone: Node3D = current_scene.get_node_or_null("Waystones/" + STONE_ID)
	if stone == null: return _fail("production world did not mount trail camp waystone")
	if not await _walk(stone.global_position, 2.1): return false
	for frame in 600:
		await physics_frame
		if game.get("local").redesign_character.last_waystones.get("meadows") == STONE_ID: break
	if game.get("local").redesign_character.last_waystones.get("meadows") != STONE_ID:
		return _fail("actual touch never committed this character's stone")
	receipts.append({"phase": "deep_touch", "position": str(current_scene.get_node(^"Player").global_position),
		"waystone": STONE_ID})
	if DisplayServer.get_name() != "headless":
		_presentation = preload("res://tests/helpers/f18_presentation_capture.gd").attach(self, game,
			"res://ralph/reports/HUB/f18/native/earned_%d" % Time.get_ticks_usec())
	if not await travel.home_key(): return _fail("actual Satchel Home Key: " + str(travel.failures))
	if not await _guards.locked_arch(): return _fail("actual locked arch: " + str(_guards.failures))
	receipts.append_array(_guards.receipts)
	_guards.receipts.clear()
	if not await _craft_at_workbench(): return false
	if not await _save_reload(): return false
	var arch: Node3D
	for candidate: Node in get_nodes_in_group(&"portal_arches"):
		if candidate.get("arch_id") == "home": arch = candidate
	if arch == null: return _fail("real Hall home arch absent")
	if not await travel.activate(arch.get_node(^"Interactable")):
		return _fail("actual home portal input: " + str(travel.failures))
	var arrival := preload("res://scripts/world/waystone.gd").resolve_position(current_scene,
		stone.get("_row"), true)
	for frame in 1200:
		await physics_frame
		var player: CharacterBody3D = current_scene.get_node(^"Player")
		if player.is_on_floor() and player.global_position.distance_to(arrival) < 1.0:
			receipts.append({"phase": "portal_return", "position": str(player.global_position), "arrival": str(arrival)})
			return true
	return _fail("real home portal did not return to retained trail camp stone")

func _craft_at_workbench() -> bool:
	var bench: Node3D
	for node: Node in get_nodes_in_group(&"placed_building"):
		if node.get_meta("building_id", "") == "workbench": bench = node
	if bench == null: return _fail("paid homestead Workbench missing")
	var prompt := bench.find_child("CraftInteractable", true, false) as Node3D
	if not await travel.activate(prompt): return _fail("homestead station input: " + str(travel.failures))
	var panel: Node = prompt.get_parent().get("_panel")
	if panel == null or panel.call("is_open") != true: return _fail("actual Workbench did not open Craft")
	var rows: Array = panel.get("_rows")
	var target: Button
	var recipe_id := ""
	var recipe: Dictionary = {}
	for index in rows.size():
		var button: Button = rows[index]
		var id: String = panel.get("_recipe_ids")[index]
		var canonical: Dictionary = game.get("items").recipe(id)
		if not button.disabled and canonical.get("output") is Dictionary:
			target = button
			recipe_id = id
			recipe = canonical
			break
	if target == null: return _fail("earned stock cannot craft any Workbench recipe")
	for step in rows.size() + 3:
		if root.gui_get_focus_owner() == target: break
		await travel.tap("ui_down")
	if root.gui_get_focus_owner() != target: return _fail("ordinary Craft focus could not reach affordable recipe")
	var before: int = game.get("inventory").revision
	var before_receipts: Array = game.get("local").redesign_character.transaction_receipts.duplicate()
	var expected: Dictionary = {}
	for need: Dictionary in recipe.cost:
		expected[need.id] = int(expected.get(need.id, game.get("inventory").count(need.id))) - int(need.n)
	var output: Dictionary = recipe.output
	expected[output.id] = int(expected.get(output.id, game.get("inventory").count(output.id))) + int(output.n)
	await travel.tap("ui_accept")
	for frame in 600:
		await process_frame
		if game.get("inventory").revision != before and panel.get("_station_intent").is_empty(): break
	if game.get("inventory").revision == before or not panel.get("_station_intent").is_empty():
		return _fail("actual Workbench Craft did not complete durable paid action")
	if str(panel.get("_status").text) != "Completed. Saved to your character.":
		return _fail("actual Workbench Craft did not confirm durable owner acceptance")
	for id: String in expected:
		if game.get("inventory").count(id) != expected[id]:
			return _fail("actual recipe debit/output differs for " + id)
	var accepted: Dictionary = {}
	for record: Variant in game.get("world").reward_deliveries.values():
		if record is Dictionary and record.get("action") == "station_craft" \
			and record.get("status") == "accepted" and record.get("character_id") == game.get("local").character_id \
			and record.get("intent", {}).get("recipe_id") == recipe_id \
			and not before_receipts.has(record.get("receipt")) \
			and game.get("local").redesign_character.transaction_receipts.has(record.get("receipt")):
			accepted = record
	if accepted.is_empty(): return _fail("actual recipe has no new host/owner accepted durable receipt")
	receipts.append({"phase": "station_craft", "recipe": recipe_id, "receipt": accepted.receipt, "expected_counts": expected})
	await travel.tap("menu_cancel")
	return true

func _save_reload() -> bool:
	var before: Dictionary = game.get("local").redesign_character.duplicate(true)
	var tab := await _tab("save")
	if tab == null: return false
	var row: Dictionary = tab.get("_rows")[0]
	if root.gui_get_focus_owner() != row.save: return _fail("Save tab did not focus actual Save button")
	await travel.tap("ui_accept")
	var menu: Node = game.call("menu")
	if not str(menu.get("_status").text).contains("Saved to slot 1."):
		return _fail("Save button did not confirm successful production write")
	if game.call("has_save", 0) != true: return _fail("ordinary Save button wrote no slot")
	await travel.tap("ui_right")
	if root.gui_get_focus_owner() != row.load: return _fail("ordinary focus did not reach Load button")
	await travel.tap("ui_accept")
	if not str(menu.get("_status").text).contains("Loaded slot 1."):
		return _fail("Load button did not confirm successful production load")
	await travel.tap("menu_cancel")
	for frame in 60: await physics_frame
	if game.get("local").redesign_character != before or game.get("inventory").count("home_key") != 1:
		return _fail("production Save/Load lost portable travel or protected key")
	receipts.append({"phase": "save_reload", "waystone": game.get("local").redesign_character.last_waystones.get("meadows")})
	return true

func _stick(x: float, y: float) -> void:
	for pair: Array in [[JOY_AXIS_LEFT_X, x], [JOY_AXIS_LEFT_Y, y]]:
		var event := InputEventJoypadMotion.new()
		event.device = 0
		event.axis = int(pair[0])
		event.axis_value = float(pair[1])
		Input.parse_input_event(event)
