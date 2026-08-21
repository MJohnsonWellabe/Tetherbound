extends RefCounted

## Reusable Gate A continuous-session segment: village conversations, Satchel
## tool assignment, and authored gathering.  The opening/catch harness invokes
## `run()` without changing scenes, so this remains the same uninterrupted
## production world session.
##
## Canonical constraints are intentional and load-bearing here:
##
## - every action enters through a physical joypad event and the live InputMap;
## - travel is by the player's left stick, including through real doors;
## - Tam's production dialogue is the only source of the tools;
## - the Satchel's focused controller UI assigns the quick slots;
## - harvesting uses `use_tool`, never a direct gather call;
## - no teleport, direct inventory grant, progression mutation, or private
##   gameplay method stages the route.
##
## This helper deliberately does not boot or finish a SceneTree.  Its caller
## owns the title/opening/catch preamble and the later build/rest/map/save
## segments, while this bounded helper reports its own exact first blocker.

const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const INTERACTABLE_SCRIPT := "res://scripts/world/interactable.gd"
const DOOR_SCRIPT := "res://scripts/world/village_door.gd"
const HARVEST_NODE_SCRIPT := "res://scripts/world/harvest_node.gd"
const BACKPACK_COLUMNS := 6

var _tree: SceneTree = null
var _world: Node = null
var _game: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _dialogue: CanvasLayer = null
var _arbiter: Node = null
var _menu: CanvasLayer = null
var _hud: CanvasLayer = null
var _failures: Array[String] = []
var _started_ms := 0


func run(tree: SceneTree, world: Node, game: Node, player: CharacterBody3D,
		camera_rig: Node3D) -> Array[String]:
	_started_ms = Time.get_ticks_msec()
	_tree = tree
	_world = world
	_game = game
	_player = player
	_rig = camera_rig
	_dialogue = _world.get_node_or_null(^"DialoguePanel") as CanvasLayer
	_arbiter = _world.get_node_or_null(^"InteractionArbiter")
	_hud = _world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	_menu = _game.call("menu") as CanvasLayer if _game != null and _game.has_method("menu") else null
	if (_tree == null or _world == null or _game == null or _player == null
			or _rig == null or _dialogue == null or _arbiter == null
			or _hud == null or _menu == null):
		_fail("segment dependencies are incomplete")
		return _failures
	if int((_game.get("party") as RefCounted).call("size")) < 2:
		_fail("NPC/gather segment began before the natural opening catch completed")
		return _failures
	if not _required_pad_actions_exist():
		return _failures

	# Tam first: all four tools must enter through the one-time production
	# conversation before the Satchel route has anything to assign.
	if not await _visit_villager("Tam", "", 1):
		return _failures
	for tool_id in ["axe", "pickaxe", "knife", "torch"]:
		if int((_game.get("inventory") as RefCounted).call("count", tool_id)) != 1:
			_fail("Tam's completed dialogue did not leave exactly one %s in the Satchel" % tool_id)
			return _failures
	_checkpoint("Tam handed over axe, pickaxe, knife and torch through dialogue")

	if not await _assign_tools_in_satchel():
		return _failures
	if not await _gather_authored_node("wood", "axe", "hotbar_1"):
		return _failures
	if not await _gather_authored_node("stone", "pickaxe", "hotbar_2"):
		return _failures
	if not await _gather_authored_node("fiber", "knife", "hotbar_3"):
		return _failures

	# Oskar and Mira each exercise a dialogue -> distinct modal -> B -> world
	# lifecycle.  Bram is deliberately reopened three times: unlike the two
	# trainers, his steady-state greeting remains a service and does not turn
	# the second visit into a battle outside this segment's scope.
	if not await _visit_villager("Oskar", "swap_panel.gd", 1):
		return _failures
	if not await _visit_villager("Mira", "shop_panel.gd", 1):
		return _failures
	if not await _visit_villager("Bram", "shop_panel.gd", 3):
		return _failures

	_checkpoint("five NPC/modal exits and three equipped-tool gathers returned world control")
	return _failures


