extends "res://tools/earned_saves/wip_fights/homestead_common.gd"

## One retained party slot per saved piece, at most nineteen paid levels.
## Building, gathering, storage withdrawal and walking reuse Fights' actual
## homestead input. No quote/submit/receipt producer is called by this helper.
const TRAINING := preload("res://tools/earned_saves/training_handoff.gd")
const ALTAR_PANEL := preload("res://scripts/ui/altar_panel.gd")
const ALTAR_INTERACTION := preload("res://scripts/ui/altar_station_interaction.gd")
const ALTAR_SERVICE := preload("res://scripts/ui/altar_service.gd")
const BRIDGE_ROUTE := preload("res://tests/helpers/meadows_earned_bridge_segment.gd")
const MAX_PAYMENTS := 19
const SPINE := preload("res://tests/helpers/meadows_earned_warrens_segment.gd")
## The Sigils piece follows the departure spine from the Old Mill Crossing's
## north road end; Mira's loop (t2) returns there along the north spine.
const MILL_NORTH_END := Vector2(-152.0, 4235.0)
var _completions: Array[Dictionary] = []

static func preflight(training: Dictionary, tier: int, index: int) -> Array[String]:
	if tier not in [1, 2, 3, 4, 5] or index < 0 or index >= 5: return ["Unknown Altar tier or slot"]
	var prior: Array = []
	for value in range(1, tier): prior.append(value)
	var party: Array = training.get("party", [])
	if party.size() != 5: return ["Altar piece requires the retained five"]
	var seen := {}
	for card: Dictionary in party:
		var uid := str(card.get("uid", ""))
		if uid.is_empty() or seen.has(uid): return ["Missing or duplicate retained UID"]
		seen[uid] = true
		if int(card.get("cap_level", -1)) != tier * 10 or card.get("breakthroughs") != prior:
			return ["Altar requires exact prior feast/cap history"]
		if int(card.get("level", -1)) < maxi(1, (tier - 1) * 10) or int(card.level) > tier * 10 or int(card.get("xp", -1)) < 0:
			return ["Invalid retained training level or XP"]
		if int(card.level) == tier * 10 and int(card.xp) != 0: return ["Locked cap must have zero XP"]
	for value in prior:
		if not training.get("master_wins", []).has("master_t%d" % value) or not training.get("feast_recipes", []).has("feast_t%d" % value):
			return ["Altar requires every prior saved Master win and recipe"]
	return []

## Pure witness check: completion alone, a level bump alone, or an old receipt
## cannot pass. Check the actual saved receipt and exact aggregate item delta.
static func payment_errors(before: Dictionary, after: Dictionary, bag_before: Dictionary, bag_after: Dictionary,
		old_receipts: Array, saved_receipts: Array, event: Dictionary, intent: Dictionary) -> Array[String]:
	var result: Dictionary = event.get("result", {})
	if result.get("ok") != true or result.get("resolved") != true or result.get("saved") != true or result.get("durable") != true:
		return ["Altar payment lacks a resolved durable saved decision"]
	var id := str(event.get("spend_id", ""))
	if id.is_empty() or id.contains(":"): return ["Invalid Altar spend identity"]
	# The displayed revision is not the first-send revision: the host service
	# may rebase it after passive care. Bind the actual accepted journal intent,
	# captured synchronously at completion, rather than trusting a receipt suffix.
	var admitted: Dictionary = event.get("admitted_request", {})
	if admitted.size() != 5 or admitted.get("spend_id") != id or admitted.get("creature_uid") != intent.uid \
			or admitted.get("expected_level") != intent.level or admitted.get("payment_item") != intent.item \
			or not ESSENCE._integer(admitted.get("expected_character_revision"), int(intent.revision), 2147483646):
		return ["Altar saved intent differs from the selected spend/UID/level/payment or regressed revision"]
	var receipt := "essence_spend:%s:%s:%s:%d:%s:%d:%d" % [intent.character_id, id,
		intent.uid, intent.level, intent.item, intent.cost, admitted.expected_character_revision]
	if result.get("receipt") != receipt or old_receipts.has(receipt) or not saved_receipts.has(receipt):
		return ["Altar receipt does not bind this new UID/level/payment/revision"]
	var expected_bag := bag_before.duplicate(true)
	if int(intent.cost) < 1 or int(expected_bag.get(intent.item, 0)) < int(intent.cost): return ["Unfunded Altar payment"]
	expected_bag[intent.item] = int(expected_bag[intent.item]) - int(intent.cost)
	if expected_bag[intent.item] == 0: expected_bag.erase(intent.item)
	if expected_bag != bag_after: return ["Altar payment changed unrelated inventory or spent the wrong quantity"]
	var expected := before.duplicate(true)
	var found := false
	for card: Dictionary in expected.get("party", []):
		if card.get("uid") == intent.uid:
			if found or card.get("level") != intent.level or int(card.get("cap_level", 0)) <= int(intent.level): return ["Stale or capped Altar intent"]
			found = true
			card.level = int(card.level) + 1
			if card.level == card.cap_level: card.xp = 0
	if not found or expected != after: return ["Altar changed unrelated training or failed to raise exactly the selected UID"]
	return []

