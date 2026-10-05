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
	var _f18_assigning_tools := false
	var _f18_assignment_trace: Array[Dictionary] = []
	var _f18_resource_watch_ids: Dictionary = {}
	func _gather_authored_node(item_id: String, tool_id: String, hotbar_action: StringName) -> bool:
		# Observe the actual resource and outgoing prop without retaining any
		# Material references or changing the inherited gather/input timing.
		var resource: Node3D = _nearest_authored_node(item_id)
		if resource != null: _f18_watch_resource_exit(resource, "harvest:" + item_id)
		var hold: Node = _player.get("tool_hold")
		if hold != null:
			var prop: Node = hold.call("prop_node")
			if is_instance_valid(prop): _f18_watch_resource_exit(prop, "outgoing:" + str(_game.get("equipped_tool")))
		return await super._gather_authored_node(item_id, tool_id, hotbar_action)
	func _f18_watch_resource_exit(node: Node, role: String) -> void:
		var nodes: Array[Node] = [node]
		nodes.append_array(node.find_children("*", "MeshInstance3D", true, false))
		for observed: Node in nodes:
			var instance_id := observed.get_instance_id()
			# The held axe can still be the same actual prop when the next
			# resource approach begins. Connect its lifetime observer once.
			if _f18_resource_watch_ids.has(instance_id): continue
			_f18_resource_watch_ids[instance_id] = true
			var path := str(observed.get_path())
			observed.tree_exiting.connect(_f18_resource_exit.bind("exiting", role, path, instance_id), CONNECT_ONE_SHOT)
			observed.tree_exited.connect(_f18_resource_exit.bind("exited", role, path, instance_id), CONNECT_ONE_SHOT)
			_f18_resource_exit("watch", role, path, instance_id)
	func _f18_resource_exit(event: String, role: String, path: String, instance_id: int) -> void:
		print("F18_RESOURCE_LIFETIME " + JSON.stringify({"event": event, "role": role, "path": path,
			"instance_id": instance_id, "process_frame": Engine.get_process_frames(), "physics_frame": Engine.get_physics_frames()}))
	func _assign_tools_in_satchel() -> bool:
		var initial: Dictionary = _f18_tool_observation()
		var inventory_before: Array = guards._inventory()
		_f18_assignment_trace.clear()
		_f18_assigning_tools = true
		# Keep the original four destinations, reverse order, focus algorithm,
		# one-cycle bound, menu close and actual movement-resumed proof.
		var passed: bool = await super._assign_tools_in_satchel()
		_f18_assigning_tools = false
		var final: Dictionary = _f18_tool_observation()
		var retained: bool = int(_game.call("hotbar_slot_of", "home_key")) == 4 \
			and guards._inventory() == inventory_before
		guards.receipts.append({"phase": "earned_tool_bindings", "initial": initial,
			"assignment_presses": _f18_assignment_trace.duplicate(true), "final": final,
			"input": "actual InputMap joypad edges, each flushed through a process frame; original 3/5 physics minima",
			"original_cycle_bound": 6, "home_key_slot": 4, "inventory_unchanged": guards._inventory() == inventory_before,
			"passed": passed and retained})
		if passed and not retained: _fail("F18 ordinary tool assignment lost key slot5 or changed earned inventory")
		return passed and retained
	func _f18_tool_observation(action: StringName = &"backpack_assign") -> Dictionary:
		var focused: Control = _tree.root.gui_get_focus_owner()
		var backpack: Node = (_menu.get("_bodies") as Array)[0]
		var slot: int = (backpack.get("_buttons") as Array).find(focused)
		var selected: int = int(backpack.get("_focused"))
		var inventory: RefCounted = _game.get("inventory")
		return {"hotbar": (_game.get("hotbar") as Array).duplicate(),
			"menu_open": _menu.call("is_open"), "tab": _menu.call("current_tab_id"),
			"gui_focus": str(focused.get_path()) if focused != null else "", "gui_inventory_slot": slot,
			"gui_stack": inventory.call("stack_at", slot), "selected_slot": selected,
			"selected_stack": inventory.call("stack_at", selected), "status": str(_menu.get("_status").get("text")),
			"action_pressed": Input.is_action_pressed(action), "action_just_pressed": Input.is_action_just_pressed(action),
			"physics_frame": Engine.get_physics_frames(), "process_frame": Engine.get_process_frames()}
	func _tap_action(action: StringName) -> void:
		if not _f18_assigning_tools:
			await super._tap_action(action)
			return
		var event: InputEvent = _event_for(action, true)
		var trace: Dictionary = {"action": str(action), "before": _f18_tool_observation(action), "edges": []}
		if event == null:
			trace["error"] = "no actual InputMap joypad binding"
			_f18_assignment_trace.append(trace)
			_fail("F18 tool assignment action has no physical joypad binding: " + str(action))
			return
		# Like FreshOpening's corrected pad driver: physics-only waits can put
		# both edges in one event flush. A process frame makes each real edge
		# observable to Satchel.poll without extending its six-press cycle.
		for pressed: bool in [true, false]:
			var edge: InputEvent = event if pressed else _event_for(action, false)
			var started: int = Engine.get_physics_frames()
			Input.parse_input_event(edge)
			await _tree.process_frame
			while Engine.get_physics_frames() - started < (3 if pressed else 5): await _tree.physics_frame
			if action == &"backpack_assign":
				trace.edges.append({"pressed": pressed, "event": edge.as_text(),
					"physics_start": started, "observed": _f18_tool_observation(action)})
		if action == &"backpack_assign":
			trace["after"] = _f18_tool_observation(action)
			_f18_assignment_trace.append(trace)
	func _wait_open_panel(script_suffix: String, budget: int) -> Node:
		var started_process: int = Engine.get_process_frames()
		var started_physics: int = Engine.get_physics_frames()
		var scene: Node = _tree.current_scene
		var character: String = str(_game.get("local").get("character_id"))
		var panel: Node = await super._wait_open_panel(script_suffix, budget)
		if panel != null and script_suffix == "shop_panel.gd":
			var initial: Dictionary = _f18_shop_handoff_observation(panel)
			# The original helper waits only for is_open(). Dialogue can retain
			# its closing Interact edge while the real shop is already open.
			# Wait for this exact panel to own input within that same process
			# frame budget; do not replay the conversation or dismiss an owner.
			while is_instance_valid(panel) and panel.call("is_open") == true \
				and INPUT_OWNER.current(_tree) != panel \
				and Engine.get_process_frames() - started_process < budget \
				and _tree.current_scene == scene \
				and str(_game.get("local").get("character_id")) == character:
				await _tree.process_frame
			var ready: bool = is_instance_valid(panel) and panel.call("is_open") == true \
				and INPUT_OWNER.current(_tree) == panel and _tree.current_scene == scene \
				and str(_game.get("local").get("character_id")) == character
			guards.receipts.append({"phase": "earned_shop_input_handoff", "initial": initial,
				"final": _f18_shop_handoff_observation(panel), "original_process_budget": budget,
				"elapsed_process_frames": Engine.get_process_frames() - started_process,
				"elapsed_physics_frames": Engine.get_physics_frames() - started_physics,
				"character": character, "passed": ready})
			if not ready:
				_fail("F18 actual shop did not acquire input within the original panel handoff budget")
				return null
			if not guards.shop_key_offer_absent(panel):
				_fail("F18 actual vendor sell-offer protection: " + str(guards.failures))
				return null
		return panel
	func _f18_shop_handoff_observation(panel: Node) -> Dictionary:
		var holder: Node = INPUT_OWNER.current(_tree)
		return {"panel_path": str(panel.get_path()) if is_instance_valid(panel) else "",
			"panel_open": panel.call("is_open") if is_instance_valid(panel) else false,
			"vendor": panel.call("vendor_id") if is_instance_valid(panel) else "",
			"holder_path": str(holder.get_path()) if holder != null else "",
			"holder_script": holder.get_script().resource_path if holder != null and holder.get_script() != null else "",
			"holder_open": holder.call("is_open") if holder != null and holder.has_method("is_open") else false,
			"holder_owns_input": holder.call("owns_input") if holder != null and holder.has_method("owns_input") else false,
			"interact_pressed": Input.is_action_pressed(&"interact"),
			"interact_just_pressed": Input.is_action_just_pressed(&"interact"),
			"physics_frame": Engine.get_physics_frames(), "process_frame": Engine.get_process_frames()}
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
	var guards: RefCounted
	var _f18_selecting := false
	var _f18_selection_trace: Array[Dictionary] = []
	func _cell_id(button: Button) -> String:
		# Several production pieces share workbench.png. Identify the actual
		# button's catalogue row; an icon filename cannot identify its piece.
		# This only observes the menu: focus and selection still use pad input.
		for menu: Node in _tree.get_nodes_in_group(BUILD_MENU_GROUP):
			if not menu.has_method("is_open") or not bool(menu.call("is_open")): continue
			var buttons: Array = menu.get("_cell_buttons")
			var slot := buttons.find(button)
			if slot < 0: continue
			var categories: Array = menu.get("_categories")
			var category_index := int(menu.get("_category_index"))
			if category_index < 0 or category_index >= categories.size(): return ""
			var catalogue: Dictionary = menu.get("_catalogue_by_category")
			var pieces: Array = catalogue.get(categories[category_index], [])
			if slot >= pieces.size(): return ""
			return str(pieces[slot].get("id", ""))
		return ""
	func _open_the_catalogue() -> Node:
		return await open_ui.call()
	func _select_piece(id: String) -> bool:
		var inventory_before: Array = guards._inventory()
		var initial: Dictionary = _f18_build_observation(id)
		_f18_selection_trace.clear()
		_f18_selecting = true
		# Retain the original category/focus algorithm and all selection bounds.
		var passed: bool = await super._select_piece(id)
		_f18_selecting = false
		var unchanged: bool = guards._inventory() == inventory_before
		guards.receipts.append({"phase": "earned_build_selection", "piece": id,
			"initial": initial, "physical_edges": _f18_selection_trace.duplicate(true),
			"final": _f18_build_observation(id), "inventory_unchanged": unchanged,
			"input": "actual InputMap joypad edges, each flushed through a process frame; original 2/3 physics minima",
			"passed": passed and unchanged})
		if passed and not unchanged: _fail("F18 catalogue selection changed earned inventory before placement")
		return passed and unchanged
	func _f18_build_observation(wanted: String, action: StringName = &"ui_accept") -> Dictionary:
		var menu: Node = null
		for candidate: Node in _tree.get_nodes_in_group(BUILD_MENU_GROUP):
			if candidate.has_method("is_open") and bool(candidate.call("is_open")):
				menu = candidate
				break
		var focused: Control = _tree.root.gui_get_focus_owner()
		var cells: Array[Dictionary] = []
		var category := ""
		var selected := ""
		var message := ""
		if menu != null:
			var categories: Array = menu.get("_categories")
			var category_index: int = int(menu.get("_category_index"))
			if category_index >= 0 and category_index < categories.size(): category = str(categories[category_index])
			var catalogue: Dictionary = menu.get("_catalogue_by_category")
			var pieces: Array = catalogue.get(category, [])
			var selected_index: int = int(menu.get("_selected_index"))
			if selected_index >= 0 and selected_index < pieces.size(): selected = str(pieces[selected_index].get("id", ""))
			message = str(menu.get("_message").get("text"))
			for cell: Button in _visible_build_cells(menu):
				cells.append({"id": _cell_id(cell), "path": str(cell.get_path()),
					"focused": cell == focused, "disabled": cell.disabled, "alpha": cell.modulate.a})
		var inventory: RefCounted = _game.get("inventory")
		var cost: Array = _game.call("build_cost_for", wanted)
		var stock: Dictionary = {}
		for need: Dictionary in cost:
			var resource_id: String = str(need.get("id", ""))
			stock[resource_id] = inventory.call("count", resource_id)
		return {"menu_open": menu != null, "category": category, "selected_piece": selected,
			"gui_focus": str(focused.get_path()) if focused != null else "",
			"gui_piece": _cell_id(focused as Button) if focused is Button else "",
			"cells": cells, "message": message, "pending_build": str(_game.get("pending_build")),
			"free_build": bool(_game.get("free_build")), "cost": cost.duplicate(true), "earned_stock": stock,
			"can_afford": bool(_game.call("can_afford", wanted)), "inventory": guards._inventory(),
			"action_pressed": Input.is_action_pressed(action), "action_just_pressed": Input.is_action_just_pressed(action),
			"physics_frame": Engine.get_physics_frames(), "process_frame": Engine.get_process_frames()}
	func _tap_action(action: StringName) -> void:
		if not _f18_selecting:
			await super._tap_action(action)
			return
		var binding: InputEvent = null
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				binding = event
				break
		if binding == null:
			_fail("%s has no physical joypad binding" % action)
			return
		var trace: Dictionary = {"action": str(action), "before": _f18_build_observation("workbench", action), "edges": []}
		for pressed: bool in [true, false]:
			var edge: InputEvent = InputEventJoypadButton.new() if binding is InputEventJoypadButton else InputEventJoypadMotion.new()
			if binding is InputEventJoypadButton:
				(edge as InputEventJoypadButton).button_index = (binding as InputEventJoypadButton).button_index
				(edge as InputEventJoypadButton).pressed = pressed
			else:
				(edge as InputEventJoypadMotion).axis = (binding as InputEventJoypadMotion).axis
				(edge as InputEventJoypadMotion).axis_value = (binding as InputEventJoypadMotion).axis_value if pressed else 0.0
			var started: int = Engine.get_physics_frames()
			Input.parse_input_event(edge)
			await _tree.process_frame
			while Engine.get_physics_frames() - started < (2 if pressed else 3): await _tree.physics_frame
			trace.edges.append({"pressed": pressed, "event": edge.as_text(), "physics_start": started,
				"observed": _f18_build_observation("workbench", action)})
		trace["after"] = _f18_build_observation("workbench", action)
		_f18_selection_trace.append(trace)

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
	if not await _guards.replay_cutscene(_tab):
		_fail("ordinary Settings Home Key Replay refusal: " + str(_guards.failures))
		_report()
		return
	# The village leg is proven from the farmyard where gate B's opening leaves
	# the player; this fresh opening's catch can end below the farm road.
	receipts.append({"phase": "village_start", "actual_position": str(current_scene.get_node(^"Player").global_position)})
	if not await _walk(Vector3(24.0, 1.0, -32.0)):
		_fail("earned village: could not walk from the catch back to the farmyard")
		_report()
		return
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