func _visit_villager(who: String, expected_panel_suffix: String, cycles: int) -> bool:
	var npc := _world.find_child(who, true, false) as Node3D
	if npc == null:
		_fail("production world has no villager named %s" % who)
		return false

	# Only these two villagers are authored inside buildings.  Oskar stands
	# close enough to Mira's cottage that a nearest-door heuristic alone would
	# incorrectly walk indoors before trying his outdoor prompt.
	var door := _nearest_door(npc) if who in ["Mira", "Bram"] else null
	if door != null and _player.global_position.distance_to(npc.global_position) > 4.0:
		if not await _enter_through(door, npc.global_position):
			_fail("could not naturally enter %s's building" % who)
			return false

	var prompt := _npc_prompt(npc)
	if prompt == null:
		_fail("%s has no enabled production greeting prompt" % who)
		return false
	for cycle in cycles:
		if not await _walk_to_and_activate(prompt, 1400):
			_fail("natural controller travel could not activate %s cycle %d" % [who, cycle + 1])
			return false
		if not await _wait_dialogue_open(90):
			_fail("%s cycle %d did not open dialogue" % [who, cycle + 1])
			return false
		if not await _close_dialogue(40):
			_fail("%s cycle %d dialogue did not close through Interact" % [who, cycle + 1])
			return false
		if not expected_panel_suffix.is_empty():
			var panel := await _wait_open_panel(expected_panel_suffix, 90)
			if panel == null:
				_fail("%s cycle %d did not hand off to %s" % [who, cycle + 1, expected_panel_suffix])
				return false
			await _tap_action(&"menu_cancel")
			if not await _wait_world_owned(45):
				_fail("%s cycle %d left stale modal ownership after B" % [who, cycle + 1])
				return false
		elif not await _wait_world_owned(30):
			_fail("%s cycle %d left stale dialogue ownership" % [who, cycle + 1])
			return false
		if not await _prove_movement_resumed():
			_fail("%s cycle %d returned visually but world movement stayed dead" % [who, cycle + 1])
			return false
		_checkpoint("%s cycle %d exited and movement resumed" % [who, cycle + 1])

	# Leave an interior through the same open doorway before the next route leg.
	if door != null:
		if not await _exit_through(door, npc.global_position):
			_fail("could not naturally leave %s's building" % who)
			return false
	return true


func _assign_tools_in_satchel() -> bool:
	await _tap_action(&"inventory")
	for _i in 90:
		if bool(_menu.call("is_open")) and str(_menu.call("current_tab_id")) == "backpack":
			break
		await _tree.process_frame
	if not bool(_menu.call("is_open")) or str(_menu.call("current_tab_id")) != "backpack":
		_fail("physical Y did not open the Satchel tab")
		return false

	var bodies: Array = _menu.get("_bodies") as Array
	if bodies.is_empty():
		_fail("Satchel menu has no tab body")
		return false
	var backpack: Node = bodies[0]
	var buttons: Array = backpack.get("_buttons") as Array
	var inventory: RefCounted = _game.get("inventory")
	# Assign in reverse quick-slot order.  The one-button assignment verb walks
	# an item through slot 1, 2, ...; reverse order prevents a later walk from
	# overwriting an earlier tool on its way to its destination.
	for spec: Array in [["torch", 3], ["knife", 2], ["pickaxe", 1], ["axe", 0]]:
		var item_id := str(spec[0])
		var destination := int(spec[1])
		var inventory_slot := int(inventory.call("find_slot", item_id))
		if inventory_slot < 0 or inventory_slot >= buttons.size():
			_fail("Satchel has no focusable slot for %s" % item_id)
			return false
		if not await _focus_satchel_slot(buttons, inventory_slot):
			_fail("controller focus could not reach %s in Satchel slot %d" % [item_id, inventory_slot + 1])
			return false
		for _press in destination + 1:
			await _tap_action(&"backpack_assign")
		if str((_game.get("hotbar") as Array)[destination]) != item_id:
			_fail("Satchel controller assignment did not put %s on quick slot %d" % [item_id, destination + 1])
			return false

	await _tap_action(&"menu_cancel")
	if not await _wait_world_owned(45):
		_fail("closing the Satchel left pause/modal ownership behind")
		return false
	if not await _prove_movement_resumed():
		_fail("closing the Satchel returned visually but movement stayed dead")
		return false
	_checkpoint("Satchel assigned four tools by focused controller input")
	return true