func run_training(tree: SceneTree, world: Node3D, game: Node, args: Dictionary = {}) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	if tree == null or not is_instance_valid(world) or not is_instance_valid(game) or tree.current_scene != world \
			or game.get("current_realm") != "meadows" or bool(game.get("free_build")) or INPUT_OWNER.current(tree) != null:
		_fail("Altar piece requires the paid, loaded Meadows with ordinary input")
		return _out()
	var tier := int(args.get("tier", 0))
	var index := int(args.get("party_index", -1))
	var before := TRAINING.snapshot(game)
	var seam := TRAINING.compare({"training": args.get("previous_training", {})}, {"training": before})
	failures.append_array(preflight(before, tier, index))
	if not bool(seam.matches): _fail("Altar input training differs from the loaded predecessor")
	if not failures.is_empty(): return _out()
	if not _bind_homestead(): return _out()
	var uid := str(before.party[index].uid)
	var station := _placed("altar")
	# A saved later slot may already stand beside the paid Altar outside the
	# village fence. Do not walk away from its live prompt and through that fence.
	if station == null or not _at_home():
		if not await _go_home(): return _out()
		station = _placed("altar")
	if station == null:
		if not await _fund({"altar": 1}): return _out()
		station = await _place_on_plot("altar")
		if station == null: return _out()
	var interaction := station.get_node_or_null("AltarInteraction")
	if interaction == null or interaction.get_script() != ALTAR_INTERACTION or interaction.call("_live_binding") != true:
		_fail("Paid Altar lacks its actual registered interaction")
		return _out()
	var prompt := interaction.get_node_or_null("TrainingInteractable") as Node3D
	if prompt == null or not await _walk_to_prompt(prompt, "paid Altar"):
		_fail("Ordinary approach did not reach the Altar prompt")
		return _out()
	if TRAINING.snapshot(game) != before:
		_fail("Travel/building changed training before the selected payment piece")
		return _out()
	await _tap(&"interact")
	var panel := await _owner_of(ALTAR_PANEL)
	var service := game.get_node_or_null("AltarService")
	if panel == null or service == null or service.get_script() != ALTAR_SERVICE \
			or panel.get("_service") != service or panel.get("_station_key") != interaction.get("_key"):
		_fail("Prompt did not open this Altar's production payment panel")
		return _out()
	service.connect("essence_spend_completed", _on_payment)
	var ok := await _raise_to_cap(panel, uid, tier * 10, prompt)
	if is_instance_valid(service): service.disconnect("essence_spend_completed", _on_payment)
	if not ok: return _out()
	await _tap(&"menu_cancel")
	if not await _until(func() -> bool: return INPUT_OWNER.current(_tree) == null):
		_fail("Altar did not release world input")
	_receipt("altar_piece", {"uid": uid, "tier": tier, "training_before": before, "training_after": TRAINING.snapshot(game), "reload_verified": false})
	return _out()