func _walk(target: Vector3, tolerance: float = 2.0, headings: Array[Vector3] = []) -> bool:
	var player: CharacterBody3D = current_scene.get_node(^"Player")
	var rig: Node3D = current_scene.get_node(^"CameraRig")
	var distance := player.global_position.distance_to(target)
	var nav := NAV.new(self, player, rig, _stick)
	var before: int = player.get("_unstick_count")
	var budget := maxi(3600, int(distance * 100.0))
	var ok: bool = await nav.walk_to_guided(target, budget, tolerance, headings)
	_stick(0, 0)
	receipts.append({"phase": "ordinary_walk", "target": str(target), "headings": headings.map(func(at: Vector3) -> String: return str(at)),
		"original_frame_budget": budget, "arrived": ok, "grounded": player.is_on_floor(),
		"unstick_count_before": before, "unstick_count_after": int(player.get("_unstick_count")),
		"actual_position": str(player.global_position), "confined_resets": nav.confined_resets()})
	return (ok and player.is_on_floor() and int(player.get("_unstick_count")) == before) \
		or _fail("ordinary grounded walk failed: target=" + str(target) + " actual=" + str(player.global_position))

func _trail_camp_headings(target: Vector3) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var gate := current_scene.find_child("TrailGate", true, false) as Node3D
	if gate == null or not bool(game.progression.call("has", "road_gate_open")):
		_fail("earned village gate must be open before the deep walk")
		return out
	var terrain: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/terrain_playground.json"))
	var points: Array = []
	for band: Dictionary in terrain.get("trail", {}).get("bands", []):
		if str(band.get("id", "")) == "band1_lower_meadows": points = band.get("points", [])
	if points.size() < 3 or points.size() > 30:
		_fail("authored Lower Meadows road is unavailable or exceeds the existing guided-walk limit")
		return out
	# R7 walked directly from the paid Workbench into a solid fence panel.
	# Follow the real open gate and the existing road around the Pond instead.
	# All headings share the original direct-distance budget and watchdog.
	var nearest := -1
	var nearest_distance := INF
	for index in points.size():
		var raw: Array = points[index]
		if raw.size() != 2: return out
		var at := Vector3(float(raw[0]), 0.0, float(raw[1]))
		if not at.is_finite(): return out
		var distance := Vector2(at.x - target.x, at.z - target.z).length_squared()
		if distance < nearest_distance:
			nearest = index
			nearest_distance = distance
	if nearest < 2: return out
	for index in range(nearest + 1):
		var raw: Array = points[index]
		out.append(Vector3(float(raw[0]), 0.0, float(raw[1])))
		if index == 1: out.append(gate.global_position)
	return out

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
	driver.guards = _guards
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
	var headings := _trail_camp_headings(stone.global_position)
	if headings.is_empty(): return _fail("actual Trail Camp road headings could not be resolved")
	if not await _walk(stone.global_position, 2.1, headings): return false
	for frame in 600:
		await physics_frame
		if game.get("local").redesign_character.last_waystones.get("meadows") == STONE_ID: break
	if game.get("local").redesign_character.last_waystones.get("meadows") != STONE_ID:
		return _fail("actual touch never committed this character's stone")
	receipts.append({"phase": "deep_touch", "position": str(current_scene.get_node(^"Player").global_position),
		"waystone": STONE_ID})
	_presentation = preload("res://tests/helpers/f18_presentation_capture.gd").attach(self, game,
		"res://ralph/reports/HUB/f18/native/earned_%d" % Time.get_ticks_usec())
	var home_before := _home_key_observation()
	var home_passed: bool = await travel.home_key()
	receipts.append({"phase": "actual_home_key_completion", "passed": home_passed,
		"before": home_before, "after": _home_key_observation(),
		"driver_result": travel.get("_home_result").duplicate(true),
		"original_process_frame_budget": 7200, "observer": "read-only before/after; no additional await or input"})
	if not home_passed: return _fail("actual Satchel Home Key: " + str(travel.failures))
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

