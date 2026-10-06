extends "res://tests/test_case.gd"

## Service controls with explicit transport/writer doubles. No actual network,
## durable write, input route, or F48 acceptance is claimed by these unit tests.
const SYNC := preload("res://scripts/net/owner_passive_sync.gd")
const REPLAY := preload("res://scripts/net/owner_passive_replay.gd")
const PREP := preload("res://scripts/net/owner_passive_preparation.gd")
const AUTH := preload("res://scripts/net/character_authority.gd")
const SOURCE := preload("res://tests/test_research_passive_preparation.gd")
const GROOM := preload("res://tests/test_den_groom_saved_transaction.gd")
const VITALS := preload("res://scripts/net/actor_vitals_delivery.gd")

class Player extends RefCounted:
	var character_id := ""
	var data: Dictionary
	func save_data() -> Dictionary: return data.duplicate(true)

class World extends RefCounted:
	var world_id := ""
	var reward_delivery_namespace := ""
	var reward_deliveries := {}
	var flags: RefCounted

class Flags extends RefCounted:
	func all_set() -> Array: return []

class Writer extends RefCounted:
	var accepted := false
	var writes := 0
	func finish_fallback() -> void: pass
	func fallback_busy() -> bool: return false
	func save_character_prepared(_game: Node, _character: String) -> bool:
		writes += 1
		return accepted

class PartyMember extends RefCounted:
	var uid := ""

class PartyFixture extends RefCounted:
	var list: Array = []
	func members() -> Array: return list

class GameFixture extends Node:
	var party: RefCounted = PartyFixture.new()
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
	var last_rejoin_admission: Dictionary = {}

	var owner_peer := 2
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
	var epoch := "current-epoch"
	var vitals_original: Dictionary = {}
	var vitals_scope: Dictionary = {}
	func _game() -> Node: return game
	func _groom_service() -> RefCounted: return maps
	func _altar_current_epoch() -> String: return epoch
	func _owner_passive_actor_vitals_scope(row: Dictionary) -> Dictionary:
		# Disclosed Session source boundary: only the retained canonical host
		# row can authorize recording. Real Session source checks run separately.
		if vitals_original.is_empty() or not PREP.exact(row,vitals_original) \
			or not PREP.exact(game.world.reward_deliveries.get(row.get("delivery_id")),vitals_original): return {}
		return vitals_scope.duplicate(true)
	func _foundation_flags(_peer: int) -> Dictionary: return {}
	func is_host() -> bool: return host
	func local_peer_id() -> int: return 1 if host else 2
	func snapshot_ready() -> bool: return true
	func _authority_character(peer: int) -> String: return game.local.character_id if peer == owner_peer else "host"
	func _owner_passive_send_host(packet: Dictionary) -> void: messages.append(packet.duplicate(true))
	func _owner_passive_send_peer(_peer: int, packet: Dictionary) -> void: messages.append(packet.duplicate(true))
	func _owner_passive_request_matches(kind: String, request: Dictionary) -> bool:
		return kind in ["foundation_request", "portal_arrival"] and PREP.exact(action_original, request)
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
	var body_realm := "meadows"
	# Disclosed host-body fixture used by reset endpoint confirmation.
	var body_position := Vector3.ZERO
	func _context(_peer: int, _stream: Dictionary) -> Dictionary:
		var result := {"realm": body_realm, "landmarks": {}, "max_speed": 40.0, "max_elapsed": 100.0}
		if body_ready:
			result.initial_position = body_position
			result.initial_max_distance = 80.0
		return result

var session: Session
var service: Service
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
	game.world.flags = Flags.new()
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

func _original_vitals() -> Dictionary:
	# Real independent LedgerRpc identities, canonical typed row and actual
	# WorldLedger install. No transport, owner BOOL or combat source is claimed.
	var host_writer := preload("res://scripts/net/ledger_rpc.gd").new()
	var guest_writer := preload("res://scripts/net/ledger_rpc.gd").new()
	var journal_epoch: String = host_writer.get("_actor_vitals_session_id")
	var guest_epoch: String = guest_writer.get("_actor_vitals_session_id")
	host_writer.free()
	guest_writer.free()
	assert_ne(journal_epoch,session._altar_current_epoch())
	assert_ne(journal_epoch,guest_epoch)
	game.world=SOURCE.DATA.new()._world()
	var card: Dictionary = before.party[0]
	var receipt := {"receipt_id":"typed-original-host-hit","encounter_id":"typed-original-encounter",
		"creature_uid":card.uid,"body_generation":7,"vitals_revision":1}
	var row := VITALS.next_record(game.world.world_id,game.world.reward_delivery_namespace,journal_epoch,
		before.character_id,card.uid,float(card.max_hp),float(card.hp),bool(card.fainted),
		maxf(0.0,float(card.hp)-1.0),false,1,receipt,null)
	assert_false(row.is_empty())
	var ledger := preload("res://scripts/net/world_ledger.gd").new(game.world)
	assert_true(ledger.commit_actor_vitals_delivery(row,2).get("ok") == true)
	assert_true(PREP.exact(game.world.reward_deliveries.get(row.delivery_id),row))
	session.vitals_original=row.duplicate(true)
	session.vitals_scope=service._scope()
	session.vitals_scope.journal_session_id=journal_epoch
	return {"row":row,"host_epoch":journal_epoch,"guest_epoch":guest_epoch}

func test_typed_vitals_records_host_journal_epoch_independently_of_transport_and_guest_writer() -> void:
	var source := _original_vitals()
	var row: Dictionary = source.row
	var original := var_to_bytes(row)
	var stream_id: String = service.local.id
	assert_true(service.record_vitals(row,false),"current transport admits the independently identified original host journal")
	assert_true(service.record_vitals(row,true),"saved binding records the same original journal without epoch replacement")
	assert_eq(service.local.inputs.size(),2)
	assert_eq(service.local.inputs[0].op,"actor_vitals_applied")
	assert_eq(service.local.inputs[1].op,"actor_vitals_saved")
	assert_eq(service.local.inputs[1].sequence,2)
	assert_eq(service.local.inputs[0].receipt_hash,preload("res://scripts/net/research_passive_preparation.gd").fingerprint(row.receipt))
	assert_true(service.record_vitals(row,true),"exact retry is idempotent")
	assert_eq(service.local.inputs.size(),2)
	assert_eq(service.local.id,stream_id,"typed recording preserves the existing care stream")
	assert_eq(var_to_bytes(row),original)
	assert_eq(row.session_id,source.host_epoch)
	assert_ne(row.session_id,source.guest_epoch,"guest's private writer identity is never substituted")

