extends Node

## Trusted production adapter. Requests choose a recipe/count only; the real
## host Forge measures the present channel and mints each unit's ticket.
## Inventory/output/receipt and both saves remain in the existing typed journal.
const REFINING := preload("res://scripts/world/homestead_refining.gd")
const FORGE := preload("res://scripts/build/station_forge.gd")
const PIECE := preload("res://scripts/build/station_piece.gd")
const ACTIONS := preload("res://scripts/net/foundation_actions.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
var _channels: Dictionary = {}
var _pending: Dictionary = {}
var _left: float = 0.0

func session() -> Node: return get_parent().get_parent()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	session().connect("peer_left", _peer_left)
	session().connect("session_ended", func(_reason: String) -> void: reset())

func reset() -> void:
	for channel: Dictionary in _channels.values():
		var manual: Node = channel.manual.get_ref()
		if manual != null: manual.call("stop_refining", "session_changed", "Refining stopped when the session changed.")
	_channels.clear()
	_pending.clear() # Durable journal, never this callback cache, owns recovery.

func _peer_left(peer: int) -> void:
	for id: int in _channels.keys():
		if _channels[id].peer != peer: continue
		var manual: Node = _channels[id].manual.get_ref()
		if manual != null: manual.call("stop_refining", "owner_left", "Leaving the world stops refining.")
		_channels.erase(id)
	for ticket: String in _pending.keys():
		if _pending[ticket].peer == peer: _pending.erase(ticket)

func _manual(key: String) -> Node:
	var owner: Node = session()
	var weak: WeakRef = owner.get("_homestead_stations").get(key)
	var station := weak.get_ref() as Node3D if weak != null else null
	if station == null or not station.is_inside_tree() or station.get_script() != PIECE \
		or station.call("source_key") != key or station.call("station_id") != "forge": return null
	var manual: Node = station.get("_manual_actor")
	if manual == null or manual.get_script() != FORGE or manual.get_parent() != station: return null
	return manual

func _body(peer: int) -> CharacterBody3D:
	var owner: Node = session()
	if peer == owner.call("local_peer_id"): return owner.call("_game").call("find_player") as CharacterBody3D
	var lifecycle := get_parent().get_node_or_null(^"TravelLifecycle")
	return lifecycle.call("remote_body", peer) if lifecycle != null else null

func _peer(actor: CharacterBody3D) -> int:
	if actor == null or not actor.is_inside_tree(): return 0
	var owner: Node = session()
	var peer: int = int(owner.call("local_peer_id")) if actor == _body(int(owner.call("local_peer_id"))) else actor.get_multiplayer_authority()
	return peer if _body(peer) == actor and not owner.call("admitted_character_state", peer).is_empty() else 0

func actor_context(actor: CharacterBody3D, uid: String) -> Dictionary:
	var owner: Node = session()
	if owner.call("is_host") != true: return {}
	var peer := _peer(actor)
	if peer < 1: return {}
	var key := "forge:meadows:" + uid
	var source: Dictionary = owner.call("_foundation_source", peer, key)
	var manual := _manual(key)
	var lifecycle := get_parent().get_node_or_null(^"TravelLifecycle")
	if source.is_empty() or manual == null or lifecycle == null: return {}
	var safety: Dictionary = lifecycle.call("local_sample") if peer == owner.call("local_peer_id") else lifecycle.call("host_context", peer)
	if safety.is_empty(): return {}
	var game: Node = owner.call("_game")
	if game == null or game.get("session") != owner or game.get("world") == null: return {}
	var modal_open: bool = safety.get("dialogue") == true or safety.get("cutscene") == true
	# The exact in-flight unit's canonical ACK owns input while its bool writes
	# settle. That is not another menu. Other UI/fades retain cancellation.
	var ticket: String = str(manual.get("_pending").get("txn_id", ""))
	var pending: Dictionary = _pending.get(ticket, {})
	if safety.get("station_ack_only") == true and not pending.is_empty() \
		and pending.peer == peer and pending.manual.get_ref() == manual \
		and pending.world.get_ref() == game.get("world") and pending.epoch == owner.call("_altar_current_epoch"):
		var world: RefCounted = game.get("world")
		var row: Dictionary = world.reward_deliveries.get(ESSENCE.training_delivery_id(world.reward_delivery_namespace, source.character_id), {})
		if row.get("action") == "station_craft" and row.get("receipt") == pending.receipt \
			and ESSENCE._equivalent(row.get("intent"), pending.intent): modal_open = false
	return {"world": game.get("world").call("save_data"),
		"character": owner.get("_character_authority").call("state", source.character_id),
		"modal_open": modal_open,
		"in_combat": owner.call("_altar_peer_in_combat", peer) == true,
		"plot_allowed": source.get("homestead") == true}

func start(peer: int, envelope: Dictionary) -> Dictionary:
	var owner: Node = session()
	if owner.call("is_host") != true or envelope.get("op") != "refine_start" \
		or owner.call("_foundation_envelope_live", peer, envelope) != true: return ACTIONS.deny("invalid_refining_owner")
	var intent: Variant = envelope.get("intent")
	if not intent is Dictionary or intent.size() != 2 or not intent.get("recipe_id") is String \
		or not intent.get("amount") is int or intent.amount < 1 \
		or REFINING.transaction_recipe(intent.recipe_id).is_empty(): return ACTIONS.deny("invalid_refining_intent")
	var source: Dictionary = owner.call("_foundation_source", peer, envelope.station_key)
	var manual := _manual(envelope.station_key)
	var actor := _body(peer)
	if source.is_empty() or manual == null or actor == null: return ACTIONS.deny("actual_forge_required")
	var result: Dictionary = manual.call("start_refining", actor, intent.recipe_id, intent.amount)
	if result.get("started") == true:
		_channels[manual.get_instance_id()] = {"peer": peer, "manual": weakref(manual),
			"world": weakref(owner.call("_game").get("world")), "epoch": owner.call("_altar_current_epoch")}
	return result

func commit_unit(plan: Dictionary, ticket: String, actor: CharacterBody3D) -> Dictionary:
	var owner: Node = session()
	if owner.call("is_host") != true or not preload("res://scripts/build/station_actions.gd").transaction_id(ticket): return {}
	var peer := _peer(actor)
	var key: String = "forge:meadows:" + str(plan.get("station_uid", ""))
	var manual := _manual(key)
	if peer < 1 or manual == null: return {}
	var completed: Dictionary = manual.call("completed_unit_plan", ticket, actor)
	if completed.is_empty() or not ESSENCE._equivalent(completed, plan): return {}
	var context: Dictionary = owner.call("_foundation_source", peer, key)
	var game: Node = owner.call("_game")
	var writer := owner.get_node_or_null(^"LedgerRpc")
	if context.is_empty() or writer == null or game == null \
		or context.character_id != plan.get("character_id") or plan.get("world_id") != game.get("world").world_id \
		or plan.get("world_namespace") != game.get("world").reward_delivery_namespace: return {}
	var recipe := REFINING.transaction_recipe(str(plan.get("recipe_id", "")))
	if recipe.is_empty() or not ESSENCE._equivalent(recipe.cost, plan.get("cost")) \
		or not ESSENCE._equivalent(recipe.output, plan.get("output")): return {}
	var cfg := preload("res://scripts/build/station_rules.gd").config()
	if cfg.get("runtime_enabled") != true or cfg.get("craft_runtime_enabled") != true \
		or cfg.get("forge", {}).get("runtime_enabled") != true: return unit_verdict(ticket, plan, {"resolved": true, "code": "refining_disabled"})
	context.foundation_runtime_authorized = true
	context.completed_manual_refine = true
	context.manual_unit_ticket = ticket
	context.recipe_known = true # The exact four current source recipes have no personal prerequisites.
	var intent := {"recipe_id": plan.recipe_id, "craft_id": ticket}
	var result := ACTIONS.commit(owner.get("_character_authority"), writer, peer, context.character_id,
		int(context.expected_revision), "station_craft", intent, context)
	if result.get("durable") != true:
		result.resolved = true
		return unit_verdict(ticket, plan, result)
	var world: RefCounted = game.get("world")
	var row: Dictionary = world.reward_deliveries.get(ESSENCE.training_delivery_id(world.reward_delivery_namespace, context.character_id), {})
	var decision: Dictionary = owner.call("_foundation_decision", peer, row)
	if decision.get("saved") != true:
		_pending[ticket] = {"peer": peer, "manual": weakref(manual), "world": weakref(world),
			"epoch": owner.call("_altar_current_epoch"), "intent": intent, "plan": plan.duplicate(true), "receipt": row.get("receipt", "")}
	return unit_verdict(ticket, plan, decision)

static func unit_verdict(ticket: String, plan: Dictionary, decision: Dictionary) -> Dictionary:
	var saved: bool = decision.get("ok") == true and decision.get("saved") == true
	return {"txn_id": ticket, "character_id": plan.get("character_id", ""), "world_id": plan.get("world_id", ""),
		"ok": saved, "pending": not saved and decision.get("resolved") != true, "durable": saved,
		"reason": str(decision.get("reason", decision.get("code", "awaiting_saved_decision")))}

func _process(delta: float) -> void:
	_left -= delta
	if _left > 0.0: return
	_left = 0.25
	var owner: Node = session()
	var game: Node = owner.call("_game")
	if owner.call("is_host") != true or game == null or game.get("world") == null:
		reset()
		return
	for id: int in _channels.keys():
		var channel: Dictionary = _channels[id]
		var manual: Node = channel.manual.get_ref()
		if manual == null: _channels.erase(id)
		elif channel.world.get_ref() != game.get("world") or channel.epoch != owner.call("_altar_current_epoch"):
			manual.call("stop_refining", "world_changed", "Changing worlds stops refining.")
			_channels.erase(id)
		elif manual.get("_running") != true and manual.get("_pending").is_empty(): _channels.erase(id)
	for ticket: String in _pending.keys():
		var original: Dictionary = _pending[ticket]
		var manual: Node = original.manual.get_ref()
		if manual == null or original.world.get_ref() != game.get("world") \
			or original.epoch != owner.call("_altar_current_epoch") \
			or original.plan.character_id != owner.call("_authority_character", original.peer):
			_pending.erase(ticket)
			continue
		var world: RefCounted = game.get("world")
		var row: Dictionary = world.reward_deliveries.get(ESSENCE.training_delivery_id(world.reward_delivery_namespace, original.plan.character_id), {})
		if row.get("action") != "station_craft" or row.get("receipt") != original.receipt \
			or not ESSENCE._equivalent(row.get("intent"), original.intent): continue
		var decision: Dictionary = owner.call("_foundation_decision", original.peer, row)
		if decision.get("saved") != true: continue
		manual.call("resolve_pending_unit", unit_verdict(ticket, original.plan, decision))
		_pending.erase(ticket)
