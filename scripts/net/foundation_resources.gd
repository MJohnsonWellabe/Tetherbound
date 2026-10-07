extends Node

## Production source resolver. Only canonical live placements become typed
## requests; inventory, stock and owner saves use the existing training journal.
const SITES := preload("res://scripts/world/renewable_site_catalog.gd")
const MOUNT := preload("res://scripts/world/f32_world_mount.gd")
const SERVICE := preload("res://scripts/world/f32_source_service.gd")
const E := preload("res://scripts/creatures/essence.gd")
const HARVEST := preload("res://scripts/world/harvest_logic.gd")
var _service: Node
var _mounts: Dictionary = {}
var _mount_retry: Dictionary = {}
var _pending: Dictionary = {}
var _left := 0.0

func session() -> Node: return get_parent().get_parent()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_service = SERVICE.new()
	_service.name = "SourceService"
	add_child(_service)
	_service.call("configure", submit, stock, plot)
	session().connect("foundation_reply_received", _reply)
	session().connect("session_ended", func(_reason: String) -> void: _pending.clear())

func _enabled() -> bool:
	return preload("res://scripts/data/redesign_data.gd").json("res://data/config/f32_runtime.json").get("runtime_enabled") == true

func _world() -> RefCounted:
	var game: Node = session().call("_game")
	return game.get("world") if game != null else null

func stock(realm: String, id: String) -> Dictionary:
	var world := _world()
	return world.call("renewable_stock_state", realm, id) if world != null else {}

func plot(realm: String, id: String) -> Dictionary:
	var world := _world()
	return world.call("resource_plot_state", realm, id) if world != null else {}

func _body(peer: int) -> CharacterBody3D:
	var owner := session()
	if peer == owner.call("local_peer_id"):
		var game: Node = owner.call("_game")
		return game.call("find_player") as CharacterBody3D if game != null else null
	return get_parent().get_node(^"TravelLifecycle").call("remote_body", peer)

func _process(delta: float) -> void:
	_left -= delta
	if _left > 0.0: return
	_left = 1.0
	if not _enabled() or session().call("snapshot_ready") != true: return
	var owner := session()
	var game: Node = owner.call("_game")
	if game == null: return
	_mount_realm(str(game.get("current_realm")), _body(int(owner.call("local_peer_id"))))
	if owner.call("is_host") == true:
		var registry: RefCounted = owner.get("_registry")
		for row: Dictionary in registry.call("rows"):
			var peer := int(row.get("peer_id", 0))
			if peer != owner.call("local_peer_id") and not owner.call("admitted_character_state", peer).is_empty():
				_mount_realm(str(row.get("realm", "")), _body(peer))
	for id: String in _pending.keys(): _send_pending(id)

func _mount_realm(realm: String, actor: CharacterBody3D) -> void:
	var shell: Node3D = session().call("_portal_world_node", realm)
	if shell == null or actor == null or not shell.is_inside_tree() or not shell.is_ancestor_of(actor): return
	var mount := _mounted(realm)
	if not is_instance_valid(mount) or mount.get_parent() != shell:
		mount = MOUNT.new()
		mount.name = "RenewableResources"
		shell.add_child(mount)
		_mounts[realm] = weakref(mount)
		_mount_retry.erase(realm)
	if Time.get_ticks_msec() < int(_mount_retry.get(realm, 0)): return
	_mount_retry[realm] = Time.get_ticks_msec() + 10000
	mount.call("mount", shell, actor, _service)
	if realm == "meadows": mount.call("mount_authored_farm", shell, actor, _service)

func _source(realm: String, id: String) -> Node3D:
	var mount := _mounted(realm)
	return mount.call("node_for", id) if is_instance_valid(mount) else null

func _mounted(realm: String) -> Node3D:
	var reference: WeakRef = _mounts.get(realm) as WeakRef
	return reference.get_ref() as Node3D if reference != null else null