func test_typed_vitals_requires_current_transport_scope_and_exact_original_host_journal() -> void:
	var source := _original_vitals()
	var row: Dictionary = source.row
	var prefix: String = service.local.prefix_hash
	var original := var_to_bytes(row)
	session.epoch=source.guest_epoch
	assert_false(service.record_vitals(row,false),"retained source cannot cross into another transport scope")
	session.epoch="current-epoch"
	var forged: Dictionary = row.duplicate(true)
	forged.session_id=source.guest_epoch
	game.world.reward_deliveries[row.delivery_id]=forged.duplicate(true)
	assert_true(VITALS.valid(forged,before.character_id,game.world.reward_delivery_namespace))
	assert_false(service.record_vitals(forged,false),"even a locally installed schema-valid row cannot replace the retained host journal")
	game.world.reward_deliveries[row.delivery_id]=row.duplicate(true)
	forged=row.duplicate(true)
	forged.receipt.body_generation += 1
	game.world.reward_deliveries[row.delivery_id]=forged.duplicate(true)
	assert_false(service.record_vitals(forged,false),"different body generation is a different original")
	game.world.reward_deliveries[row.delivery_id]=row.duplicate(true)
	session.vitals_scope.journal_session_id=source.guest_epoch
	assert_false(service.record_vitals(row,false),"journal scope must agree with the exact source row")
	session.vitals_scope.journal_session_id=source.host_epoch
	for field: String in ["character_id","world_id","world_namespace","session_epoch"]:
		var expected: String = session.vitals_scope[field]
		session.vitals_scope[field]="foreign"
		assert_false(service.record_vitals(row,false),"source bridge must bind "+field)
		session.vitals_scope[field]=expected
	session.vitals_scope.extra=true
	assert_false(service.record_vitals(row,false),"unexpected source shape fails closed")
	session.vitals_scope.erase("extra")
	var retained: Dictionary = session.vitals_original.duplicate(true)
	session.vitals_original={}
	assert_false(service.record_vitals(row,false),"absence of authenticated current host source never records")
	session.vitals_original=retained
	assert_eq(service.local.inputs.size(),0)
	assert_eq(service.local.prefix_hash,prefix,"all refusals preserve the original input chain")
	assert_eq(var_to_bytes(row),original)
	assert_true(service.record_vitals(row,false),"restoring only the original source/scope permits the untouched row")

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

func test_owner_sends_each_input_once_and_the_window_again_only_when_acks_stall() -> void:
	# F01#6b: a whole unacknowledged window every flush cost the host ~126 ms per
	# packet. Stop-and-wait: one contiguous window, nothing until it is acked.
	service.record_input(_input(0.1))
	service.record_input(_input(0.2))
	session.messages.clear()
	service._flush()
	assert_eq(session.messages.size(), 1)
	assert_eq((session.messages[0].inputs as Array).map(func(i: Dictionary) -> int: return int(i.sequence)), [1, 2])
	service.record_input(_input(0.3))
	service._flush()
	assert_eq(session.messages.size(), 1, "nothing more while that window is in flight")
	service.receive_owner(_envelope({"op": "inputs_ack", "sequence": 2}))
	service._flush()
	assert_eq((session.messages[1].inputs as Array).map(func(i: Dictionary) -> int: return int(i.sequence)), [3],
		"after the ACK only what follows it, contiguous with the host's cursor")
	service._flush()
	assert_eq(session.messages.size(), 2)
	service.local.ack_progress_ms = Time.get_ticks_msec() - int(service.RESEND_STALL_S * 1000.0) - 1
	service._flush()
	assert_eq((session.messages[2].inputs as Array).map(func(i: Dictionary) -> int: return int(i.sequence)), [3],
		"a stall resends the unacknowledged window from its first input (the host may have waited)")
	service._flush()
	assert_eq(session.messages.size(), 3, "and only once per stall")

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

func test_gate_binds_a_remote_boss_relic_duty_with_its_world_namespace() -> void:
	# F19 world-scoped drops: the host's retry adds the settlement flags and the
	# current world namespace to a retained boss duty before it stages. A remote
	# owner's gate must expect exactly those fields, or no guest's relic or
	# portal key is ever delivered and its later duties starve behind it.
	var boss_context := {"source_key": "boss:warden_aldis", "realm": "meadows",
		"validated_host_outcome": "win", "encounter_id": "encounter-boss", "participants": [before.character_id]}
	var intent := {"trainer_id": "warden_aldis", "biome": "meadows", "encounter_id": "encounter-boss"}
	var boss := SOURCE.EVENT.make(SOURCE.DATA.new()._world(), "original-epoch", "boss:warden_aldis:encounter-boss",
		[{"character_id": before.character_id, "action": "boss_relic", "intent": intent, "context": boss_context}])
	assert_false(boss.is_empty())
	game.world.reward_deliveries[boss.delivery_id] = boss.duplicate(true)
	var stream := _host_stream()
	var context := boss_context.duplicate(true)
	context.boss_settlement_world_flags = []
	context.world_namespace = game.world.reward_delivery_namespace
	context.character_id = before.character_id
	context.expected_revision = 0
	context.in_range = true
	context.retained_event = boss.delivery_id
	context.in_combat = false
	context.foundation_runtime_authorized = true
	assert_eq(service.gate(2, "boss_relic", intent, context).code, "owner_passive_checkpoint_pending",
		"the retry's own context binds the retained boss duty")
	assert_false(stream.checkpoint.is_empty())
	var other_world := context.duplicate(true)
	other_world.world_namespace = "another-world"
	stream.checkpoint = {}
	assert_eq(service.gate(2, "boss_relic", intent, other_world).code, "owner_passive_original_duty_required",
		"a different world's namespace never binds")


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

func _portal_request() -> Dictionary:
	var envelope := {"request_id": "current-epoch:actual-request", "session_epoch": "current-epoch",
		"character_id": before.character_id, "world_instance_id": event.world_namespace,
		"payload": {"kind": "portal_enter", "arch_id": "tidewake"}}
	var permit := {"peer_id": 2, "character_id": before.character_id, "world_instance_id": event.world_namespace,
		"request_id": "consumed-permit-distinct-from-envelope", "origin_realm": "meadows", "realm": "water", "entry_id": "hall_home"}
	return PREP.portal_request(envelope, permit)

func _portal_frozen(request: Dictionary) -> Dictionary:
	service.record_input(_input(0.6))
	var stream := _host_stream()
	service.receive_host(2, _envelope({"op": "inputs", "inputs": service.local.inputs.duplicate(true)}))
	assert_eq(service.portal_begin(2, request).code, "owner_passive_checkpoint_pending")
	service.receive_host(2, _envelope({"op": "frozen", "id": stream.checkpoint.id,
		"sequence": stream.cursor.sequence, "prefix_hash": stream.cursor.prefix_hash, "hash": PREP.fingerprint(stream.cursor.state)}))
	assert_true(stream.checkpoint.has("prepared"))
	session.capture_service = service
	return stream

