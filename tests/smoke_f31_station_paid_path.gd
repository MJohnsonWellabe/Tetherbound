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
const REMAINING_STATIONS := ["workbench", "altar", "den", "farm"]
const GHOST_TO_STANCE := Vector3(0.0, 0.5, 2.0) # Facing -Z, the ghost lands 2 m ahead.

var _failures: Array[String] = []
var _game: Node
var _world: Node
var _placer: Node
var _player: Node3D
var _command_tier_proof := false
var _command_config_before: Dictionary = {}
var _actor_vitals_before: Dictionary = {}


func _init() -> void:
	_run()


func _run() -> void:
	_command_tier_proof = OS.get_cmdline_user_args().has("--prove-command-tier")
	if _command_tier_proof:
		await process_frame
		var game := root.get_node("Game")
		var local: RefCounted = game.get("local")
		var session: Node = game.get("session")
		var character_id: String = str(session.call("_local_character_id")) if session != null else ""
		if session == null or session.call("is_active") == true or character_id.is_empty():
			_fail("returning-character fixtures require a stable offline identity before admission")
			_report()
			return
		# Existing returning-character fixture format from hall_agreement_net_peer::_seed_relic_hung.
		# Unlocks and ingredients are setup only; no accepted campaign boundary is claimed.
		var character: Dictionary = local.get("redesign_character")
		for biome: String in ["meadows", "tidewake", "cloudreach"]:
			if not (character.relics_hung as Array).has(biome): character.relics_hung.append(biome)
			var receipt := "relic_hang:%s:%s" % [biome, character_id]
			if not (character.transaction_receipts as Array).has(receipt): character.transaction_receipts.append(receipt)
		local.set("redesign_character", character)
		if int(game.get("party").call("size")) == 0:
			if game.get("party").call("add", preload("res://scripts/creatures/creature_species.gd").spawn("terrapup")) != true:
				_fail("disclosed pre-admission owned starter fixture was refused")
				_report()
				return
		var commands := preload("res://scripts/combat/tether_commands.gd")
		_command_config_before = commands.config()
		commands._config = _command_config_before.duplicate(true)
		for flag: String in ["runtime_enabled", "network_enabled", "ui_enabled"]: commands._config.feature_flags[flag] = true
		var math := preload("res://scripts/combat/combat_math.gd")
		_actor_vitals_before = math.config().actor_vitals.duplicate(true)
		math.config().actor_vitals = _actor_vitals_before.duplicate(true)
		math.config().actor_vitals.runtime_enabled = true
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
	if _command_tier_proof:
		await _check_crafted_command_tiers()
		_check_saved_world_binding()
		_report()
		return
	await _check_forged_legacy_station_intent_is_refused()
	var forge := await _check_paid_station_place("forge")
	if forge != null:
		var attachment := await _check_paid_attachment_place(forge)
		if attachment != null:
			await _check_dismantle_order_and_refund(forge, attachment)
	await _check_host_station_craft_settles_the_panel()
	await _check_remaining_stations_place()
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
		_fail("pressing Place on a legal %s ghost journaled/planted nothing (row %s, ghost ok %s reason '%s' at %s)" % [id, str(row),
			str(_placer.get("_ghost_ok")), str(_placer.get("_ghost_reason")), str(_player.global_position)])
		return null
	# The Altar keeps its own (version-1) altar journal; the other stations
	# use the version-2 homestead row.
	var version := 1 if id == "altar" else 2
	if row.status != "accepted" or int(row.version) != version:
		_fail("%s placement row did not settle as an accepted version-%d row: %s" % [id, version, str(row)])
	var after := _counts(cost)
	for need: Dictionary in cost:
		if int(after[need.id]) != int(before[need.id]) - int(need.n):
			_fail("%s placement spent %d %s, not the settled %d" % [id, int(before[need.id]) - int(after[need.id]), need.id, int(need.n)])
	var index := int(_game.get("world").call("building_index_of", uid))
	if index < 0 or (id != "altar" and not DELIVERY.record_valid(_game.get("placed_buildings")[index])):
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
	var announced: Array[int] = [0]
	var count_completion := func(op: String, _intent: Dictionary, _result: Dictionary) -> void:
		if op == "station_craft": announced[0] += 1
	_game.get("session").connect("homestead_action_completed", count_completion)
	panel.call("_station_action", "station_craft", {"recipe_id": "potion_small"})
	for i in 300:
		if (panel.get("_station_intent") as Dictionary).is_empty(): break
		await physics_frame
	# Several background polls (0.5 s each) re-deliver the accepted row; the
	# completion must still be announced exactly once.
	for i in 150: await physics_frame
	_game.get("session").disconnect("homestead_action_completed", count_completion)
	if announced[0] != 1:
		_fail("the host's craft completion was announced %d times, not once" % announced[0])
	else:
		print("host craft completion announced exactly once across later polls")
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


