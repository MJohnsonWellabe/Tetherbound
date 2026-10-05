extends SceneTree

## F31 paid station path, end to end in the real Meadows world:
##
##   godot --headless --path . --script tests/smoke_f31_station_paid_path.gd
##
## Pressing Place on a legal homestead ghost must journal a version-2 row,
## debit exactly the settled price through the owner import, plant the
## canonical record and settle its typed ACK. A live Meadows attachment snaps
## to its parent's socket and raises that station's tier. Dismantle refuses
## while an attachment stands, then refunds exactly the paid price through a
## proven refund row. The saved world keeps every row bound to its records,
## and a forged legacy intent can neither plant nor remove a station.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const DELIVERY := preload("res://scripts/net/homestead_building_delivery.gd")
const WORLD := preload("res://autoload/world_state.gd")
const STATION_RULES := preload("res://scripts/build/station_rules.gd")
const RULES := preload("res://scripts/world/death_satchel_rules.gd")
## Open homestead yard west of the berry beds; facing the default -Z the
## ghost lands on the (-6, 20) cell.
const STANCE := Vector3(-6.0, 1.4, 22.0)
const SETTLE_FRAMES := 240

var _failures: Array[String] = []
var _game: Node
var _world: Node
var _placer: Node
var _player: Node3D


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	# The title enters this world with change_scene_to_file.
	current_scene = _world
	for i in SETTLE_FRAMES: await physics_frame
	_game = root.get_node_or_null(^"Game")
	_placer = _world.get_node_or_null(^"BuildPlacer")
	_player = _world.get_node_or_null(^"Player") as Node3D
	if _game == null or _placer == null or _player == null:
		_fail("the Meadows world has no Game, BuildPlacer or Player")
		_report()
		return
	_player.global_position = STANCE
	for i in 10: await physics_frame
	await _check_forged_legacy_station_intent_is_refused()
	var forge := await _check_paid_station_place("forge")
	if forge != null:
		var attachment := await _check_paid_attachment_place(forge)
		if attachment != null:
			await _check_dismantle_order_and_refund(forge, attachment)
	await _check_host_station_craft_settles_the_panel()
	_check_saved_world_binding()
	_report()


func _check_forged_legacy_station_intent_is_refused() -> void:
	var transport: Node = _game.get("session").get_node_or_null(^"LedgerRpc")
	var before: int = _game.get("placed_buildings").size()
	var verdict: Dictionary = transport.call("submit", {"kind": "place_building", "realm": "meadows", "id": "kitchen",
		"position": [-6.0, 0.9, 20.0], "yaw_deg": 0.0, "paid": true, "txn_id": "zz"})
	if verdict.get("ok") == true or verdict.get("pending") == true or _game.get("placed_buildings").size() != before:
		_fail("a forged/malformed station intent was accepted: %s" % str(verdict))
	else:
		print("forged station intent refused (%s)" % str(verdict.get("code", "")))


func _counts(cost: Array) -> Dictionary:
	var out := {}
	var inventory: RefCounted = _game.get("inventory")
	for need: Dictionary in cost: out[need.id] = int(inventory.call("count", need.id))
	return out


func _fund(cost: Array) -> void:
	for need: Dictionary in cost: _game.get("inventory").call("add", need.id, int(need.n))


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)


func _node_for(uid: String) -> Node3D:
	for node: Node in get_nodes_in_group("placed_building"):
		if node.get_meta("building_uid", "") == uid and _world.is_ancestor_of(node): return node as Node3D
	return null


func _row_for(uid: String, action: String) -> Dictionary:
	for raw: Variant in _game.get("world").reward_deliveries.values():
		if raw is Dictionary and raw.get("kind") == "altar_building" and raw.get("action") == action \
				and raw.get("intent", {}).get("record", {}).get("uid") == uid: return raw
	return {}


## Waits for the owner import and the typed ACK to settle the row.
func _await_accepted(uid: String, action: String) -> Dictionary:
	for i in 240:
		var row := _row_for(uid, action)
		if row.get("status") == "accepted": return row
		await physics_frame
	return _row_for(uid, action)


func _check_paid_station_place(id: String) -> Node3D:
	var cost := DELIVERY.cost(id)
	_fund(cost)
	var before := _counts(cost)
	var uid := "b%d" % int(_game.get("world").next_building_uid)
	_game.set("pending_build", id)
	for i in 30: await physics_frame
	await _press("build_place")
	var row := await _await_accepted(uid, "place_building")
	var node := _node_for(uid)
	if node == null or row.is_empty():
		_fail("pressing Place on a legal %s ghost journaled/planted nothing (row %s)" % [id, str(row)])
		return null
	if row.status != "accepted" or int(row.version) != 2:
		_fail("%s placement row did not settle as an accepted version-2 row: %s" % [id, str(row)])
	var after := _counts(cost)
	for need: Dictionary in cost:
		if int(after[need.id]) != int(before[need.id]) - int(need.n):
			_fail("%s placement spent %d %s, not the settled %d" % [id, int(before[need.id]) - int(after[need.id]), need.id, int(need.n)])
	var index := int(_game.get("world").call("building_index_of", uid))
	if index < 0 or not DELIVERY.record_valid(_game.get("placed_buildings")[index]):
		_fail("%s has no canonical version-2 world record" % id)
	if not str(node.name).begins_with("Piece_" + id):
		_fail("the planted %s is named %s" % [id, node.name])
	print("%s planted through the paid journal; exact price spent; row accepted" % id)
	return node