func _focus_satchel_slot(buttons: Array, target: int) -> bool:
	var focused := _tree.root.get_viewport().gui_get_focus_owner()
	var current := buttons.find(focused)
	if current < 0:
		return false
	var current_row: int = current / BACKPACK_COLUMNS
	var current_column := current % BACKPACK_COLUMNS
	var target_row: int = target / BACKPACK_COLUMNS
	var target_column := target % BACKPACK_COLUMNS
	for _i in absi(target_row - current_row):
		await _tap_action(&"ui_down" if target_row > current_row else &"ui_up")
	for _i in absi(target_column - current_column):
		await _tap_action(&"ui_right" if target_column > current_column else &"ui_left")
	return _tree.root.get_viewport().gui_get_focus_owner() == buttons[target]


func _gather_authored_node(item_id: String, tool_id: String, hotbar_action: StringName) -> bool:
	var node := _nearest_authored_node(item_id)
	if node == null:
		_fail("no unspent authored %s node exists in the opening route" % item_id)
		return false
	if not await _walk_toward(node.global_position, 1800, 1.55):
		_fail("natural controller travel could not reach the authored %s node" % item_id)
		return false
	# A visible swing owns the held prop for its full production animation.  Do
	# not overlap the next hotbar edge with it: the player cannot switch tools
	# mid-swing, and a continuous controller route must respect that same rule.
	if not await _wait_for_tool_idle():
		return false
	await _tap_action(hotbar_action)
	var hold: Node = _player.get("tool_hold")
	for _i in 30:
		if str(_game.get("equipped_tool")) == tool_id and hold != null and hold.call("prop_node") != null:
			break
		await _tree.process_frame
	if str(_game.get("equipped_tool")) != tool_id or hold == null or hold.call("prop_node") == null:
		var hotbar: Array = _game.get("hotbar") as Array
		var action_text := str(hotbar_action)
		var hotbar_index := action_text.trim_prefix("hotbar_").to_int() - 1 if action_text.begins_with("hotbar_") else -1
		var assigned := str(hotbar[hotbar_index]) if hotbar_index >= 0 and hotbar_index < hotbar.size() else "<unavailable>"
		_fail("%s quick slot did not put a visible %s in the trainer's hand (assigned=%s, game=%s, hold=%s, prop=%s, swinging=%s)" % [
			hotbar_action, tool_id, assigned, str(_game.get("equipped_tool")),
			str(hold.call("equipped")) if hold != null else "<missing>",
			str(hold.call("prop_node")) if hold != null else "<missing>",
			str(hold.call("is_swinging")) if hold != null else "<missing>"])
		return false

	var inventory: RefCounted = _game.get("inventory")
	var before := int(inventory.call("count", item_id))
	var message := _hud.get_node_or_null(^"Root/BottomDock/HotbarPanel/Margin/Layout/Message") as Label
	if message != null:
		message.text = ""
		message.visible = false
	await _tap_action(&"use_tool")
	if not bool(hold.call("is_swinging")):
		_fail("physical Use Tool did not start the visible %s swing" % tool_id)
		return false
	for _i in 90:
		if int(inventory.call("count", item_id)) > before and message != null and message.visible:
			break
		await _tree.process_frame
	var credited := int(inventory.call("count", item_id)) - before
	if credited <= 0:
		_fail("visible %s swing credited no %s" % [tool_id, item_id])
		return false
	var expected := "+%d %s" % [credited, str((_game.get("items") as RefCounted).call("item_name", item_id))]
	if message == null or not message.visible or message.text != expected:
		_fail("%s credited %d but visible pickup feedback was '%s'" % [
			item_id, credited, message.text if message != null else "<missing>"])
		return false
	_checkpoint("%s equipped, swung, gathered %s" % [tool_id, expected])
	return true