func _home_key_observation() -> Dictionary:
	# Serialize only values from live nodes. Never retain Materials, stale scene
	# objects or the arrival coordinator's weak-reference bindings in receipts.
	var scene: Node = current_scene
	var actor: Variant = game.call("find_player")
	var key: Node = game.get_node_or_null(^"HomeKey")
	var session: Node = game.get("session")
	var arrival: Node = session.get_node_or_null(^"FoundationComposition/PortalArrival") if session != null else null
	var pending: Dictionary = arrival.get("_pending") if arrival != null else {}
	var owner: Node = preload("res://scripts/ui/input_owner.gd").current(self)
	var local: RefCounted = game.get("local")
	var realm: String = str(game.get("current_realm"))
	var out := {"process_frame": Engine.get_process_frames(), "physics_frame": Engine.get_physics_frames(),
		"realm": realm, "pending_realm_entry": str(game.get("pending_realm_entry")),
		"scene": scene.scene_file_path if scene != null else "", "scene_instance": scene.get_instance_id() if scene != null else 0,
		"realm_scene_ready": game.call("_realm_scene_ready", scene, realm) if scene != null else false,
		"input_owner": str(owner.get_path()) if owner != null else "",
		"character_id": str(local.get("character_id")) if local != null else "",
		"home_keys": game.get("inventory").call("count", "home_key"),
		"key": {"phase": key.get("_phase"), "pending": key.get("_pending"), "use_id": key.get("_use_id"),
			"elapsed_seconds": key.get("_elapsed"), "fading": key.call("is_fading")} if key != null else {},
		"portal_requests": session.get("_portal_requests").keys() if session != null else [],
		"arrival": {"present": arrival != null, "pending": not pending.is_empty(), "fields": pending.keys(),
			"seated": pending.get("seated"), "journal_started": pending.get("journal_started"),
			"contact_generation": pending.get("contact_generation"), "save_wait_notified": pending.get("save_wait_notified")},
		"actor": {"present": false}}
	if is_instance_valid(actor) and actor is CharacterBody3D and actor.is_inside_tree():
		var contact: Variant = actor.get("_foundation_ground_contact_position")
		out.actor = {"present": true, "instance_id": actor.get_instance_id(),
			"position": [actor.global_position.x, actor.global_position.y, actor.global_position.z],
			"on_floor": actor.is_on_floor(), "physics_processing": actor.is_physics_processing(),
			"contact_generation": actor.get("_foundation_ground_contact_generation"),
			"contact_position": [contact.x, contact.y, contact.z] if contact is Vector3 else null,
			"unstick_count": actor.get("_unstick_count")}
	return out

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
		var owner_session: Node = game.get("session")
		var row: Dictionary = owner_session.call("_owner_training_row")
		return _fail("actual Workbench Craft did not complete durable paid action (status=%s intent=%s block=%s row=%s/%s)" % [
			str(panel.get("_status").text), str(panel.get("_station_intent")),
			str(owner_session.call("_owner_snapshot_block_reason", game.get("local"))),
			str(row.get("action", "")), str(row.get("status", ""))])
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