func _check_paid_attachment_place(parent: Node3D) -> Node3D:
	var id := "forge_meadows"
	var parent_uid := str(parent.get_meta("building_uid", ""))
	var cost := DELIVERY.cost(id)
	_fund(cost)
	var before := _counts(cost)
	var uid := "b%d" % int(_game.get("world").next_building_uid)
	_game.set("pending_build", id)
	for i in 30: await physics_frame
	await _press("build_place")
	var row := await _await_accepted(uid, "place_building")
	var node := _node_for(uid)
	if node == null or row.is_empty() or row.status != "accepted":
		_fail("pressing Place on the snapped %s ghost did not settle a paid attachment (row %s)" % [id, str(row)])
		return null
	var record: Dictionary = row.intent.record
	if record.parent_uid != parent_uid or int(record.slot) != 1:
		_fail("%s recorded parent %s slot %s" % [id, record.parent_uid, str(record.slot)])
	var after := _counts(cost)
	for need: Dictionary in cost:
		if int(after[need.id]) != int(before[need.id]) - int(need.n):
			_fail("%s spent the wrong %s" % [id, need.id])
	var tier := STATION_RULES.effective_tier(STATION_RULES.config(), _game.get("placed_buildings"), parent_uid)
	if tier.get("ok") != true or int(tier.effective_tier) != 1:
		_fail("the paid Meadows attachment did not raise the Forge to tier 1: %s" % str(tier))
	else:
		print("%s snapped to slot 1 of %s; Forge effective tier 1" % [id, parent_uid])
	await _press("build_cancel")
	for i in 6: await physics_frame
	return node


func _check_dismantle_order_and_refund(forge: Node3D, attachment: Node3D) -> void:
	var forge_uid := str(forge.get_meta("building_uid", ""))
	var attachment_uid := str(attachment.get_meta("building_uid", ""))
	if _placer.call("dismantle_piece", _game, forge) == true:
		_fail("the Forge dismantle was accepted while its attachment stands")
	for i in 10: await physics_frame
	for pair: Array in [[attachment, attachment_uid, "forge_meadows"], [forge, forge_uid, "forge"]]:
		var cost := DELIVERY.cost(pair[2])
		var before := _counts(cost)
		if _placer.call("dismantle_piece", _game, pair[0]) != true:
			_fail("dismantling the paid %s was refused" % pair[2])
			continue
		var row := await _await_accepted(pair[1], "dismantle")
		if row.is_empty() or row.status != "accepted" or int(row.version) != 2:
			_fail("the %s refund row did not settle: %s" % [pair[2], str(row)])
		for i in 10: await physics_frame
		if int(_game.get("world").call("building_index_of", pair[1])) >= 0 or is_instance_valid(_node_for(pair[1])):
			_fail("the dismantled %s is still standing" % pair[2])
		var after := _counts(cost)
		for need: Dictionary in cost:
			if int(after[need.id]) != int(before[need.id]) + int(need.n):
				_fail("dismantling %s refunded %d %s, not the paid %d" % [pair[2], int(after[need.id]) - int(before[need.id]), need.id, int(need.n)])
		print("%s dismantled; exact paid price refunded through a proven row" % pair[2])


## Coordinator / lane B finding: a host's own station craft (solo too) was
## answered "awaiting_saved_decision" and, once its row was accepted, nothing
## announced it, so the station panel never cleared and its Craft buttons
## stayed disabled. Real Kitchen + Spice rack, the real panel's own recipe
## handler (_station_action, what the row press calls), real Small Potion.
func _check_host_station_craft_settles_the_panel() -> void:
	var kitchen := await _check_paid_station_place("kitchen")
	if kitchen == null:
		return
	_game.set("pending_build", "kitchen_meadows")
	_fund(DELIVERY.cost("kitchen_meadows"))
	var rack_uid := "b%d" % int(_game.get("world").next_building_uid)
	for i in 30: await physics_frame
	await _press("build_place")
	if (await _await_accepted(rack_uid, "place_building")).get("status") != "accepted":
		_fail("the Spice rack did not settle for the craft check")
		return
	await _press("build_cancel")
	for i in 10: await physics_frame
	_game.get("inventory").call("add", "berries", 4)
	_game.get("inventory").call("add", "fiber", 1)
	var potions := int(_game.get("inventory").call("count", "potion_small"))
	kitchen.call("_open")
	for i in 20: await physics_frame
	var panel: Node = kitchen.get("_panel")
	if panel == null or not bool(panel.call("is_open")):
		_fail("the Kitchen's station panel did not open")
		return
	panel.call("_station_action", "station_craft", {"recipe_id": "potion_small"})
	for i in 300:
		if (panel.get("_station_intent") as Dictionary).is_empty(): break
		await physics_frame
	if not (panel.get("_station_intent") as Dictionary).is_empty():
		_fail("the host's station craft never settled the panel (status '%s')" % str(panel.get("_status").text))
	elif int(_game.get("inventory").call("count", "potion_small")) != potions + 1:
		_fail("the settled craft did not grant exactly one Small Potion")
	else:
		var enabled := false
		for button: Button in panel.get("_station_buttons"):
			if not button.disabled: enabled = true
		if not enabled:
			_fail("the station buttons stayed disabled after the craft settled")
		else:
			print("host Kitchen craft settled: panel cleared ('%s'), one Small Potion, buttons re-enabled" % str(panel.get("_status").text))
	panel.call("close")
	for i in 10: await physics_frame


func _check_saved_world_binding() -> void:
	var world: RefCounted = _game.get("world")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(world.save_data()))
	var errors := WORLD.training_world_errors(saved.get("reward_deliveries", {}), str(saved.get("reward_delivery_namespace", "")),
		str(saved.get("world_id", "")), saved.get("placed_buildings", []))
	if not errors.is_empty(): _fail("the saved world's station journal does not bind: %s" % str(errors))
	else: print("saved world journal binds every station record")


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("F31 station paid path smoke test passed")
		quit(0)
		return
	for line in _failures: print("  FAIL: %s" % line)
	quit(1)