func test_portal_origin_checkpoint_reserves_without_promoting_until_actual_ground() -> void:
	var request := _portal_request()
	var stream := _portal_frozen(request)
	if not stream.checkpoint.has("prepared"): return
	assert_false(service.portal_departure_authorized(2, request))
	assert_true(session._character_authority.creature_training_is_pending(before.character_id), "real exclusion held before origin BOOL ACK")
	assert_true(PREP.exact(session._character_authority.state(before.character_id), before))
	var saved := _envelope({"op": "saved", "id": stream.checkpoint.id, "hash": stream.checkpoint.prepared.hash, "saved": false})
	service.receive_host(2, saved)
	assert_false(service.portal_departure_authorized(2, request))
	saved.saved = true
	for attempt: int in range(2):
		service.receive_host(2, saved)
		assert_eq(session.messages[-1].op, "portal_travel")
		assert_true(PREP.exact(session.messages[-1].request, request))
		assert_true(session.action_calls.is_empty(), "duplicate pretravel ACK never stages arrival")
		assert_true(PREP.exact(session._character_authority.state(before.character_id), before), "reservation stays uncommitted while travelling")
	assert_true(service.portal_departure_authorized(2, request))
	var changed: Dictionary = request.duplicate(true)
	changed.permit.entry_id = "substituted-entry"
	assert_false(service.portal_departure_authorized(2, changed))
	assert_eq(service.portal_grounded(2, changed).code, "owner_passive_arrival_pending")
	for attempt: int in range(2):
		var result: Dictionary = service.portal_grounded(2, request)
		assert_eq(result.code, "fixture_world_write_failed")
		assert_eq(session.action_calls.size(), attempt + 1)
		assert_true(session.action_calls[-1].gate.ok)
		assert_true(PREP.exact(session.action_calls[-1].state, stream.cursor.state))
		assert_true(PREP.exact(session.action_calls[-1].request, request))
		assert_eq(session._character_authority.revision(before.character_id), 0)
		assert_true(session._character_authority.creature_training_is_pending(before.character_id))

func test_cloud_portal_navigation_bind_rebases_only_host_proved_discoveries_before_next_portal() -> void:
	var request := _portal_request()
	request.envelope.payload.arch_id = "cloudreach"
	request.permit.realm = "cloudreach"
	request.permit.entry_id = "cloudreach_arrival_from_meadows"
	var stream := _portal_frozen(request)
	var original_prepared := var_to_bytes(stream.checkpoint.prepared)
	var old_stream: String = stream.id
	service.receive_host(2, _envelope({"op": "saved", "id": stream.checkpoint.id,
		"hash": stream.checkpoint.prepared.hash, "saved": true}))
	assert_false(stream.checkpoint.has("arrival_discoveries"), "origin BOOL cannot prove destination navigation")
	service.body_realm = "cloudreach"
	service.body_position = Vector3(0, 105.03, -260)
	assert_true(SYNC._cloud_initial_navigation_bound(request, stream.cursor.state, service.body_position, stream.cursor.discovered))
	var other_entry: Dictionary = request.duplicate(true)
	other_entry.permit.entry_id = "cloudreach_summit_bivouac"
	assert_false(SYNC._cloud_initial_navigation_bound(other_entry, stream.cursor.state, service.body_position, stream.cursor.discovered))
	var returning: Dictionary = stream.cursor.state.duplicate(true)
	returning.redesign_character.last_waystones.cloudreach = "cloudreach_galefoot_waycamp"
	assert_false(SYNC._cloud_initial_navigation_bound(request, returning, service.body_position, stream.cursor.discovered))
	assert_false(SYNC._cloud_initial_navigation_bound(request, stream.cursor.state, Vector3(0, 1000, 5000), stream.cursor.discovered))
	assert_false(SYNC._cloud_initial_navigation_bound(request, stream.cursor.state, service.body_position,
		{"cloudreach": ["realm_gate_crag"]}), "prior Cloud visit is not a first-entry navigation proof")
	session.action_result = {"ok": true, "durable": true, "receipt": "fixture-accepted-portal-receipt"}
	service.portal_grounded(2, request)
	assert_true(stream.checkpoint.has("arrival_discoveries"))
	if not stream.checkpoint.has("arrival_discoveries"): return
	var discoveries: Dictionary = stream.checkpoint.arrival_discoveries.duplicate(true)
	assert_eq(discoveries.cloudreach, ["realm_gate_crag"], "production navigation reveals the arrival region while ticks are frozen")
	assert_eq(var_to_bytes(stream.checkpoint.prepared), original_prepared, "origin preparation stays immutable")
	assert_true(PREP.exact(stream.cursor.state, session._character_authority.state(before.character_id)), "navigation adds no passive credit")
	# Disclosed accepted journal/owner doubles: this fixture has no production
	# writer. Exercise the original accepted-row rebase with actual map logic.
	var row := {"kind": "creature_training", "version": 2, "action": "portal_arrival", "status": "accepted", "receipt": session.action_result.receipt,
		"delivery_id": "fixture-cloud-portal-delivery", "character_id": before.character_id,
		"intent": {"permit_id": request.permit.request_id, "realm": request.permit.realm, "entry_id": request.permit.entry_id},
		"after": session._character_authority.state(before.character_id)}
	game.world.reward_deliveries[row.delivery_id] = row.duplicate(true)
	game.local.data = row.after.duplicate(true)
	# Review nit: the owner's map runs ahead of the proof (an extra region
	# reveal), so only adopting the host's proof can produce the matching hash.
	session.maps.value = discoveries.duplicate(true)
	session.maps.value.cloudreach.append("three_bells_bridge")
	var journaled: Array = session.messages.filter(func(m: Dictionary) -> bool: return m.get("op") == "journaled")
	assert_false(journaled.is_empty(), "the host journals the grounded arrival to its owner")
	if not journaled.is_empty():
		assert_eq(journaled[-1].get("arrival_discoveries"), discoveries, "carrying the host's own proven navigation reveal")
	session.host = false
	service.receive_owner(_envelope({"op": "inputs_ack", "sequence": stream.cursor.sequence}))
	if not journaled.is_empty(): service.receive_owner(journaled[-1].duplicate(true))
	service.owner_settled(row)
	var packet: Dictionary = session.messages[-1].duplicate(true)
	assert_eq(packet.op, "rebase")
	session.host = true
	var forged: Dictionary = packet.duplicate(true)
	var extra: Dictionary = discoveries.duplicate(true)
	extra.cloudreach.append("three_bells_bridge")
	forged.discoveries_hash = PREP.fingerprint({"discovered": extra})
	service.receive_host(2, forged)
	assert_eq(service.hosts[before.character_id].id, old_stream, "no owner-supplied extra landmark")
	extra = discoveries.duplicate(true)
	extra.meadows = ["village"]
	forged.discoveries_hash = PREP.fingerprint({"discovered": extra})
	service.receive_host(2, forged)
	assert_eq(service.hosts[before.character_id].id, old_stream, "proof cannot change another realm")
	forged = packet.duplicate(true)
	forged.old_prefix_hash = "0".repeat(64)
	service.receive_host(2, forged)
	assert_eq(service.hosts[before.character_id].id, old_stream, "original exact input prefix required")
	game.world.reward_deliveries[row.delivery_id].intent.permit_id = "another-consumed-permit"
	service.receive_host(2, packet)
	assert_eq(service.hosts[before.character_id].id, old_stream, "another row cannot use this proof")
	game.world.reward_deliveries[row.delivery_id] = row.duplicate(true)
	game.world.reward_deliveries[row.delivery_id].receipt = "another-arrival-receipt"
	forged = packet.duplicate(true)
	forged.receipt = "another-arrival-receipt"
	service.receive_host(2, forged)
	assert_eq(service.hosts[before.character_id].id, old_stream, "matching intent still requires original committed receipt")
	game.world.reward_deliveries[row.delivery_id] = row.duplicate(true)
	stream.checkpoint.grounded = false
	service.receive_host(2, packet)
	assert_eq(service.hosts[before.character_id].id, old_stream, "ungrounded origin cannot grant discoveries")
	stream.checkpoint.grounded = true
	service.receive_host(3, packet)
	assert_eq(service.hosts[before.character_id].id, old_stream, "actual admitted owner required")
	forged = packet.duplicate(true)
	forged.session_epoch = "old-epoch"
	service.receive_host(2, forged)
	assert_eq(service.hosts[before.character_id].id, old_stream)
	service.receive_host(2, packet)
	assert_eq(session.messages[-1].op, "rebase_ack")
	assert_eq(service.hosts[before.character_id].id, packet.stream_id)
	assert_true(PREP.exact(service.hosts[before.character_id].cursor.discovered, discoveries))
	var rebased := var_to_bytes(service.hosts[before.character_id].cursor)
	service.receive_host(2, packet)
	assert_eq(var_to_bytes(service.hosts[before.character_id].cursor), rebased, "duplicate completion cannot restart cursor")
	var next := _portal_request()
	next.envelope.request_id += ":return"
	next.envelope.payload = {"kind": "home_key_finish", "use_id": "actual-home-key-raise"}
	next.permit.origin_realm = "cloudreach"
	next.permit.realm = "meadows"
	next.permit.request_id += ":return"
	assert_eq(service.portal_begin(2, next).code, "owner_passive_checkpoint_pending", "second portal uses exact new baseline")

