extends "res://tests/test_case.gd"

## Service controls with explicit transport/writer doubles. No actual network,
## durable write, input route, or F48 acceptance is claimed by these unit tests.
const SYNC := preload("res://scripts/net/owner_passive_sync.gd")
const REPLAY := preload("res://scripts/net/owner_passive_replay.gd")
const PREP := preload("res://scripts/net/owner_passive_preparation.gd")
const AUTH := preload("res://scripts/net/character_authority.gd")
const SOURCE := preload("res://tests/test_research_passive_preparation.gd")
const GROOM := preload("res://tests/test_den_groom_saved_transaction.gd")

class Player extends RefCounted:
	var character_id := ""
	var data: Dictionary
	func save_data() -> Dictionary: return data.duplicate(true)

class World extends RefCounted:
	var world_id := ""
	var reward_delivery_namespace := ""
	var reward_deliveries := {}

class Writer extends RefCounted:
	var accepted := false
	var writes := 0
	func finish_fallback() -> void: pass
	func fallback_busy() -> bool: return false
	func save_character_prepared(_game: Node, _character: String) -> bool:
		writes += 1
		return accepted

class GameFixture extends Node:
	var local: RefCounted
	var world: RefCounted
	var save_system: RefCounted
	var _travel_pos_valid := true
	var _discovery_elapsed := 10.0

class Discoveries extends RefCounted:
	var value := {}
	func admission_landmarks() -> Dictionary: return value.duplicate(true)

class Session extends Node:
	var game: Node
	var host := false
	var _character_authority: RefCounted
	var messages: Array[Dictionary] = []
	var maps: RefCounted
	var capture_service: RefCounted
	var capture_context: Dictionary = {}
	var capture_calls: Array[Dictionary] = []
	var action_original: Dictionary = {}
	var action_calls: Array[Dictionary] = []
	var action_terminals: Array[Dictionary] = []
	var action_result := {"ok": false, "durable": false, "code": "fixture_world_write_failed"}
	func _game() -> Node: return game
	func _groom_service() -> RefCounted: return maps
	func _altar_current_epoch() -> String: return "current-epoch"
	func is_host() -> bool: return host
	func local_peer_id() -> int: return 1 if host else 2
	func snapshot_ready() -> bool: return true
	func _authority_character(peer: int) -> String: return game.local.character_id if peer == 2 else "host"
	func _owner_passive_send_host(packet: Dictionary) -> void: messages.append(packet.duplicate(true))
	func _owner_passive_send_peer(_peer: int, packet: Dictionary) -> void: messages.append(packet.duplicate(true))
	func _owner_passive_request_matches(kind: String, request: Dictionary) -> bool:
		return kind == "foundation_request" and PREP.exact(action_original, request)
	func _owner_passive_request_terminal(kind: String, request: Dictionary, result: Dictionary) -> void:
		action_terminals.append({"kind": kind, "request": request.duplicate(true), "result": result.duplicate(true)})
	func _owner_passive_commit_request(peer: int, kind: String, request: Dictionary, context: Dictionary) -> Dictionary:
		var gate: Dictionary = capture_service.call("action_gate", peer, kind, request, context)
		action_calls.append({"request": request.duplicate(true), "gate": gate,
			"revision": _character_authority.call("revision", game.local.character_id),
			"state": _character_authority.call("state", game.local.character_id)})
		return action_result.duplicate(true)
	func _foundation_handle(peer: int, envelope: Dictionary) -> Dictionary:
		# Disclosed failed world-writer seam: the real service must have completed
		# its CAS, and must retain the original for another authenticated ACK.
		var context := capture_context.duplicate(true)
		context.expected_revision = _character_authority.call("revision", game.local.character_id)
		var gate: Dictionary = capture_service.call("capture_gate", peer, envelope, context)
		capture_calls.append({"envelope": envelope.duplicate(true), "gate": gate,
			"revision": context.expected_revision, "state": _character_authority.call("state", game.local.character_id)})
		return {"ok": false, "durable": false, "code": "fixture_world_write_failed"}

