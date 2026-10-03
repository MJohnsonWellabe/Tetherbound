extends "res://tests/test_case.gd"

## Actual trait rules/authority/ledger BOOL write; physical Altar admission and
## remote transport are explicit doubles. No ENet or controller-route claim.
const TRANSPORT := preload("res://scripts/net/altar_traits_transport.gd")
const DATA := preload("res://tests/test_foundation_resources.gd")
const SAVE := preload("res://tests/test_foundation_resource_save.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const AUTH := preload("res://scripts/net/character_authority.gd")
const TRAITS := preload("res://scripts/creatures/traits.gd")

class Gate extends RefCounted:
	var calls := 0
	func action_gate(_peer: int, kind: String, _request: Dictionary, _context: Dictionary) -> Dictionary:
		calls += 1
		return {"ok": false, "durable": false, "code": "checkpoint_pending" if kind == "altar_traits" else "wrong_kind"}

class FixtureRpc extends SAVE.FixtureRpc:
	func publish_creature_training(_peer: int, _character: String, _receipt: String) -> bool:
		return false # Publication/owner ACK withheld explicitly; only world BOOL tested here.

class FixtureSession extends SAVE.FixtureSession:
	var host := true
	var station := true
	var gate := Gate.new()
	var sent_quote: Dictionary = {}
	var sent_request: Dictionary = {}
	func is_host() -> bool: return host
	func _authority_character(peer: int) -> String: return DATA.CHARACTER if peer in [1, 2] else ""
	func admitted_character_state(_peer: int) -> Dictionary: return get("_character_authority").call("state", DATA.CHARACTER)
	func _altar_station_for_peer(_peer: int, _key: String) -> bool: return station
	func _foundation_source(_peer: int, key: String, _part: String = "workbench") -> Dictionary:
		return {"character_id": DATA.CHARACTER, "expected_revision": get("_character_authority").call("revision", DATA.CHARACTER),
			"source_key": key, "station_id": "altar", "homestead": true, "in_range": true, "in_combat": false}
	func _altar_envelope_matches(peer: int, envelope: Dictionary, fields: Array) -> bool:
		if not host or peer not in [1, 2] or envelope.size() != fields.size(): return false
		for field: String in fields:
			if not envelope.has(field): return false
		return envelope.character_id == DATA.CHARACTER and envelope.session_epoch == "resource-epoch" \
			and envelope.world_namespace == "resource-namespace" and envelope.station_key == "altar:meadows:b1"
	func _owner_passive_service() -> RefCounted: return gate
	func _altar_traits_send_quote(envelope: Dictionary) -> void: sent_quote = envelope.duplicate(true)
	func _altar_traits_send(envelope: Dictionary, _reconcile: bool) -> void: sent_request = envelope.duplicate(true)

func _fixture() -> Dictionary:
	var game := SAVE.FixtureGame.new()
	game.local = DATA.new()._player()
	game.world = DATA.new()._world()
	var caught := preload("res://scripts/creatures/creature_species.gd").spawn("mudsnout")
	game.local.party.add(caught)
	var before := RECORD.portable_projection(game.local.save_data())
	before.redesign_character.creatures[caught.uid].captured_from = {
		"kind": "wild", "world_namespace": "resource-namespace", "spawn_id": "caught-source", "spawn_generation": 1}
	var session := FixtureSession.new()
	session.fixture = game
	game.session = session
	var authority := AUTH.new()
	session.set("_character_authority", authority)
	assert_true(authority.bind_world("resource-namespace"))
	assert_true(authority.seed_admitted_character(before, DATA.CHARACTER).ok)
	var directory := "user://test_altar_trait_transport_" + Crypto.new().generate_random_bytes(12).hex_encode()
	var writer := SAVE.BoolWriter.new()
	writer.world_store = preload("res://scripts/save/world_save.gd").new(directory.path_join("worlds"))
	writer.character_store = preload("res://scripts/save/character_save.gd").new(directory.path_join("characters"))
	game.save_system = writer
	var rpc := FixtureRpc.new()
	rpc.name = "LedgerRpc"
	rpc.fixture = game
	rpc.ledger = preload("res://scripts/net/world_ledger.gd").new(game.world)
	session.add_child(rpc)
	var transport := TRANSPORT.new(session)
	session.add_child(transport)
	var request := {"op": "altar_trait", "session_epoch": "resource-epoch", "world_namespace": "resource-namespace",
		"character_id": DATA.CHARACTER, "station_key": "altar:meadows:b1", "intent": {
			"action_id": "trait-transport-original", "action": "release", "creature_uid": caught.uid,
			"trait_id": "", "slot": -1, "payment_item": "", "expected_character_revision": 0}}
	return {"game": game, "session": session, "authority": authority, "transport": transport,
		"request": request, "before": before, "writer": writer, "directory": directory}

func _close(f: Dictionary) -> void:
	f.session.free()
	f.game.free()
	preload("res://tests/helpers/split_save_fixture.gd").wipe(f.directory)

func test_release_world_bool_failure_retains_original_and_retries_one_journal() -> void:
	var f := _fixture()
	f.writer.refuse_world = true
	var failed: Dictionary = f.transport.handle(1, f.request)
	assert_false(failed.get("durable", true), str(failed))
	assert_eq(f.authority.state(DATA.CHARACTER), f.before)
	assert_true(f.game.world.reward_deliveries.is_empty())
	f.writer.refuse_world = false
	var result: Dictionary = f.transport.handle(1, f.request, true)
	assert_true(result.get("durable") == true, str(result))
	var id := preload("res://scripts/creatures/essence.gd").training_delivery_id("resource-namespace", DATA.CHARACTER)
	var row: Dictionary = f.game.world.reward_deliveries.get(id, {})
	assert_false(row.is_empty())
	if not row.is_empty():
		assert_eq(row.intent, f.request.intent)
		assert_eq(row.receipt, "release:" + str(f.request.intent.creature_uid))
		assert_eq(row.after.party.size(), 1)
		var recovered: Dictionary = f.writer.world_store.read("resource-slot")
		var world := DATA.new()._world()
		world.load_data(recovered)
		assert_eq(world.reward_deliveries[id].receipt, row.receipt)
		var frozen: Dictionary = row.duplicate(true)
		f.session.station = false
		f.transport.handle(1, f.request, true)
		assert_eq(f.game.world.reward_deliveries[id], frozen, "recovery never creates or overwrites a journal")
	_close(f)

func test_guest_checkpoint_precedes_stage_and_foreign_or_changed_requests_refuse() -> void:
	var f := _fixture()
	var pending: Dictionary = f.transport.handle(2, f.request)
	assert_eq(pending.get("code"), "checkpoint_pending")
	assert_eq(f.session.gate.calls, 1)
	assert_eq(f.authority.state(DATA.CHARACTER), f.before)
	assert_true(f.game.world.reward_deliveries.is_empty())
	var changed: Dictionary = f.request.duplicate(true)
	changed.intent.trait_id = "bold"
	assert_eq(f.transport.handle(2, changed).code, "original_trait_request_pending")
	changed = f.request.duplicate(true)
	changed.character_id = "other-owner"
	assert_eq(f.transport.handle(2, changed).code, "invalid_trait_request")
	assert_eq(f.transport.handle(99, f.request).code, "invalid_trait_request")
	f.session.station = false
	assert_true(f.transport.handle(2, f.request, true).get("terminal") == true)
	f.session.station = true
	changed = f.request.duplicate(true)
	changed.intent.action_id = "trait-new-after-refusal"
	assert_eq(f.transport.handle(2, changed).code, "checkpoint_pending", "terminal pre-journal refusal releases only original request cache")
	_close(f)

func test_async_quote_accepts_only_original_scope_and_notifies_existing_ui_signal() -> void:
	var f := _fixture()
	f.session.host = false
	var updates: Array = []
	f.session.connect("altar_trait_quote_completed", func(key: String, uid: String) -> void: updates.append([key, uid]))
	var first: Dictionary = f.transport.quote(f.request.station_key, f.request.intent.creature_uid)
	assert_eq(first.code, "quote_pending")
	var original: Dictionary = f.session.sent_quote.duplicate(true)
	f.session.host = true
	var quote: Dictionary = f.transport.handle_quote(2, original)
	assert_true(quote.get("ok") == true, str(quote))
	assert_true(quote.get("release_allowed") == true)
	f.session.host = false
	var foreign: Dictionary = original.duplicate(true)
	foreign.quote_id = "f".repeat(32)
	f.transport.receive_quote(foreign, quote)
	assert_true(updates.is_empty())
	f.transport.receive_quote(original, quote)
	assert_eq(updates.size(), 1)
	assert_eq(f.transport.quote(f.request.station_key, f.request.intent.creature_uid), quote)
	f.transport.invalidate_quote()
	f.transport.receive_quote(original, quote)
	assert_eq(updates.size(), 1, "closed/reopened quote cannot accept a previous reply")
	assert_eq(f.transport.quote(f.request.station_key, f.request.intent.creature_uid).code, "quote_pending")
	assert_false(f.session.sent_quote.quote_id == original.quote_id)
	assert_eq(f.authority.state(DATA.CHARACTER), f.before, "quote cannot adopt or change saved traits")
	_close(f)
