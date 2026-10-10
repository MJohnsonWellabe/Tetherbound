extends "res://tests/test_case.gd"

## Actual SaveGame, CharacterSave, WorldSave, Session, authority and LedgerRpc.
## Detached physical admission/actor handoff and UI mounting are disclosed seams.
## No native scene, ENet, catch animation or controller claim is made here.
const PREPARED := preload("res://tests/test_prepared_training_owner_identity.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const EVENT := preload("res://scripts/net/foundation_event.gd")
const RULES := preload("res://scripts/net/foundation_capture_rules.gd")
const CODEC := preload("res://scripts/save/water_capture_codec.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CHARACTER := PREPARED.CHARACTER
const NAMESPACE := PREPARED.NAMESPACE
const EPOCH := PREPARED.EPOCH

class CaptureGame extends PREPARED.GameFixture:
	var pending_catch: RefCounted
	var current_realm := "meadows"
	func is_host() -> bool: return true

class WorldWriter extends "res://scripts/save/world_save.gd":
	var refuse := false
	var attempts := 0
	func write(id: String, payload: Dictionary, envelope: Dictionary = {}, retain_previous: bool = false) -> bool:
		attempts += 1
		return false if refuse else super.write(id, payload, envelope, retain_previous)

class CaptureSession extends "res://scripts/net/session.gd":
	var fixture: Node
	var fighting := false
	var offer: Dictionary
	var retained_id := ""
	func _game() -> Node: return fixture
	func is_host() -> bool: return true
	func is_active() -> bool: return false
	func local_peer_id() -> int: return 1
	func _altar_current_epoch() -> String: return EPOCH
	func _authority_character(peer: int) -> String:
		return CHARACTER if peer == 1 else ""
	func admitted_character_state(peer: int) -> Dictionary:
		return _character_authority.state(CHARACTER) if peer == 1 else {}
	func _altar_peer_in_combat(_peer: int) -> bool: return fighting
	func _altar_envelope(op: String, key: String) -> Dictionary:
		return {"op": op, "session_epoch": EPOCH, "world_namespace": NAMESPACE,
			"character_id": CHARACTER, "station_key": key}
	func _altar_envelope_matches(peer: int, envelope: Dictionary, fields: Array) -> bool:
		if peer != 1 or envelope.size() != fields.size(): return false
		for field: String in fields:
			if not envelope.has(field): return false
		return envelope.character_id == CHARACTER and envelope.session_epoch == EPOCH \
			and envelope.world_namespace == NAMESPACE
	func _foundation_source(_peer: int, _key: String, _part: String = "workbench") -> Dictionary:
		return {} # No physical stations are mounted in this detached fixture.
	func _foundation_capture_context(peer: int, key: String) -> Dictionary:
		if peer != 1 or fighting or key != offer.get("source_key") \
			or not EVENT.valid(fixture.world.reward_deliveries.get(retained_id), NAMESPACE, fixture.world.world_id):
			return {}
		var context := offer.duplicate(true)
		context.merge({"character_id": CHARACTER, "expected_revision": _character_authority.revision(CHARACTER),
			"in_range": true, "in_combat": false, "foundation_runtime_authorized": true,
			"retained_event": retained_id})
		return context
	func training_actor_baseline_ready(_peer: int, _row: Dictionary) -> bool:
		return true # No active actor exists; live actor handoff is a separate proof.
	func _training_actor_baseline_proposals(peer: int, row: Dictionary) -> Dictionary:
		if peer != 1 or row.get("character_id") != CHARACTER: return {"ok": false}
		return {"ok": true, "proposals": [], "admitted": _character_authority.state(CHARACTER),
			"revision": _character_authority.revision(CHARACTER)}

class CaptureRpc extends "res://scripts/net/ledger_rpc.gd":
	var fixture: Node
	func _game() -> Node: return fixture
	func _local_peer_id() -> int: return 1

class Presenter extends "res://scripts/net/foundation_capture.gd":
	func _bind_release_service() -> bool:
		return true # UI mounting is disclosed; production settlement is unchanged.

func _fixture(count: int = 1) -> Dictionary:
	var directory := "user://test_local_trait_capture_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	var seed := PREPARED.new()._game(directory)
	var game := CaptureGame.new()
	game.local = seed.local
	game.world = seed.world
	game.forwarded = seed.forwarded
	game.save_system = seed.save_system
	seed.session.free()
	seed.free()
	for index: int in range(1, count): game.local.party.add(SPECIES.spawn("terrapup"))
	var session := CaptureSession.new()
	session.fixture = game
	game.session = session
	var authority := preload("res://scripts/net/character_authority.gd").new()
	session.set("_character_authority", authority)
	session.get("_registry").call("add", 1, CHARACTER)
	var before := RECORD.portable_projection(game.local.save_data())
	assert_eq(RECORD.errors(before, CHARACTER), [], "actual owner must pass admission")
	assert_true(authority.bind_world(NAMESPACE))
	assert_true(authority.seed_admitted_character(before, CHARACTER).get("ok") == true)
	var world_writer := WorldWriter.new(directory.path_join("worlds"))
	game.save_system.set("_worlds", world_writer)
	var rpc := CaptureRpc.new()
	rpc.name = "LedgerRpc"
	rpc.fixture = game
	rpc.ledger = preload("res://scripts/net/world_ledger.gd").new(game.world)
	session.add_child(rpc)
	var composition := Node.new()
	composition.name = "FoundationComposition"
	session.add_child(composition)
	var presenter := Presenter.new()
	presenter.name = "Captures"
	composition.add_child(presenter)
	var card := CODEC.encode(SPECIES.spawn("bramblebun"))
	var traits := {"traits_initialized": true, "rolled_traits": ["surefoot"], "taught_traits": {},
		"captured_from": {"kind": "wild", "world_namespace": NAMESPACE,
			"spawn_id": "actual-retained-test-spawn", "spawn_generation": 1}}
	var offer_id := JSON.stringify([NAMESPACE, "actual-test-claim", card.uid]).sha256_text()
	var offer := {"offer_id": offer_id, "source_key": "capture:" + offer_id,
		"world_namespace": NAMESPACE, "session_id": EPOCH, "participants": [CHARACTER],
		"realm": "meadows", "creature": card, "capture_traits": traits}
	assert_true(RULES.offer_valid(offer), "canonical retained offer")
	var duty := {"character_id": CHARACTER, "action": "capture_offer", "intent": {}, "context": offer}
	var retained := EVENT.make(game.world, EPOCH, offer.source_key, [duty])
	assert_false(retained.is_empty(), "canonical capture event")
	game.world.reward_deliveries[retained.delivery_id] = retained
	session.offer = offer
	session.retained_id = retained.delivery_id
	assert_true(game.save_system.save_world_prepared(game, game.world.world_id), "actual initial world BOOL")
	assert_true(game.save_system.save_character_prepared(game, CHARACTER), "actual initial owner BOOL")
	return {"game": game, "session": session, "presenter": presenter, "rpc": rpc, "authority": authority,
		"creature": CODEC.decode(card, traits), "offer": offer, "directory": directory,
		"world_writer": world_writer, "owner_writer": game.save_system.get("_characters")}

func _close(f: Dictionary) -> void:
	f.session.free()
	f.game.free()
	preload("res://tests/helpers/split_save_fixture.gd").wipe(f.directory)

func _row(f: Dictionary) -> Dictionary:
	return f.game.world.reward_deliveries.get(ESSENCE.training_delivery_id(NAMESPACE, CHARACTER), {})

func _ready(f: Dictionary) -> bool:
	return f.presenter.call("complete_local_catch", f.creature) == true

func _assert_settled(f: Dictionary, count: int) -> void:
	var row := _row(f)
	assert_eq(row.get("action"), "wild_capture")
	assert_eq(row.get("status"), "accepted")
	assert_eq(row.get("receipt"), RULES.receipt(f.offer.offer_id, CHARACTER))
	assert_false(f.authority.creature_training_is_pending(CHARACTER))
	assert_eq(f.game.local.party.size(), count)
	assert_true(f.game.local.redesign_character.transaction_receipts.has(row.receipt))
	assert_true(f.game.pending_catch == null, "saved owner must not open a stale catch ceremony")
	assert_false(f.presenter.owns_pending_capture(f.creature), "completed offer releases its presenter")
	var decision: Dictionary = f.session._foundation_decision(1, row)
	assert_true(decision.get("saved") == true and decision.get("owner_acknowledged") == true, str(decision))
	var owner_disk: Dictionary = f.owner_writer.read(CHARACTER)
	assert_eq(owner_disk.party.size(), count, "actual disk BOOL contains the awarded owner")
	assert_true(owner_disk.redesign_character.transaction_receipts.has(row.receipt))
	var world_disk: Dictionary = f.world_writer.read(f.game.world.world_id)
	assert_eq(world_disk.reward_deliveries[row.delivery_id].status, "accepted", "accepted world BOOL persisted")

func test_local_free_slot_catch_requires_terminal_state_and_real_owner_ack_before_completion() -> void:
	var f := _fixture()
	f.session.fighting = true
	assert_false(_ready(f), "an active combat manager cannot use a completion hook")
	assert_true(_row(f).is_empty())
	assert_eq(f.game.local.party.size(), 1)
	f.session.fighting = false
	assert_true(_ready(f), "terminal manager can settle through the actual local BOOL/ACK path")
	_assert_settled(f, 2)
	var receipt: String = _row(f).receipt
	var uid: String = f.offer.creature.uid
	assert_true(_ready(f), "duplicate terminal callback recognizes its original settled receipt")
	assert_eq(f.game.local.party.size(), 2)
	assert_eq(f.game.local.redesign_character.transaction_receipts.count(receipt), 1)
	var copies := 0
	for creature: RefCounted in f.game.local.party.members():
		if creature.uid == uid: copies += 1
	assert_eq(copies, 1)
	_close(f)

func test_local_capture_world_bool_failure_keeps_original_offer_and_retries_once() -> void:
	var f := _fixture()
	var owner_path: String = f.owner_writer.path_for(CHARACTER)
	var original_owner := FileAccess.get_file_as_bytes(owner_path)
	f.world_writer.refuse = true
	assert_false(_ready(f), "world BOOL false must hold completion")
	assert_true(_row(f).is_empty(), "failed hidden stage rolls back")
	assert_eq(f.game.local.party.size(), 1)
	assert_eq(FileAccess.get_file_as_bytes(owner_path), original_owner)
	assert_true(f.game.world.reward_deliveries.has(f.session.retained_id), "original catch offer remains")
	assert_true(f.game.pending_catch != null, "failed world BOOL preserves pending presentation")
	f.world_writer.refuse = false
	assert_true(_ready(f))
	_assert_settled(f, 2)
	assert_eq(_row(f).journal_revision, 1, "acceptance settles the original pending journal revision")
	_close(f)

func test_owner_bool_failure_when_four_becomes_five_must_not_escape_through_full_roster_ceremony() -> void:
	var f := _fixture(4)
	var owner_path: String = f.owner_writer.path_for(CHARACTER)
	var original_owner := FileAccess.get_file_as_bytes(owner_path)
	f.owner_writer.refuse = true
	assert_false(_ready(f), "owner BOOL false must hold completion")
	assert_eq(_row(f).status, "pending")
	assert_true(f.game.pending_catch != null, "failed owner BOOL preserves pending presentation")
	assert_eq(f.game.local.party.size(), 5, "the existing owner retry retains its installed after-state")
	assert_eq(FileAccess.get_file_as_bytes(owner_path), original_owner)
	var receipt: String = _row(f).receipt
	assert_false(_ready(f), "now-full installed roster is pending ACK, not a new ceremony")
	assert_eq(_row(f).receipt, receipt, "retry retains the original decision")
	assert_eq(_row(f).status, "pending")
	f.owner_writer.refuse = false
	assert_true(_ready(f))
	_assert_settled(f, 5)
	assert_eq(_row(f).receipt, receipt)
	assert_eq(f.game.local.redesign_character.transaction_receipts.count(receipt), 1)
	_close(f)

func test_original_five_owned_catch_hands_off_to_existing_ceremony_without_sixth_owner() -> void:
	var f := _fixture(5)
	var writes: int = f.owner_writer.attempts
	assert_true(_ready(f), "full roster may finish only to present its original ceremony")
	assert_eq(f.game.local.party.size(), 5)
	assert_true(_row(f).is_empty(), "completion did not decide release or auto-keep")
	assert_eq(f.owner_writer.attempts, writes)
	assert_true(f.game.pending_catch != null)
	assert_eq(f.game.pending_catch.uid, f.offer.creature.uid)
	assert_true(f.presenter.owns_pending_capture(f.game.pending_catch))
	_close(f)


func test_later_pending_research_does_not_reopen_an_acknowledged_capture_ceremony() -> void:
	var f := _fixture()
	assert_true(_ready(f))
	_assert_settled(f, 2)
	var original := _row(f).duplicate(true)
	var before: Dictionary = f.authority.state(CHARACTER)
	var revision: int = f.authority.revision(CHARACTER)
	var research: RefCounted = preload("res://tests/test_research_log.gd").new()
	var context: Dictionary = research.call("_context", before, revision, "sight", "later-research")
	context.world_namespace = NAMESPACE
	context.session_id = EPOCH
	var token: Dictionary = f.authority.stage_character_action(CHARACTER, revision, "research_event", {}, context)
	assert_true(token.get("ok") == true, str(token))
	if token.get("ok") != true:
		_close(f)
		return
	var accepted: Dictionary = f.authority.staged_creature_training(token)
	var written: Dictionary = f.rpc.journal_creature_training_prepared(1, CHARACTER, accepted)
	assert_true(written.get("ok") == true and written.get("durable") == true, str(written))
	assert_true(f.authority.finish_creature_training(token, written.get("ok") == true and written.get("durable") == true))
	var row := _row(f)
	assert_eq(row.action, "research_event")
	assert_eq(row.status, "pending", "new research still awaits its own owner BOOL/ACK")
	assert_eq(row.journal_revision, int(original.journal_revision) + 1)
	assert_true(row.before.redesign_character.transaction_receipts.has(original.receipt))
	var writes_before: int = f.owner_writer.attempts
	assert_true(f.presenter.call("_offer").is_empty(), "a later pending action cannot re-offer the original acknowledged catch")
	assert_false(f.presenter.call("_offer", f.offer.offer_id, true).is_empty(), "the original source remains available for explicit reconciliation")
	f.presenter.call("_process", 0.6)
	assert_true(f.game.pending_catch == null, "Game's ceremony watcher must have no stale capture to open")
	assert_eq(f.owner_writer.attempts, writes_before, "presentation neither acknowledges research nor repeats the catch write")
	assert_eq(_row(f).status, "pending")
	assert_eq(f.game.local.party.size(), 2)
	assert_eq(f.game.local.redesign_character.transaction_receipts.count(original.receipt), 1)
	_close(f)


func test_pending_first_capture_after_state_cannot_hide_its_missing_owner_ack() -> void:
	var f := _fixture()
	f.owner_writer.refuse = true
	assert_false(_ready(f))
	var row := _row(f)
	assert_eq(row.status, "pending")
	assert_false(row.before.redesign_character.transaction_receipts.has(row.receipt))
	assert_true(row.after.redesign_character.transaction_receipts.has(row.receipt))
	assert_false(f.presenter.call("_offer").is_empty(), "pending AFTER cannot count as an accepted capture prefix")
	assert_true(f.game.pending_catch != null)
	f.owner_writer.refuse = false
	assert_true(_ready(f))
	_assert_settled(f, 2)
	_close(f)