func submit(operation: String, request: Dictionary, consumer: Node) -> Dictionary:
	if operation not in ["node", "farm"] or not request.get("action_id") is String or not is_instance_valid(consumer):
		return _refusal("invalid_resource", "That resource is unavailable.")
	var game: Node = session().call("_game")
	var world := _world()
	if game == null or world == null: return _refusal("world_unavailable", "The world is not ready.")
	var realm := str(game.get("current_realm"))
	var id := str(request.get("site_id" if operation == "node" else "plot_id", ""))
	if _source(realm, id) != consumer: return _refusal("unregistered_source", "That resource is unavailable.")
	var action_id: String = request.action_id
	if _pending.has(action_id): return {"ok": false, "pending": true, "resolved": false}
	if _pending.size() >= 16: return _refusal("resource_busy", "Wait for the current gathering to finish.")
	_pending[action_id] = {"operation": operation, "source_id": id, "key": "resource:%s:%s" % [realm, id],
		"intent": {"operation": operation, "request": request.duplicate(true)}, "revision": -1,
		"world": weakref(world), "epoch": session().call("_altar_current_epoch"),
		"character_id": session().call("_local_character_id")}
	# Defer so the consumer finishes recording its pending action before a solo
	# saved decision can notify it. Every retry retains this exact request.
	call_deferred("_send_pending", action_id)
	return {"ok": false, "pending": true, "resolved": false}

func _send_pending(id: String) -> void:
	if not _pending.has(id): return
	var pending: Dictionary = _pending[id]
	var owner := session()
	if pending.world.get_ref() != _world() or pending.epoch != owner.call("_altar_current_epoch") \
		or pending.character_id != owner.call("_local_character_id"):
		_finish(id, _refusal("owner_changed", "Gathering stopped when the world changed."))
		return
	if int(pending.revision) < 0:
		# A prior morning/station write can finish during finish_fallback.
		# Settle it BEFORE the first quote, then wait on the existing owner
		# mutation fence. An already quoted original is never rewritten.
		var game: Node = owner.call("_game")
		var saver: RefCounted = game.get("save_system") if game != null else null
		if saver == null: return
		saver.call("finish_fallback")
		if pending.world.get_ref() != _world() or pending.epoch != owner.call("_altar_current_epoch") \
			or pending.character_id != owner.call("_local_character_id"):
			_finish(id, _refusal("owner_changed", "Gathering stopped when the world changed."))
			return
		if saver.call("fallback_busy") == true or owner.call("_owner_training_mutation_blocked", game.get("local")) == true: return
		var view: Dictionary = owner.call("homestead_personal_view")
		if view.get("character_id") != pending.character_id or not view.has("registry_revision"): return
		pending.revision = int(view.registry_revision)
	var result: Dictionary = owner.call("_foundation_send", "resource", pending.key, pending.intent, pending.revision)
	_consider(id, result)

func _reply(envelope: Dictionary, result: Dictionary) -> void:
	if envelope.get("op") != "resource" or not envelope.get("intent") is Dictionary: return
	var id := str(envelope.intent.get("request", {}).get("action_id", ""))
	var pending: Dictionary = _pending.get(id, {})
	if pending.is_empty() or not E._equivalent(pending.intent, envelope.intent) \
		or pending.revision != envelope.get("revision") or pending.key != envelope.get("station_key"): return
	_consider(id, result)

static func saved_decision(result: Dictionary) -> bool:
	return result.get("ok") == true and result.get("resolved") == true \
		and result.get("owner_saved") == true and result.get("owner_acknowledged") == true

func _consider(id: String, result: Dictionary) -> void:
	if saved_decision(result) or result.get("terminal_refusal") == true: _finish(id, result)

func _finish(id: String, result: Dictionary) -> void:
	var pending: Dictionary = _pending.get(id, {})
	if pending.is_empty(): return
	_pending.erase(id)
	_service.call("notify_settled", pending.operation, pending.source_id, id, result)