class Service extends SYNC:
	var body_ready := true
	func _context(_peer: int, _stream: Dictionary) -> Dictionary:
		var result := {"realm": "meadows", "landmarks": {}, "max_speed": 40.0, "max_elapsed": 100.0}
		if body_ready:
			result.initial_position = Vector3.ZERO
			result.initial_max_distance = 80.0
		return result

var session: Session
var service: RefCounted
var game: GameFixture
var before: Dictionary
var event: Dictionary

func before_each() -> void:
	before = GROOM.new()._before()
	event = SOURCE.new()._event()
	game = GameFixture.new()
	game.local = Player.new()
	game.local.character_id = before.character_id
	game.local.data = before.duplicate(true)
	game.world = World.new()
	game.world.world_id = event.world_id
	game.world.reward_delivery_namespace = event.world_namespace
	game.world.reward_deliveries[event.delivery_id] = event.duplicate(true)
	game.save_system = Writer.new()
	session = Session.new()
	session.game = game
	session.maps = Discoveries.new()
	session._character_authority = AUTH.new()
	assert_true(session._character_authority.bind_world(event.world_namespace))
	assert_true(session._character_authority.seed_admitted_character(before, before.character_id).ok)
	assert_true(session._character_authority.seed_discovered_landmarks(before.character_id, {}))
	service = Service.new(session)
	service.arm_owner(before, {})

func after_each() -> void:
	game.free()
	session.free()

func _input(delta: float = 0.5) -> Dictionary:
	var uids: Array = []
	for card: Dictionary in before.party: uids.append(card.uid)
	return {"op": "condition", "delta": delta, "uids": uids}

func _envelope(message: Dictionary) -> Dictionary:
	var packet: Dictionary = service._scope()
	packet.stream_id = service.local.id
	packet.merge(message, true)
	return packet

func _host_stream() -> Dictionary:
	session.host = true
	assert_true(service._add_host(2, before.character_id, service.local.id, before, {}))
	return service.hosts[before.character_id]

func _prepared_owner() -> Dictionary:
	service.record_input(_input())
	var packet: Dictionary = service.local.inputs[0]
	var cursor := REPLAY.begin(before, {})
	var applied := REPLAY.apply(cursor, packet, {"realm": "meadows", "landmarks": {}, "max_speed": 40.0, "max_elapsed": 2.0})
	assert_true(applied.ok)
	game.local.data = applied.cursor.state.duplicate(true)
	var prepared := PREP.make(event, event.duties[0], before, 0, "current-epoch", applied.cursor, "c".repeat(32))
	assert_false(prepared.is_empty())
	service.receive_owner(_envelope({"op": "freeze", "id": prepared.preparation_id,
		"retained_event": event.delivery_id, "duty_hash": prepared.duty_hash}))
	return prepared

func test_recording_reset_and_authenticated_ordered_ack() -> void:
	assert_false(game._travel_pos_valid)
	assert_eq(game._discovery_elapsed, 0.0)
	service.record_input(_input(0.1))
	service.record_input(_input(0.2))
	assert_eq(service.local.sequence, 2)
	assert_eq(service.local.inputs[0].delta, 0.1)
	var wrong := _envelope({"op": "inputs_ack", "sequence": 2})
	wrong.session_epoch = "stale"
	service.receive_owner(wrong)
	assert_eq(service.local.inputs.size(), 2)
	service.receive_owner(_envelope({"op": "inputs_ack", "sequence": 3}))
	assert_eq(service.local.inputs.size(), 2)
	service.receive_owner(_envelope({"op": "inputs_ack", "sequence": 1}))
	assert_eq(service.local.inputs.size(), 1)
	assert_eq(service.local.inputs[0].sequence, 2)

func test_host_duplicate_input_is_idempotent_and_conflict_does_not_promote() -> void:
	service.record_input(_input())
	var stream := _host_stream()
	var packet := _envelope({"op": "inputs", "inputs": service.local.inputs.duplicate(true)})
	service.receive_host(2, packet)
	assert_eq(stream.cursor.sequence, 1)
	var expected: PackedByteArray = var_to_bytes(stream.cursor)
	service.receive_host(2, packet)
	assert_eq(var_to_bytes(stream.cursor), expected)
	assert_true(PREP.exact(session._character_authority.state(before.character_id), before), "stream is only a candidate")
	packet.inputs[0].delta = 0.6
	service.receive_host(2, packet)
	assert_eq(stream.error, "owner_passive_conflicting_duplicate")
	assert_eq(var_to_bytes(stream.cursor), expected)