## F31#0: the other base stations go through the same paid press, each from
## its own stance along the open yard (the Kitchen above keeps its cell).
## Chests are the existing Storage piece (smoke_menu_focus places one).
func _check_remaining_stations_place() -> void:
	for id: String in REMAINING_STATIONS:
		var cell := _legal_cell(id)
		if not cell.is_finite():
			_fail("no legal homestead cell found for the %s near the yard" % id)
			continue
		_player.global_position = cell + GHOST_TO_STANCE
		for i in 10: await physics_frame
		if await _check_paid_station_place(id) != null:
			await _press("build_cancel")
			for i in 6: await physics_frame


## The first open, level homestead cell (by the placer's own legality) along
## the yard; the ghost then lands there from the trainer's ordinary stance.
func _legal_cell(id: String) -> Vector3:
	var cfg := STATION_RULES.config()
	for dz in [0, -4, 4, -8, 8]:
		for dx in range(0, 40, 4):
			for sign: int in [-1, 1]:
				var x: float = STANCE.x + sign * dx
				var z: float = STANCE.z - GHOST_TO_STANCE.z + dz
				var at := Vector3(x, float(_world.call("ground_height_at", x, z)), z)
				var legal: bool = _placer.call("_altar_pose_valid", _game, "meadows", at, 0.0).ok if id == "altar" else \
					(STATION_RULES.placement(cfg, _game.get("placed_buildings"), id, "meadows", at, 0.0, {}, "").get("ok") == true \
						and _placer.call("_station_pose_valid", _game, id, "meadows", at, 0.0).get("ok") == true)
				if legal:
					return at
	return Vector3.INF


func _check_saved_world_binding() -> void:
	var world: RefCounted = _game.get("world")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(world.save_data()))
	var errors := WORLD.training_world_errors(saved.get("reward_deliveries", {}), str(saved.get("reward_delivery_namespace", "")),
		str(saved.get("world_id", "")), saved.get("placed_buildings", []))
	if not errors.is_empty(): _fail("the saved world's station journal does not bind: %s" % str(errors))
	else: print("saved world journal binds every station record")


