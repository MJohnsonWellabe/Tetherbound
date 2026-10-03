extends Node
const BACKGROUND_TRACE := preload("res://scripts/net/background_work_trace.gd")

## Host-internal composition adapter. Session authenticates peer/generation
## before calling claim; event tokens resolve ONLY through the real host
## catch/alpha/rematch producer. No RPC accepts an event or a proposed context.
## Uses the existing registry and LedgerRpc journal, never a second ledger.
const BOARD := preload("res://scripts/world/bounty_board.gd")
const ACTIONS := preload("res://scripts/net/character_action_rules.gd")
var _session: Node
var _source_context: Callable
var _accepted_event: Callable
var _poll_left := 0.0

func configure(session: Node, actual_source_context: Callable, accepted_event_lookup: Callable) -> bool:
	if session == null or not actual_source_context.is_valid() or not accepted_event_lookup.is_valid(): return false
	_session = session
	_source_context = actual_source_context
	_accepted_event = accepted_event_lookup
	return true

func _process(delta: float) -> void:
	if not is_instance_valid(_session) or _session.call("is_host") != true: return
	_poll_left -= delta
	if _poll_left > 0.0: return
	_poll_left = float(BOARD.config().get("host_poll_seconds", 1.0))
	var trace := BACKGROUND_TRACE.begin("bounty.poll")
	_poll_background_work()
	BACKGROUND_TRACE.end("bounty.poll", trace)

func _poll_background_work() -> void:
	# Session's peer registry includes admitted guest identity. Never enumerate
	# owner-supplied character IDs or persist another admission table here.
	var peers: Array[int] = [int(_session.call("local_peer_id"))]
	for row: Dictionary in _session.call("peers"):
		var peer: int = int(row.get("peer_id", 0))
		if peer > 0 and not peers.has(peer): peers.append(peer)
	for peer: int in peers:
		var context_trace := BACKGROUND_TRACE.begin("bounty.context", peer)
		var context := _context(peer)
		BACKGROUND_TRACE.end("bounty.context", context_trace, peer)
		if context.is_empty() or context.get("clock_confirmed") != true: continue
		var registry: RefCounted = _session.get("_character_authority")
		var current: Dictionary = registry.call("state", context.character_id)
		var board: Dictionary = current.redesign_character.get("bounties", BOARD.empty_board())
		if board.get("anchor_world") != context.get("world_namespace") \
			or int(board.get("anchor_day", 0)) < int(context.get("host_day", 0)):
			var morning_trace := BACKGROUND_TRACE.begin("bounty.morning", peer)
			morning(peer)
			BACKGROUND_TRACE.end("bounty.morning", morning_trace, peer)

func _context(peer: int) -> Dictionary:
	if BOARD.config().get("runtime_enabled") != true or not is_instance_valid(_session) \
		or _session.call("is_host") != true or not _source_context.is_valid(): return {}
	var raw: Variant = _source_context.call(peer)
	if not raw is Dictionary: return {}
	var actual: Variant = _session.call("_authority_character", peer)
	var registry: Variant = _session.get("_character_authority")
	var game: Node = _session.call("_game")
	if not actual is String or actual.is_empty() or not registry is RefCounted \
		or game == null or game.get("world") == null \
		or raw.get("world_namespace") != game.get("world").get("reward_delivery_namespace") \
		or raw.get("character_id") != actual \
		or raw.get("expected_revision") != registry.call("revision", actual): return {}
	return raw.duplicate(true)

func _commit(peer: int, action: String, intent: Dictionary, context: Dictionary) -> Dictionary:
	if context.is_empty(): return ACTIONS.deny("bounty_source_unavailable")
	var registry: RefCounted = _session.get("_character_authority")
	var writer := _session.get_node_or_null(^"LedgerRpc")
	return ACTIONS.commit_host_action(registry, writer, peer, context.character_id,
		int(context.expected_revision), action, intent, context)

## Invoke for every admitted character after morning/admission, including
## return from another world. Repeated calls are harmless; one pending action
## fences other writes until its real owner-save/ACK has settled.
func morning(peer: int) -> Dictionary:
	var context := _context(peer)
	if context.is_empty() or context.get("clock_confirmed") != true: return ACTIONS.deny("host_morning_required")
	context["in_range"] = true # clock event; no spatial interaction
	context["source_key"] = "halda_bounty_clock"
	return _commit(peer, "bounty_rotate", {}, context)

func claim(peer: int, intent: Dictionary) -> Dictionary:
	var context := _context(peer)
	# Source provider must measure the actual registered board and host actor.
	# Do not turn a supplied node name or client position into in_range=true.
	return _commit(peer, "bounty_claim", intent.duplicate(true), context)

func confirmed_event(peer: int, token: String) -> Dictionary:
	var context := _context(peer)
	if context.is_empty() or not _accepted_event.is_valid(): return ACTIONS.deny("accepted_host_event_required")
	var event: Variant = _accepted_event.call(peer, token)
	if not event is Dictionary or event.get("event_confirmed") != true \
		or event.get("character_id") != context.character_id \
		or event.get("world_namespace") != context.get("world_namespace"):
		return ACTIONS.deny("accepted_host_event_required")
	# Board IDs must be frozen at encounter/catch admission, not looked up
	# after a late victory: an old encounter cannot complete tomorrow's board.
	for field: String in ["event_id", "kind", "biome", "traits", "participants", "issued_instances", "event_confirmed"]:
		if event.has(field): context[field] = event[field].duplicate(true) if event[field] is Array or event[field] is Dictionary else event[field]
	context["in_range"] = true
	context["source_key"] = "halda_bounty_event"
	return _commit(peer, "bounty_event", {}, context)

func personal_view(peer: int) -> Dictionary:
	var context := _context(peer)
	if context.is_empty(): return {"ready": false}
	var registry: RefCounted = _session.get("_character_authority")
	var current: Dictionary = registry.call("state", context.character_id)
	var result := BOARD.view(current.redesign_character, context.character_id)
	result["world_namespace"] = context.world_namespace
	return result
