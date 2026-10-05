extends "res://tests/test_case.gd"

const OPENING := preload("res://scripts/net/opening_home_key.gd")
const REWARD := preload("res://scripts/net/reward_delivery.gd")
const WORLD := preload("res://autoload/world_state.gd")
const PLAYER := preload("res://autoload/player_state.gd")
const ITEMS := preload("res://autoload/item_db.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const CHARACTER := "guest-opening"
const NAMESPACE := "0123456789abcdef0123456789abcdef"


class Saver extends RefCounted:
	var fail := false
	var writes := 0
	var seen_journal := false
	func finish_fallback() -> bool: return true
	func fallback_busy() -> bool: return false
	func save_world_prepared(game: Node, _id: String) -> bool:
		writes += 1
		seen_journal = game.get("world").reward_deliveries.size() == 1
		return not fail


class Transport extends Node:
	var ledger: RefCounted
	var publications: Array = []
	func _ensure_ledger() -> void: pass
	func publish_journaled_delta(delta: Dictionary) -> void:
		publications.append(delta.duplicate(true))


class Authority extends RefCounted:
	var recorded: Dictionary = {}
	var locked := false
	func _training_locked(_character: String) -> bool: return locked
	func record_personal_flag(character: String, flag: String, value: bool) -> void:
		recorded[character + ":" + flag] = value


class SessionFixture extends Node:
	var game: Node
	var _character_authority: RefCounted = Authority.new()
	var epoch := "opening-epoch"
	var character := CHARACTER
	var admitted_inventory: Array = []
	var flags: Dictionary = {}
	var escrow: Dictionary = {}
	func _init() -> void: admitted_inventory.resize(24)
	func local_peer_id() -> int: return 1
	func _foundation_flags(_peer: int) -> Dictionary: return flags.duplicate()
	func _altar_peer_in_combat(_peer: int) -> bool: return true # Reconcile stops before the owner CAS here.
	func _game() -> Node: return game
	func is_host() -> bool: return true
	func portal_runtime_ready() -> bool: return true
	func _authority_character(peer: int) -> String: return character if peer == 7 else "other"
	func _altar_current_epoch() -> String: return epoch
	func admitted_character_state(peer: int) -> Dictionary:
		return {"character_id": _authority_character(peer), "inventory": admitted_inventory.duplicate(true),
			"portal_escrow": escrow.duplicate(true)}


class GameFixture extends Node:
	var world: RefCounted = WORLD.new()
	var save_system: RefCounted = Saver.new()


var _game: GameFixture
var _session: SessionFixture
var _transport: Transport


func before_each() -> void:
	_game = GameFixture.new()
	_game.world.world_id = "opening-world"
	_game.world.reward_delivery_namespace = NAMESPACE
	_session = SessionFixture.new()
	_session.game = _game
	_game.add_child(_session)
	_transport = Transport.new()
	_transport.name = "LedgerRpc"
	_transport.ledger = LEDGER.new(_game.world)
	_session.add_child(_transport)


func after_each() -> void:
	_game.free()


func _row() -> Dictionary:
	return REWARD.make_record(_game.world.world_id, NAMESPACE, "home_key:grant:" + CHARACTER,
		CHARACTER, "home_key", 1, "home_key_given")


func _bound() -> Dictionary:
	return {"game": _game, "world": _game.world, "character": CHARACTER,
		"request": OPENING.envelope(CHARACTER, NAMESPACE, _session.epoch)}


func _player() -> RefCounted:
	var player: RefCounted = PLAYER.new()
	player.configure(ITEMS.new())
	player.character_id = CHARACTER
	return player


func _settlement() -> Dictionary:
	var request := OPENING.envelope(CHARACTER, NAMESPACE, _session.epoch)
	request.delivery_id = _row().delivery_id
	return request


func test_request_accepts_only_bound_identity_without_client_coordinates_or_flags() -> void:
	var request := OPENING.envelope(CHARACTER, NAMESPACE, _session.epoch)
	assert_true(OPENING.valid_envelope(request, CHARACTER, NAMESPACE, _session.epoch))
	assert_false(OPENING.valid_envelope(request, "other", NAMESPACE, _session.epoch))
	assert_false(OPENING.valid_envelope(request, CHARACTER, "other-world", _session.epoch))
	assert_false(OPENING.valid_envelope(request, CHARACTER, NAMESPACE, "new-epoch"))
	request.position = Vector3.ZERO
	assert_false(OPENING.valid_envelope(request, CHARACTER, NAMESPACE, _session.epoch))
	request.erase("position")
	request.opening_starter_granted = true
	assert_false(OPENING.valid_envelope(request, CHARACTER, NAMESPACE, _session.epoch))


func test_original_starter_requires_own_receipt_admitted_flag_and_same_owned_uid() -> void:
	var personal := {"character_id": CHARACTER, "party": [{"uid": "original", "species_id": "terrapup"}],
		"redesign_character": {"transaction_receipts": ["starter_choice:" + CHARACTER + ":original"]}}
	var flags := {"opening:starter_granted": true}
	assert_eq(OPENING.starter_uid(personal, flags), "original")
	assert_eq(OPENING.starter_uid(personal, {}), "")
	personal.party[0].uid = "another"
	assert_eq(OPENING.starter_uid(personal, flags), "")
	personal.party[0].uid = "original"
	personal.party[0].species_id = "bramblebun"
	assert_eq(OPENING.starter_uid(personal, flags), "")
	personal.party[0].species_id = "terrapup"
	personal.redesign_character.transaction_receipts.append("starter_choice:" + CHARACTER + ":another")
	assert_eq(OPENING.starter_uid(personal, flags), "")


func test_world_writer_sees_frozen_gift_before_any_recipient_publication() -> void:
	var verdict := OPENING._journal_prepared(_session, 7, _bound())
	assert_true(verdict.get("durable", false))
	assert_true(_game.save_system.seen_journal)
	assert_eq(_game.save_system.writes, 1)
	assert_eq(_transport.publications.size(), 1)
	var ops: Array = LEDGER.player_ops_for(_transport.publications[0], 7)
	assert_eq(ops.size(), 0, "physical gift is a host inventory CAS, never a generic recipient grant")
	assert_eq(_game.world.reward_deliveries[_row().delivery_id], _row())
	assert_true(LEDGER.player_ops_for(_transport.publications[0], 1).is_empty())
	assert_true(OPENING._journal_prepared(_session, 7, _bound()).get("duplicate", false))
	assert_eq(_game.save_system.writes, 1)
	assert_eq(_transport.publications.size(), 1)


func test_failed_world_write_rolls_back_and_publishes_nothing() -> void:
	var before: Dictionary = _game.world.save_data()
	var revision: int = _game.world.revision
	_game.save_system.fail = true
	assert_false(OPENING._journal_prepared(_session, 7, _bound()).get("durable", false))
	assert_eq(_game.world.save_data(), before)
	assert_eq(_game.world.revision, revision)
	assert_eq(_transport.ledger.seq, 0)
	assert_true(_transport.publications.is_empty())
	_game.save_system.fail = false
	assert_true(OPENING._journal_prepared(_session, 7, _bound()).get("durable", false))
	assert_eq(_game.world.reward_deliveries.size(), 1)


func test_canonical_settlement_rejects_wrong_owner_epoch_source_and_row() -> void:
	_game.world.reward_deliveries[_row().delivery_id] = _row()
	var request := _settlement()
	assert_false(OPENING.host_confirm_settled(_session, 8, request))
	request.session_epoch = "old-epoch"
	assert_false(OPENING.host_confirm_settled(_session, 7, request))
	request.session_epoch = _session.epoch
	_game.world.reward_deliveries[request.delivery_id].stacks = [{"id": "home_key", "n": 2}]
	assert_false(OPENING.host_confirm_settled(_session, 7, request))
	assert_true(_session._character_authority.recorded.is_empty())
	_game.world.reward_deliveries[request.delivery_id] = _row()
	_game.world.reward_deliveries[request.delivery_id].status = "accepted"
	assert_false(OPENING.host_confirm_settled(_session, 7, request), "accepted generic receipt alone proves no physical inventory")
	assert_true(_session._character_authority.recorded.is_empty())
	_session.admitted_inventory[0] = {"id": "home_key", "n": 1}
	_session._character_authority.locked = true
	assert_false(OPENING.host_confirm_settled(_session, 7, request), "hidden host inventory promotion remains locked until owner save ACK")
	_session._character_authority.locked = false
	assert_true(OPENING.host_confirm_settled(_session, 7, request), "later full-bag settlement still works after ordinary acceptance")
	assert_eq(_session._character_authority.recorded, {CHARACTER + ":home_key_given": true})


func test_saved_original_world_gift_accepts_json_numbers_without_widening_source_schema() -> void:
	var saved: Variant = JSON.parse_string(JSON.stringify(_row()))
	assert_true(OPENING.valid_row(saved, _game.world, CHARACTER))
	saved.version = 1.25
	assert_false(OPENING.valid_row(saved, _game.world, CHARACTER))
	saved.version = 1.0
	saved.stacks[0].n = true
	assert_false(OPENING.valid_row(saved, _game.world, CHARACTER))
	saved.stacks[0].n = 1.0
	saved.client_authorized = true
	assert_false(OPENING.valid_row(saved, _game.world, CHARACTER))


func test_full_bag_owed_grant_is_not_physical_possession_and_portable_duplicate_gives_one() -> void:
	var player := _player()
	for index: int in player.inventory.slot_count():
		player.inventory.set_slot(index, {"id": "wood", "n": ITEMS.new().stack_size("wood")})
	var original := _row()
	var owed := REWARD.apply(player, original)
	assert_true(owed.ok)
	assert_false(owed.settled)
	assert_false(OPENING.owner_physically_settled(player, original.delivery_id))
	var other := REWARD.make_record("another-world", "fedcba9876543210fedcba9876543210",
		original.source, CHARACTER, "home_key", 1, "home_key_given")
	assert_true(REWARD.apply(player, other).settled)
	assert_false(OPENING.owner_physically_settled(player, other.delivery_id), "duplicate suppression is not physical settlement")
	player.inventory.set_slot(0, null)
	assert_true(REWARD.apply(player, original).settled)
	assert_true(OPENING.owner_physically_settled(player, original.delivery_id))
	REWARD.apply(player, other)
	assert_eq(player.inventory.count("home_key"), 1)


func test_legacy_character_past_first_catch_gets_one_deterministic_grant() -> void:
	_session.flags = {OPENING.PAST_FIRST_CATCH_FLAG: true}
	var first: Dictionary = OPENING.host_legacy_grant(_session, 7)
	assert_true(first.get("durable") == true, str(first))
	assert_eq(first.get("delivery_id"), _row().delivery_id, "same id Grandpa's own grant uses")
	assert_eq(_game.world.reward_deliveries.size(), 1)
	assert_true(OPENING.valid_row(_game.world.reward_deliveries[_row().delivery_id], _game.world, CHARACTER))
	var again: Dictionary = OPENING.host_legacy_grant(_session, 7)
	assert_true(again.get("duplicate") == true, "a repeat tick journals nothing new")
	assert_eq(_game.world.reward_deliveries.size(), 1)
	assert_eq(_game.save_system.writes, 1)


func test_legacy_grant_skips_keyed_owed_given_and_unfinished_openings() -> void:
	_session.flags = {}
	var early: Dictionary = OPENING.host_legacy_grant(_session, 7)
	assert_eq(early.get("code"), "not_past_first_catch", "not past Grandpa's first catch: no grant, the arm waits")
	assert_true(early.get("durable") == false)
	assert_eq(_game.world.reward_deliveries.size(), 0)
	_session.flags = {OPENING.PAST_FIRST_CATCH_FLAG: true, "home_key_given": true}
	assert_true(OPENING.host_legacy_grant(_session, 7).is_empty(), "already given")
	_session.flags = {OPENING.PAST_FIRST_CATCH_FLAG: true}
	_session.admitted_inventory[3] = {"id": "home_key", "n": 1}
	assert_true(OPENING.host_legacy_grant(_session, 7).is_empty(), "already holds a key")
	_session.admitted_inventory[3] = null
	var owed := _row()
	owed.kind = "reward_delivery"
	owed.status = "grant_due"
	_session.escrow = {owed.delivery_id: owed}
	assert_true(OPENING.legacy_grant_due({"character_id": CHARACTER, "inventory": _session.admitted_inventory,
		"portal_escrow": {}}, _session.flags, CHARACTER))
	assert_false(OPENING.legacy_grant_due({"character_id": CHARACTER, "inventory": _session.admitted_inventory,
		"portal_escrow": _session.escrow}, _session.flags, CHARACTER), "an owed key follows its character")
	assert_eq(_game.world.reward_deliveries.size(), 0)


class GiftSeenSession extends SessionFixture:
	var gift_seen := true
	func opening_gift_requested(_peer: int) -> bool: return gift_seen

## Review finding 1: a guest's opening beats stay on the guest, so the host
## never sees its walk_out mid-session. A verified gift request that reached
## this host is the host's own evidence; the reconcile grants on it.
func test_a_gift_request_seen_by_the_host_is_past_first_catch_evidence() -> void:
	_game.remove_child(_session)
	var seen := GiftSeenSession.new()
	seen.game = _game
	seen.flags = {}
	_game.add_child(seen)
	_transport.reparent(seen)
	var granted: Dictionary = OPENING.host_legacy_grant(seen, 7)
	assert_true(granted.get("durable") == true, "no walk_out on the host, gift seen: " + str(granted))
	assert_eq(_game.world.reward_deliveries.size(), 1)
	seen.gift_seen = false
	seen.flags = {"home_key_given": true}
	assert_true(OPENING.host_legacy_grant(seen, 7).is_empty(), "a given key is final")
	_transport.reparent(_session)
	_game.add_child(_session)
	seen.queue_free()


class NoteSession extends SessionFixture:
	var noted: Array = []
	func note_opening_gift_requested(peer: int) -> void: noted.append(peer)
	func _portal_world_node(_realm: String) -> Node3D: return null # No authored Grandpa here.

## Review nit 2: a rejected gift request records no evidence. Only a request
## that passes binding, Grandpa geometry and the starter check is noted.
func test_a_rejected_gift_request_records_no_evidence() -> void:
	var probe := NoteSession.new()
	probe.game = _game
	var request := OPENING.envelope(CHARACTER, NAMESPACE, probe.epoch)
	var away: Dictionary = OPENING.host_grant(probe, 7, request)
	assert_eq(away.get("code"), "opening_context_changed", "away from Grandpa")
	assert_eq(probe.noted, [], "no evidence without Grandpa's geometry")
	var stranger: Dictionary = OPENING.host_grant(probe, 9, request)
	assert_eq(stranger.get("code"), "not_admitted")
	assert_eq(probe.noted, [], "no evidence for an unadmitted or foreign request")
	assert_eq(_game.world.reward_deliveries.size(), 0)
	probe.free()


func test_reconcile_waits_while_another_owner_delivery_is_unsettled() -> void:
	# render.yml 37378022226: a returning guest past the opening gathered
	# berries while its legacy Home Key row was staged against an admitted
	# record without them; the owner apply conflicted and held every write.
	_session.flags = {OPENING.PAST_FIRST_CATCH_FLAG: true}
	assert_true(OPENING.host_legacy_grant(_session, 7).get("durable") == true)
	var request := _settlement()
	request.origin_namespace = NAMESPACE
	var find := REWARD.make_record(_game.world.world_id, NAMESPACE, "gather_batch:1", CHARACTER, "berries", 2)
	_game.world.reward_deliveries[find.delivery_id] = find
	assert_eq(OPENING.host_reconcile(_session, 7, request).get("code"), "owner_delivery_pending",
		"a find the owner may already hold blocks the full-record Home Key row")
	var other := REWARD.make_record(_game.world.world_id, NAMESPACE, "gather_batch:1", "someone-else", "berries", 2)
	_game.world.reward_deliveries.erase(find.delivery_id)
	_game.world.reward_deliveries[other.delivery_id] = other
	assert_eq(OPENING.host_reconcile(_session, 7, request).get("code"), "actor_in_combat",
		"another character's delivery and the gift's own pending row do not block (the fixture then stops at combat)")
	find.status = "accepted"
	_game.world.reward_deliveries[find.delivery_id] = find
	assert_eq(OPENING.host_reconcile(_session, 7, request).get("code"), "actor_in_combat", "an accepted find no longer blocks")


class GateRecorder extends RefCounted:
	var calls: Array = []
	func action_gate(peer: int, source_kind: String, request: Dictionary, context: Dictionary) -> Dictionary:
		calls.append({"peer": peer, "source_kind": source_kind, "request": request.duplicate(true), "context": context.duplicate(true)})
		return {"ok": false, "code": "owner_passive_checkpoint_pending"}


class RevisionAuthority extends Authority:
	func revision(_character: String) -> int: return 4


class GatedSession extends SessionFixture:
	var gate := GateRecorder.new()
	func _altar_peer_in_combat(_peer: int) -> bool: return false
	func _owner_passive_service() -> RefCounted: return gate


func test_a_guest_reconcile_freezes_its_owner_passive_stream_before_staging() -> void:
	# render.yml 37383201956: the guest's home_key_owe row staged straight onto
	# the admitted record while its owner-passive stream kept replaying care
	# and finds; the stream's base went stale and the next find's replay
	# stopped it (owner_passive_delivery_authority_changed). The reconcile now
	# asks the owner-passive gate first, as waystone touches do.
	var gated := GatedSession.new()
	gated.game = _game
	gated._character_authority = RevisionAuthority.new()
	gated.flags = {OPENING.PAST_FIRST_CATCH_FLAG: true}
	_session.remove_child(_transport)
	gated.add_child(_transport)
	_game.add_child(gated)
	assert_true(OPENING.host_legacy_grant(gated, 7).get("durable") == true)
	var request := _settlement()
	request.origin_namespace = NAMESPACE
	var result: Dictionary = OPENING.host_reconcile(gated, 7, request)
	assert_eq(result.get("code"), "owner_passive_checkpoint_pending", "nothing stages until the owner is frozen")
	assert_eq(gated.gate.calls.size(), 1)
	var call: Dictionary = gated.gate.calls[0]
	assert_eq(call.source_kind, "home_key")
	assert_true(_same(call.request, preload("res://scripts/net/owner_passive_preparation.gd").home_key_request(request)),
		"the gate binds the owner's exact request")
	assert_eq(call.context.expected_revision, 4)
	assert_eq(call.context.home_key_record.status, "grant_due", "a first debt is the host's own saved grant")
	assert_eq(call.context.source_key, "opening_home_key:" + request.delivery_id)
	assert_false(_game.world.reward_deliveries.keys().any(func(id: String) -> bool: return id.begins_with("creature_training")),
		"no full-record row was staged")


func _same(a: Variant, b: Variant) -> bool:
	return preload("res://scripts/creatures/essence.gd")._equivalent(a, b)
