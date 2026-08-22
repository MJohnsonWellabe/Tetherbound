extends SceneTree

## Gate A checkpoints 10-11: one production world, real controller edges.
##
##   godot --headless --path . --script tests/smoke_gate_a_rest_torch.gd
##
## Fixture setup directly arms free-build pieces so this smoke can stay focused;
## placement, creature-bed UI, player-bed interaction, and torch draw/stow all
## travel through their live InputMap-backed joypad paths.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const TORCH_CYCLES := 6

var _failures: Array[String] = []
var _world: Node
var _game: Node
var _player: CharacterBody3D
var _arbiter: Node


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_arbiter = get_first_node_in_group("interaction_arbiter")
	if _game == null or _player == null or _arbiter == null:
		_fail("Meadows did not stand up Game, Player, and InteractionArbiter")
		_report()
		return

	var director := _world.find_child("SequenceDirector", true, false)
	if director != null and director.has_method("_set_beat"):
		director.call("_set_beat", "free_play")
	var party: RefCounted = _game.get("party")
	if party == null:
		_fail("Game has no party")
		_report()
		return
	while int(party.call("size")) < 2:
		var creature: RefCounted = _game.call("make_creature", "terrapup" if int(party.call("size")) == 0 else "bramblebun")
		if creature == null or not bool(party.call("add", creature)):
			break
	if int(party.call("size")) < 2:
		_fail("could not prepare two real party creatures")
		_report()
		return

	_game.set("free_build", true)
	# Known clear-meadow coordinates also used by the modal/build regressions.
	var bed := await _place_fixture("creature_bed", Vector3(70.0, 0.0, 70.0))
	var camp := await _place_fixture("camp", Vector3(100.0, 0.0, 80.0))
	if bed == null or camp == null:
		_report()
		return

	await _exercise_creature_bed(bed, party)
	await _exercise_repeated_torch()
	await _exercise_player_rest(camp, bed, party)
	_report()


func _place_fixture(id: String, at: Vector3) -> Node3D:
	await _teleport_to(at)
	_game.set("pending_build", id)
	for i in 18:
		await physics_frame
	var before: Array[Node] = get_nodes_in_group("placed_building")
	await _tap("build_place")
	for i in 24:
		await physics_frame
	await _tap("build_cancel")
	for node: Node in get_nodes_in_group("placed_building"):
		if before.has(node):
			continue
		if str(node.get_meta("building_id", "")) == id:
			print("fixture placed through controller: %s" % id)
			return node as Node3D
	_fail("controller placement produced no '%s' fixture" % id)
	return null


func _exercise_creature_bed(bed: Node3D, party: RefCounted) -> void:
	var creature: RefCounted = party.call("at", 0)
	var max_hp := float(creature.get("max_hp"))
	var damaged_hp := maxf(1.0, max_hp * 0.25)
	creature.set("hp", damaged_hp)
	creature.set("fainted", false)
	var prompt := bed.get_node_or_null(^"Interactable") as Node3D
	if prompt == null:
		_fail("placed creature bed has no interaction prompt")
		return
	await _teleport_near(prompt)
	if not await _wait_provider(prompt):
		_fail("creature-bed prompt never won arbitration")
		return
	await _tap("interact")
	var panel := await _wait_open_script("creature_bed_panel.gd")
	if panel == null:
		_fail("controller interact did not open the creature-bed panel")
		return
	await _tap("ui_accept")
	if not bool(creature.get("resting")) or int(bed.call("occupant_index")) != 0:
		_fail("focused controller A did not assign the creature to this bed")
	if bool(party.call("set_active", 0)):
		_fail("a resting creature could still be selected active")
	var rest_body := bed.get_node_or_null(^"RestingCreature") as Node3D
	if rest_body == null or not rest_body.visible:
		_fail("assigned creature has no visible resting body at the bed")
	await _tap("menu_cancel")
	if bool(panel.call("is_open")) or paused:
		_fail("creature-bed panel did not release pause on controller B")
	# Recovery uses elapsed live game time and correctly stands still while the
	# assignment modal pauses the world. Measure only after returning to play.
	for i in 35:
		await physics_frame
	var partial_hp := float(creature.get("hp"))
	if partial_hp <= damaged_hp or partial_hp >= max_hp:
		_fail("bed recovery was not gradual (%.2f -> %.2f / %.2f)" % [damaged_hp, partial_hp, max_hp])
	else:
		print("creature bed: visible body, gradual HP %.2f -> %.2f, active selection refused" % [damaged_hp, partial_hp])


