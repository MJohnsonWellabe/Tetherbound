extends RefCounted

## Canonical paid-build material route for Gate A's one continuous session.
##
## This section does not create stock, move the trainer by transform, or call a
## gather/private implementation method. It walks with parsed controller input,
## equips the tools Tam gave through the Satchel, swings at visible live nodes,
## and picks up the downed result the production harvest path creates.
##
## The authored Band-1 route supplies 16 wood, 9 stone, and (after the fiber
## supply branch lands) 20 fiber. The paid 2x2 house + camp + creature bed
## requires 57 wood, 42 stone, and 18 fiber, so the route deliberately expands
## to the nearest live, deterministic harvest-all trees/rocks for the exact
## 41 wood / 33 stone authored shortfall. Runtime selection is intentional:
## scatter locations are deterministic for a candidate SHA, but not source
## constants, and selecting the live public resource nodes proves the actual
## loaded Meadow has the claimed economy.

const HARVEST_NODE_PATH := "res://scripts/world/harvest_node.gd"
const VEGETATION_POINT_PATH := "res://scripts/world/vegetation_harvest_point.gd"
const TARGET_STOCK := {"wood": 57, "stone": 42, "fiber": 18}
const TOOL_ACTION := {"wood": &"hotbar_1", "stone": &"hotbar_2", "fiber": &"hotbar_3"}
const TOOL_ID := {"wood": "axe", "stone": "pickaxe", "fiber": "knife"}
const AUTHORED_ROUTE: Array[Dictionary] = [
	{"item": "wood", "amount": 4, "at": Vector2(16.0, -28.0)},
	{"item": "wood", "amount": 4, "at": Vector2(26.0, -44.0)},
	{"item": "wood", "amount": 4, "at": Vector2(44.0, -24.0)},
	{"item": "wood", "amount": 4, "at": Vector2(-8.0, 8.0)},
	{"item": "stone", "amount": 3, "at": Vector2(22.0, -34.0)},
	{"item": "stone", "amount": 3, "at": Vector2(52.0, -30.0)},
	{"item": "stone", "amount": 3, "at": Vector2(-18.0, 6.0)},
	{"item": "fiber", "amount": 4, "at": Vector2(12.0, -22.0)},
	{"item": "fiber", "amount": 4, "at": Vector2(34.0, -46.0)},
	{"item": "fiber", "amount": 4, "at": Vector2(-2.0, -20.0)},
	# The two Gate-A fiber stops are deliberately on ordinary open-spine travel.
	{"item": "fiber", "amount": 4, "at": Vector2(-5.0, 141.0)},
	{"item": "fiber", "amount": 4, "at": Vector2(-168.0, 312.0)},
]

var failures: Array[String] = []
var transcript: Array[String] = []
var _tree: SceneTree
var _world: Node3D
var _game: Node
var _player: CharacterBody3D
var _rig: Node3D
var _arbiter: Node
var _move_x_axis: JoyAxis = JOY_AXIS_LEFT_X
var _move_y_axis: JoyAxis = JOY_AXIS_LEFT_Y
var _move_x_sign := 1.0
var _move_y_sign := 1.0


func run(tree: SceneTree, world: Node3D, game: Node, player: CharacterBody3D,
		camera_rig: Node3D) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	_player = player
	_rig = camera_rig
	if _tree == null or _world == null or _game == null or _player == null or _rig == null:
		_fail("material route dependencies are incomplete")
		return _result()
	_arbiter = _tree.get_first_node_in_group(&"interaction_arbiter")
	if _arbiter == null:
		_fail("material route could not find the production interaction arbiter")
		return _result()
	if not _resolve_move_bindings():
		return _result()
	if not _verify_tool_hotbar():
		return _result()
	transcript.append("starting natural paid-build route with %s" % _stock_snapshot())

	for stop in AUTHORED_ROUTE:
		if not await _harvest_authored_stop(stop):
			return _result()
	if not await _fill_with_live_scatter("wood"):
		return _result()
	if not await _fill_with_live_scatter("stone"):
		return _result()
	if not _stock_is_sufficient():
		_fail("natural harvest route ended below paid-house/rest target: %s" % _stock_snapshot())
	else:
		transcript.append("natural material invariant met: %s (need wood 57, stone 42, fiber 18)" % _stock_snapshot())
	return _result()


func _verify_tool_hotbar() -> bool:
	var hotbar: Array = _game.get("hotbar") as Array
	if hotbar.size() < 3:
		_fail("Satchel route did not expose three tool quick slots")
		return false
	for item_id in ["axe", "pickaxe", "knife"]:
		if int((_game.get("inventory") as RefCounted).call("find_slot", item_id)) < 0:
			_fail("natural route requires Tam's %s before it can harvest" % item_id)
			return false
	return true


