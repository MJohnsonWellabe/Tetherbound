extends "res://tests/test_case.gd"

## Production arrival lifecycle and typed journal validation. Detached session,
## bool writer and contact doubles isolate retries; these tests do not prove
## live physics, realm loading, disk durability or ENet delivery.
const ACTIONS := preload("res://scripts/net/foundation_actions.gd")
const DELIVERY := preload("res://scripts/net/foundation_delivery.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const PLAYER := preload("res://autoload/player_state.gd")
const WORLD := preload("res://autoload/world_state.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")

class ContactArrival extends "res://scripts/net/foundation_portal_arrival.gd":
	var contact_valid := true
	func _grounded_actor(_actor: CharacterBody3D) -> bool: return contact_valid

class BoolWriter extends RefCounted:
	var succeeds := false
	var attempts := 0
	var characters: Array[String] = []
	func fallback_busy() -> bool: return false
	func save_character_prepared(_game: Node, character: String) -> bool:
		attempts += 1
		characters.append(character)
		return succeeds

class DetachedGame extends Node:
	var local: RefCounted
	var world: RefCounted
	var save_system: RefCounted
	var actor: CharacterBody3D
	var current_realm := "meadows"
	var captures := 0
	func find_player() -> Node3D: return actor
	func _capture_player_pose() -> void: captures += 1

class DetachedSession extends Node:
	var game: Node
	var epoch := "arrival-epoch"
	var row: Dictionary = {}
	var durable := true
	var accepted := false
	var journal_calls := 0
	var receipts: Array[String] = []
	var journal_intents: Array[Dictionary] = []
	var notices: Array[Dictionary] = []
	var replies: Array[Dictionary] = []
	func is_host() -> bool: return true
	func is_active() -> bool: return true
	func _game() -> Node: return game
	func _authority_character(_peer: int) -> String: return game.local.character_id
	func _altar_current_epoch() -> String: return epoch
	func portal_owner_save_waiting(producer: Node, envelope: Dictionary, permit: Dictionary) -> void:
		if producer.call("presentation_binding", envelope, permit, true) == true:
			notices.append({"envelope": envelope.duplicate(true), "permit": permit.duplicate(true)})
	func foundation_grounded_arrival(producer: Node, envelope: Dictionary, permit: Dictionary) -> Dictionary:
		journal_calls += 1
		journal_intents.append({"envelope": envelope.duplicate(true), "permit": permit.duplicate(true)})
		if producer.call("arrival_binding", envelope, permit) != true:
			return {"ok": false, "saved": false, "durable": false}
		if not durable: return {"ok": false, "saved": false, "durable": false}
		if not game.world.reward_deliveries.has(row.delivery_id):
			game.world.reward_deliveries[row.delivery_id] = row.duplicate(true)
			receipts.append(str(row.receipt))
		if accepted:
			game.world.reward_deliveries[row.delivery_id].status = "accepted"
		return {"ok": accepted, "saved": accepted, "durable": true}
	func _portal_reply(peer: int, envelope: Dictionary, result: Dictionary) -> void:
		replies.append({"peer": peer, "envelope": envelope.duplicate(true), "result": result.duplicate(true)})

class PresentationSession extends "res://scripts/net/session.gd":
	var detached_game: Node
	func _game() -> Node: return detached_game

class PresentationProducer extends Node:
	var envelope: Dictionary = {}
	var permit: Dictionary = {}
	var seated := true
	func presentation_binding(original: Dictionary, travel: Dictionary, waiting: bool = false) -> bool:
		return original == envelope and travel == permit and (not waiting or seated)

class PresentationKey extends Node:
	var notices: Array[String] = []
	func save_waiting(request: String) -> void: notices.append(request)

func _row(envelope: Dictionary, permit: Dictionary) -> Dictionary:
	var player := PLAYER.new()
	player.configure(preload("res://autoload/item_db.gd").new())
	player.character_id = envelope.character_id
	var before := RECORD.portable_projection(player.save_data())
	var intent := {"permit_id": permit.request_id, "realm": permit.realm, "entry_id": permit.entry_id}
	var context := {"character_id": envelope.character_id, "expected_revision": 0,
		"in_range": true, "in_combat": false, "foundation_runtime_authorized": true,
		"grounded_arrival": true, "source_key": "arrival:" + str(permit.request_id),
		"permit_id": permit.request_id, "realm": permit.realm, "entry_id": permit.entry_id,
		"world_namespace": envelope.world_instance_id}
	var proposal := ACTIONS.stage(before, 0, "portal_arrival", intent, context, RECORD.errors)
	assert_true(proposal.get("ok") == true, "production arrival stage: " + str(proposal))
	if proposal.get("ok") != true: return {}
	proposal.character_revision = 1
	var result := DELIVERY.make_record("arrival-slot", envelope.world_instance_id,
		envelope.session_epoch, proposal, null, RECORD.errors)
	assert_false(result.is_empty(), "production codec must produce the fixture row")
	return result

func _fixture() -> Dictionary:
	var game := DetachedGame.new()
	game.local = PLAYER.new()
	game.local.configure(preload("res://autoload/item_db.gd").new())
	game.local.character_id = "arrival-owner"
	game.world = WORLD.new()
	game.world.world_id = "arrival-slot"
	game.world.reward_delivery_namespace = "arrival-world"
	game.save_system = BoolWriter.new()
	game.actor = CharacterBody3D.new()
	game.add_child(game.actor)
	var session := DetachedSession.new()
	session.game = game
	var envelope := {"request_id": "finish-request", "character_id": "arrival-owner",
		"world_instance_id": "arrival-world", "session_epoch": "arrival-epoch",
		"payload": {"kind": "home_key_finish", "use_id": "approved-raise"}}
	var permit := {"request_id": "consumed-permit", "peer_id": 1,
		"character_id": "arrival-owner", "world_instance_id": "arrival-world",
		"origin_realm": "water", "realm": "meadows", "entry_id": "hall_home"}
	session.row = _row(envelope, permit)
	var arrival := ContactArrival.new()
	# Set up the already consumed/seated boundary. Only ordinary contact is
	# doubled; all ownership, BOOL-save, deadline, row and retry logic is real.
	arrival._pending = {"session": weakref(session), "game": weakref(game), "peer": 1,
		"owner": weakref(game.local), "world": weakref(game.world),
		"envelope": envelope.duplicate(true), "permit": permit.duplicate(true),
		"seated": true, "save_deadline_msec": Time.get_ticks_msec() + 12000}
	return {"game": game, "session": session, "arrival": arrival,
		"envelope": envelope, "permit": permit}

func _dispose(fixture: Dictionary) -> void:
	fixture.arrival.free()
	fixture.session.free()
	fixture.game.free()

func _tick(fixture: Dictionary) -> void:
	fixture.arrival._retry_left = 0.0
	fixture.arrival._process(0.25)

func test_permanent_bool_save_failure_retains_original_and_notifies_once() -> void:
	var f := _fixture()
	f.arrival._pending.seated = false
	f.game.current_realm = "water"
	assert_true(f.arrival.owns_input(), "the exact unseated transition cannot be paused by inventory")
	assert_true(f.arrival.is_open(), "the ordinary story-modal graph holds the solo menu")
	f.arrival._pending.seated = true
	f.game.current_realm = "meadows"
	_tick(f)
	assert_eq(f.session.notices.size(), 0, "no save-wait notice before its seated deadline")
	f.arrival._pending.save_deadline_msec = Time.get_ticks_msec() - 1
	for _attempt: int in range(4): _tick(f)
	assert_eq(f.game.save_system.attempts, 5)
	assert_eq(f.game.captures, 5, "unsaved pose retries remain ordinary bool-save attempts")
	assert_eq(f.game.save_system.characters, ["arrival-owner", "arrival-owner", "arrival-owner", "arrival-owner", "arrival-owner"])
	assert_eq(f.session.notices.size(), 1, "one seated timeout notice despite permanent failure")
	assert_eq(f.session.notices[0], {"envelope": f.envelope, "permit": f.permit})
	assert_eq(f.arrival._pending.envelope, f.envelope)
	assert_eq(f.arrival._pending.permit, f.permit)
	assert_false(f.arrival._pending.get("pose_saved") == true)
	assert_false(f.arrival._pending.get("journal_started") == true)
	assert_eq(f.session.journal_calls, 0)
	assert_eq(f.session.replies.size(), 0, "failed owner save cannot ACK success or erase its original")
	assert_true(f.game.world.reward_deliveries.is_empty())
	assert_true(f.arrival.owns_input(), "a failed BOOL save cannot release arrival input")
	_dispose(f)

func test_durable_original_retries_after_movement_without_second_pose_or_receipt() -> void:
	var f := _fixture()
	f.game.save_system.succeeds = true
	f.arrival._save_arrival()
	assert_true(f.arrival._pending.get("pose_saved") == true)
	assert_true(f.arrival._pending.get("journal_started") == true)
	assert_eq(f.session.replies.size(), 0, "durable pending journal is not an accepted owner ACK")
	assert_true(f.arrival.owns_input(), "the exact durable original still waits for its ACK")
	assert_true(f.arrival._original_arrival_row(f.game.world, f.arrival._pending))
	f.arrival.contact_valid = false
	assert_true(f.arrival.arrival_binding(f.envelope, f.permit), "exact durable row owns the retry after movement")
	f.arrival._save_arrival()
	assert_eq(f.session.replies.size(), 0)
	f.session.accepted = true
	f.arrival._save_arrival()
	assert_true(f.arrival._pending.is_empty())
	assert_false(f.arrival.owns_input(), "accepted saved arrival releases ordinary input")
	assert_false(f.arrival.is_open())
	assert_eq(f.game.captures, 1)
	assert_eq(f.game.save_system.attempts, 1)
	assert_eq(f.session.journal_calls, 3)
	assert_eq(f.session.receipts, [f.session.row.receipt], "only one original journal receipt")
	assert_eq(f.game.world.reward_deliveries.size(), 1)
	for original: Dictionary in f.session.journal_intents:
		assert_eq(original, {"envelope": f.envelope, "permit": f.permit})
	assert_eq(f.session.replies.size(), 1)
	assert_eq(f.session.replies[0].envelope, f.envelope)
	assert_eq(f.session.replies[0].result, {"ok": true, "saved": true, "durable": true,
		"arrival_applied": true, "arrived": true, "permit_id": "consumed-permit", "reason": ""})
	assert_eq(f.game.world.reward_deliveries[f.session.row.delivery_id].status, "accepted")
	# The existing real-input travel helper must retain only the exact
	# Session-authenticated Enter reply; world readiness alone is insufficient.
	var travel := preload("res://tests/helpers/f49_portal_travel.gd").new(null, f.game)
	travel._enter_binding = {"request_id": f.envelope.request_id, "character_id": f.envelope.character_id,
		"world_instance_id": f.envelope.world_instance_id, "session_epoch": f.envelope.session_epoch}
	var reply: Dictionary = f.session.replies[0].result.duplicate(true)
	reply.merge(travel._enter_binding)
	reply.kind = "portal_enter"
	for field: String in ["request_id", "character_id", "world_instance_id", "session_epoch", "kind"]:
		var unrelated := reply.duplicate(true)
		unrelated[field] = "another"
		travel._portal_result(unrelated)
		assert_true(travel._enter_result.is_empty(), "unrelated " + field + " is not this arrival")
	travel._portal_result(reply)
	assert_eq(travel._enter_result, reply, "the actual saved/durable/arrived schema is retained intact")
	var refusal := reply.duplicate(true)
	refusal.ok = false
	refusal.reason = "The arrival has not reached supported ground."
	travel._portal_result(refusal)
	assert_eq(travel._enter_result, refusal, "a correlated terminal refusal is preserved, never ready-world success")
	_dispose(f)

func test_non_durable_journal_cannot_replace_contact_even_after_owner_pose_save() -> void:
	var f := _fixture()
	f.game.save_system.succeeds = true
	f.session.durable = false
	f.arrival._save_arrival()
	assert_true(f.arrival._pending.get("pose_saved") == true)
	assert_false(f.arrival._pending.get("journal_started") == true)
	f.arrival.contact_valid = false
	assert_false(f.arrival.arrival_binding(f.envelope, f.permit))
	f.arrival._save_arrival()
	assert_true(f.arrival._pending.is_empty())
	assert_false(f.arrival.owns_input(), "terminal host refusal releases the exact arrival hold")
	assert_eq(f.game.save_system.attempts, 1)
	assert_eq(f.session.journal_calls, 1, "loss of contact before durable row must refuse")
	assert_eq(f.session.replies.size(), 1)
	assert_false(f.session.replies[0].result.ok)
	assert_true(f.game.world.reward_deliveries.is_empty())
	_dispose(f)

func test_forged_other_permit_session_character_and_destination_rows_do_not_retain_arrival() -> void:
	for scenario: String in ["forged_after", "other_permit", "other_session", "other_character", "other_destination"]:
		var f := _fixture()
		var envelope: Dictionary = f.envelope.duplicate(true)
		var permit: Dictionary = f.permit.duplicate(true)
		match scenario:
			"other_permit": permit.request_id = "another-permit"
			"other_session": envelope.session_epoch = "another-epoch"
			"other_character": envelope.character_id = "another-owner"
			"other_destination":
				permit.realm = "water"
				permit.entry_id = "water_entry"
		var row := _row(envelope, permit)
		if scenario == "forged_after": row.after.inventory[0] = {"id": "wood", "n": 99}
		else: assert_true(WORLD.training_row_valid(row, "arrival-world", "arrival-slot"), scenario + " is valid typed history, but not this original")
		var id := ESSENCE.training_delivery_id("arrival-world", "arrival-owner")
		f.game.world.reward_deliveries[id] = row
		# Deliberately forge a marker too: it cannot bypass production row checks.
		f.arrival._pending.journal_started = true
		f.arrival.contact_valid = false
		assert_false(f.arrival._original_arrival_row(f.game.world, f.arrival._pending), scenario)
		assert_false(f.arrival.arrival_binding(f.envelope, f.permit), scenario)
		f.arrival._save_arrival()
		assert_true(f.arrival._pending.is_empty(), scenario)
		assert_eq(f.game.save_system.attempts, 0, scenario)
		assert_eq(f.session.journal_calls, 0, scenario)
		assert_eq(f.session.replies.size(), 1, scenario)
		assert_false(f.session.replies[0].result.ok, scenario)
		_dispose(f)

func test_actual_session_save_waiting_requires_its_producer_exact_pending_and_seated_binding() -> void:
	# Only the key and producer binding are spies here; Session's actual
	# producer path, request equality, action kind and seated gate run intact.
	var session := PresentationSession.new()
	var game := Node.new()
	session.detached_game = game
	var key := PresentationKey.new()
	key.name = "HomeKey"
	game.add_child(key)
	var composition := Node.new()
	composition.name = "FoundationComposition"
	session.add_child(composition)
	var producer := PresentationProducer.new()
	producer.name = "PortalArrival"
	composition.add_child(producer)
	producer.envelope = {"request_id": "finish-request", "payload": {"kind": "home_key_finish"}}
	producer.permit = {"request_id": "original-permit"}
	session._portal_requests["finish-request"] = producer.envelope.duplicate(true)
	var impostor := PresentationProducer.new()
	impostor.envelope = producer.envelope.duplicate(true)
	impostor.permit = producer.permit.duplicate(true)
	session.portal_owner_save_waiting(impostor, producer.envelope, producer.permit)
	assert_true(key.notices.is_empty(), "another node with a true binding cannot notify")
	var changed := producer.envelope.duplicate(true)
	changed.extra = true
	session.portal_owner_save_waiting(producer, changed, producer.permit)
	assert_true(key.notices.is_empty(), "same request ID is not exact pending equality")
	session.portal_owner_save_waiting(producer, producer.envelope, {"request_id": "different-permit"})
	assert_true(key.notices.is_empty(), "producer rejects another permit")
	producer.seated = false
	session.portal_owner_save_waiting(producer, producer.envelope, producer.permit)
	assert_true(key.notices.is_empty(), "load time cannot release input as save-wait time")
	producer.seated = true
	producer.envelope.payload.kind = "portal_enter"
	session._portal_requests["finish-request"] = producer.envelope.duplicate(true)
	session.portal_owner_save_waiting(producer, producer.envelope, producer.permit)
	assert_true(key.notices.is_empty(), "another action cannot alter Home Key presentation")
	producer.envelope.payload.kind = "home_key_finish"
	session._portal_requests.clear()
	session.portal_owner_save_waiting(producer, producer.envelope, producer.permit)
	assert_true(key.notices.is_empty(), "a no-longer-pending request cannot notify")
	session._portal_requests["finish-request"] = producer.envelope.duplicate(true)
	session.portal_owner_save_waiting(producer, producer.envelope, producer.permit)
	assert_eq(key.notices, ["finish-request"], "only the original seated consumer may notify")
	assert_eq(session._portal_requests["finish-request"], producer.envelope, "presentation cannot erase durable pending")
	impostor.free()
	session.free()
	game.free()

func test_retained_row_cannot_survive_live_session_or_world_identity_change() -> void:
	for scenario: String in ["epoch", "world", "owner", "realm"]:
		var f := _fixture()
		f.game.save_system.succeeds = true
		f.arrival._save_arrival()
		assert_true(f.arrival._pending.get("journal_started") == true)
		match scenario:
			"epoch": f.session.epoch = "replacement-epoch"
			"world": f.game.world = WORLD.new()
			"owner": f.game.local = PLAYER.new()
			"realm": f.game.current_realm = "water"
		assert_false(f.arrival.presentation_binding(f.envelope, f.permit, true), scenario)
		assert_false(f.arrival.owns_input(), "another live " + scenario + " cannot inherit this input hold")
		assert_false(f.arrival.arrival_binding(f.envelope, f.permit), scenario)
		f.arrival._save_arrival()
		assert_true(f.arrival._pending.is_empty(), scenario)
		assert_eq(f.game.save_system.attempts, 1, scenario)
		assert_eq(f.session.journal_calls, 1, scenario)
		assert_eq(f.session.replies.size(), 1, scenario)
		assert_false(f.session.replies[0].result.ok, scenario)
		_dispose(f)