func _wait_for_tool_idle() -> bool:
	var hold: Node = _player.get("tool_hold")
	if hold == null:
		_fail("trainer has no ToolHold while waiting to switch tools")
		return false
	for _i in 120:
		if not bool(hold.call("is_swinging")):
			return true
		await _tree.physics_frame
	_fail("previous tool swing did not finish before the next controller hotbar edge")
	return false


func _nearest_authored_node(item_id: String) -> Node3D:
	var best: Node3D = null
	var distance := INF
	for node: Node in _tree.get_nodes_in_group("harvestable"):
		if not node is Node3D or _script_path(node) != HARVEST_NODE_SCRIPT:
			continue
		if (str(node.get("_item_id")) != item_id or not node.is_inside_tree()
				or float(node.get("_respawn_left")) > 0.0):
			continue
		var candidate := node as Node3D
		var gap := _player.global_position.distance_to(candidate.global_position)
		if gap < distance:
			distance = gap
			best = candidate
	return best


func _enter_through(door: Node3D, inside_target: Vector3) -> bool:
	var prompt := door.get_node_or_null(^"Prompt") as Node3D
	if prompt == null:
		return false
	if not bool(door.call("is_open")):
		if not await _walk_to_and_activate(prompt, 1200):
			return false
		for _i in 45:
			if bool(door.call("is_open")):
				break
			await _tree.process_frame
	if not bool(door.call("is_open")):
		return false
	var inward := inside_target - door.global_position
	inward.y = 0.0
	return await _walk_toward(door.global_position + inward.normalized() * 2.2, 600, 0.7)


func _exit_through(door: Node3D, inside_target: Vector3) -> bool:
	var outward := door.global_position - inside_target
	outward.y = 0.0
	if not await _walk_toward(door.global_position, 700, 0.65):
		return false
	return await _walk_toward(door.global_position + outward.normalized() * 2.4, 500, 0.7)


func _nearest_door(npc: Node3D) -> Node3D:
	var best: Node3D = null
	var distance := INF
	for node: Node in _descendants(_world):
		if not node is Node3D or _script_path(node) != DOOR_SCRIPT:
			continue
		var gap := npc.global_position.distance_to((node as Node3D).global_position)
		# Outdoor villagers must not inherit a nearby cottage door.  Mira is a
		# few metres behind hers; Bram is at the far end of the longer inn.
		if gap < distance and gap < 10.5:
			distance = gap
			best = node as Node3D
	return best


func _npc_prompt(npc: Node3D) -> Node3D:
	for node: Node in _descendants(npc):
		if node is Node3D and _script_path(node) == INTERACTABLE_SCRIPT \
				and bool(node.get("enabled")):
			return node as Node3D
	return null


func _walk_to_and_activate(target: Node3D, budget: int) -> bool:
	if not await _walk_toward(target.global_position, budget, 1.65):
		return false
	for _i in 30:
		if _arbiter.call("winning_provider") == target:
			await _tap_action(&"interact")
			return true
		await _tree.physics_frame
	return false


func _walk_toward(point: Vector3, budget: int, close_enough: float = 0.8) -> bool:
	for _i in budget:
		var to := point - _player.global_position
		to.y = 0.0
		if to.length() <= close_enough:
			_stop_left_stick()
			for _j in 5:
				await _tree.physics_frame
			return true
		var basis: Basis = _rig.call("planar_basis")
		var local := basis.inverse() * to.normalized()
		_send_axis(JOY_AXIS_LEFT_X, local.x)
		_send_axis(JOY_AXIS_LEFT_Y, local.z)
		await _tree.physics_frame
	_stop_left_stick()
	return false