func _harvest_authored_stop(stop: Dictionary) -> bool:
	var item_id := str(stop["item"])
	if _count(item_id) >= int(TARGET_STOCK[item_id]):
		return true
	var expected := Vector2(stop["at"])
	var node := _authored_node_at(expected, item_id)
	if node == null:
		# A preceding evidence section may already have spent this exact authored
		# stop. That is valid only when the inventory reflects it; the final
		# invariant, not a synthetic replacement, decides sufficiency.
		transcript.append("authored %s at %s was already spent; continuing from real satchel stock" % [item_id, expected])
		return true
	if not await _walk_to(node.global_position, 1.65, 1800):
		_fail("controller could not reach authored %s at %s" % [item_id, expected])
		return false
	if not await _harvest_node(node, item_id, true):
		return false
	transcript.append("authored %s %+d at (%.1f, %.1f)" % [item_id, int(stop["amount"]), expected.x, expected.y])
	return true


func _fill_with_live_scatter(item_id: String) -> bool:
	var required := int(TARGET_STOCK[item_id])
	var trips := 0
	while _count(item_id) < required:
		var node := _nearest_live_scatter(item_id)
		if node == null:
			_fail("no live natural %s scatter remains at %d/%d; authored route cannot fund the required paid build" % [
				item_id, _count(item_id), required])
			return false
		var before := _count(item_id)
		if not await _walk_to(node.global_position, 1.65, 2400):
			_fail("controller could not reach live natural %s at %s" % [item_id, node.global_position])
			return false
		if not await _harvest_node(node, item_id, false):
			return false
		var gained := _count(item_id) - before
		if gained <= 0:
			_fail("natural %s at %s paid no inventory after production chop/pickup" % [item_id, node.global_position])
			return false
		trips += 1
		transcript.append("scatter %s +%d at (%.2f, %.2f); %d/%d" % [
			item_id, gained, node.global_position.x, node.global_position.z, _count(item_id), required])
	transcript.append("natural %s deficit closed with %d live scatter stops" % [item_id, trips])
	return true


func _harvest_node(node: Node3D, item_id: String, authored: bool) -> bool:
	if str(node.call("resource_item")) != item_id:
		_fail("route target changed from %s to %s" % [item_id, str(node.call("resource_item"))])
		return false
	if int(node.call("resource_amount")) <= 0:
		_fail("live %s target exposed a non-positive public resource amount" % item_id)
		return false
	if not await _equip(item_id):
		return false
	var before := _count(item_id)
	await _tap_action(&"use_tool")
	if authored:
		return await _wait_for_inventory_gain(item_id, before, 120)
	# Scatter stands are a two-stage production verb: physical tool swing chops,
	# then the same player picks up the visible felled pile. Never call either
	# stage directly, and never assume a swing is itself an inventory grant.
	var pile := await _wait_for_felled_pickup(node.global_position, item_id, 180)
	if pile == null:
		_fail("visible %s swing created no public felled pickup near %s" % [item_id, node.global_position])
		return false
	if not await _walk_to(pile.global_position, 1.5, 300):
		_fail("controller could not reach its felled %s pickup" % item_id)
		return false
	var prompt := pile.get_node_or_null(^"Interactable") as Node3D
	if prompt == null or not await _wait_for_prompt(prompt, 90):
		_fail("felled %s pickup never offered the production Pick up prompt" % item_id)
		return false
	await _tap_action(&"interact")
	return await _wait_for_inventory_gain(item_id, before, 120)


func _equip(item_id: String) -> bool:
	await _tap_action(TOOL_ACTION[item_id])
	var expected_tool := str(TOOL_ID[item_id])
	for _i in 45:
		var hold: Node = _player.get("tool_hold")
		if str(_game.get("equipped_tool")) == expected_tool and hold != null and hold.call("prop_node") != null:
			return true
		await _tree.physics_frame
	_fail("controller quick slot did not visibly equip %s for %s" % [expected_tool, item_id])
	return false


func _authored_node_at(at: Vector2, item_id: String) -> Node3D:
	var nearest: Node3D = null
	var distance := INF
	for candidate: Node in _tree.get_nodes_in_group("harvestable"):
		if not candidate is Node3D or not candidate.has_method("resource_item"):
			continue
		var script := candidate.get_script() as Script
		if script == null or script.resource_path != HARVEST_NODE_PATH:
			continue
		if str(candidate.call("resource_item")) != item_id:
			continue
		var gap := Vector2((candidate as Node3D).global_position.x - at.x,
			(candidate as Node3D).global_position.z - at.y).length()
		if gap < distance:
			distance = gap
			nearest = candidate as Node3D
	return nearest if distance <= 2.0 else null