func host_context(peer: int, key: String, intent: Dictionary) -> Dictionary:
	var owner := session()
	if not _enabled() or owner.call("is_host") != true or owner.call("admitted_character_state", peer).is_empty() \
		or intent.size() != 2 or intent.get("operation") not in ["node", "farm"] or not intent.get("request") is Dictionary: return {}
	var actor := _body(peer)
	var lifecycle := get_parent().get_node(^"TravelLifecycle")
	var safety: Dictionary = lifecycle.call("local_sample") if peer == owner.call("local_peer_id") else lifecycle.call("host_context", peer)
	if actor == null or safety.is_empty() or safety.get("dialogue") != false or safety.get("cutscene") != false \
		or safety.get("downed") != false or owner.call("_altar_peer_in_combat", peer) == true: return {}
	var realm := str(safety.get("realm", ""))
	var shell: Node3D = owner.call("_portal_world_node", realm)
	var id := str(intent.request.get("site_id" if intent.operation == "node" else "plot_id", ""))
	var source := _source(realm, id)
	if shell == null or source == null or not source.is_inside_tree() or source.is_queued_for_deletion() \
		or not shell.is_ancestor_of(actor) or not shell.is_ancestor_of(source) \
		or key != "resource:%s:%s" % [realm, id] or actor.global_position.distance_to(source.global_position) > (2.6 if intent.operation == "node" else 2.2): return {}
	var world := _world()
	var character: String = owner.call("_authority_character", peer)
	var authority: RefCounted = owner.get("_character_authority")
	var current: Dictionary = authority.call("state", character)
	var tool := str(safety.get("equipped_tool", ""))
	tool = effective_tool(tool, current.inventory)
	var context := {"character_id": character, "expected_revision": int(authority.call("revision", character)),
		"source_key": key, "source_id": id, "world_id": world.world_id, "world_namespace": world.reward_delivery_namespace,
		"realm": realm, "actor_realm": realm, "host_day": int(world.day), "in_range": true, "in_combat": false,
		"modal_open": false, "registered_live_source": true, "resource_runtime_authorized": true, "equipped_tool": tool}
	if intent.operation == "node":
		var definition := SITES.by_id(realm, id)
		var live_stock := stock(realm, id)
		if definition.is_empty() or live_stock.is_empty() or not _available(peer, definition, world): return {}
		context.stock = live_stock
		context.source_definition = definition
		context.source_generation = str(int(live_stock.generation))
		context.source_available = true
		# Stable per stock generation, so failed saves/retries never reroll seeds.
		context.retained_seed_roll = float((world.reward_delivery_namespace + key + str(int(live_stock.generation))).sha256_text().left(8).hex_to_int()) / 4294967296.0
	else:
		var live_plot := plot(realm, id)
		if live_plot.is_empty(): return {}
		context.plot = live_plot
		context.source_generation = str(int(live_plot.revision))
		context.greenhouse_built = false
		for building: Dictionary in world.placed_buildings:
			if building.get("id") == "greenhouse" and building.get("realm") == "meadows" and building.get("paid") == true:
				context.greenhouse_built = true
	return context

## A held tool the character no longer owns (dropped, traded, left in a death
## satchel) or has worn out gathers as bare hands: it grants nothing, and
## tool-gated sites still refuse with equipped_tool_required. Refusing the whole
## host context instead locked the player out of every later gather.
static func effective_tool(held: String, admitted_inventory: Array) -> String:
	if held.is_empty(): return ""
	var bag := preload("res://scripts/world/death_satchel_rules.gd").inventory_from(admitted_inventory)
	return held if HARVEST.tool_slot(held, bag) >= 0 else ""

func _available(peer: int, definition: Dictionary, world: RefCounted) -> bool:
	var personal: Dictionary = session().call("_foundation_flags", peer)
	var required := str(definition.get("requires_flag", ""))
	if not required.is_empty() and not world.flags.call("has", required) and personal.get(required) != true: return false
	for flag: String in definition.get("requires_world_flags", []):
		if not world.flags.call("has", flag): return false
	if definition.get("realm") == "stormwood":
		var origin := str(definition.get("anchor", {}).get("id", definition.id))
		var rules := preload("res://scripts/world/stormwood_harvest_rules.gd").new()
		if not rules.refusal(origin, world).is_empty(): return false
	return true

static func _refusal(code: String, reason: String) -> Dictionary:
	return {"ok": false, "resolved": true, "terminal_refusal": true, "code": code, "reason": reason}