func test_portal_owner_freeze_blocks_new_inputs_and_pose_save_requires_exact_saved_token() -> void:
	var request := _portal_request()
	var stream := _portal_frozen(request)
	if not stream.checkpoint.has("prepared"): return
	var prepared: Dictionary = stream.checkpoint.prepared
	session.host = false
	session.action_original = request
	game.local.data = prepared.after.duplicate(true)
	service.receive_owner(_envelope({"op": "freeze", "id": prepared.preparation_id, "source_kind": "portal_arrival",
		"request": request, "request_hash": prepared.request_hash}))
	var sequence: int = service.local.sequence
	service.record_input(_input(0.5))
	assert_eq(service.local.sequence, sequence, "no care/discovery input crosses the frozen origin prefix")
	assert_true(service.blocked(game.local))
	service.receive_owner(_envelope({"op": "prepared", "id": prepared.preparation_id, "prepared": prepared, "retained": {}}))
	assert_eq(service.pending.phase, "save", "failed BOOL cannot authorize departure")
	game.save_system.accepted = true
	service._retry_owner()
	assert_eq(service.pending.phase, "saved")
	var composition := Node.new()
	composition.name = "FoundationComposition"
	session.add_child(composition)
	var arrival := Node.new()
	arrival.name = "PortalArrival"
	composition.add_child(arrival)
	var other := Node.new()
	assert_false(service.portal_pose_save(other, request))
	other.free()
	game.local.data.saved_player_pose = {"position": [1.0, 2.0, 3.0], "realm": "water"}
	assert_true(service.portal_pose_save(arrival, request), "real pose is outside the exact portable projection")
	assert_false(service.snapshot_allowed(game.local, game.local.data), "save privilege ends synchronously")
	game.local.data.party[0].nourishment -= 0.1
	assert_false(service.portal_pose_save(arrival, request), "care cannot change under the pose-save bracket")
	assert_true(service.blocked(game.local), "pose BOOL alone never releases the journal fence")

func test_portal_refusal_preserves_saved_care_and_immutable_journal() -> void:
	var request := _portal_request()
	var stream := _portal_frozen(request)
	if not stream.checkpoint.has("prepared"): return
	var saved := _envelope({"op": "saved", "id": stream.checkpoint.id, "hash": stream.checkpoint.prepared.hash, "saved": true})
	service.receive_host(2, saved)
	var row := {"action": "portal_arrival", "intent": {"permit_id": request.permit.request_id}, "status": "pending"}
	var id: String = preload("res://scripts/creatures/essence.gd").training_delivery_id(event.world_namespace, before.character_id)
	game.world.reward_deliveries[id] = row.duplicate(true)
	var original := var_to_bytes(game.world.reward_deliveries)
	assert_false(service.portal_refused(2, request, "support changed"), "an existing journal remains its only recovery source")
	assert_eq(var_to_bytes(game.world.reward_deliveries), original)
	game.world.reward_deliveries.erase(id) # Disclosed fixture removes its synthetic row, not production recovery.
	assert_true(service.portal_refused(2, request, "support changed"))
	assert_true(session.action_calls.is_empty(), "no receipt is staged for failed physical arrival")
	assert_true(PREP.exact(session._character_authority.state(before.character_id), stream.cursor.state), "already BOOL-saved care never rolls back")
	assert_false(session._character_authority.creature_training_is_pending(before.character_id))
	assert_eq(session.messages[-1].op, "no_effect")
	assert_true(stream.checkpoint.no_effect)
	assert_false(service.portal_departure_authorized(2, request))

func test_portal_codec_binds_consumed_permit_without_faking_grounded_departure() -> void:
	var request := _portal_request()
	var stream := _portal_frozen(request)
	if not stream.checkpoint.has("prepared"): return
	var prepared: Dictionary = stream.checkpoint.prepared
	assert_true(PREP.valid_action_host(prepared, stream.cursor))
	assert_false(prepared.host_context.has("grounded_arrival"))
	for field: String in ["realm", "entry_id", "request_id", "origin_realm"]:
		var changed: Dictionary = prepared.duplicate(true)
		changed.request.permit[field] = "changed"
		assert_false(PREP.valid_action(changed), "changed consumed permit must invalidate its original hash")
	var fake_ground: Dictionary = prepared.duplicate(true)
	fake_ground.host_context.grounded_arrival = true
	fake_ground.hash = PREP.preparation_hash(fake_ground)
	assert_false(PREP.valid_action(fake_ground), "departure cannot claim future physics proof")
	var wrong_peer: Dictionary = request.duplicate(true)
	wrong_peer.permit.peer_id = 3
	assert_eq(service.portal_begin(2, wrong_peer).code, "owner_passive_request_scope_changed")

