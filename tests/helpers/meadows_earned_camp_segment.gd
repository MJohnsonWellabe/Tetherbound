extends "res://tests/helpers/gate_b_tail_segment.gd"

## Earned campsite construction in the caller's current world. Only the
## parent's controller catalogue, navigation and placement methods are reused.
## The fixture, feeding, dialogue and combat shortcuts are fail-closed below.
const PLACER := preload("res://scripts/build/build_placer.gd")


static func piece_plan() -> Array[String]:
	var pieces: Array[String] = ["tent", "campfire", "bedroll"]
	for _index in TOURNAMENT.required_party_size():
		pieces.append("creature_bed")
	return pieces


static func required_stock(game: Node) -> Dictionary:
	var stock := {}
	for id in piece_plan():
		for requirement: Dictionary in game.call("build_cost_for", id):
			var item := str(requirement.get("id", ""))
			stock[item] = int(stock.get(item, 0)) + int(requirement.get("n", 0))
	return stock


func run(tree: SceneTree, world: Node3D, game: Node, player: CharacterBody3D,
		rig: Node3D, stage_arena: bool = false, skip_house: bool = false) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	_player = player
	_rig = rig
	if stage_arena or skip_house:
		_fail("earned campsite does not accept arena or campsite fixtures")
		return _result()
	_progression = game.get("progression")
	_party = game.get("party")
	if bool(game.get("free_build")):
		_fail("earned campsite cannot run with Free Build enabled")
		return _result()
	for id in piece_plan():
		if (game.call("build_cost_for", id) as Array).is_empty():
			_fail("earned campsite has no payable catalogue cost for " + id)
			return _result()
	if not _collect_nodes():
		return _result()
	_resolve_move_bindings()
	var needed := required_stock(game)
	for item: String in needed:
		if int(game.get("inventory").call("count", item)) < int(needed[item]):
			_fail("earned campsite lacks %s: need %d, have %d" % [item,
				needed[item], game.get("inventory").call("count", item)])
	if not failures.is_empty():
		return _result()
	if not await _place_the_campsite():
		return _result()
	if not await _place_the_creature_beds():
		return _result()
	transcript.append("paid campsite and %d beds placed; care and tournament remain" % _beds.size())
	return _result()


func _place_fixture(id: String) -> Node3D:
	var before := _cost_snapshot(id)
	var placed := await super._place_fixture(id)
	if placed != null and (not _paid_exactly(id, before) or not _paid_record(placed, id)):
		return null
	return placed


func _place_the_campsite() -> bool:
	var tent := await _place_fixture("tent")
	if tent == null or await _place_fixture("campfire") == null:
		return false
	_bedroll = await _place_bedroll_in_tent(tent)
	if _bedroll == null:
		return false
	if _flag("home_built"):
		_fail("campsite without a creature bed incorrectly completed home_built")
		return false
	_objective_should_be("tournament_build_home", "paid tent, fire and bedroll")
	return failures.is_empty()


func _place_bedroll_in_tent(tent: Node3D) -> Node3D:
	# Walk first, open the ordinary catalogue, then re-aim after any movement
	# required to free Interact. Placement follows camera aim in production.
	var center := tent.global_position
	for direction in [Vector3.FORWARD, Vector3.RIGHT, Vector3.BACK, Vector3.LEFT]:
		if not await _stow_piece():
			return null
		var stance: Vector3 = center - direction * PLACER.PLACE_AHEAD
		if not await _walk_to(stance, "bedroll stance", MOVE_EPSILON, false):
			continue
		if not await _select_piece("bedroll"):
			return null
		if not await _walk_to(stance, "armed bedroll stance", MOVE_EPSILON, false):
			continue
		if not await _face_with_input(center - _player.global_position):
			return null
		await _settle(10)
		var placer := _tree.get_first_node_in_group(&"build_placer")
		var ghost: Node3D = placer.get("_ghost") if placer != null else null
		if ghost == null or not bool(placer.get("_ghost_ok")):
			transcript.append("bedroll ghost refused: %s" % str(placer.get("_ghost_reason") if placer != null else "no placer"))
			continue
		var before := _cost_snapshot("bedroll")
		var buildings := _tree.get_nodes_in_group(&"placed_building")
		await _tap(&"build_place")
		await _settle(12)
		for node: Node in _tree.get_nodes_in_group(&"placed_building"):
			if not buildings.has(node) and str(node.get_meta("building_id", "")) == "bedroll":
				if not _paid_exactly("bedroll", before) or not _paid_record(node, "bedroll"):
					return null
				await _stow_piece()
				transcript.append("placed paid bedroll through a live green ghost inside the tent")
				return node as Node3D
		_fail("green bedroll placement produced no placed bedroll")
		return null
	_fail("ordinary bedroll approaches found no legal green ghost in the tent")
	return null


