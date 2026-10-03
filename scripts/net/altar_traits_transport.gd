extends Node

## Altar UI transport over the existing full-character journal. This stores
## original requests only; costs, roster removal and seed payout stay in Traits.
const TRAITS := preload("res://scripts/creatures/traits.gd")
const ACTIONS := preload("res://scripts/net/character_action_rules.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const HASH := preload("res://scripts/net/owner_passive_preparation.gd")
const REQUEST_FIELDS := ["op", "session_epoch", "world_namespace", "character_id", "station_key", "intent"]
const QUOTE_FIELDS := ["op", "session_epoch", "world_namespace", "character_id", "station_key", "owned_uid", "quote_id"]
var _session: WeakRef
var _request: Dictionary = {}
var _quote_request: Dictionary = {}
var _quote_result: Dictionary = {}
var _originals: Dictionary = {}

func _init(session: Node = null) -> void:
	if session != null: _session = weakref(session)

func session() -> Node:
	return _session.get_ref() as Node if _session != null else null

func reset() -> void:
	_request.clear()
	_quote_request.clear()
	_quote_result.clear()
	_originals.clear()

func invalidate_quote() -> void:
	_quote_request.clear()
	_quote_result.clear()

func _local_scope(request: Dictionary) -> bool:
	var owner := session()
	if owner == null: return false
	var scope: Dictionary = owner.call("_altar_envelope", str(request.get("op", "")), str(request.get("station_key", "")))
	if scope.is_empty(): return false
	for field: String in scope:
		if request.get(field) != scope[field]: return false
	return true

func quote(key: String, uid: String) -> Dictionary:
	var owner := session()
	if owner == null or not ESSENCE._component(uid): return _deny("invalid_quote", true)
	var envelope: Dictionary = owner.call("_altar_envelope", "altar_trait_quote", key)
	if envelope.is_empty(): return _deny("authority_missing")
	envelope.owned_uid = uid
	if _local_scope(_quote_request) and _quote_request.get("station_key") == key and _quote_request.get("owned_uid") == uid:
		return _quote_result.duplicate(true) if not _quote_result.is_empty() else _deny("quote_pending")
	envelope.quote_id = Crypto.new().generate_random_bytes(16).hex_encode()
	_quote_request = envelope.duplicate(true)
	_quote_result.clear()
	if owner.call("is_host") == true:
		_quote_result = handle_quote(int(owner.call("local_peer_id")), envelope)
		return _quote_result.duplicate(true)
	owner.call("_altar_traits_send_quote", envelope)
	return _deny("quote_pending")

func handle_quote(peer: int, envelope: Dictionary) -> Dictionary:
	var owner := session()
	if owner == null or owner.call("_altar_envelope_matches", peer, envelope, QUOTE_FIELDS) != true \
		or envelope.get("op") != "altar_trait_quote" or not owner.call("_altar_hex_id", envelope.get("quote_id")) \
		or not ESSENCE._component(envelope.get("owned_uid")): return _deny("invalid_quote", true)
	var context := _context(peer, str(envelope.station_key))
	if context.is_empty(): return _deny("actual_altar_required", true)
	var registry: RefCounted = owner.get("_character_authority")
	var current: Dictionary = registry.call("state", context.character_id)
	# Same deterministic legacy adoption as CharacterActions; quote never writes.
	for card: Dictionary in current.party:
		if card.uid == envelope.owned_uid:
			current.redesign_character.creatures[card.uid] = TRAITS.initialize_legacy_record(card, current.redesign_character.creatures[card.uid])
	return TRAITS.quote_action(current, context.character_id, envelope.owned_uid, context.expected_revision)

func receive_quote(envelope: Dictionary, result: Dictionary) -> void:
	if not _local_scope(envelope) or not HASH.exact(_quote_request, envelope): return
	_quote_result = result.duplicate(true)
	session().emit_signal("altar_trait_quote_completed", str(envelope.station_key), str(envelope.owned_uid))

func send(key: String, intent: Dictionary, reconcile: bool = false) -> Dictionary:
	var owner := session()
	if owner == null or not TRAITS.intent_valid(intent): return _deny("invalid_trait_intent", true)
	var envelope: Dictionary = owner.call("_altar_envelope", "altar_trait", key)
	if envelope.is_empty(): return _deny("authority_missing")
	envelope.intent = intent.duplicate(true)
	if not _request.is_empty() and (_request.get("station_key") != key or not HASH.exact(_request.get("intent"), intent)):
		return _deny("original_trait_request_pending")
	_request = envelope.duplicate(true) # Rejoin refreshes scope, never the choice.
	_quote_request.clear()
	_quote_result.clear()
	if owner.call("is_host") == true:
		var result := handle(int(owner.call("local_peer_id")), envelope, reconcile)
		if _finished(result): _request.clear()
		return result
	owner.call("_altar_traits_send", envelope, reconcile)
	return _deny("awaiting_saved_decision")

func owner_request_matches(request: Dictionary) -> bool:
	return _local_scope(request) and HASH.exact(_request, request)

func receive_result(envelope: Dictionary, result: Dictionary) -> void:
	if not owner_request_matches(envelope): return
	if result.get("ok") == true:
		var row: Dictionary = session().call("_owner_training_row")
		if row.get("intent") != envelope.intent or row.get("action") != _action(envelope.intent) \
			or session().call("_foundation_decision", session().call("local_peer_id"), row).get("ok") != true: return
	if _finished(result): _request.clear()
	session().emit_signal("altar_trait_completed", str(envelope.station_key), str(envelope.intent.action_id), result.duplicate(true))

func _context(peer: int, key: String) -> Dictionary:
	var owner := session()
	if owner == null or not TRAITS.runtime_enabled() or ESSENCE.config().get("altar_runtime_enabled") != true \
		or owner.call("_altar_station_for_peer", peer, key) != true \
		or owner.call("admitted_character_state", peer).is_empty(): return {}
	var context: Dictionary = owner.call("_foundation_source", peer, key)
	if context.get("station_id") != "altar" or context.get("homestead") != true \
		or context.get("in_combat") != false: return {}
	context.foundation_runtime_authorized = true
	return context

func handle(peer: int, envelope: Dictionary, reconcile: bool = false) -> Dictionary:
	var owner := session()
	if owner == null or owner.call("_altar_envelope_matches", peer, envelope, REQUEST_FIELDS) != true \
		or envelope.get("op") != "altar_trait" or not TRAITS.intent_valid(envelope.get("intent")):
		return _deny("invalid_trait_request", true)
	var character: String = owner.call("_authority_character", peer)
	var world: RefCounted = owner.call("_game").get("world")
	var row: Variant = world.reward_deliveries.get(ESSENCE.training_delivery_id(world.reward_delivery_namespace, character))
	# Reconcile the immutable original before station/ownership checks: a release
	# has already removed its UID, and its source may disappear after journaling.
	if row is Dictionary and row.get("action") == _action(envelope.intent) and HASH.exact(row.get("intent"), envelope.intent):
		var decision: Dictionary = owner.call("_foundation_decision", peer, row)
		if _finished(decision): _originals.erase(character)
		return decision
	if _originals.has(character) and not HASH.exact(_originals[character], envelope): return _deny("original_trait_request_pending")
	if reconcile and not _originals.has(character): return _deny("original_trait_decision_unavailable")
	var saver: RefCounted = owner.call("_game").get("save_system")
	if saver == null: return _deny("writer_unavailable")
	saver.call("finish_fallback")
	if saver.call("fallback_busy") == true or owner.call("_altar_envelope_matches", peer, envelope, REQUEST_FIELDS) != true:
		return _deny("writer_busy")
	var context := _context(peer, str(envelope.station_key))
	if context.is_empty(): return _terminal_before_journal(character, envelope, "actual_altar_required")
	var registry: RefCounted = owner.get("_character_authority")
	var proposal := ACTIONS.stage(registry.call("state", character), int(context.expected_revision),
		_action(envelope.intent), envelope.intent, context, Callable(registry, "errors"))
	if proposal.get("ok") != true: return _terminal_before_journal(character, envelope, str(proposal.get("code", "trait_refused")))
	_originals[character] = envelope.duplicate(true)
	if peer != owner.call("local_peer_id"):
		var ready: Dictionary = owner.call("_owner_passive_service").call("action_gate", peer, "altar_traits", envelope, context)
		if ready.get("ok") != true: return ready
	var writer := owner.get_node_or_null(^"LedgerRpc")
	var result := ACTIONS.commit_host_action(registry, writer, peer, character,
		int(context.expected_revision), _action(envelope.intent), envelope.intent, context)
	if result.get("durable") != true: return result
	row = world.reward_deliveries.get(ESSENCE.training_delivery_id(world.reward_delivery_namespace, character))
	return owner.call("_foundation_decision", peer, row) if row is Dictionary else _deny("decision_unavailable")

func _terminal_before_journal(character: String, envelope: Dictionary, code: String) -> Dictionary:
	# Called only after the retained original journal recovery above. A terminal
	# source/choice refusal must not strand the next request in a transient cache.
	if HASH.exact(_originals.get(character), envelope): _originals.erase(character)
	return _deny(code, true)

func commit_prepared(peer: int, request: Dictionary) -> Dictionary:
	# Called synchronously by the exact passive checkpoint after owner BOOL ACK.
	# Its private committing guard authorizes this SAME request at action_gate.
	return handle(peer, request, true)

static func _action(intent: Dictionary) -> String:
	return "trait_release" if intent.get("action") == "release" else "trait_teach"

static func _finished(result: Dictionary) -> bool:
	return (result.get("ok") == true and result.get("durable") == true \
		and result.get("owner_saved") == true and result.get("owner_acknowledged") == true) \
		or (result.get("terminal") == true and result.get("durable") == false)

static func _deny(code: String, terminal: bool = false) -> Dictionary:
	return {"ok": false, "durable": false, "resolved": terminal,
		"terminal": terminal, "terminal_refusal": terminal, "code": code}