func test_portal_known_origin_save_disconnect_preserves_rejoin_baseline_without_arrival() -> void:
	var request := _portal_request()
	var stream := _portal_frozen(request)
	if not stream.checkpoint.has("prepared"): return
	var after: Dictionary = stream.cursor.state.duplicate(true)
	service.receive_host(2, _envelope({"op": "saved", "id": stream.checkpoint.id,
		"hash": stream.checkpoint.prepared.hash, "saved": true}))
	service.portal_departed(2)
	assert_true(PREP.exact(session._character_authority.state(before.character_id), after))
	assert_false(session._character_authority.creature_training_is_pending(before.character_id))
	assert_true(session.action_calls.is_empty())
	assert_false(service.hosts.has(before.character_id))
	assert_true(service._add_host(2, before.character_id, "d".repeat(32), after, {}))
	assert_true(PREP.exact(service.hosts[before.character_id].cursor.base, after))

func test_portal_refusal_owner_fence_releases_only_after_exact_no_effect_rebase() -> void:
	var request := _portal_request()
	var stream := _portal_frozen(request)
	if not stream.checkpoint.has("prepared"): return
	var prepared: Dictionary = stream.checkpoint.prepared
	game.local.data = prepared.after.duplicate(true)
	session.action_original = request.duplicate(true)
	session.host = false
	service.receive_owner(_envelope({"op": "inputs_ack", "sequence": prepared.final_sequence}))
	service.receive_owner(_envelope({"op": "freeze", "id": prepared.preparation_id, "source_kind": "portal_arrival",
		"request": request, "request_hash": prepared.request_hash}))
	game.save_system.accepted = true
	service.receive_owner(_envelope({"op": "prepared", "id": prepared.preparation_id, "prepared": prepared, "retained": {}}))
	var saved: Dictionary = session.messages[-1].duplicate(true)
	session.host = true
	service.receive_host(2, saved)
	assert_true(service.portal_refused(2, request, "real support refused"))
	var completion: Dictionary = session.messages[-1].duplicate(true)
	session.host = false
	assert_true(service.blocked(game.local))
	var wrong: Dictionary = completion.duplicate(true)
	wrong.hash = "0".repeat(64)
	service.receive_owner(wrong)
	assert_true(service.blocked(game.local))
	service.receive_owner(completion)
	assert_false(service.blocked(game.local))
	assert_true(PREP.exact(game.local.data, prepared.after))
	assert_eq(session.action_terminals.size(), 1)
	assert_eq(session.action_terminals[0].kind, "portal_arrival")
	var rebase: Dictionary = session.messages[-1].duplicate(true)
	assert_eq(rebase.op, "rebase")
	session.host = true
	service.receive_host(2, rebase)
	assert_eq(session.messages[-1].op, "rebase_ack")
	assert_true(PREP.exact(service.hosts[before.character_id].cursor.base, prepared.after))

func test_portal_lost_origin_ack_rejoin_requires_fresh_bool_and_replays_new_care() -> void:
	var request := _portal_request()
	var original_stream := _portal_frozen(request)
	if not original_stream.checkpoint.has("prepared"): return
	var original: Dictionary = original_stream.checkpoint.prepared.duplicate(true)
	var original_bytes := var_to_bytes(original_stream.checkpoint)
	game.local.data = original.after.duplicate(true) # Disclosed successful origin disk write; its ACK is lost.
	service.portal_departed(2)
	assert_true(service.hosts.has(before.character_id))
	assert_true(session._character_authority.creature_training_is_pending(before.character_id))
	assert_true(PREP.exact(session._character_authority.state(before.character_id), original.before))
	assert_eq(var_to_bytes(original_stream.checkpoint), original_bytes)
	var declaration: Dictionary = service.arm_owner(original.after, original.discoveries)
	session.owner_peer = 3 # Reconnect has a fresh authenticated transport identity.
	service.admitted(3, {"portable_authority": original.after, "discovered_landmarks": original.discoveries,
		"owner_passive_stream": declaration})
	var challenge: Dictionary = session.messages[-1].duplicate(true)
	assert_eq(challenge.op, "portal_recover")
	assert_true(PREP.exact(session._character_authority.state(before.character_id), original.before), "hello is never a BOOL ACK")
	service.record_input(_input(0.4))
	var applied := REPLAY.apply(REPLAY.begin(original.after, original.discoveries), service.local.inputs[0], service._context(3, {}))
	assert_true(applied.ok)
	game.local.data = applied.cursor.state.duplicate(true) # Real owner care during reconnect, modeled by pure replay.
	var start: int = session.messages.size()
	session.host = false
	service.receive_owner(challenge)
	assert_true(service.blocked(game.local))
	var to_host: Array[Dictionary] = session.messages.slice(start).duplicate(true)
	session.host = true
	for packet: Dictionary in to_host: service.receive_host(3, packet)
	var prepared_packet: Dictionary = session.messages[-1].duplicate(true)
	assert_eq(prepared_packet.op, "recovery_prepared")
	assert_true(PREP.valid_recovery(prepared_packet.prepared))
	assert_true(PREP.exact(prepared_packet.prepared.original, original))
	assert_true(PREP.exact(prepared_packet.prepared.after, game.local.data))
	session.host = false
	service.receive_owner(prepared_packet)
	assert_eq(service.pending.phase, "save", "a refused fresh BOOL keeps the original reservation")
	assert_true(PREP.exact(session._character_authority.state(before.character_id), original.before))
	game.save_system.accepted = true
	service._retry_owner()
	var saved: Dictionary = session.messages[-1].duplicate(true)
	assert_eq(saved.op, "saved")
	session.host = true
	var wrong: Dictionary = saved.duplicate(true)
	wrong.hash = original.hash
	service.receive_host(3, wrong)
	service.receive_host(2, saved)
	wrong = saved.duplicate(true)
	wrong.saved = false
	service.receive_host(3, wrong)
	wrong = saved.duplicate(true)
	wrong.stream_id = original_stream.id
	service.receive_host(3, wrong)
	wrong = saved.duplicate(true)
	wrong.session_epoch = "retired-epoch"
	service.receive_host(3, wrong)
	assert_true(PREP.exact(session._character_authority.state(before.character_id), original.before))
	service.receive_host(3, saved)
	assert_true(PREP.exact(session._character_authority.state(before.character_id), game.local.data), "original then fresh replay CAS promote only the BOOL-saved care")
	assert_false(session._character_authority.creature_training_is_pending(before.character_id))
	var recovered: Dictionary = service.hosts[before.character_id]
	assert_true(PREP.exact(recovered.cursor.base, original.after))
	assert_true(PREP.exact(recovered.cursor.state, game.local.data), "new care stays in the authenticated replay")
	assert_eq(recovered.id, declaration.id)
	assert_eq(var_to_bytes(original_stream.checkpoint), original_bytes)
	assert_true(session.action_calls.is_empty(), "departed travel never stages arrival")
	var input_ack: Dictionary = session.messages[-2].duplicate(true)
	var completion: Dictionary = session.messages[-1].duplicate(true)
	service.receive_host(3, saved) # Completion ACK lost: same proof resends without another CAS or trip.
	assert_eq(session.messages[-1].op, "portal_recovered")
	session.host = false
	service.receive_owner(input_ack)
	service.receive_owner(completion)
	assert_false(service.blocked(game.local))
	assert_true(PREP.exact(game.local.data, applied.cursor.state), "no saved state is installed or rolled back")
	var rebase: Dictionary = session.messages[-1].duplicate(true)
	assert_eq(rebase.op, "rebase")
	session.host = true
	service.receive_host(3, rebase)
	assert_eq(session.messages[-1].op, "rebase_ack")
	assert_true(PREP.exact(service.hosts[before.character_id].cursor.base, game.local.data))
	assert_false(service.hosts[before.character_id].cursor.travel_valid, "fresh stream matches Game's travel reset after its mutation fence")