func _face_with_input(direction: Vector3) -> bool:
	direction.y = 0.0
	for _frame in 480:
		var forward := _forward()
		if forward.normalized().dot(direction.normalized()) >= 0.995:
			Input.action_release(&"look_left")
			Input.action_release(&"look_right")
			return true
		Input.action_release(&"look_left")
		Input.action_release(&"look_right")
		Input.action_press(&"look_right" if -forward.cross(direction).y > 0.0 else &"look_left")
		await _tree.physics_frame
	Input.action_release(&"look_left")
	Input.action_release(&"look_right")
	_fail("look input could not aim the bedroll at the tent")
	return false


func _cost_snapshot(id: String) -> Dictionary:
	var stock := {}
	var cost: Array = (_game.call("build_cost_for", id) as Array).duplicate(true)
	for requirement: Dictionary in cost:
		var item := str(requirement["id"])
		stock[item] = int(_game.get("inventory").call("count", item))
	return {"stock": stock, "cost": cost}


func _paid_exactly(id: String, before: Dictionary) -> bool:
	if bool(_game.get("free_build")) or (_game.call("build_cost_for", id) as Array).is_empty():
		_fail("paid placement lost its payable cost for " + id)
		return false
	for requirement: Dictionary in before["cost"]:
		var item := str(requirement["id"])
		var after := int(_game.get("inventory").call("count", item))
		if int(before["stock"][item]) - after != int(requirement["n"]):
			_fail("%s placement did not spend its exact %s cost" % [id, item])
			return false
	return true


func _paid_record(placed: Node, id: String) -> bool:
	var index := int(placed.get_meta("placed_index", -1))
	var records: Array = _game.get("placed_buildings")
	if index < 0 or index >= records.size():
		_fail("placed %s has no durable building record" % id)
		return false
	var record: Dictionary = records[index]
	if str(record.get("id", "")) != id or not bool(record.get("paid", false)):
		_fail("placed %s has no paid durable building receipt: %s" % [id, record])
		return false
	return true


func _hammer_in_hand() -> bool:
	var slot := int(_game.call("hotbar_slot_of", "hammer"))
	if slot < 0 or slot >= HOTBAR_ACTIONS.size():
		_fail("earned hammer must already be assigned through the village Satchel flow")
		return false
	if int(_game.get("inventory").call("count", "hammer")) <= 0:
		_fail("earned hammer is missing from inventory")
		return false
	if str(_game.get("equipped_tool")) != "hammer":
		await _tap(HOTBAR_ACTIONS[slot])
		await _settle(8)
	if str(_game.get("equipped_tool")) != "hammer":
		_fail("hammer hotbar input did not equip the earned tool")
		return false
	return true


func _stand_in_the_campsite_that_was_granted() -> bool:
	_fail("fixture campsite is forbidden in an earned campaign")
	return false


func _feed_the_team() -> void:
	_fail("direct fixture feeding is forbidden; use earned food through the Satchel")


func _play(_conversation_id: String) -> void:
	_fail("direct dialogue invocation is forbidden; walk to the marshal")


func _stand_on_the_tournament_ground() -> void:
	_fail("arena teleport is forbidden; walk to the marshal")


func _fight_and_win(_spec: Dictionary) -> bool:
	_fail("fixture combat is forbidden; use the live combat pilot")
	return false
