extends Node

## Actual Altar UI bridge. The host Session owns station identity/proximity,
## sender binding and typed commit. This node never stages or applies rewards.
## Missing doors explicitly refuse; there is no local leveling fallback.
## Foundation Session contract (actual canonical/transport implementation):
## altar_station_available(key) -> bool (actual reach/out-of-combat AND all
## canonical registry/world/owner-write/recovery doors available)
## quote_altar_essence_spend(key, owned_uid) -> Dictionary
## submit_altar_essence_spend(key, five-field-intent) -> Dictionary
## reconcile_altar_essence_spend(key, ORIGINAL-five-field-intent) -> Dictionary
## altar_essence_spend_completed(key, spend_id, result:Dictionary) signal.
const PANEL := preload("res://scripts/ui/altar_panel.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const RULES := preload("res://scripts/world/death_satchel_rules.gd")
const PARTY := preload("res://autoload/party.gd")
const NODE_NAME := "AltarService"
signal essence_spend_completed(spend_id: String, result: Dictionary)
var _game: Node = null
var _session: Node = null
var _connection := Callable()
var _panel: CanvasLayer = null
var _pending: Dictionary = {}
var _retry_left := 0.0
var _last_code := "authority_missing"
var _loadout_ui_service: Node

## F23 mounts its station-bound canonical transport here. Existing essence
## requests keep their original service and receipt path.
func configure_loadout_ui(service: Node) -> bool:
	if not is_instance_valid(service): return false
	for method: String in ["quote_loadout", "submit_loadout", "reconcile_loadout"]:
		if not service.has_method(method): return false
	if not service.has_signal("loadout_completed"): return false
	_loadout_ui_service = service
	if is_instance_valid(_panel): _panel.call("configure_loadout_service", service)
	return true


## The owning homestead interaction calls attach(Game).open(station_key)
## with its actual registered Altar id. No scan, synthetic station or debug grant.
static func attach(game: Node) -> Node:
	if game == null: return null
	var existing := game.get_node_or_null(NodePath(NODE_NAME))
	if existing != null:
		return existing if existing.get_script() == load("res://scripts/ui/altar_service.gd") else null
	var service: Node = load("res://scripts/ui/altar_service.gd").new()
	service.name = NODE_NAME
	service.set("_game", game)
	game.add_child(service)
	return service


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _game == null: _game = get_node_or_null(^"/root/Game")


func _exit_tree() -> void:
	_disconnect_session()


func _disconnect_session() -> void:
	if is_instance_valid(_session) and _connection.is_valid() \
			and _session.is_connected("altar_essence_spend_completed", _connection):
		_session.disconnect("altar_essence_spend_completed", _connection)
	_session = null
	_connection = Callable()


func _bind_session() -> bool:
	if not is_instance_valid(_game): return false
	var candidate: Variant = _game.get("session")
	if candidate == _session and is_instance_valid(_session): return true
	_disconnect_session()
	if not candidate is Node or not is_instance_valid(candidate):
		_last_code = "authority_missing"
		return false
	for method: String in ["altar_station_available", "quote_altar_essence_spend",
		"submit_altar_essence_spend", "reconcile_altar_essence_spend"]:
		if not candidate.has_method(method):
			_last_code = "authority_missing"
			return false
	if not candidate.has_signal("altar_essence_spend_completed"):
		_last_code = "authority_missing"
		return false
	_session = candidate
	_connection = _on_session_completed.bind(_session)
	_session.connect("altar_essence_spend_completed", _connection)
	return true


func _context() -> Dictionary:
	if not is_instance_valid(_game): return {}
	var player: Variant = _game.get("local")
	var world: Variant = _game.get("world")
	if not player is RefCounted or not world is RefCounted: return {}
	var character: Variant = player.get("character_id")
	var namespace_id: Variant = world.get("reward_delivery_namespace")
	var world_id: Variant = world.get("world_id")
	if not ESSENCE._component(character) or not ESSENCE._opaque_id(namespace_id) \
			or not ESSENCE._opaque_id(world_id): return {}
	return {"character_id": character, "world_id": world_id, "world_namespace": namespace_id}


func station_available(station_key: String) -> bool:
	if not ESSENCE._opaque_id(station_key) or _context().is_empty():
		_last_code = "authority_missing"
		return false
	if not _bind_session(): return false
	var available: Variant = _session.call("altar_station_available", station_key)
	if available != true or not available is bool:
		_last_code = "station_unavailable"
		return false
	return true


func open(station_key: String) -> bool:
	if not _pending.is_empty():
		_say(refusal_text("transaction_busy"))
		return false
	if not station_available(station_key):
		_say(refusal_text(_last_code))
		return false
	if not is_instance_valid(_panel):
		_panel = PANEL.new()
		add_child(_panel)
		if _panel.call("configure_service", self) != true: return false
	if is_instance_valid(_loadout_ui_service): _panel.call("configure_loadout_service", _loadout_ui_service)
	return _panel.call("open", station_key) == true


func quote_essence_spend(station_key: String, owned_uid: String) -> Dictionary:
	if not station_available(station_key): return {"ok": false, "code": _last_code}
	if not ESSENCE._component(owned_uid): return {"ok": false, "code": "not_owned"}
	var raw: Variant = _session.call("quote_altar_essence_spend", station_key, owned_uid)
	return raw.duplicate(true) if raw is Dictionary else {"ok": false, "code": "quote_unavailable"}


func _intent_valid(request: Dictionary) -> bool:
	var fields := ["spend_id", "creature_uid", "expected_level", "payment_item", "expected_character_revision"]
	if request.size() != fields.size(): return false
	for field: String in fields:
		if not request.has(field): return false
	for field: String in ["spend_id", "creature_uid", "payment_item"]:
		if not ESSENCE._component(request[field]): return false
	return ESSENCE._integer(request.expected_level, 1, 60) \
		and ESSENCE._integer(request.expected_character_revision, 0, 2147483646)


func submit_essence_spend(station_key: String, request: Dictionary) -> void:
	var id := str(request.get("spend_id", ""))
	if not _intent_valid(request):
		_emit_refusal(id, "invalid_spend_intent")
		return
	if not _pending.is_empty():
		if _pending.request.spend_id == id and _pending.station_key == station_key \
				and ESSENCE._equivalent(_pending.request, request): reconcile_essence_spend(id)
		else: _emit_refusal(id, "transaction_busy")
		return
	if not station_available(station_key):
		_emit_refusal(id, _last_code)
		return
	var context := _context()
	if context.is_empty():
		_emit_refusal(id, "authority_missing")
		return
	# Freeze BEFORE calling: Session may complete synchronously in solo.
	_pending = {"station_key": station_key, "request": request.duplicate(true),
		"context": context, "durable": false}
	_retry_left = _retry_seconds()
	var raw: Variant = _session.call("submit_altar_essence_spend", station_key, request.duplicate(true))
	if not _pending.is_empty(): _accept_result(id, raw)


func reconcile_essence_spend(spend_id: String) -> void:
	if _pending.is_empty() or _pending.request.spend_id != spend_id:
		essence_spend_completed.emit(spend_id, {"ok": false, "resolved": false,
			"code": "decision_unavailable", "reason": refusal_text("decision_unavailable")})
		return
	if not ESSENCE._equivalent(_context(), _pending.context) or not _bind_session():
		_accept_result(spend_id, {"ok": false, "resolved": false, "code": "rejoin_original_character_world"})
		return
	# Read the SAME operation identity. Never resubmit, reprice or mint an id.
	var raw: Variant = _session.call("reconcile_altar_essence_spend", _pending.station_key,
		_pending.request.duplicate(true))
	_accept_result(spend_id, raw)

func retained_training_transaction(actions: Array) -> Dictionary:
	return _session.call("retained_training_transaction", actions) \
		if _bind_session() and _session.has_method("retained_training_transaction") else {}

func retry_retained_transaction(station_key: String, spend_id: String) -> void:
	var retained := retained_training_transaction(["altar_spend"])
	if retained.is_empty() or not _intent_valid(retained.intent) or retained.intent.spend_id != spend_id:
		_emit_refusal(spend_id, "decision_unavailable")
		return
	if not _pending.is_empty():
		if _pending.request != retained.intent: _emit_refusal(spend_id, "transaction_busy"); return
	else:
		var context := _context()
		if context.is_empty(): _emit_refusal(spend_id, "authority_missing"); return
		_pending = {"station_key": station_key, "request": retained.intent.duplicate(true), "context": context, "durable": true}
		_retry_left = _retry_seconds()
	reconcile_essence_spend(spend_id)


func _retry_seconds() -> float:
	var raw: Variant = ESSENCE.config().get("altar_result_retry_seconds")
	return float(raw) if ESSENCE._integer(raw, 1, 30) else 0.0


func _process(delta: float) -> void:
	if _pending.is_empty(): return
	var interval := _retry_seconds()
	if interval <= 0.0: return # Invalid authored budget never spins/retries fast.
	_retry_left -= maxf(delta, 0.0)
	if _retry_left > 0.0: return
	_retry_left = interval
	reconcile_essence_spend(_pending.request.spend_id)


func _on_session_completed(station_key: String, spend_id: String, result: Dictionary, source: Node) -> void:
	if not is_instance_valid(source) or source != _session or not is_instance_valid(_game) \
			or _game.get("session") != source or _pending.is_empty() \
			or station_key != _pending.station_key: return
	_accept_result(spend_id, result)


func _accept_result(spend_id: String, raw: Variant) -> void:
	if _pending.is_empty() or _pending.request.spend_id != spend_id: return
	if not ESSENCE._equivalent(_context(), _pending.context): return
	var result: Dictionary = raw.duplicate(true) if raw is Dictionary else {}
	if result.get("durable") == true or _current_earned_decision(): _pending.durable = true
	if not result.get("ok") is bool or not result.get("resolved") is bool:
		result = {"ok": false, "resolved": false, "code": "decision_unavailable"}
	if result.resolved == true:
		if result.ok == true:
			if not _saved_decision_matches(result):
				result = {"ok": false, "resolved": false, "code": "awaiting_saved_decision"}
		elif _pending.durable == true or result.get("durable") == true:
			result = {"ok": false, "resolved": false, "code": "owner_training_save_failed", "durable": true}
	if result.get("resolved") == true:
		_pending = {}
	var code := str(result.get("code", "decision_unavailable"))
	result["reason"] = "Level raised and saved." if result.get("ok") == true and result.get("resolved") == true else refusal_text(code)
	essence_spend_completed.emit(spend_id, result)


func _current_earned_decision() -> bool:
	var world: RefCounted = _game.get("world")
	var rows: Variant = world.get("reward_deliveries")
	if not rows is Dictionary: return false
	var context: Dictionary = _pending.context
	var row: Variant = rows.get(ESSENCE.training_delivery_id(context.world_namespace, context.character_id))
	return ESSENCE.training_row_valid(row, context.character_id, context.world_namespace) \
		and row.world_id == context.world_id and row.action == "altar_spend" \
		and row.action_id == _pending.request.spend_id \
		and ESSENCE._equivalent(row.intent, _pending.request)


## A final success needs actual canonical owner and current-world evidence,
## not UI optimism. Accepted later rows can retain the original action receipt;
## this resolves a lost notification after another earned action without
## importing an old full-party baseline or requiring the old level forever.
func _saved_decision_matches(result: Dictionary) -> bool:
	if result.get("saved") != true or result.get("durable") != true: return false
	var player: RefCounted = _game.get("local")
	var world: RefCounted = _game.get("world")
	var namespace_id: String = _pending.context.world_namespace
	var character: String = _pending.context.character_id
	var rows: Variant = world.get("reward_deliveries")
	if not rows is Dictionary: return false
	var latest: Variant = rows.get(ESSENCE.training_delivery_id(namespace_id, character))
	if not ESSENCE.training_row_valid(latest, character, namespace_id) or latest.world_id != _pending.context.world_id \
			or latest.status != "accepted" or not result.get("receipt") is String: return false
	# Read only the receipt witness and actual UID membership/slot inventory.
	# PlayerState.save_data builds map payloads; a UI confirmation must not
	# create unvisited maps or use a full save as its ordinary read accessor.
	var party: Variant = player.get("party")
	var inventory: Variant = player.get("inventory")
	var personal: Variant = player.get("redesign_character")
	if not party is RefCounted or not party.has_method("members") \
			or not inventory is RefCounted or not inventory.has_method("slot_count") \
			or not inventory.has_method("stack_at") or not personal is Dictionary: return false
	var members: Variant = party.call("members")
	if not members is Array or members.size() > PARTY.MAX_CREATURES: return false
	var uid_rows: Array = []
	var seen_uids := {}
	for creature: Variant in members:
		if not creature is RefCounted: return false
		var uid: Variant = creature.get("uid")
		if not ESSENCE._component(uid) or seen_uids.has(uid): return false
		seen_uids[uid] = true
		uid_rows.append({"uid": uid})
	var snapshot := {"character_id": character, "party": uid_rows,
		"inventory": RULES.slots(inventory).duplicate(true), "redesign_character": personal.duplicate(true)}
	var request: Dictionary = _pending.request
	# Duplicate handling precedes owned-row stat math, so no made-up stats,
	# HP, known moves or cap history are needed for this receipt-only witness.
	var replay := ESSENCE.stage_spend(snapshot, character, request.creature_uid, request.spend_id,
		int(request.expected_level), request.payment_item, int(request.expected_character_revision),
		ESSENCE.config(), PROGRESSION.config())
	return replay.get("ok") == true and replay.get("duplicate") == true \
		and replay.get("receipt") == result.receipt \
		and latest.after.redesign_character.transaction_receipts.has(result.receipt)


func _emit_refusal(spend_id: String, code: String) -> void:
	if not _pending.is_empty() and _pending.request.spend_id == spend_id:
		# A conflicting/malformed repeat is refused as a packet, but it cannot
		# classify the original unknown in-flight decision as a failed spend.
		essence_spend_completed.emit(spend_id, {"ok": false, "resolved": false,
			"code": "receipt_conflict", "reason": "Your original choice is still waiting for confirmation."})
		return
	essence_spend_completed.emit(spend_id, {"ok": false, "resolved": true,
		"code": code, "reason": refusal_text(code), "durable": false})


func _say(text: String) -> void:
	if is_instance_valid(_game) and _game.has_method("push_world_message"): _game.call("push_world_message", text)


func refusal_text(code: String) -> String:
	var messages := {"authority_missing": "Leveling at this Altar is not ready yet.",
		"training_registry_unavailable": "Leveling at this Altar is not ready yet.",
		"training_writer_unavailable": "Leveling at this Altar is not ready yet.",
		"station_unavailable": "Return to the Altar outside combat to raise a level.",
		"station_missing": "The Altar is no longer here.",
		"insufficient_items": "You need more of that essence or candy.",
		"breakthrough_needed": "This companion needs a breakthrough before another level.",
		"cap_not_admitted": "Training for this companion needs to sync first.",
		"stale_level": "Your companion's level changed. Choose the payment again.",
		"stale_revision": "Your team or items changed. Choose the payment again.",
		"transaction_busy": "Your previous choice is still being saved.",
		"training_journal_failed": "The Altar could not save this choice. Try again.",
		"journal_failed": "The Altar could not save this choice. Try again.",
		"owner_training_save_failed": "Your level was accepted. Waiting for your character to save.",
		"rejoin_original_character_world": "Return to the same character and world to recover your choice.",
		"decision_unavailable": "Your choice is still waiting for confirmation.",
		"awaiting_saved_decision": "Waiting for the host to confirm your saved level."}
	return str(messages.get(code, "Leveling is unavailable for this companion. Your choice has not been confirmed."))