func test_host_sequence_gap_and_initial_remote_pose_refused() -> void:
	service.record_input(_input())
	var stream := _host_stream()
	var packet: Dictionary = service.local.inputs[0].duplicate(true)
	packet.sequence = 2
	service.receive_host(2, _envelope({"op": "inputs", "inputs": [packet]}))
	assert_eq(stream.error, "sequence_mismatch")
	assert_eq(stream.cursor.sequence, 0)
	stream.error = ""
	packet.sequence = 1
	service.receive_host(2, _envelope({"op": "inputs", "inputs": [packet]}))
	service.receive_host(2, _envelope({"op": "inputs", "inputs": [{"version": 1, "sequence": 2,
		"op": "discovery", "realm": "meadows", "from": [0,0,0], "to": [100,0,0],
		"travel_valid": false, "new_landmarks": []}]}))
	assert_eq(stream.error, "owner_passive_initial_pose_unconfirmed")
	assert_eq(stream.cursor.sequence, 1)

func test_failed_bool_save_never_acks_or_installs_and_success_is_exact() -> void:
	var prepared := _prepared_owner()
	assert_true(service.blocked(game.local))
	var recorded: int = service.local.sequence
	service.record_input(_input())
	assert_eq(service.local.sequence, recorded, "checkpoint stops new inputs")
	var original: PackedByteArray = var_to_bytes(game.local.data)
	service.receive_owner(_envelope({"op": "prepared", "id": prepared.preparation_id,
		"prepared": prepared, "retained": event}))
	assert_eq(game.save_system.writes, 1)
	assert_eq(service.pending.phase, "save")
	for message: Dictionary in session.messages: assert_ne(message.op, "saved")
	assert_eq(var_to_bytes(game.local.data), original, "neither failed nor successful save installs a candidate")
	game.save_system.accepted = true
	service._retry_owner()
	assert_eq(service.pending.phase, "saved")
	assert_eq(session.messages[-1].op, "saved")
	assert_eq(session.messages[-1].hash, prepared.hash)
	assert_eq(var_to_bytes(game.local.data), original)

func test_core_change_before_checkpoint_refuses_without_owner_write() -> void:
	var prepared := _prepared_owner()
	game.local.data.party[0].hp -= 1.0
	service.receive_owner(_envelope({"op": "prepared", "id": prepared.preparation_id,
		"prepared": prepared, "retained": event}))
	assert_eq(game.save_system.writes, 0)
	assert_eq(service.local.error, "owner_passive_checkpoint_conflict")
	assert_true(service.blocked(game.local), "no unsafe resume on unresolved exact original")

func test_no_progress_exact_reply_releases_fence_into_retryable_rebase() -> void:
	var prepared := _prepared_owner()
	service.pending.prepared = prepared
	var old_id: String = service.local.id
	service.receive_owner(_envelope({"op": "no_progress", "id": prepared.preparation_id,
		"hash": prepared.hash, "result": {"code": "research_no_progress"}}))
	assert_true(service.pending.is_empty())
	assert_false(service.blocked(game.local))
	assert_ne(service.local.id, old_id)
	assert_eq(service.local.rebase.old_stream, old_id)
	assert_eq(session.messages[-1].op, "inputs", "unacknowledged original input drains before switching baseline")
	assert_eq(session.messages[-1].stream_id, old_id)
	var acknowledgement := _envelope({"op": "inputs_ack", "sequence": 1})
	acknowledgement.stream_id = old_id
	service.receive_owner(acknowledgement)
	service._flush()
	assert_eq(session.messages[-1].op, "rebase")
	service._flush()
	assert_eq(session.messages[-1].op, "rebase", "rebase survives early host refusal")
	service.receive_owner(_envelope({"op": "rebase_ack"}))
	assert_true(service.local.rebase.is_empty())