## F24#4: required crafted-tier witness; same paid placement/panel transaction as F31.
## Fixtures: pre-admission regional relic entitlements/one owned starter if empty,
## existing _fund ingredients, harness relocation and ordinary wild auto-engage callback.
func _check_crafted_command_tiers() -> void:
	var cell := _legal_cell("workbench")
	if not cell.is_finite():
		_fail("no legal Workbench cell for the command-tier witness")
		return
	_player.global_position = cell + GHOST_TO_STANCE
	for i in 10: await physics_frame
	var bench := await _check_paid_station_place("workbench")
	if bench == null: return
	await _press("build_cancel")
	var gear := preload("res://scripts/creatures/creature_gear.gd").config()
	var inventory: RefCounted = _game.get("inventory")
	var equipment: RefCounted = _game.get("local").get("equipment")
	var completed: Array[Dictionary] = []
	for prefix: String in ["rootiron", "tidesteel", "skyglass", "stormglass"]:
		var item := prefix + "_command_pouch"
		var recipe_id := "craft_" + item
		var recipe: Dictionary = gear.recipes[recipe_id]
		_fund(recipe.cost) # Same disclosed paid-path supplies; output is never granted.
		var before := _counts(recipe.cost)
		var owned_before := int(inventory.call("count", item))
		bench.call("_open")
		for i in 20: await physics_frame
		var panel: Node = bench.get("_panel")
		if panel == null or not bool(panel.call("is_open")):
			_fail("real Workbench panel did not open for " + recipe_id)
			return
		var reply := {"result": {}}
		var on_complete := func(op: String, _intent: Dictionary, result: Dictionary) -> void:
			if op == "station_craft": reply.result = result.duplicate(true)
		_game.get("session").connect("homestead_action_completed", on_complete)
		panel.call("_station_action", "station_craft", {"recipe_id": recipe_id})
		for i in 600:
			if reply.result.get("settled") == true or reply.result.get("terminal_refusal") == true: break
			await physics_frame
		_game.get("session").disconnect("homestead_action_completed", on_complete)
		var after := _counts(recipe.cost)
		if reply.result.get("ok") != true or reply.result.get("settled") != true or int(inventory.call("count", item)) != owned_before + 1:
			_fail("Workbench craft failed to settle one " + item + ": " + str(reply.result))
			panel.call("close")
			return
		for need: Dictionary in recipe.cost:
			if int(after.get(need.id, 0)) != int(before.get(need.id, 0)) - int(need.n): _fail("pouch craft cost mismatch: " + str(need))
		completed.append({"item": item, "recipe": recipe_id, "before": before, "after": after, "result": reply.result})
		panel.call("close")
		for i in 10: await physics_frame
	# Use the actual Backpack Equip verb; local-only mutation cannot update
	# admitted equipment and is deliberately refused by its refresh guard.
	var menu: Node = _game.call("menu")
	menu.call("open", "backpack")
	for i in 10: await process_frame
	var backpack: Node
	for i in (menu.get("_tabs") as Array).size():
		if menu.get("_tabs")[i].get("id") == "backpack": backpack = menu.get("_bodies")[i]
	var equip_reply := {"result": {}}
	var on_equip := func(op: String, _intent: Dictionary, result: Dictionary) -> void:
		if op == "trainer_equip": equip_reply.result = result.duplicate(true)
	if backpack == null:
		_fail("actual Backpack did not open for crafted pouch Equip")
		return
	_game.get("session").connect("homestead_action_completed", on_equip)
	backpack.get("_buttons")[int(inventory.call("find_slot", "stormglass_command_pouch"))].grab_focus()
	await process_frame
	await _press("interact")
	for i in 600:
		if equip_reply.result.get("settled") == true or equip_reply.result.get("terminal_refusal") == true: break
		await process_frame
	_game.get("session").disconnect("homestead_action_completed", on_equip)
	menu.call("close")
	if equip_reply.result.get("settled") != true or equipment.call("equipped_in", "backpack") != "stormglass_command_pouch" \
		or int(inventory.call("count", "stormglass_command_pouch")) != 0:
		_fail("actual Backpack Equip did not settle crafted Stormglass: " + str(equip_reply.result))
		return
	var director: Node = _world.get_node("EncounterDirector")
	var manager: Node = _world.get_node("CombatManager")
	# Owning a creature is distinct from recalling its grounded body. Use the
	# same production recall seam exercised by smoke_creature_control.
	if director.call("ally_instance") == null and not await director.call("summon_active_creature"):
		_fail("actual owned creature recall was refused before command admission")
		return
	var wild: Node3D = director.call("aggressive_creature")
	if wild == null:
		_fail("no authored wild body for crafted-pouch gameplay admission")
		return
	_player.global_position = wild.global_position + Vector3(3.0, 0.0, 3.0)
	for i in 30: await physics_frame
	var canonical: Dictionary = director.call("_canonical_wild_start_state", wild)
	print("F24_COMMAND_ADMISSION " + JSON.stringify({"canonical": canonical,
		"context": _game.get("session").call("_host_wild_training_context"),
		"owned_uid": str(director.call("ally_instance").get("uid")),
		"body_ready": director.get("_ally_ready_body") != null}))
	if canonical.get("ready") != true:
		_fail("crafted gear's canonical actor preflight refused: " + str(canonical))
		return
	director.call("_on_wild_wants_to_engage", wild)
	for i in 180:
		if manager.call("is_fighting") == true and int(manager.call("tether_command_snapshot").get("tier", -1)) == 4: break
		await physics_frame
	var snapshot: Dictionary = manager.call("tether_command_snapshot")
	var host: RefCounted = director.get("_encounter_host")
	var id: String = str(manager.call("encounter_id"))
	var record: Dictionary = host.call("record", id) if host != null else {}
	var pool: Dictionary = record.get("participants", {}).get(1, {}).get("tether_commands", {})
	if manager.call("is_fighting") != true or pool.get("tier") != 4 or snapshot.get("tier") != 4:
		_fail("real command admission did not consume the crafted/equipped tier: " + str(snapshot))
	print("F24_CRAFTED_COMMAND_TIERS " + JSON.stringify({"crafted": completed, "equipment": equipment.call("save_data"),
		"equip_result": equip_reply.result,
		"canonical_ready": canonical.get("ready"), "encounter_kind": record.get("kind"), "pool": pool, "snapshot": snapshot,
		"tier_profile": preload("res://scripts/combat/tether_commands.gd").tier_profile(4), "fixtures": "regional relic receipts and pre-admission starter; funded costs; harness relocation/auto-engage; process-local gates"}))


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if not _command_config_before.is_empty(): preload("res://scripts/combat/tether_commands.gd")._config = _command_config_before
	if not _actor_vitals_before.is_empty(): preload("res://scripts/combat/combat_math.gd").config().actor_vitals = _actor_vitals_before
	print("")
	if _failures.is_empty():
		print("F31 station paid path smoke test passed")
		quit(0)
		return
	for line in _failures: print("  FAIL: %s" % line)
	quit(1)