func test_portal_recovery_refuses_changed_hello_and_old_scope_without_discarding_original() -> void:
	var stream := _portal_frozen(_portal_request())
	if not stream.checkpoint.has("prepared"): return
	var original: Dictionary = stream.checkpoint.prepared.duplicate(true)
	service.portal_departed(2)
	var changed: Dictionary = original.after.duplicate(true)
	changed.party[0].nourishment -= 0.1
	var declaration: Dictionary = service.arm_owner(changed, original.discoveries)
	service.admitted(2, {"portable_authority": changed, "discovered_landmarks": original.discoveries,
		"owner_passive_stream": declaration})
	assert_false(stream.has("recovery"), "an arbitrary claimed current record cannot replace retained replay")
	assert_true(session._character_authority.creature_training_is_pending(before.character_id))
	assert_true(PREP.exact(stream.checkpoint.prepared, original))
	assert_false(service.portal_departure_authorized(2, original.request))

func test_portal_unsaved_origin_rejoin_cancels_original_only_after_fresh_bool() -> void:
	var stream := _portal_frozen(_portal_request())
	if not stream.checkpoint.has("prepared"): return
	var original: Dictionary = stream.checkpoint.prepared.duplicate(true)
	service.portal_departed(2)
	var declaration: Dictionary = service.arm_owner(original.before, {})
	game.local.data = original.before.duplicate(true) # Failed origin BOOL restores its existing earlier disk baseline.
	service.admitted(2, {"portable_authority": original.before, "discovered_landmarks": {}, "owner_passive_stream": declaration})
	var challenge: Dictionary = session.messages[-1].duplicate(true)
	session.host = false
	service.receive_owner(challenge)
	var frozen: Dictionary = session.messages[-1].duplicate(true)
	session.host = true
	service.receive_host(2, frozen)
	var prepared: Dictionary = session.messages[-1].duplicate(true)
	assert_eq(prepared.op, "recovery_prepared")
	session.host = false
	game.save_system.accepted = true
	service.receive_owner(prepared)
	var saved: Dictionary = session.messages[-1].duplicate(true)
	session.host = true
	assert_true(session._character_authority.creature_training_is_pending(before.character_id))
	service.receive_host(2, saved)
	assert_false(session._character_authority.creature_training_is_pending(before.character_id))
	assert_true(PREP.exact(session._character_authority.state(before.character_id), original.before), "never promote the unsaved old care candidate")
	assert_true(PREP.exact(service.hosts[before.character_id].cursor.base, original.before))
	assert_true(session.action_calls.is_empty())

func _recovery_saved_packet(peer: int, baseline: Dictionary, discoveries: Dictionary) -> Dictionary:
	var declaration: Dictionary = service.arm_owner(baseline, discoveries)
	session.owner_peer = peer
	session.host = true
	service.admitted(peer, {"portable_authority": baseline, "discovered_landmarks": discoveries,
		"owner_passive_stream": declaration})
	var challenge: Dictionary = session.messages[-1].duplicate(true)
	assert_eq(challenge.op, "portal_recover")
	service.record_input(_input(0.4))
	var applied := REPLAY.apply(REPLAY.begin(baseline, discoveries), service.local.inputs[0], service._context(peer, {}))
	assert_true(applied.ok)
	game.local.data = applied.cursor.state.duplicate(true)
	var start: int = session.messages.size()
	session.host = false
	service.receive_owner(challenge)
	var outgoing: Array[Dictionary] = session.messages.slice(start).duplicate(true)
	session.host = true
	for packet: Dictionary in outgoing: service.receive_host(peer, packet)
	var prepared: Dictionary = session.messages[-1].duplicate(true)
	assert_eq(prepared.op, "recovery_prepared")
	session.host = false
	game.save_system.accepted = true
	service.receive_owner(prepared)
	assert_eq(service.pending.phase, "saved")
	assert_eq(session.messages[-1].op, "saved")
	return session.messages[-1].duplicate(true)

func test_portal_repeated_recovery_bool_ack_loss_keeps_only_exact_latest_candidates() -> void:
	var original_stream := _portal_frozen(_portal_request())
	if not original_stream.checkpoint.has("prepared"): return
	var original: Dictionary = original_stream.checkpoint.prepared.duplicate(true)
	var original_bytes := var_to_bytes(original_stream.checkpoint)
	game.local.data = original.after.duplicate(true)
	service.portal_departed(2)
	for peer: int in [3, 4, 5]:
		var disk_baseline: Dictionary = game.local.data.duplicate(true)
		_recovery_saved_packet(peer, disk_baseline, original.discoveries) # Fresh BOOL succeeds; every ACK is lost.
		session.host = true
		service.portal_departed(peer)
		assert_true(session._character_authority.creature_training_is_pending(before.character_id))
		assert_true(PREP.exact(session._character_authority.state(before.character_id), original.before))
		assert_true(original_stream.recovery_candidates.size() <= 2, "retention is bounded to latest exact before/after")
		assert_eq(var_to_bytes(original_stream.checkpoint), original_bytes, "the consumed original permit/reservation remains immutable")
		assert_false(original_stream.has("recovery"))
		var found := false
		for candidate: Dictionary in original_stream.recovery_candidates:
			if PREP.exact(candidate.prepared.after, game.local.data): found = true
		assert_true(found, "the actual BOOL-saved care candidate remains recoverable")
	var final_baseline: Dictionary = game.local.data.duplicate(true)
	var saved := _recovery_saved_packet(6, final_baseline, original.discoveries)
	session.host = true
	service.receive_host(6, saved)
	assert_true(PREP.exact(session._character_authority.state(before.character_id), game.local.data))
	assert_false(session._character_authority.creature_training_is_pending(before.character_id))
	assert_true(session.action_calls.is_empty(), "no departed trip stages an arrival across any recovery")
	# Host committed the fresh BOOL, but its completion/rebase never reached the
	# owner. This cut must permit ordinary admission from the completed baseline.
	service.portal_departed(6)
	assert_false(service.hosts.has(before.character_id))
	var declaration: Dictionary = service.arm_owner(game.local.data, original.discoveries)
	session.owner_peer = 7
	service.admitted(7, {"portable_authority": game.local.data, "discovered_landmarks": original.discoveries,
		"owner_passive_stream": declaration})
	assert_true(service.hosts.has(before.character_id))
	assert_true(PREP.exact(service.hosts[before.character_id].cursor.base, game.local.data))
	assert_true(service.hosts[before.character_id].checkpoint.is_empty())