func test_missing_remote_body_defers_exact_discovery_without_poisoning_stream() -> void:
	service.record_input(_input())
	var stream := _host_stream()
	service.receive_host(2, _envelope({"op": "inputs", "inputs": service.local.inputs.duplicate(true)}))
	var packet := _envelope({"op": "inputs", "inputs": [{"version": 1, "sequence": 2,
		"op": "discovery", "realm": "meadows", "from": [0,0,0], "to": [0,0,0],
		"travel_valid": false, "new_landmarks": []}]})
	service.body_ready = false
	var original: PackedByteArray = var_to_bytes(stream.cursor)
	service.receive_host(2, packet)
	assert_eq(var_to_bytes(stream.cursor), original)
	assert_eq(stream.error, "", "late realm/body readiness is retryable, not permission to import a pose")
	service.body_ready = true
	service.receive_host(2, packet)
	assert_eq(stream.cursor.sequence, 2)
	assert_eq(stream.error, "")

func test_gate_binds_real_retained_duty_and_reuses_original_checkpoint() -> void:
	var stream := _host_stream()
	var context: Dictionary = event.duties[0].context.duplicate(true)
	context.character_id = before.character_id
	context.expected_revision = 0
	context.in_range = true
	context.retained_event = event.delivery_id
	var rejected := context.duplicate(true)
	rejected.retained_event = "missing"
	assert_eq(service.gate(2, "research_event", {}, rejected).code, "owner_passive_retained_event_required")
	assert_true(stream.checkpoint.is_empty())
	assert_eq(service.gate(2, "research_event", {}, context).code, "owner_passive_checkpoint_pending")
	var original: PackedByteArray = var_to_bytes(stream.checkpoint)
	assert_eq(service.gate(2, "research_event", {}, context).code, "owner_passive_checkpoint_pending")
	assert_eq(var_to_bytes(stream.checkpoint), original, "retry freezes the same original id and duty")
	rejected = context.duplicate(true)
	rejected.species_id = "mudsnout"
	assert_eq(service.gate(2, "research_event", {}, rejected).code, "owner_passive_original_duty_required")
	assert_eq(var_to_bytes(stream.checkpoint), original)

func test_legacy_typed_accepted_row_rebases_full_record_and_duplicate_keeps_progress() -> void:
	const ESSENCE := preload("res://scripts/creatures/essence.gd")
	const TEACHING := preload("res://scripts/creatures/teaching.gd")
	const PROGRESSION := preload("res://scripts/creatures/progression.gd")
	const RECORD := preload("res://scripts/net/character_record_rules.gd")
	var player: RefCounted = GROOM.new()._player()
	var cfg: Dictionary = ESSENCE.config()
	player.inventory.add(str(cfg.tether_candy_item), int(cfg.tether_candy_cost))
	var initial := RECORD.portable_projection(player.save_data())
	var intent := {"spend_id": "typed-rebase-spend", "creature_uid": initial.party[0].uid,
		"expected_level": initial.party[0].level, "payment_item": str(cfg.tether_candy_item), "expected_character_revision": 0}
	var proposal := ESSENCE.stage_core_spend(initial, initial.character_id, 0, intent, cfg,
		PROGRESSION.config(), TEACHING.available_moves, TEACHING.character_loadout_mirror)
	assert_true(proposal.get("ok") == true, str(proposal))
	if proposal.get("ok") != true: return
	proposal.merge({"character_id": initial.character_id, "character_revision": 1, "action": "altar_spend",
		"action_id": intent.spend_id, "intent": intent})
	var row := ESSENCE.next_training_delivery(event.world_id, event.world_namespace, "current-epoch", proposal,
		null, cfg, PROGRESSION.config(), TEACHING.available_moves, TEACHING.character_loadout_mirror)
	assert_false(row.is_empty())
	if row.is_empty(): return
	row.status = "accepted"
	assert_true(preload("res://autoload/world_state.gd").training_row_valid(row, event.world_namespace, event.world_id))
	assert_eq(row.after.size(), 3, "legacy receipt carries its original narrower training projection")
	game.local.data = proposal.state.duplicate(true)
	game.world.reward_deliveries[row.delivery_id] = row.duplicate(true)
	session._character_authority = AUTH.new()
	assert_true(session._character_authority.bind_world(event.world_namespace))
	assert_true(session._character_authority.seed_admitted_character(proposal.state, before.character_id).ok)
	assert_true(session._character_authority.seed_discovered_landmarks(before.character_id, {}))
	var old_stream: String = service.local.id
	service.owner_settled(row)
	assert_ne(service.local.id, old_stream)
	assert_eq(service.local.rebase.receipt, row.receipt)
	var packet: Dictionary = session.messages[-1].duplicate(true)
	assert_eq(packet.op, "rebase")
	session.host = true
	service.receive_host(2, packet)
	assert_true(service.hosts.has(before.character_id))
	if not service.hosts.has(before.character_id): return
	var stream: Dictionary = service.hosts[before.character_id]
	assert_true(PREP.exact(stream.cursor.base, proposal.state), "full authority baseline survives the legacy narrow receipt")
	var applied := REPLAY.apply(stream.cursor, {"version": 1, "sequence": 1, "op": "condition", "delta": 0.1,
		"uids": [proposal.state.party[0].uid]}, {"realm": "meadows", "landmarks": {}, "max_speed": 40.0, "max_elapsed": 2.0})
	assert_true(applied.ok)
	stream.cursor = applied.cursor
	var progress: PackedByteArray = var_to_bytes(stream.cursor)
	service.receive_host(2, packet)
	assert_eq(var_to_bytes(stream.cursor), progress, "duplicate rebase ACK cannot reset newer exact replay input")
	assert_eq(session.messages[-1].op, "rebase_ack")
	session.host = false
	service.receive_owner(session.messages[-1])
	assert_true(service.local.rebase.is_empty())

