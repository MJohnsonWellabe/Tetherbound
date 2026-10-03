extends RefCounted

## Exact owner-input replay before an ORIGINAL retained research duty. This
## never installs a host candidate into the owner or replaces an immutable row.
const REPLAY := preload("res://scripts/net/owner_passive_replay.gd")
const PREP := preload("res://scripts/net/owner_passive_preparation.gd")
const HASH := preload("res://scripts/net/research_passive_preparation.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const E := preload("res://scripts/creatures/essence.gd")
const EVENT := preload("res://scripts/net/foundation_event.gd")
const GROOM := preload("res://scripts/net/groom_passive_sync.gd")
const RESEARCH := preload("res://scripts/creatures/research_actions.gd")
const REQUEST_KINDS := ["foundation_request", "altar_spend", "manual_refine", "altar_traits"]
const REQUEST_ACTIONS := ["station_craft", "feast_cook", "feast_feed", "relic_hang", "master_chest"]
const RETAINED_ACTIONS := ["research_event", "master_win", "boss_relic", "combat_mastery"]
const MAX_BUFFER := 120000
const MAX_BATCH := 64
const MAX_PEERS := 4
const MAX_SPEED := 40.0
## The recorder starts before the existing connection+snapshot handshake.
## This bounded initial allowance does not replace or extend those deadlines.
const ADMISSION_ALLOWANCE_S := 80.0
const INITIAL_POSE_LAG_S := 2.0
var _session: WeakRef
var local: Dictionary = {}
var hosts: Dictionary = {}
var pending: Dictionary = {}
var committing: Dictionary = {}
var saving := false
var _left := 0.0

func _init(session: Node = null) -> void:
	if session != null: _session = weakref(session)

func owner() -> Node:
	return _session.get_ref() as Node if _session != null else null

func _game() -> Node:
	return owner().call("_game") as Node if owner() != null else null

func _discoveries() -> Dictionary:
	return owner().call("_groom_service").call("admission_landmarks")

func _projection() -> Dictionary:
	return RECORD.portable_projection(_game().get("local").call("save_data"))

func arm_owner(before: Dictionary, discoveries: Dictionary) -> Dictionary:
	var cursor := REPLAY.begin(before, discoveries)
	if cursor.is_empty(): return {}
	local = {"id": Crypto.new().generate_random_bytes(16).hex_encode(), "character": before.character_id,
		"base_hash": HASH.fingerprint(before), "sequence": 0, "prefix_hash": cursor.prefix_hash,
		"inputs": [], "acked": 0, "error": "", "last_settlement": "", "rebase": {}}
	pending.clear()
	var game := _game()
	if game != null:
		game.set("_travel_pos_valid", false)
		game.set("_discovery_elapsed", 0.0)
	return {"id": local.id, "baseline_hash": local.base_hash}

func record_input(input: Dictionary) -> void:
	if local.is_empty() or not pending.is_empty() or not str(local.error).is_empty(): return
	if local.inputs.size() >= MAX_BUFFER:
		local.error = "owner_passive_buffer_full"
		return # Never discard an unacknowledged transition.
	var packet := input.duplicate(true)
	packet.version = 1
	packet.sequence = int(local.sequence) + 1
	local.sequence = packet.sequence
	local.prefix_hash = HASH.fingerprint({"previous": local.prefix_hash, "packet": packet})
	local.inputs.append(packet)

func recording_active() -> bool:
	return not local.is_empty() and pending.is_empty() and str(local.error).is_empty()

func _scope() -> Dictionary:
	var game := _game()
	if game == null or game.get("world") == null or game.get("local") == null or owner() == null: return {}
	return {"character_id": game.get("local").character_id, "world_id": game.get("world").world_id,
		"world_namespace": game.get("world").reward_delivery_namespace,
		"session_epoch": owner().call("_altar_current_epoch")}

func _send_host(message: Dictionary, stream_id: String = "") -> void:
	if local.is_empty() or owner() == null or owner().call("snapshot_ready") != true: return
	var packet := _scope()
	packet.merge(message, true)
	packet.stream_id = local.id if stream_id.is_empty() else stream_id
	owner().call("_owner_passive_send_host", packet)

func _send_owner(peer: int, stream: Dictionary, message: Dictionary) -> void:
	var packet := {"character_id": stream.character, "world_id": stream.world_id,
		"world_namespace": stream.world_namespace, "session_epoch": stream.epoch, "stream_id": stream.id}
	packet.merge(message, true)
	owner().call("_owner_passive_send_peer", peer, packet)

func admitted(peer: int, summary: Dictionary) -> void:
	var session := owner()
	var declaration: Variant = summary.get("owner_passive_stream")
	if session == null or session.call("is_host") != true or not declaration is Dictionary \
		or not HASH._hex(declaration.get("id"), 32): return
	var character: String = session.call("_authority_character", peer)
	var authority: RefCounted = session.get("_character_authority")
	var before: Dictionary = authority.call("state", character)
	if not E._equivalent(before, summary.get("portable_authority")) \
		or HASH.fingerprint(before) != declaration.get("baseline_hash"): return
	_add_host(peer, character, str(declaration.id), before, authority.call("discovered_landmarks", character))

func _add_host(peer: int, character: String, stream_id: String, before: Dictionary, discoveries: Dictionary) -> bool:
	if not hosts.has(character) and hosts.size() >= MAX_PEERS: return false
	if hosts.has(character) and not hosts[character].get("checkpoint", {}).is_empty(): return false
	var cursor := REPLAY.begin(before, discoveries)
	if cursor.is_empty(): return false
	var world: RefCounted = _game().get("world")
	hosts[character] = {"peer": peer, "character": character, "id": stream_id,
		"world_id": world.world_id, "world_namespace": world.reward_delivery_namespace,
		"epoch": owner().call("_altar_current_epoch"), "started_ms": Time.get_ticks_msec(),
		"cursor": cursor, "revision": owner().get("_character_authority").call("revision", character),
		"seen": {}, "checkpoint": {}, "error": ""}
	return true

func _host_scope(peer: int, packet: Dictionary) -> bool:
	var session := owner()
	var game := _game()
	return session != null and game != null and session.call("is_host") == true \
		and packet.get("character_id") == session.call("_authority_character", peer) \
		and packet.get("world_id") == game.get("world").world_id \
		and packet.get("world_namespace") == game.get("world").reward_delivery_namespace \
		and packet.get("session_epoch") == session.call("_altar_current_epoch")

func receive_host(peer: int, packet: Dictionary) -> void:
	if not _host_scope(peer, packet): return
	var character: String = packet.character_id
	if packet.get("op") == "rebase":
		_rebase_host(peer, packet)
		return
	if not hosts.has(character): return
	var stream: Dictionary = hosts[character]
	if stream.peer != peer or stream.id != packet.get("stream_id") or stream.epoch != packet.session_epoch: return
	match packet.get("op"):
		"inputs": _inputs_host(peer, stream, packet)
		"frozen": _frozen_host(peer, stream, packet)
		"saved": _saved_host(peer, stream, packet)

func _context(peer: int, stream: Dictionary) -> Dictionary:
	var session := owner()
	var registry: RefCounted = session.call("registry")
	var realm := ""
	for row: Dictionary in registry.call("rows"):
		if row.get("peer_id") == peer: realm = str(row.get("realm", ""))
	var map: RefCounted = _game().get("local").call("map_for", realm)
	var definitions := GROOM.landmark_definitions(map, realm, session.call("_foundation_flags", peer),
		_game().get("world").flags.call("all_set"))
	var context := {"realm": realm, "landmarks": definitions, "max_speed": MAX_SPEED,
		"max_elapsed": ADMISSION_ALLOWANCE_S + float(Time.get_ticks_msec() - int(stream.started_ms)) / 1000.0}
	var lifecycle := session.get_node_or_null(^"FoundationComposition/TravelLifecycle")
	var actor: CharacterBody3D = lifecycle.call("remote_body", peer) if lifecycle != null else null
	var shell: Node3D = session.call("_portal_world_node", realm)
	if actor != null and shell != null and shell.is_ancestor_of(actor):
		context.initial_position = actor.global_position
		context.initial_max_distance = MAX_SPEED * INITIAL_POSE_LAG_S
	return context

func _inputs_host(peer: int, stream: Dictionary, packet: Dictionary) -> void:
	if not str(stream.error).is_empty() or not packet.get("inputs") is Array \
		or packet.inputs.is_empty() or packet.inputs.size() > MAX_BATCH: return
	var context := _context(peer, stream)
	for input: Variant in packet.inputs:
		if not input is Dictionary or not input.get("sequence") is int:
			stream.error = "owner_passive_invalid_input"; return
		var sequence: int = input.sequence
		var digest := HASH.fingerprint(input)
		if sequence <= int(stream.cursor.sequence):
			if stream.seen.get(sequence) != digest: stream.error = "owner_passive_conflicting_duplicate"
			if not str(stream.error).is_empty(): return
			continue
		if stream.seen.size() >= MAX_BUFFER:
			stream.error = "owner_passive_host_buffer_full"; return
		if input.get("op") == "discovery" and (stream.cursor.travel_valid != true or stream.cursor.realm != context.realm):
			var at: Variant = input.get("to")
			if not context.get("initial_position") is Vector3: return # Realm body has not arrived; retry this exact prefix.
			if not REPLAY._position(at) \
				or context.initial_position.distance_to(Vector3(float(at[0]), float(at[1]), float(at[2]))) > float(context.initial_max_distance):
				stream.first_input_refusal = {"input": input.duplicate(true), "context": context.duplicate(true),
					"cursor_sequence": stream.cursor.sequence, "sampled_ms": Time.get_ticks_msec()}
				stream.error = "owner_passive_initial_pose_unconfirmed"; return
		var input_context := context.duplicate()
		if input.get("op") == "discovery" and REPLAY._position(input.get("from")) and REPLAY._position(input.get("to")):
			var from := Vector3(float(input.from[0]), float(input.from[1]), float(input.from[2]))
			var to := Vector3(float(input.to[0]), float(input.to[1]), float(input.to[2]))
			if input.get("travel_valid") == true and from.distance_to(to) > 30.0:
				# A real host-observed discontinuity can establish a new endpoint,
				# never walking credit. Wait for replication instead of inventing it.
				if not context.get("initial_position") is Vector3 or context.initial_position.distance_to(to) > 2.0: return
				input_context.discontinuity_authorized = true
		var applied := REPLAY.apply(stream.cursor, input, input_context)
		if applied.get("ok") != true:
			stream.first_input_refusal = {"input": input.duplicate(true), "context": input_context.duplicate(true),
				"cursor_sequence": stream.cursor.sequence, "sampled_ms": Time.get_ticks_msec()}
			stream.error = str(applied.get("code", "owner_passive_replay_refused")); return
		stream.cursor = applied.cursor
		stream.seen[sequence] = digest
	_send_owner(peer, stream, {"op": "inputs_ack", "sequence": stream.cursor.sequence})
	if not stream.checkpoint.is_empty() and stream.checkpoint.has("frozen"):
		_prepare_host(peer, stream)

func gate(peer: int, action: String, intent: Dictionary, event: Dictionary) -> Dictionary:
	var session := owner()
	if peer == session.call("local_peer_id"): return {"ok": true}
	var character: String = session.call("_authority_character", peer)
	var binding := {"character": character, "action": action, "intent": intent, "event": event}
	if E._equivalent(committing, binding): return {"ok": true}
	if action not in RETAINED_ACTIONS or not hosts.has(character): return _deny("owner_passive_recording_unavailable")
	var stream: Dictionary = hosts[character]
	if not str(stream.error).is_empty(): return _deny(str(stream.error))
	var world: RefCounted = _game().get("world")
	var retained: Variant = world.reward_deliveries.get(event.get("retained_event"))
	if not EVENT.valid(retained, world.reward_delivery_namespace, world.world_id): return _deny("owner_passive_retained_event_required")
	var matching: Array[Dictionary] = []
	for duty: Dictionary in retained.duties:
		if duty.character_id != character or duty.action != action or not E._equivalent(duty.intent, intent): continue
		var expected: Dictionary = duty.context.duplicate(true)
		expected.character_id = character
		expected.expected_revision = event.get("expected_revision")
		expected.in_range = true
		expected.retained_event = retained.delivery_id
		if action != "research_event":
			expected.in_combat = false
			expected.foundation_runtime_authorized = true
		if action == "boss_relic": expected.boss_settlement_world_flags = world.flags.call("all_set").duplicate()
		if E._equivalent(expected, event): matching.append(duty)
	if matching.size() != 1: return _deny("owner_passive_original_duty_required")
	return _checkpoint(peer, stream, binding, retained, matching[0])

func capture_gate(peer: int, envelope: Dictionary, context: Dictionary) -> Dictionary:
	var session := owner()
	if peer == session.call("local_peer_id"): return {"ok": true}
	var character: String = session.call("_authority_character", peer)
	# Only the synchronous post-BOOL/CAS call below can reuse this exact request.
	if committing.get("character") == character and committing.get("action") == "wild_capture" \
		and PREP.exact(committing.get("envelope"), envelope):
		var expected: Dictionary = committing.event.duplicate(true)
		expected.expected_revision = envelope.revision
		return {"ok": true} if PREP.exact(expected, context) else _terminal("owner_passive_source_changed")
	if envelope.get("op") != "wild_capture" or not envelope.get("intent") is Dictionary \
		or not hosts.has(character): return _deny("owner_passive_recording_unavailable")
	var stream: Dictionary = hosts[character]
	if not str(stream.error).is_empty(): return _deny(str(stream.error))
	var world: RefCounted = _game().get("world")
	if envelope.get("session_epoch") != session.call("_altar_current_epoch") \
		or envelope.get("world_namespace") != world.reward_delivery_namespace: return _deny("owner_passive_capture_scope_changed")
	var retained: Variant = world.reward_deliveries.get(context.get("retained_event"))
	if not EVENT.valid(retained, world.reward_delivery_namespace, world.world_id): return _deny("owner_passive_retained_event_required")
	var matching: Array[Dictionary] = []
	for duty: Dictionary in retained.duties:
		if duty.character_id != character or duty.action != "capture_offer": continue
		var expected: Dictionary = duty.context.duplicate(true)
		expected.character_id = character
		expected.expected_revision = session.get("_character_authority").call("revision", character)
		expected.in_range = true
		expected.in_combat = false
		expected.foundation_runtime_authorized = true
		expected.retained_event = retained.delivery_id
		if PREP.exact(expected, context) and envelope.get("character_id") == character \
			and envelope.get("station_key") == duty.context.source_key \
			and envelope.get("revision") == expected.expected_revision: matching.append(duty)
	if matching.size() != 1: return _deny("owner_passive_original_duty_required")
	var current: Dictionary = session.get("_character_authority").call("state", character)
	var choice: Dictionary = preload("res://scripts/net/foundation_capture_rules.gd").stage(current, envelope.intent, context)
	if choice.get("ok") != true: return _deny(str(choice.get("code", "capture_choice_refused")))
	var binding := {"character": character, "action": "wild_capture", "intent": envelope.intent.duplicate(true),
		"event": context.duplicate(true), "envelope": envelope.duplicate(true)}
	return _checkpoint(peer, stream, binding, retained, matching[0])

func _checkpoint(peer: int, stream: Dictionary, binding: Dictionary, retained: Dictionary, duty: Dictionary) -> Dictionary:
	if stream.checkpoint.is_empty():
		var authority: RefCounted = owner().get("_character_authority")
		if authority.call("creature_training_is_pending", str(stream.character)) == true: return _deny("owner_passive_prior_transaction_pending")
		stream.checkpoint = {"id": Crypto.new().generate_random_bytes(16).hex_encode(), "binding": binding.duplicate(true),
			"retained": retained.duplicate(true), "duty": duty.duplicate(true)}
	elif not E._equivalent(stream.checkpoint.binding, binding): return _deny("owner_passive_original_pending")
	_send_owner(peer, stream, {"op": "freeze", "id": stream.checkpoint.id,
		"retained_event": retained.delivery_id, "duty_hash": HASH.fingerprint(duty)})
	return _deny("owner_passive_checkpoint_pending")

## Each caller has already authenticated its original request and validated
## its actual station/completed unit with the existing pure action producer.
## No invented retained event represents these explicit player requests.
func action_gate(peer: int, source_kind: String, request: Dictionary, context: Dictionary) -> Dictionary:
	var session := owner()
	if peer == session.call("local_peer_id"): return {"ok": true}
	var character: String = session.call("_authority_character", peer)
	if source_kind not in REQUEST_KINDS: return _deny("owner_passive_request_kind")
	if source_kind == "foundation_request" and request.get("op") not in REQUEST_ACTIONS: return _deny("owner_passive_request_kind")
	if committing.get("character") == character and committing.get("source_kind") == source_kind \
		and PREP.exact(committing.get("envelope"), request):
		return {"ok": true} if PREP.exact(committing.event, context) else _terminal("owner_passive_source_changed")
	if not hosts.has(character): return _deny("owner_passive_recording_unavailable")
	var stream: Dictionary = hosts[character]
	if not str(stream.error).is_empty(): return _deny(str(stream.error))
	var world: RefCounted = _game().get("world")
	if request.get("character_id") != character or request.get("session_epoch") != session.call("_altar_current_epoch") \
		or request.get("world_namespace") != world.reward_delivery_namespace: return _deny("owner_passive_request_scope_changed")
	var binding := {"character": character, "action": request.get("op"), "source_kind": source_kind,
		"envelope": request.duplicate(true), "event": context.duplicate(true)}
	if stream.checkpoint.is_empty():
		var authority: RefCounted = session.get("_character_authority")
		if authority.call("creature_training_is_pending", character) == true: return _deny("owner_passive_prior_transaction_pending")
		# Validate the exact source shape and locally replayed cursor before
		# asking the owner to freeze. This check does not promote any state.
		var shape := PREP.make_action(request, context, authority.call("state", character),
			int(authority.call("revision", character)), str(stream.epoch), world.world_id, stream.cursor,
			"0".repeat(32), source_kind)
		if shape.is_empty(): return _deny("owner_passive_request_source_changed")
		stream.checkpoint = {"id": Crypto.new().generate_random_bytes(16).hex_encode(),
			"binding": binding, "source_kind": source_kind, "request": request.duplicate(true),
			"host_context": context.duplicate(true)}
	elif not PREP.exact(stream.checkpoint.binding, binding): return _deny("owner_passive_original_pending")
	_send_owner(peer, stream, {"op": "freeze", "id": stream.checkpoint.id, "source_kind": source_kind,
		"request": request, "request_hash": HASH.fingerprint(request)})
	return _deny("owner_passive_checkpoint_pending")

func pending_manual_unit(character: String, ticket: String) -> bool:
	var checkpoint: Dictionary = hosts.get(character, {}).get("checkpoint", {})
	return checkpoint.get("source_kind") == "manual_refine" \
		and checkpoint.get("host_context", {}).get("manual_unit_ticket") == ticket

func _frozen_host(peer: int, stream: Dictionary, packet: Dictionary) -> void:
	var checkpoint: Dictionary = stream.checkpoint
	if checkpoint.is_empty() or packet.get("id") != checkpoint.id \
		or not packet.get("sequence") is int or not HASH._hex(packet.get("hash"), 64) \
		or not HASH._hex(packet.get("prefix_hash"), 64): return
	var frozen := {"sequence": packet.sequence, "hash": packet.hash, "prefix_hash": packet.prefix_hash}
	if checkpoint.has("frozen") and not E._equivalent(checkpoint.frozen, frozen): return
	checkpoint.frozen = frozen
	_prepare_host(peer, stream)

func _prepare_host(peer: int, stream: Dictionary) -> void:
	var checkpoint: Dictionary = stream.checkpoint
	if not str(stream.error).is_empty() or checkpoint.is_empty() or not checkpoint.has("frozen"): return
	var frozen: Dictionary = checkpoint.frozen
	if int(stream.cursor.sequence) < int(frozen.sequence): return
	if stream.cursor.sequence != frozen.sequence or stream.cursor.prefix_hash != frozen.prefix_hash \
		or HASH.fingerprint(stream.cursor.state) != frozen.hash:
		stream.error = "owner_passive_exact_projection_conflict"; return
	if not checkpoint.has("prepared"):
		var authority: RefCounted = owner().get("_character_authority")
		var before: Dictionary = authority.call("state", stream.character)
		if not E._equivalent(before, stream.cursor.base) or authority.call("revision", stream.character) != stream.revision:
			stream.error = "owner_passive_authority_changed"; return
		var prepared: Dictionary
		if checkpoint.has("source_kind"):
			prepared = PREP.make_action(checkpoint.request, checkpoint.host_context, before, stream.revision,
				stream.epoch, str(stream.world_id), stream.cursor, checkpoint.id, checkpoint.source_kind)
		else:
			prepared = PREP.make(checkpoint.retained, checkpoint.duty, before, stream.revision,
				stream.epoch, stream.cursor, checkpoint.id)
		if prepared.is_empty() or authority.call("reserve_owner_passive_checkpoint", stream.character, prepared, checkpoint.get("retained", {}), stream.cursor) != true: return
		checkpoint.prepared = prepared
	_send_owner(peer, stream, {"op": "prepared", "id": checkpoint.id, "prepared": checkpoint.prepared,
		"retained": checkpoint.get("retained", {})})

func _saved_host(peer: int, stream: Dictionary, packet: Dictionary) -> void:
	var checkpoint: Dictionary = stream.checkpoint
	if checkpoint.is_empty() or not checkpoint.has("prepared") or packet.get("id") != checkpoint.id \
		or packet.get("hash") != checkpoint.prepared.hash or packet.get("saved") != true: return
	if checkpoint.has("result"):
		_completion(peer, stream)
		return
	var world: RefCounted = _game().get("world")
	if not checkpoint.has("source_kind") and not E._equivalent(world.reward_deliveries.get(checkpoint.retained.delivery_id), checkpoint.retained): return
	var authority: RefCounted = owner().get("_character_authority")
	if authority.call("commit_owner_passive_checkpoint", stream.character, checkpoint.prepared.hash) != true: return
	committing = checkpoint.binding.duplicate(true)
	var result: Dictionary
	if checkpoint.has("source_kind"):
		# Request checkpoints preserve the action revision. Original Altar/
		# Traits intent and immutable receipt correlation are never rewritten.
		result = owner().call("_owner_passive_commit_request", peer, checkpoint.source_kind,
			committing.envelope, checkpoint.host_context)
	elif committing.action == "wild_capture":
		# The exact choice/source remains the authenticated original. Only this
		# host's successful checkpoint CAS advances its expected revision.
		committing.envelope.revision = authority.call("revision", stream.character)
		result = owner().call("_foundation_handle", peer, committing.envelope)
	elif committing.action == "research_event":
		result = RESEARCH.commit(owner(), peer, committing.action, committing.intent, committing.event)
	else:
		result = owner().call("_owner_passive_commit_retained", peer, committing)
	committing.clear()
	var no_effect: bool = _terminal_without_effect(stream, result)
	if result.get("durable") == true or result.get("code") == "research_no_progress" or no_effect:
		authority.call("cancel_owner_passive_checkpoint", stream.character, checkpoint.prepared.hash)
		checkpoint.result = result.duplicate(true)
		checkpoint.no_effect = no_effect
		_completion(peer, stream)
	else:
		authority.call("retain_owner_passive_checkpoint", stream.character, checkpoint.prepared.hash)

func _terminal_without_effect(stream: Dictionary, result: Dictionary) -> bool:
	if result.get("durable") == true or result.get("terminal_refusal") != true or result.get("resolved") != true: return false
	if result.get("code") in ["training_journal_failed", "world_not_prepared", "world_save_failed", "stage_changed", "fallback_busy", "character_busy", "transaction_busy"]: return false
	var authority: RefCounted = owner().get("_character_authority")
	return authority.call("creature_training_is_pending", str(stream.character)) != true \
		and PREP.exact(authority.call("state", stream.character), stream.checkpoint.prepared.after)

func _completion(peer: int, stream: Dictionary) -> void:
	var checkpoint: Dictionary = stream.checkpoint
	var op := "journaled"
	if checkpoint.get("no_effect") == true: op = "no_effect"
	elif checkpoint.result.get("code") == "research_no_progress": op = "no_progress"
	_send_owner(peer, stream, {"op": op, "id": checkpoint.id, "hash": checkpoint.prepared.hash, "result": checkpoint.result})

func receive_owner(packet: Dictionary) -> void:
	if local.is_empty(): return
	var scope := _scope()
	for field: String in scope:
		if packet.get(field) != scope[field]: return
	if packet.get("stream_id") != local.id:
		if packet.get("op") != "inputs_ack" or local.rebase.get("old_stream") != packet.get("stream_id") \
			or not packet.get("sequence") is int or packet.sequence > int(local.rebase.get("old_sequence", -1)): return
		var old_inputs: Array = local.rebase.get("old_inputs", [])
		while not old_inputs.is_empty() and int(old_inputs[0].sequence) <= int(packet.sequence): old_inputs.pop_front()
		return
	match packet.get("op"):
		"rebase_ack": local.rebase = {}
		"inputs_ack":
			if not packet.get("sequence") is int or packet.sequence < local.acked or packet.sequence > local.sequence: return
			local.acked = packet.sequence
			while not local.inputs.is_empty() and int(local.inputs[0].sequence) <= int(local.acked): local.inputs.pop_front()
		"freeze":
			if not HASH._hex(packet.get("id"), 32): return
			var request_source: bool = packet.get("source_kind") in REQUEST_KINDS
			if request_source:
				if not packet.get("request") is Dictionary or HASH.fingerprint(packet.request) != packet.get("request_hash") \
					or owner().call("_owner_passive_request_matches", packet.source_kind, packet.request) != true: return
			elif packet.has("source_kind") or not HASH._hex(packet.get("duty_hash"), 64): return
			if not pending.is_empty() and pending.id != packet.id: return
			if pending.is_empty():
				var saver: RefCounted = _game().get("save_system")
				if saver == null: return
				saver.call("finish_fallback") # Complete reentrant save callbacks before freezing any owner state.
				if saver.call("fallback_busy") == true or _scope() != scope or local.is_empty() or local.id != packet.stream_id: return
				pending = {"id": packet.id, "scope": scope, "retained_event": packet.get("retained_event"),
					"duty_hash": packet.get("duty_hash", ""), "sequence": local.sequence, "prefix_hash": local.prefix_hash,
					"hash": HASH.fingerprint(_projection()), "phase": "frozen"}
				if request_source:
					pending.source_kind = packet.source_kind
					pending.request_hash = packet.request_hash
			_retry_owner()
		"prepared":
			if pending.is_empty() or pending.id != packet.get("id"): return
			var prepared: Variant = packet.get("prepared")
			var retained: Variant = packet.get("retained")
			var request_source: bool = pending.has("source_kind")
			if request_source:
				if not PREP.valid_action(prepared) or prepared.source_kind != pending.source_kind \
					or prepared.request_hash != pending.request_hash \
					or owner().call("_owner_passive_request_matches", prepared.source_kind, prepared.request) != true: return
			elif not PREP.valid(prepared, retained) or prepared.retained_event != pending.retained_event \
				or prepared.duty_hash != pending.duty_hash: return
			if prepared.character_id != scope.character_id \
				or prepared.session_epoch != scope.session_epoch or prepared.world_namespace != scope.world_namespace \
				or prepared.world_id != scope.world_id or prepared.final_sequence != pending.sequence \
				or prepared.input_prefix_hash != pending.prefix_hash or HASH.fingerprint(prepared.after) != pending.hash: return
			if pending.has("prepared") and not E._equivalent(pending.prepared, prepared): return
			pending.prepared = prepared.duplicate(true)
			pending.retained = retained.duplicate(true)
			pending.phase = "save"
			_retry_owner()
		"journaled":
			if not pending.is_empty() and pending.id == packet.get("id"):
				pending.phase = "journaled" # Existing original owner-row settlement releases the fence.
		"no_progress", "no_effect":
			if pending.is_empty() or pending.id != packet.get("id") or not pending.has("prepared") \
				or packet.get("hash") != pending.prepared.hash \
				or not PREP.exact(_projection(), pending.prepared.after): return
			var result: Dictionary = packet.get("result", {})
			if packet.op == "no_progress" and result.get("code") != "research_no_progress": return
			if packet.op == "no_effect" and (result.get("terminal_refusal") != true or result.get("resolved") != true or result.get("durable") == true): return
			var old := {"checkpoint_id": pending.id, "checkpoint_hash": pending.prepared.hash}
			var terminal_source := str(pending.get("source_kind", ""))
			var terminal_request: Dictionary = pending.prepared.get("request", {}).duplicate(true)
			var previous := local.duplicate(true)
			var declaration := arm_owner(_projection(), _discoveries())
			if declaration.is_empty(): return
			_queue_rebase(declaration, previous, old)
			_flush()
			if packet.op == "no_effect" and not terminal_source.is_empty():
				owner().call("_owner_passive_request_terminal", terminal_source, terminal_request, result)

func blocked(player: RefCounted) -> bool:
	return not pending.is_empty() and _game() != null and player == _game().get("local") and pending.scope == _scope()

func snapshot_allowed(player: RefCounted, payload: Dictionary) -> bool:
	return saving and blocked(player) and pending.has("prepared") \
		and PREP.exact(RECORD.portable_projection(payload), pending.prepared.after)

func _retry_owner() -> void:
	if pending.is_empty() or pending.scope != _scope() or not str(local.error).is_empty(): return
	_flush()
	if pending.phase == "frozen":
		_send_host({"op": "frozen", "id": pending.id, "sequence": pending.sequence,
			"prefix_hash": pending.prefix_hash, "hash": pending.hash})
	elif pending.phase == "save":
		var saver: RefCounted = _game().get("save_system")
		if saver == null: return
		saver.call("finish_fallback")
		if saver.call("fallback_busy") == true or pending.scope != _scope(): return
		var plan := PREP.owner_plan(_projection(), pending.prepared, pending.retained, _discoveries())
		if plan.get("ok") != true:
			local.error = str(plan.get("code", "owner_passive_owner_changed")); return
		saving = true
		var saved: bool = saver.call("save_character_prepared", _game(), str(local.character)) == true
		saving = false
		if not saved or pending.scope != _scope(): return
		if not PREP.exact(_projection(), pending.prepared.after):
			local.error = "owner_passive_owner_changed_after_save"; return
		pending.phase = "saved"
	if pending.phase == "saved":
		_send_host({"op": "saved", "id": pending.id, "hash": pending.prepared.hash, "saved": true})

func _flush() -> void:
	if local.is_empty() or not str(local.error).is_empty(): return
	if not local.rebase.is_empty():
		var old_inputs: Array = local.rebase.get("old_inputs", [])
		if not old_inputs.is_empty():
			_send_host({"op": "inputs", "inputs": old_inputs.slice(0, mini(MAX_BATCH, old_inputs.size())).duplicate(true)}, str(local.rebase.old_stream))
		else:
			var request: Dictionary = local.rebase.duplicate(true)
			request.erase("old_inputs")
			_send_host(request)
		return # Retry until authenticated host accepts this exact saved baseline.
	if local.inputs.is_empty(): return
	_send_host({"op": "inputs", "inputs": local.inputs.slice(0, mini(MAX_BATCH, local.inputs.size())).duplicate(true)})

func tick(delta: float) -> void:
	_left -= delta
	if _left > 0.0: return
	_left = 0.25
	if owner() == null or owner().call("is_host") == true: return
	if pending.is_empty(): _flush()
	else: _retry_owner()

func owner_settled(row: Dictionary) -> void:
	if local.is_empty() or owner().call("is_host") == true or row.get("status") != "accepted" \
		or row.get("character_id") != local.character or not row.get("after") is Dictionary \
		or local.get("last_settlement") == row.get("receipt") \
		or not PREP.exact(RECORD.training_projection(_projection(), row, E.training_projection), row.after): return
	var previous := local.duplicate(true)
	var declaration := arm_owner(_projection(), _discoveries())
	if declaration.is_empty(): return
	local.last_settlement = row.receipt
	_queue_rebase(declaration, previous, {"receipt": row.receipt, "delivery_id": row.delivery_id})
	_flush()

func _queue_rebase(declaration: Dictionary, previous: Dictionary, binding: Dictionary) -> void:
	local.rebase = {"op": "rebase", "baseline_hash": declaration.baseline_hash,
		"old_stream": previous.id, "old_sequence": previous.sequence, "old_prefix_hash": previous.prefix_hash,
		"old_inputs": previous.inputs.duplicate(true), "discoveries_hash": HASH.fingerprint({"discovered": _discoveries()})}
	local.rebase.merge(binding, true)

func _rebase_host(peer: int, packet: Dictionary) -> void:
	if not HASH._hex(packet.get("stream_id"), 32): return
	var world: RefCounted = _game().get("world")
	var row: Variant = world.reward_deliveries.get(packet.get("delivery_id"))
	var authority: RefCounted = owner().get("_character_authority")
	var character: String = packet.character_id
	if hosts.has(character) and hosts[character].id == packet.stream_id:
		if HASH.fingerprint(hosts[character].cursor.base) == packet.get("baseline_hash"):
			_send_owner(peer, hosts[character], {"op": "rebase_ack"})
		return
	var before: Dictionary = authority.call("state", character)
	var discoveries: Dictionary = authority.call("discovered_landmarks", character)
	if hosts.has(character):
		var previous: Dictionary = hosts[character]
		if previous.id != packet.get("old_stream") or previous.cursor.sequence != packet.get("old_sequence") \
			or previous.cursor.prefix_hash != packet.get("old_prefix_hash"): return
		discoveries = previous.cursor.discovered.duplicate(true)
	if HASH.fingerprint({"discovered": discoveries}) != packet.get("discoveries_hash"): return
	if packet.has("checkpoint_id"):
		if not hosts.has(character): return
		var old: Dictionary = hosts[character]
		var checkpoint: Dictionary = old.checkpoint
		if old.id != packet.get("old_stream") or checkpoint.get("id") != packet.checkpoint_id \
			or checkpoint.get("prepared", {}).get("hash") != packet.get("checkpoint_hash") \
			or (checkpoint.get("result", {}).get("code") != "research_no_progress" and checkpoint.get("no_effect") != true) \
			or not PREP.exact(before, checkpoint.prepared.after) or HASH.fingerprint(before) != packet.get("baseline_hash"): return
		hosts.erase(character)
		if _add_host(peer, character, packet.stream_id, before, discoveries):
			_send_owner(peer, hosts[character], {"op": "rebase_ack"})
		return
	if not row is Dictionary or row.get("status") != "accepted" or row.get("receipt") != packet.get("receipt") \
		or row.get("character_id") != character or not row.get("after") is Dictionary \
		or not PREP.exact(RECORD.training_projection(before, row, E.training_projection), row.after) \
		or HASH.fingerprint(before) != packet.get("baseline_hash"): return
	if hosts.has(character):
		var checkpoint: Dictionary = hosts[character].checkpoint
		if checkpoint.has("prepared") and not checkpoint.has("result"): return
		hosts.erase(character)
	if _add_host(peer, character, packet.stream_id, before, discoveries):
		_send_owner(peer, hosts[character], {"op": "rebase_ack"})

func reset() -> void:
	if owner() != null:
		var authority: RefCounted = owner().get("_character_authority")
		if authority != null:
			for stream: Dictionary in hosts.values():
				if stream.checkpoint.has("prepared"):
					authority.call("cancel_owner_passive_checkpoint", stream.character, stream.checkpoint.prepared.hash)
	local.clear()
	hosts.clear()
	pending.clear()
	committing.clear()
	saving = false

static func _deny(code: String) -> Dictionary:
	return {"ok": false, "durable": false, "resolved": false, "code": code}

static func _terminal(code: String) -> Dictionary:
	return {"ok": false, "durable": false, "resolved": true, "terminal_refusal": true, "code": code}