func _exercise_repeated_torch() -> void:
	var inventory: RefCounted = _game.get("inventory")
	if inventory == null:
		_fail("Game has no inventory for the torch")
		return
	if int(inventory.call("find_slot", "torch")) < 0:
		inventory.call("add", "torch", 1)
	_game.set("equipped_tool", "")
	var look := get_first_node_in_group("day_cycle")
	if look == null or not look.has_method("apply_time"):
		_fail("world has no controllable day/night look")
		return
	look.call("apply_time", "night")
	for i in 5:
		await physics_frame
	var torch: Node = _player.get("torch")
	var hold: Node = _player.get("tool_hold")
	if torch == null or hold == null:
		_fail("Player has no production torch/tool-hold nodes")
		return

	# CONTROLLER-MAP, ralph/OWNER_DIRECTIVES_2026-08-22.md section 1: "Torch is
	# a tool that lives in the bar ('torch doesn't need a button')."
	# `torch_place` kept its keyboard key and lost its pad binding, so tapping
	# it here failed the InputMap lookup outright and every torch assertion
	# below fell over behind it. The torch is drawn and stowed the way every
	# other tool is: assigned to a quick slot and toggled with that slot's
	# button (`playground_hud.gd::_use_hotbar_slot`).
	var inventory: RefCounted = _game.get("inventory")
	if int(inventory.call("find_slot", "torch")) < 0:
		inventory.call("add", "torch", 1)
	if not bool(_game.call("assign_hotbar", 0, "torch")):
		_fail("could not put the torch on the quick bar, which is how it is drawn now")
		return

	for cycle in TORCH_CYCLES:
		await _tap("hotbar_1")
		for i in 8:
			await physics_frame
		var prop := torch.call("prop_node") as Node3D
		if str(_game.get("equipped_tool")) != "torch" or str(hold.call("equipped")) != "torch":
			_fail("torch cycle %d: controller draw did not equip torch" % (cycle + 1))
		elif prop == null or not prop.visible:
			_fail("torch cycle %d: draw produced no visible hand prop" % (cycle + 1))
		elif not bool(torch.call("is_on")):
			_fail("torch cycle %d: night draw did not restore light" % (cycle + 1))
		else:
			var flame_local: Vector3 = prop.call("flame_local_position") if prop.has_method("flame_local_position") else Vector3.ZERO
			var flame_world: Vector3 = prop.global_transform * flame_local
			if flame_world.y <= prop.global_position.y:
				_fail("torch cycle %d: flame anchor is not above its held prop origin" % (cycle + 1))
		var spot := torch.get_node_or_null(^"TorchLight") as Light3D
		var omni := torch.get_node_or_null(^"TorchOmni") as Light3D
		if spot == null or omni == null or not spot.visible or not omni.visible:
			_fail("torch cycle %d: both production light nodes were not active" % (cycle + 1))
		if torch.get_children().filter(func(child: Node) -> bool: return child.name == &"TorchLight").size() != 1 \
				or torch.get_children().filter(func(child: Node) -> bool: return child.name == &"TorchOmni").size() != 1:
			_fail("torch cycle %d: duplicate light nodes accumulated" % (cycle + 1))

		await _tap("hotbar_1")
		for i in 8:
			await physics_frame
		if not str(_game.get("equipped_tool")).is_empty() or not str(hold.call("equipped")).is_empty():
			_fail("torch cycle %d: controller stow left torch equipped" % (cycle + 1))
		if bool(torch.call("is_on")):
			_fail("torch cycle %d: stowed torch stayed lit" % (cycle + 1))
		if (torch.get_node(^"TorchLight") as Light3D).visible or (torch.get_node(^"TorchOmni") as Light3D).visible:
			_fail("torch cycle %d: stow left an invisible-source light active" % (cycle + 1))
	if _failures.is_empty():
		print("torch: %d physical draw/stow cycles restored prop and lights without duplicates" % TORCH_CYCLES)