func _prove_movement_resumed() -> bool:
	if _tree.paused or INPUT_OWNER.current(_tree) != null or not bool(_player.call("locomotion_enabled")):
		return false
	# Try four physical directions because a villager counter or wall can block
	# one without implying dead world input.  This is ordinary walking, not a
	# relocation shortcut, and leaves the player wherever the successful step
	# naturally ended.
	for axis: Vector2 in [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]:
		var before := _player.global_position
		_send_axis(JOY_AXIS_LEFT_X, axis.x)
		_send_axis(JOY_AXIS_LEFT_Y, axis.y)
		for _i in 22:
			await _tree.physics_frame
		_stop_left_stick()
		for _i in 4:
			await _tree.physics_frame
		if Vector2(_player.global_position.x - before.x,
				_player.global_position.z - before.z).length() >= 0.3:
			return true
	return false


func _wait_dialogue_open(budget: int) -> bool:
	for _i in budget:
		if bool(_dialogue.call("is_open")):
			return true
		await _tree.process_frame
	return false


func _close_dialogue(max_presses: int) -> bool:
	for _i in max_presses:
		if not bool(_dialogue.call("is_open")):
			return true
		await _tap_action(&"interact")
	return not bool(_dialogue.call("is_open"))


func _wait_open_panel(script_suffix: String, budget: int) -> Node:
	for _i in budget:
		for node: Node in _tree.get_nodes_in_group(INPUT_OWNER.GROUP):
			if (_script_path(node).ends_with(script_suffix) and node.has_method("is_open")
					and bool(node.call("is_open"))):
				return node
		await _tree.process_frame
	return null


func _wait_world_owned(budget: int) -> bool:
	for _i in budget:
		if (not _tree.paused and INPUT_OWNER.current(_tree) == null
				and not bool(_dialogue.call("is_open")) and not bool(_menu.call("is_open"))):
			return true
		await _tree.process_frame
	return false


func _tap_action(action: StringName) -> void:
	var event := _event_for(action, true)
	if event == null:
		_fail("'%s' has no physical joypad binding" % action)
		return
	Input.parse_input_event(event)
	for _i in 3:
		await _tree.physics_frame
	var released := event.duplicate() as InputEvent
	if released is InputEventJoypadButton:
		(released as InputEventJoypadButton).pressed = false
	elif released is InputEventJoypadMotion:
		(released as InputEventJoypadMotion).axis_value = 0.0
	Input.parse_input_event(released)
	for _i in 5:
		await _tree.physics_frame


func _event_for(action: StringName, pressed: bool) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	for configured: InputEvent in InputMap.action_get_events(action):
		if configured is InputEventJoypadButton:
			var button := InputEventJoypadButton.new()
			button.device = 0
			button.button_index = (configured as InputEventJoypadButton).button_index
			button.pressed = pressed
			return button
		if configured is InputEventJoypadMotion:
			var motion := InputEventJoypadMotion.new()
			motion.device = 0
			motion.axis = (configured as InputEventJoypadMotion).axis
			motion.axis_value = (configured as InputEventJoypadMotion).axis_value if pressed else 0.0
			return motion
	return null


func _required_pad_actions_exist() -> bool:
	for action: StringName in [&"inventory", &"backpack_assign", &"ui_up", &"ui_down",
			&"ui_left", &"ui_right", &"menu_cancel", &"interact", &"use_tool",
			&"hotbar_1", &"hotbar_2", &"hotbar_3"]:
		if _event_for(action, true) == null:
			_fail("required action '%s' has no physical joypad binding" % action)
	return _failures.is_empty()


func _send_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = clampf(value, -1.0, 1.0)
	Input.parse_input_event(event)


func _stop_left_stick() -> void:
	_send_axis(JOY_AXIS_LEFT_X, 0.0)
	_send_axis(JOY_AXIS_LEFT_Y, 0.0)


func _script_path(node: Node) -> String:
	var script := node.get_script() as Script
	return script.resource_path if script != null else ""


func _descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child: Node in node.get_children():
		out.append_array(_descendants(child))
	return out


func _checkpoint(label: String) -> void:
	print("GATE A NPC/GATHER +%.2fs — %s" % [
		(Time.get_ticks_msec() - _started_ms) / 1000.0, label])


func _fail(message: String) -> void:
	if not _failures.has(message):
		_failures.append(message)
	push_error(message)