func test_host_accepted_travel_reset_is_exact_single_use_and_grants_no_distance() -> void:
	var stream := _host_stream()
	service.body_position = Vector3(-16, 1.11597406864166, 14)
	assert_eq(service._context(2, stream).initial_position, service.body_position, "host geometry uses the configured fixture endpoint")
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


func test_rejoin_with_unreplayed_landmarks_readmits_on_the_hosts_held_set_and_prefixes_match() -> void:
	# Review G1 (render g1-departure-2peer-r6): a guest that discovered a
	# landmark the host never replayed before it left rejoins with a larger set.
	# The host keeps its held set (seed_discovered_landmarks), so admission must
	# readmit on it and the owner adopt it; otherwise both cursors seed their
	# input prefix differently and every later checkpoint ends
	# owner_passive_exact_projection_conflict with identical states.
	var character: String = before.character_id
	var held: Dictionary = session._character_authority.discovered_landmarks(character)
	var owner_seen := {"meadows": ["g1-landmark-the-host-never-replayed"]}
	var hash := preload("res://scripts/net/research_passive_preparation.gd")
	session.host = true
	service.hosts.clear()
	session.messages.clear()
	var declaration := {"id": "0123456789abcdef0123456789abcdef", "baseline_hash": hash.fingerprint(before)}
	service.admitted(2, {"portable_authority": before.duplicate(true), "discovered_landmarks": owner_seen,
		"owner_passive_stream": declaration})
	assert_true(service.hosts.has(character), "the host admits the rejoined stream")
	var readmits := session.messages.filter(func(m: Dictionary) -> bool: return m.get("op") == "readmit")
	assert_eq(readmits.size(), 1, "a landmark mismatch alone forces a readmit")
	if readmits.size() != 1: return
	var readmit: Dictionary = readmits[0]
	assert_eq(readmit.get("discovered"), held, "carrying the host's held landmarks")
	var host_prefix: String = service.hosts[character].cursor.prefix_hash
	assert_eq(host_prefix, REPLAY.begin(before, held).prefix_hash, "the host seeds from its held set")
	# The owner side of the same exchange.
	session.host = false
	session.maps.value = owner_seen.duplicate(true)
	for card: Dictionary in before.party:
		var member := PartyMember.new()
		member.uid = str(card.uid)
		game.party.list.append(member)
	service.arm_owner(before, owner_seen)
	assert_ne(service.local.prefix_hash, host_prefix, "before the readmit the two seeds differ (the G1 failure)")
	service._readmit_owner(readmit)
	assert_eq(service._discoveries(), held, "the owner adopts the host's held landmarks as its replay identity")
	assert_eq(session.maps.value, owner_seen, "while its map keeps every landmark it saw")
	assert_eq(service.local.prefix_hash, host_prefix, "and both input prefixes now start equal")
	assert_eq(session.messages.back().get("op"), "readmitted")


func test_rejoin_with_matching_landmarks_still_admits_directly() -> void:
	var character: String = before.character_id
	var held: Dictionary = session._character_authority.discovered_landmarks(character)
	var hash := preload("res://scripts/net/research_passive_preparation.gd")
	session.host = true
	service.hosts.clear()
	session.messages.clear()
	service.admitted(2, {"portable_authority": before.duplicate(true), "discovered_landmarks": held,
		"owner_passive_stream": {"id": "fedcba9876543210fedcba9876543210", "baseline_hash": hash.fingerprint(before)}})
	assert_true(service.hosts.has(character))
	assert_true(session.messages.filter(func(m: Dictionary) -> bool: return m.get("op") == "readmit").is_empty(),
		"an exact rejoin needs no readmit")


func test_a_behind_rejoin_readmits_to_adopt_and_any_other_difference_is_refused() -> void:
	# Owner ruling (STATE §0): the host world's held record wins inside it. A
	# declaration that differs beyond passive drift (an offline catch) is not
	# refused (that left the guest diverged for the whole session): the owner
	# is sent the held record whole to adopt.
	var character: String = before.character_id
	var held: Dictionary = session._character_authority.discovered_landmarks(character)
	var hash := preload("res://scripts/net/research_passive_preparation.gd")
	var declared: Dictionary = before.duplicate(true)
	var caught: Dictionary = declared.party[0].duplicate(true)
	caught.uid = "creature-%s" % "d1b2c3d4e5f60718293a4b5c6d7e8f90"
	declared.party.append(caught)
	session.host = true
	service.hosts.clear()
	service.refused.clear()
	session.messages.clear()
	# Owner ruling 2026-10-05: a difference left after the hello means the
	# hello found the declaration behind (held_wins); only then adopt.
	session.last_rejoin_admission[character] = "held_wins"
	service.admitted(2, {"portable_authority": declared, "discovered_landmarks": held,
		"owner_passive_stream": {"id": "00112233445566778899aabbccddeeff", "baseline_hash": hash.fingerprint(declared)}})
	assert_true(service.hosts.has(character) and not service.refused.has(character), "the rejoined stream is admitted, not refused")
	var readmits := session.messages.filter(func(m: Dictionary) -> bool: return m.get("op") == "readmit")
	assert_eq(readmits.size(), 1, "one readmit")
	if readmits.size() != 1: return
	assert_eq(readmits[0].get("adopt"), true, "marked adopt: the owner takes the held record whole")
	assert_eq((readmits[0].baseline as Dictionary).party.size(), before.party.size(), "the baseline is the held record, without the offline catch")
	# A declaration that does not match its own stream baseline is still refused.
	service.hosts.clear()
	session.messages.clear()
	service.admitted(2, {"portable_authority": declared, "discovered_landmarks": held,
		"owner_passive_stream": {"id": "ffeeddccbbaa99887766554433221100", "baseline_hash": hash.fingerprint(before)}})
	assert_true(service.refused.has(character), "a malformed declaration is refused")
	# A difference the hello did not find behind (e.g. an open host
	# transaction kept the held record) is refused, never adopted over.
	session.last_rejoin_admission[character] = "host_duties_unsettled"
	service.hosts.clear()
	service.refused.clear()
	session.messages.clear()
	service.admitted(2, {"portable_authority": declared, "discovered_landmarks": held,
		"owner_passive_stream": {"id": "11223344556677889900aabbccddeeff", "baseline_hash": hash.fingerprint(declared)}})
	assert_true(service.refused.has(character), "refused, not adopted")
	assert_true(session.messages.filter(func(m: Dictionary) -> bool: return m.get("op") == "readmit").is_empty(), "no readmit")