func test_capture_choice_checkpoint_keeps_original_and_only_saved_ack_reenters_handler() -> void:
	var capture: Dictionary = preload("res://tests/test_owner_passive_preparation.gd").new()._capture_event()
	assert_false(capture.is_empty())
	game.world.reward_deliveries[capture.delivery_id] = capture.duplicate(true)
	var stream := _host_stream()
	var context: Dictionary = capture.duties[0].context.duplicate(true)
	context.merge({"character_id": before.character_id, "expected_revision": 0, "in_range": true,
		"in_combat": false, "foundation_runtime_authorized": true, "retained_event": capture.delivery_id})
	var envelope := {"op": "wild_capture", "session_epoch": "current-epoch", "world_namespace": event.world_namespace,
		"character_id": before.character_id, "station_key": context.source_key, "revision": 0,
		"intent": {"offer_id": context.offer_id, "keep": true, "released_uid": ""}}
	var changed := envelope.duplicate(true)
	changed.intent.released_uid = before.party[0].uid
	assert_false(service.capture_gate(2, changed, context).ok, "free-slot capture cannot silently release an owned companion")
	assert_true(stream.checkpoint.is_empty())
	changed = envelope.duplicate(true)
	changed.session_epoch = "foreign"
	assert_false(service.capture_gate(2, changed, context).ok)
	assert_true(stream.checkpoint.is_empty())
	assert_eq(service.capture_gate(2, envelope, context).code, "owner_passive_checkpoint_pending")
	var original: PackedByteArray = var_to_bytes(stream.checkpoint)
	assert_eq(service.capture_gate(2, envelope, context).code, "owner_passive_checkpoint_pending")
	assert_eq(var_to_bytes(stream.checkpoint), original)
	changed = envelope.duplicate(true)
	changed.intent.keep = false
	assert_eq(service.capture_gate(2, changed, context).code, "owner_passive_original_pending")
	assert_eq(var_to_bytes(stream.checkpoint), original, "decline cannot substitute for the frozen keep choice")
	service.receive_host(2, _envelope({"op": "frozen", "id": stream.checkpoint.id, "sequence": stream.cursor.sequence,
		"prefix_hash": stream.cursor.prefix_hash, "hash": PREP.fingerprint(stream.cursor.state)}))
	assert_true(stream.checkpoint.has("prepared"))
	if not stream.checkpoint.has("prepared"): return
	var saved := _envelope({"op": "saved", "id": stream.checkpoint.id, "hash": stream.checkpoint.prepared.hash, "saved": false})
	service.receive_host(2, saved)
	assert_eq(session._character_authority.revision(before.character_id), 0)
	assert_true(session.capture_calls.is_empty(), "failed BOOL-save cannot reach the capture handler")
	session.capture_service = service
	session.capture_context = context.duplicate(true)
	saved.saved = true
	service.receive_host(2, saved)
	assert_eq(session.capture_calls.size(), 1)
	if session.capture_calls.is_empty(): return
	assert_true(session.capture_calls[0].gate.ok, "only synchronous exact original handler reentry bypasses the checkpoint")
	assert_eq(session.capture_calls[0].revision, 1)
	assert_true(PREP.exact(session.capture_calls[0].envelope.intent, envelope.intent))
	assert_true(PREP.exact(session.capture_calls[0].state, stream.checkpoint.prepared.after))
	assert_true(session._character_authority.creature_training_is_pending(before.character_id), "failed world writer retains exact checkpoint")
	service.receive_host(2, saved)
	assert_eq(session.capture_calls.size(), 2)
	assert_eq(session._character_authority.revision(before.character_id), 1, "saved ACK retry cannot replay passive inputs twice")
	assert_true(PREP.exact(stream.checkpoint.binding.envelope, envelope), "host-derived CAS revision never rewrites original request")
	assert_eq(session._character_authority.state(before.character_id).party.size(), before.party.size(), "failed capture writer grants no creature")