func _exercise_player_rest(camp: Node3D, bed: Node3D, party: RefCounted) -> void:
	var creature: RefCounted = party.call("at", 0)
	var vitals: RefCounted = _player.get("vitals")
	var day_before := int(_game.get("day"))
	if vitals == null:
		_fail("Player has no vitals for rest verification")
		return
	vitals.set("health", 40.0)
	var prompt := camp.get_node_or_null(^"Interactable") as Node3D
	if prompt == null:
		_fail("placed camp has no player-bed Rest interaction")
		return
	await _teleport_near(prompt, Vector3.ZERO)
	if not await _wait_provider(prompt):
		_fail("camp Rest prompt never won arbitration")
		return
	await _tap("interact")
	for i in 150:
		await physics_frame
	if int(_game.get("day")) != day_before + 1:
		_fail("player-bed interaction did not advance to the next day")
	if float(vitals.get("health")) < float(vitals.get("max_health")):
		_fail("player-bed interaction did not restore player health")
	if bool(creature.get("resting")) or not bool(creature.get("rested")):
		_fail("overnight boundary did not complete the assigned creature rest")
	if float(creature.get("hp")) < float(creature.get("max_hp")):
		_fail("completed overnight creature rest did not fully heal")
	if not bool(party.call("set_active", 0)):
		_fail("completed rest did not return the creature to active eligibility")
	for i in 4:
		await process_frame
	if bed.get_node_or_null(^"RestingCreature") != null:
		_fail("completed rest left a duplicate resting body in the bed")
	else:
		print("player rest: day advanced, trainer healed, creature completed rest and returned active")


func _tap(action: String) -> void:
	var mapped: InputEvent = _joy_event_for(action, true)
	if mapped == null:
		_fail("InputMap action '%s' has no joypad button or axis" % action)
		return
	Input.parse_input_event(mapped)
	await process_frame
	await process_frame
	Input.parse_input_event(_joy_event_for(action, false))
	for i in 5:
		await process_frame


func _joy_event_for(action: String, pressed: bool) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			var out := InputEventJoypadButton.new()
			out.device = 0
			out.button_index = button.button_index
			out.pressed = pressed
			return out
		var motion := event as InputEventJoypadMotion
		if motion != null:
			var out := InputEventJoypadMotion.new()
			out.device = 0
			out.axis = motion.axis
			out.axis_value = motion.axis_value if pressed else 0.0
			return out
	return null


func _teleport_to(at: Vector3) -> void:
	var y := float(_world.call("ground_height_at", at.x, at.z)) if _world.has_method("ground_height_at") else _player.global_position.y
	_player.global_position = Vector3(at.x, y + 0.2, at.z)
	_player.velocity = Vector3.ZERO
	for i in 14:
		await physics_frame


func _teleport_near(prompt: Node3D, offset: Vector3 = Vector3(0.25, 0.0, 0.25)) -> void:
	var at := prompt.global_position + offset
	var y := float(_world.call("ground_height_at", at.x, at.z)) if _world.has_method("ground_height_at") else at.y
	_player.global_position = Vector3(at.x, y + 0.2, at.z)
	_player.velocity = Vector3.ZERO
	for i in 18:
		await physics_frame


func _wait_provider(provider: Node) -> bool:
	for i in 45:
		await physics_frame
		if _arbiter.call("winning_provider") == provider:
			return true
	return false


func _wait_open_script(suffix: String) -> Node:
	for i in 45:
		await process_frame
		for node: Node in root.get_children():
			var script := node.get_script() as Script
			if script != null and str(script.resource_path).ends_with(suffix) \
					and node.has_method("is_open") and bool(node.call("is_open")):
				return node
	return null


func _fail(message: String) -> void:
	_failures.append(message)
	print("FAIL: %s" % message)


func _report() -> void:
	if _game != null:
		_game.set("free_build", false)
		_game.set("pending_build", "")
	if paused:
		paused = false
	print("")
	if _failures.is_empty():
		print("Gate A rest/torch smoke passed")
		quit(0)
		return
	for failure in _failures:
		print("  FAIL: %s" % failure)
	quit(1)