func _bind_homestead() -> bool:
	_player = _world.get_node_or_null("Player") as CharacterBody3D
	_rig = _world.get_node_or_null("CameraRig") as Node3D
	_progression = _game.get("progression")
	_party = _game.get("party")
	if _player == null or _rig == null or not _collect_nodes(): return _fail_b("Training piece lacks live homestead movement nodes")
	_resolve_move_bindings()
	if not failures.is_empty(): return false
	_travel = TRAVEL.new(_tree, _game)
	return true

## The Warrens input checks physical far-bank stance. Reuse the authored
## bridge approach and live near/far points after the saved homestead loop.
func return_to_bridge(tree: SceneTree, world: Node3D, game: Node, previous: Dictionary, onward_to_mill := false) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	if tree == null or not is_instance_valid(world) or not is_instance_valid(game) or tree.current_scene != world \
			or game.get("current_realm") != "meadows" or bool(game.get("free_build")) or INPUT_OWNER.current(tree) != null:
		_fail("Training return requires ordinary paid Meadows input")
		return _out()
	var before := TRAINING.snapshot(game)
	if not TRAINING.compare({"training": previous}, {"training": before}).matches:
		_fail("Training return differs from the saved feed predecessor")
		return _out()
	if not _bind_homestead(): return _out()
	var bridge := world.get_node_or_null("SouthBridge") as Node3D
	if bridge == null or not bool(bridge.call("is_open")) or not _flag("south_bridge_open") or not _flag("defeated_south_bridge_grunt"):
		_fail("Training return requires the already earned open bridge")
		return _out()
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BRIDGE_ROUTE.TERRAIN))
	var crossing := BRIDGE_ROUTE.crossing_config(config)
	var route := BRIDGE_ROUTE.approach_route(config)
	if crossing.is_empty() or route.is_empty():
		_fail("Training return lacks the authored bridge approach")
		return _out()
	var carve: Dictionary = crossing.get("carve", {})
	var bank := float(carve.get("half_width", 0.0)) + float(carve.get("rim", 0.0)) + 3.0
	route.append(bridge.call("near_point", bank))
	route.append(bridge.call("far_point", bank))
	if not await _stow_piece() or not await _stow_hammer(): return _out()
	for point: Vector2 in route:
		var at := Vector3(point.x, float(world.call("ground_height_at", point.x, point.y)), point.y)
		if not await _walk_to(at, "earned bridge return", 0.6): return _out()
	var depth := float(bridge.call("depth_past_crossing", Vector2(_player.global_position.x, _player.global_position.z)))
	if depth < bank - 0.6 or TRAINING.snapshot(game) != before:
		_fail("Training return failed physical far-bank or retained training checks")
	_receipt("training_bridge_return", {"depth": depth, "required_depth": bank - 0.6, "training": TRAINING.snapshot(game)})
	if onward_to_mill and failures.is_empty():
		for point: Vector2 in mill_legs(config):
			var at := Vector3(point.x, float(world.call("ground_height_at", point.x, point.y)), point.y)
			if not await _walk_to(at, "earned north spine return", 0.6 if point == MILL_NORTH_END else 10.0): return _out()
		if TRAINING.snapshot(game) != before:
			_fail("Training return changed retained training on the north spine")
		_receipt("training_mill_return", {"player": _player.global_position, "training": TRAINING.snapshot(game)})
	return _out()

## Far bank -> the north spine (bands 2 and 3) -> the Old Mill Crossing's north
## road end, where the Sigils piece's departure spine begins.
static func mill_legs(terrain: Dictionary) -> Array[Vector2]:
	var legs: Array[Vector2] = []
	for id: String in ["band2_stone_and_root", "band3_the_river_lock"]:
		for point: Vector2 in SPINE.trail_points(terrain, "bands", id):
			if not legs.is_empty() and legs[-1] == point: continue
			legs.append(point)
			if point == MILL_NORTH_END: return legs
	return []