func _request_fixture() -> Dictionary:
	var request := {"op": "station_craft", "session_epoch": "current-epoch", "world_namespace": event.world_namespace,
		"character_id": before.character_id, "station_key": "workbench:meadows:fixture", "revision": 0,
		"intent": {"recipe_id": "fixture-recipe", "craft_id": "f".repeat(32)}}
	var context := {"character_id": before.character_id, "expected_revision": 0, "source_key": request.station_key,
		"in_range": true, "in_combat": false, "foundation_runtime_authorized": true}
	return {"request": request, "context": context}

func test_request_owner_requires_existing_exact_request_and_actual_bool_save() -> void:
	var f := _request_fixture()
	service.record_input(_input())
	var applied := REPLAY.apply(REPLAY.begin(before, {}), service.local.inputs[0],
		{"realm": "meadows", "landmarks": {}, "max_speed": 40.0, "max_elapsed": 2.0})
	assert_true(applied.ok)
	game.local.data = applied.cursor.state.duplicate(true)
	var prepared := PREP.make_action(f.request, f.context, before, 0, "current-epoch", event.world_id,
		applied.cursor, "b".repeat(32))
	assert_false(prepared.is_empty())
	var freeze := _envelope({"op": "freeze", "id": prepared.preparation_id, "source_kind": "foundation_request",
		"request": f.request, "request_hash": prepared.request_hash})
	service.receive_owner(freeze)
	assert_true(service.pending.is_empty(), "host cannot invent an owner request")
	session.action_original = f.request.duplicate(true)
	session.action_original.intent.recipe_id = "different-recipe"
	service.receive_owner(freeze)
	assert_true(service.pending.is_empty())
	session.action_original = f.request.duplicate(true)
	service.receive_owner(freeze)
	assert_true(service.blocked(game.local))
	var original: PackedByteArray = var_to_bytes(game.local.data)
	service.receive_owner(_envelope({"op": "prepared", "id": prepared.preparation_id, "prepared": prepared, "retained": {}}))
	assert_eq(game.save_system.writes, 1)
	assert_eq(service.pending.phase, "save")
	for message: Dictionary in session.messages: assert_ne(message.op, "saved")
	game.save_system.accepted = true
	service._retry_owner()
	assert_eq(service.pending.phase, "saved")
	assert_eq(session.messages[-1].op, "saved")
	assert_eq(session.messages[-1].hash, prepared.hash)
	assert_eq(var_to_bytes(game.local.data), original)