func test_a_pending_payout_the_held_record_holds_forces_a_readmit_that_settles_it() -> void:
	# Re-review H1/M1: even an exact rejoin is readmitted while a payout the
	# held record absorbed is still pending, carrying that row to settle; the
	# owner's deliveries wait for admission so the readmit always comes first.
	var character: String = before.character_id
	var held: Dictionary = session._character_authority.discovered_landmarks(character)
	var hash := preload("res://scripts/net/research_passive_preparation.gd")
	var row := preload("res://scripts/net/reward_delivery.gd").make_record(event.world_id, event.world_namespace, "pickup:folded", character, "berries", 2)
	row.status = "pending"
	game.world.reward_deliveries[row.delivery_id] = row
	session._character_authority.call("_absorbed", character)[row.delivery_id] = true
	session._character_authority._records[character].unconfirmed_folds = {row.delivery_id: row.duplicate(true)}
	session.host = true
	service.hosts.clear()
	session.messages.clear()
	service.admitted(2, {"portable_authority": before.duplicate(true), "discovered_landmarks": held,
		"owner_passive_stream": {"id": "0f1e2d3c4b5a69788796a5b4c3d2e1f0", "baseline_hash": hash.fingerprint(before)}})
	var readmits := session.messages.filter(func(m: Dictionary) -> bool: return m.get("op") == "readmit")
	assert_eq(readmits.size(), 1, "an exact rejoin is readmitted while the folded row is pending")
	if readmits.size() != 1: return
	assert_eq(readmits[0].get("adopt"), false, "not an adoption")
	assert_eq((readmits[0].get("folded", []) as Array).map(func(r: Dictionary) -> String: return r.delivery_id), [row.delivery_id],
		"carrying the row to settle")
	# The owner's settlement is saved before "readmitted"; then the host
	# confirms and the row leaves the record.
	service.receive_host(2, _envelope({"op": "readmitted", "baseline_hash": readmits[0].baseline_hash}).merged(
		{"stream_id": service.hosts[character].id}, true))
	assert_true((session._character_authority.call("unconfirmed_folds", character) as Array).is_empty(), "confirmed by the saved readmit")
	session.host = false
	service.arm_owner(before, held)
	assert_false(service.delivery_ready(), "the owner's deliveries wait for this join's admission")
	service.local.hello_pending = false
	assert_true(service.delivery_ready(), "and run once admitted")
	service.local.admission_pending = true
	assert_true(service.delivery_ready(), "a rebase (admission pending again) does not hold them")


func test_an_open_host_duty_at_the_hello_refuses_and_never_adopts() -> void:
	# The hello kept the held record while a host transaction was open: the
	# stream is refused with a reason (as before the ruling), never adopted
	# over and never parked on the stale declaration.
	var character: String = before.character_id
	var held: Dictionary = session._character_authority.discovered_landmarks(character)
	var hash := preload("res://scripts/net/research_passive_preparation.gd")
	var declared: Dictionary = before.duplicate(true)
	var caught: Dictionary = declared.party[0].duplicate(true)
	caught.uid = "creature-%s" % "e1b2c3d4e5f60718293a4b5c6d7e8f90"
	declared.party.append(caught)
	session.host = true
	service.hosts.clear()
	service.refused.clear()
	session.messages.clear()
	session.last_rejoin_admission[character] = "host_duties_unsettled"
	service.admitted(2, {"portable_authority": declared, "discovered_landmarks": held, "personal_flags": {"flags": []},
		"owner_passive_stream": {"id": "aa112233445566778899aabbccddeeff", "baseline_hash": hash.fingerprint(declared)}})
	assert_true(service.refused.has(character) and not service.deferred.has(character), "refused, not parked")
	assert_true(str(service.refused[character].reason).contains("host_duties_unsettled"), "naming why: %s" % str(service.refused[character].reason))
	assert_true(session.messages.filter(func(m: Dictionary) -> bool: return m.get("op") == "readmit").is_empty(), "no adoption")
	assert_eq((session._character_authority.call("state", character) as Dictionary).party.size(), before.party.size(), "the held record is untouched")


func test_a_landmark_revealed_without_an_input_never_changes_the_owner_passive_identity() -> void:
	# G1 follow-up (review-g1-landmarks.md finding 1): a manual landmark
	# (Meadowhart herd) or a story-revealed one (Cloudreach sync_navigation)
	# lands on the owner's map with no discovery input, so the host's replayed
	# set never gains it. The owner's discovery identity (the seed of every
	# rebase and readmit) must stay the replayed set; the map keeps the landmark.
	var start := {"meadows": ["walked-landmark"]}
	session.maps.value = start.duplicate(true)
	service.arm_owner(before, start)
	session.maps.value = {"meadows": ["walked-landmark", "story-revealed-landmark"]}
	assert_eq(service._discoveries(), start, "a landmark with no input stays out of the replay identity")
	service.record_input({"op": "discovery", "realm": "meadows", "from": [0.0, 0.0, 0.0], "to": [1.0, 0.0, 0.0],
		"travel_valid": true, "new_landmarks": ["walked-second"]})
	assert_eq(service._discoveries(), {"meadows": ["walked-landmark", "walked-second"]},
		"a landmark the owner sent in a discovery input joins it, exactly as the host replays it")
	assert_eq(session.maps.value.meadows.size(), 2, "the owner's map is never rewritten by the identity")


func test_cloud_reentry_without_a_host_proof_keeps_the_identity_whatever_the_map_reveals() -> void:
	# Review BLOCK finding 1: a guest that already explored Cloudreach (its map
	# has region reveals the replayed set never gained) portals back in. The host
	# proves no first-entry reveal, so it rebases on its replayed set; the owner
	# must too, never its live map.
	var identity := {"cloudreach": ["realm_gate_crag"]}
	session.host = false
	service.arm_owner(before, identity)
	session.maps.value = {"cloudreach": ["realm_gate_crag", "three_bells_bridge"]}
	var row := {"kind": "creature_training", "version": 2, "action": "portal_arrival", "status": "accepted",
		"receipt": "reentry-receipt", "delivery_id": "fixture-reentry-delivery", "character_id": before.character_id,
		"intent": {"permit_id": "reentry-permit", "realm": "cloudreach", "entry_id": "cloudreach_arrival_from_meadows"},
		"after": session._character_authority.state(before.character_id)}
	game.local.data = row.after.duplicate(true)
	var discoveries := service._discoveries()
	assert_eq(discoveries, identity, "no proof: the map's extra reveal stays out of the identity")
	session.messages.clear()
	service.owner_settled(row)
	var rebases: Array = session.messages.filter(func(m: Dictionary) -> bool: return m.get("op") == "rebase")
	assert_false(rebases.is_empty(), "the arrival settlement rebases")
	if not rebases.is_empty():
		assert_eq(rebases[-1].discoveries_hash, PREP.fingerprint({"discovered": identity}),
			"seeded from the replayed identity, exactly what the host's unproven rebase uses")