func _nearest_live_scatter(item_id: String) -> Node3D:
	var candidates: Array[Node3D] = []
	for candidate: Node in _tree.get_nodes_in_group("harvestable"):
		if not candidate is Node3D or not candidate.has_method("resource_item"):
			continue
		var script := candidate.get_script() as Script
		if script == null or script.resource_path != VEGETATION_POINT_PATH:
			continue
		if str(candidate.call("resource_item")) == item_id:
			candidates.append(candidate as Node3D)
	candidates.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		var a_distance := _player.global_position.distance_squared_to(a.global_position)
		var b_distance := _player.global_position.distance_squared_to(b.global_position)
		if not is_equal_approx(a_distance, b_distance):
			return a_distance < b_distance
		if not is_equal_approx(a.global_position.x, b.global_position.x):
			return a.global_position.x < b.global_position.x
		return a.global_position.z < b.global_position.z
	)
	return candidates[0] if not candidates.is_empty() else null


func _wait_for_felled_pickup(at: Vector3, item_id: String, frames: int) -> Node3D:
	for _i in frames:
		for candidate: Node in _descendants(_world):
			if not candidate is Node3D or not candidate.has_method("resource_item"):
				continue
			if str(candidate.call("resource_item")) != item_id:
				continue
			var prompt := candidate.get_node_or_null(^"Interactable")
			if prompt != null and (candidate as Node3D).global_position.distance_to(at) <= 3.0:
				return candidate as Node3D
		await _tree.physics_frame
	return null


func _wait_for_prompt(prompt: Node3D, frames: int) -> bool:
	for _i in frames:
		if _arbiter.call("winning_provider") == prompt:
			return true
		await _tree.physics_frame
	return false


func _wait_for_inventory_gain(item_id: String, before: int, frames: int) -> bool:
	for _i in frames:
		if _count(item_id) > before:
			return true
		await _tree.physics_frame
	_fail("%s action produced no visible inventory gain" % item_id)
	return false


func _walk_to(target: Vector3, close_enough: float, budget: int) -> bool:
	for _i in budget:
		var delta := target - _player.global_position
		delta.y = 0.0
		if delta.length() <= close_enough:
			_release_move()
			return true
		var basis: Basis = _rig.call("planar_basis")
		var local := basis.inverse() * delta.normalized()
		_parse_axis(_move_x_axis, clampf(local.x, -1.0, 1.0) * _move_x_sign)
		_parse_axis(_move_y_axis, clampf(local.z, -1.0, 1.0) * _move_y_sign)
		await _tree.physics_frame
	_release_move()
	return false


func _tap_action(action: StringName) -> void:
	var binding := _event_for(action, true)
	if binding == null:
		_fail("%s has no physical joypad binding" % action)
		return
	Input.parse_input_event(binding)
	for _i in 3:
		await _tree.physics_frame
	var released := binding.duplicate() as InputEvent
	if released is InputEventJoypadButton:
		(released as InputEventJoypadButton).pressed = false
	else:
		(released as InputEventJoypadMotion).axis_value = 0.0
	Input.parse_input_event(released)
	for _i in 5:
		await _tree.physics_frame


func _event_for(action: StringName, pressed: bool) -> InputEvent:
	for configured: InputEvent in InputMap.action_get_events(action):
		if configured is InputEventJoypadButton:
			var button := InputEventJoypadButton.new()
			button.button_index = (configured as InputEventJoypadButton).button_index
			button.pressed = pressed
			return button
		if configured is InputEventJoypadMotion:
			var motion := InputEventJoypadMotion.new()
			motion.axis = (configured as InputEventJoypadMotion).axis
			motion.axis_value = (configured as InputEventJoypadMotion).axis_value if pressed else 0.0
			return motion
	return null


func _resolve_move_bindings() -> bool:
	var right := _motion_for(&"move_right")
	var back := _motion_for(&"move_back")
	if right == null or back == null:
		_fail("material route needs physical left-stick movement bindings")
		return false
	_move_x_axis = right.axis
	_move_x_sign = signf(right.axis_value)
	_move_y_axis = back.axis
	_move_y_sign = signf(back.axis_value)
	return true


func _motion_for(action: StringName) -> InputEventJoypadMotion:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion:
			return event as InputEventJoypadMotion
	return null


func _parse_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)


func _release_move() -> void:
	_parse_axis(_move_x_axis, 0.0)
	_parse_axis(_move_y_axis, 0.0)


func _count(item_id: String) -> int:
	return int((_game.get("inventory") as RefCounted).call("count", item_id))


func _stock_is_sufficient() -> bool:
	for item_id: String in TARGET_STOCK:
		if _count(item_id) < int(TARGET_STOCK[item_id]):
			return false
	return true


func _stock_snapshot() -> String:
	return "wood %d / stone %d / fiber %d" % [_count("wood"), _count("stone"), _count("fiber")]


func _descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_descendants(child))
	return out


func _fail(message: String) -> void:
	if not failures.has(message):
		failures.append(message)


func _result() -> Dictionary:
	_release_move()
	return {"passed": failures.is_empty(), "failures": failures.duplicate(), "transcript": transcript.duplicate()}