func test_request_host_preserves_original_scope_and_same_revision_on_failed_world_retry() -> void:
	var f := _request_fixture()
	service.record_input(_input())
	var stream := _host_stream()
	service.receive_host(2, _envelope({"op": "inputs", "inputs": service.local.inputs.duplicate(true)}))
	assert_eq(service.action_gate(2, "foundation_request", f.request, f.context).code, "owner_passive_checkpoint_pending")
	var original: PackedByteArray = var_to_bytes(stream.checkpoint)
	assert_eq(service.action_gate(2, "foundation_request", f.request, f.context).code, "owner_passive_checkpoint_pending")
	assert_eq(var_to_bytes(stream.checkpoint), original)
	var changed: Dictionary = f.context.duplicate(true)
	changed.source_key = "another-station"
	assert_eq(service.action_gate(2, "foundation_request", f.request, changed).code, "owner_passive_original_pending")
	assert_eq(var_to_bytes(stream.checkpoint), original)
	service.receive_host(2, _envelope({"op": "frozen", "id": stream.checkpoint.id, "sequence": stream.cursor.sequence,
		"prefix_hash": stream.cursor.prefix_hash, "hash": PREP.fingerprint(stream.cursor.state)}))
	assert_true(stream.checkpoint.has("prepared"))
	if not stream.checkpoint.has("prepared"): return
	session.capture_service = service
	var saved := _envelope({"op": "saved", "id": stream.checkpoint.id, "hash": stream.checkpoint.prepared.hash, "saved": false})
	service.receive_host(2, saved)
	assert_true(session.action_calls.is_empty())
	assert_true(PREP.exact(session._character_authority.state(before.character_id), before))
	saved.saved = true
	for attempt: int in range(2):
		service.receive_host(2, saved)
		assert_eq(session.action_calls.size(), attempt + 1)
		if session.action_calls.is_empty(): return
		assert_true(session.action_calls[-1].gate.ok)
		assert_eq(session.action_calls[-1].revision, 0)
		assert_true(PREP.exact(session.action_calls[-1].request, f.request))
		assert_true(PREP.exact(session.action_calls[-1].state, stream.cursor.state))
		assert_true(session._character_authority.creature_training_is_pending(before.character_id))
	assert_true(PREP.exact(stream.checkpoint.request, f.request))

func test_terminal_request_refusal_rebases_only_the_exact_saved_checkpoint() -> void:
	var f := _request_fixture()
	session.action_original = f.request.duplicate(true)
	service.record_input(_input())
	var stream := _host_stream()
	service.receive_host(2, _envelope({"op": "inputs", "inputs": service.local.inputs.duplicate(true)}))
	game.local.data = stream.cursor.state.duplicate(true)
	var input_ack: Dictionary = session.messages[-1].duplicate(true)
	assert_eq(service.action_gate(2, "foundation_request", f.request, f.context).code, "owner_passive_checkpoint_pending")
	var freeze: Dictionary = session.messages[-1].duplicate(true)
	session.host = false
	service.receive_owner(input_ack)
	service.receive_owner(freeze)
	assert_true(service.blocked(game.local))
	var frozen: Dictionary = session.messages[-1].duplicate(true)
	session.host = true
	service.receive_host(2, frozen)
	var prepared: Dictionary = session.messages[-1].duplicate(true)
	assert_eq(prepared.op, "prepared")
	session.host = false
	game.save_system.accepted = true
	service.receive_owner(prepared)
	assert_eq(game.save_system.writes, 1)
	var saved: Dictionary = session.messages[-1].duplicate(true)
	assert_eq(saved.op, "saved")
	session.host = true
	session.capture_service = service
	session.action_result = {"ok": false, "durable": false, "resolved": true,
		"terminal_refusal": true, "code": "fixture_source_disappeared"}
	service.receive_host(2, saved)
	var completed: Dictionary = session.messages[-1].duplicate(true)
	assert_eq(completed.op, "no_effect")
	assert_false(session._character_authority.creature_training_is_pending(before.character_id))
	assert_eq(session._character_authority.revision(before.character_id), 0)
	session.host = false
	var wrong := completed.duplicate(true)
	wrong.hash = "a".repeat(64)
	service.receive_owner(wrong)
	assert_true(service.blocked(game.local), "unbound refusal cannot release the owner fence")
	assert_true(session.action_terminals.is_empty())
	service.receive_owner(completed)
	assert_false(service.blocked(game.local))
	assert_eq(session.action_terminals.size(), 1)
	assert_true(PREP.exact(session.action_terminals[0].request, f.request))
	assert_eq(session.action_terminals[0].result.code, "fixture_source_disappeared")
	var rebase: Dictionary = session.messages[-1].duplicate(true)
	assert_eq(rebase.op, "rebase")
	session.host = true
	service.receive_host(2, rebase)
	assert_eq(session.messages[-1].op, "rebase_ack")
	assert_true(PREP.exact(service.hosts[before.character_id].cursor.base, game.local.data))
	session.host = false
	service.receive_owner(session.messages[-1])
	assert_true(service.local.rebase.is_empty())