func _raise_to_cap(panel: Node, uid: String, target: int, prompt: Node3D) -> bool:
	if not await _altar_focus(panel, "creature:" + uid): return _fail_b("Cannot focus retained Altar companion")
	await _tap(&"ui_accept")
	var payments := 0
	for _attempt in MAX_PAYMENTS * 2 + 1:
		if not await _until(func() -> bool: return is_instance_valid(panel) and not bool(panel.get("_quote_waiting")) and str(panel.get("_pending_id")).is_empty()):
			return _fail_b("Altar quote/payment did not settle within the bounded wait")
		var quote: Dictionary = panel.get("_quote")
		if quote.get("creature_uid") != uid or int(quote.get("cap", -1)) != target:
			return _fail_b("Altar quote does not bind the retained UID and earned cap")
		if int(quote.get("level", -1)) == target: return true
		if payments == MAX_PAYMENTS: return _fail_b("Altar piece exceeded nineteen payments")
		var payment := {}
		# Production quote order: compatible essence types, then earned candy.
		for row: Dictionary in quote.get("payments", []):
			if int(row.get("cost", 0)) > 0 and int(row.get("available", 0)) >= int(row.cost):
				payment = row.duplicate(true)
				break
		if payment.is_empty():
			panel = await _retrieve_payment(panel, quote, prompt, uid)
			if panel == null: return false
			continue
		if not await _altar_focus(panel, "payment:" + str(payment.id)): return _fail_b("Cannot focus the quoted Altar payment")
		# Focus must not have replaced the quote with another creature/revision.
		if panel.get("_quote") != quote: return _fail_b("Altar quote changed while focusing payment")
		var before := TRAINING.snapshot(_game)
		var bag := _stacks()
		var old: Array = _game.get("local").get("redesign_character").get("transaction_receipts", []).duplicate()
		var intent := {"character_id": str(_game.get("local").get("character_id")), "uid": uid,
			"level": int(quote.level), "item": str(payment.id), "cost": int(payment.cost), "revision": int(quote.expected_character_revision)}
		_completions.clear()
		await _tap(&"ui_accept")
		if not await _until(func() -> bool: return not _terminal_payment().is_empty()):
			return _fail_b("Altar payment lacks a terminal saved decision; do not replay a new intent")
		var event := _terminal_payment()
		var saved: Array = _game.get("local").get("redesign_character").get("transaction_receipts", [])
		var errors := payment_errors(before, TRAINING.snapshot(_game), bag, _stacks(), old, saved, event, intent)
		if not errors.is_empty():
			failures.append_array(errors)
			return false
		payments += 1
		_receipt("altar_payment", {"intent": intent, "completion": event, "training_before": before,
			"training_after": TRAINING.snapshot(_game), "inventory_before": bag, "inventory_after": _stacks()})
	return _fail_b("Altar payment/retrieval budget exhausted")

## Called only when no carried payment is affordable. Retrieve one quoted
## shortfall through Fights' conserved chest UI, then reopen the real prompt.
## Do not reserve every alternative or withdraw while a payment is pending.
func _retrieve_payment(panel: Node, quote: Dictionary, prompt: Node3D, uid: String) -> Node:
	var before := TRAINING.snapshot(_game)
	var stored := {}
	for chest: Node3D in storage_chests(_world, _tree.get_nodes_in_group(&"placed_building")):
		for row: Dictionary in quote.get("payments", []):
			stored[row.id] = int(stored.get(row.id, 0)) + _chest_count(chest, str(row.id))
	var needed := stored_payment(quote.get("payments", []), _stacks(), stored)
	if needed.is_empty():
		_fail("No earned compatible Altar payment in bag or storage; acquire resources before resuming")
		return null
	var key: String = str(panel.get("_station_key"))
	var service: Node = panel.get("_service")
	await _tap(&"menu_cancel")
	if not await _until(func() -> bool: return INPUT_OWNER.current(_tree) == null):
		_fail("Altar did not release input for earned payment retrieval")
		return null
	if not await _withdraw_available(needed) or not is_instance_valid(prompt) or not await _walk_to_prompt(prompt, "paid Altar"):
		if failures.is_empty(): _fail("Stored payment return lost the actual Altar prompt")
		return null
	await _tap(&"interact")
	var reopened := await _owner_of(ALTAR_PANEL)
	if reopened == null or reopened.get("_station_key") != key or reopened.get("_service") != service:
		_fail("Stored payment return opened a different Altar")
		return null
	if TRAINING.snapshot(_game) != before:
		_fail("Stored payment retrieval changed retained training")
		return null
	if not await _altar_focus(reopened, "creature:" + uid):
		_fail("Stored payment return lost the retained companion choice")
		return null
	await _tap(&"ui_accept")
	return reopened

static func stored_payment(payments: Array, carried: Dictionary, stored: Dictionary) -> Dictionary:
	# A full bag already able to pay must not attempt an unnecessary withdrawal.
	for row: Dictionary in payments:
		if int(row.get("cost", 0)) > 0 and int(carried.get(row.get("id"), 0)) >= int(row.cost): return {}
	for row: Dictionary in payments:
		var cost := int(row.get("cost", 0))
		var item := str(row.get("id", ""))
		if cost > 0 and not item.is_empty() and int(carried.get(item, 0)) + int(stored.get(item, 0)) >= cost:
			return {item: cost}
	return {}

static func accepted_request(row: Variant, character: String, namespace_id: String, world_id: String,
		spend_id: String, receipt: String) -> Dictionary:
	if not ESSENCE.training_row_valid(row, character, namespace_id) or row.world_id != world_id \
			or row.status != "accepted" or row.action != "altar_spend" or row.action_id != spend_id \
			or row.receipt != receipt or row.intent.get("spend_id") != spend_id \
			or row.intent.get("expected_character_revision") != int(row.character_revision) - 1:
		return {}
	return row.intent.duplicate(true)

func _on_payment(spend_id: String, result: Dictionary) -> void:
	var admitted := {}
	if result.get("ok") == true and result.get("resolved") == true:
		var world: RefCounted = _game.get("world")
		var character := str(_game.get("local").get("character_id"))
		var namespace_id := str(world.get("reward_delivery_namespace"))
		var rows: Dictionary = world.get("reward_deliveries")
		var row: Variant = rows.get(ESSENCE.training_delivery_id(namespace_id, character))
		admitted = accepted_request(row, character, namespace_id, str(world.get("world_id")), spend_id, str(result.get("receipt", "")))
	_completions.append({"spend_id": spend_id, "result": result.duplicate(true), "admitted_request": admitted})

func _terminal_payment() -> Dictionary:
	for event: Dictionary in _completions:
		if event.result.get("resolved") == true: return event
	return {}

func _altar_focus(panel: Node, key: String) -> bool:
	for _step in 8:
		if not is_instance_valid(panel) or INPUT_OWNER.current(_tree) != panel: return false
		var focus := _tree.root.gui_get_focus_owner()
		if focus == null or not panel.is_ancestor_of(focus):
			await _settle(2)
			continue
		var current := str(focus.get_meta("altar_focus_key", ""))
		if current == key: return focus is Button and not (focus as Button).disabled
		if current.begins_with("retry:") and key.begins_with("payment:"):
			# A retained transaction's Retry button shares the payment column.
			# Right loops back to itself; down reaches the quoted live payment.
			await _tap(&"ui_down")
		elif current.get_slice(":", 0) != key.get_slice(":", 0):
			await _tap(&"ui_left" if key.begins_with("creature:") else &"ui_right")
		else:
			await _tap(&"ui_down")
	return false