func test_host_accepted_travel_reset_is_exact_single_use_and_grants_no_distance() -> void:
	var stream := _host_stream()
	service.body_position = Vector3(-16, 1.11597406864166, 14)
	service.travel_reset_confirmed(3, "meadows", service.body_position)
	assert_false(stream.has("travel_reset"), "a different peer cannot mint a reset proof")
	service.travel_reset_confirmed(2, "water", service.body_position)
	assert_false(stream.has("travel_reset"), "a different realm cannot mint a reset proof")
	service.travel_reset_confirmed(2, "meadows", service.body_position)
	assert_true(stream.has("travel_reset"))
	# Landing RPC can precede the buffered initial discovery inputs. The proof
	# is scoped to this stream, rather than a stale from-position snapshot.
	service.record_input(_input(0.6))
	service.record_input({"op": "discovery", "realm": "meadows", "from": [0, 0, 0], "to": [0, 0.900942, 0],
		"travel_valid": false, "new_landmarks": []})
	service.receive_host(2, _envelope({"op": "inputs", "inputs": service.local.inputs.duplicate(true)}))
	assert_true(stream.cursor.travel_valid)
	assert_true(stream.has("travel_reset"))
	var previous_distance: float = stream.cursor.state.party[0].distance_m_together
	service.record_input(_input(0.504022))
	var target := [service.body_position.x, service.body_position.y, service.body_position.z]
	service.record_input({"op": "discovery", "realm": "meadows", "from": [0, 0.900942, 0], "to": target,
		"travel_valid": false, "new_landmarks": []})
	var reset: Dictionary = service.local.inputs[-1]
	var context: Dictionary = service._context(2, stream)
	var wrong: Dictionary = reset.duplicate(true)
	wrong.to = [-15, service.body_position.y, 14]
	assert_false(service._reset_matches(2, stream, wrong, context), "owner cannot replace the accepted endpoint")
	wrong = reset.duplicate(true)
	wrong.travel_valid = true
	assert_false(service._reset_matches(2, stream, wrong, context), "ordinary walking keeps its speed and distance rules")
	var packet := _envelope({"op": "inputs", "inputs": service.local.inputs.slice(2).duplicate(true)})
	service.receive_host(2, packet)
	assert_eq(stream.error, "")
	assert_false(stream.has("travel_reset"))
	assert_eq(stream.cursor.state.party[0].distance_m_together, previous_distance)
	var cursor_bytes := var_to_bytes(stream.cursor)
	service.receive_host(2, packet)
	assert_eq(var_to_bytes(stream.cursor), cursor_bytes, "duplicate prefix grants no second credit")
	service.body_position = Vector3.ZERO
	service.record_input(_input(0.6))
	service.record_input({"op": "discovery", "realm": "meadows", "from": target, "to": [0, 0, 0],
		"travel_valid": false, "new_landmarks": []})
	service.receive_host(2, _envelope({"op": "inputs", "inputs": service.local.inputs.slice(4).duplicate(true)}))
	assert_eq(stream.error, "travel_baseline_mismatch", "live endpoint alone never grants another false reset")
