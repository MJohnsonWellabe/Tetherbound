extends "res://tests/test_case.gd"

## The receipt service must retain failed writes and abandon outgoing bindings.
## Writer/session doubles exercise reentrant failures; the existing paid Altar
## and Masters Title Load smokes remain the production disk/input proof.
const SERVICE := preload("res://scripts/onboarding/lesson_service.gd")
const MASTER := "opening:lesson:masters"
const PORTAL := "opening:lesson:portals"

class Player extends RefCounted:
	var character_id := "character-lesson"
	var flags := preload("res://autoload/progression_state.gd").new()

class Session extends Node:
	var snapshot_applied := true
	var client := false
	var admitted := true
	func snapshot_ready() -> bool: return snapshot_applied
	func mode() -> String: return "client" if client else "solo"
	func handshake_snapshot_applied() -> bool: return admitted

class Ledger extends Node:
	var requests: Array = []
	func submit(intent: Dictionary) -> void: requests.append(intent.duplicate(true))

class Saver extends RefCounted:
	var succeeds := true
	var hook := Callable()
	var writes: Array = []
	func save_character_prepared(game: Object, id: String) -> bool:
		writes.append(id)
		if hook.is_valid(): hook.call(game)
		return succeeds

class GameStub extends Node:
	var local: RefCounted = Player.new()
	var session: Node = Session.new()
	var ledger: Node = Ledger.new()
	var save_system: RefCounted = Saver.new()
	var host := true
	var owned := true
	func is_host() -> bool: return host
	func world_save_owned() -> bool: return owned

var game: Node
var service: Node

func before_each() -> void:
	game = GameStub.new()
	game.add_child(game.session)
	game.add_child(game.ledger)
	service = SERVICE.new()
	game.add_child(service)
	service.set("_identity", game.local.character_id)
	game.local.flags.set_flag(MASTER, true)
	service.set("_pending", {MASTER:true, PORTAL:true})

func after_each() -> void:
	game.free()

func test_failed_prepared_write_retains_live_receipt_and_retries_without_resubmitting_it() -> void:
	game.save_system.succeeds = false
	service.call("_flush_receipts")
	assert_eq(game.save_system.writes, ["character-lesson"])
	assert_true(service.get("_pending").has(MASTER))
	assert_eq(game.ledger.requests.size(), 1)
	assert_eq(game.ledger.requests[0].id, PORTAL)
	service.call("_flush_receipts")
	assert_eq(game.save_system.writes.size(), 1, "existing retry throttle")
	game.save_system.succeeds = true
	service.set("_retry_at", 0)
	service.call("_flush_receipts")
	assert_false(service.get("_pending").has(MASTER))
	assert_true(service.get("_pending").has(PORTAL), "absent ACK is never cleared by saving")

func test_any_changed_save_binding_stops_both_clearing_and_submission() -> void:
	for changed: String in ["cid", "identity", "generation", "saver", "session", "player"]:
		var original_player: RefCounted = game.local
		var original_session: Node = game.session
		var original_saver: RefCounted = game.save_system
		var replacement_session: Node = Session.new()
		game.save_system.hook = func(owner: Object) -> void:
			match changed:
				"cid": owner.local.character_id = "character-other"
				"identity": service.set("_identity", "character-other")
				"generation": service.set("_receipt_generation", 1)
				"saver": owner.save_system = Saver.new()
				"session": owner.session = replacement_session
				"player": owner.local = Player.new()
		service.set("_retry_at", 0)
		service.call("_flush_receipts")
		assert_eq(service.get("_pending"), {MASTER:true, PORTAL:true}, changed)
		assert_true(game.ledger.requests.is_empty(), changed + " must not submit an outgoing intent")
		game.local = original_player
		game.local.character_id = "character-lesson"
		game.session = original_session
		game.save_system = original_saver
		service.set("_identity", "character-lesson")
		service.set("_receipt_generation", 0)
		replacement_session.free()

func test_unadmitted_or_foreign_snapshot_cannot_write_or_submit_a_receipt() -> void:
	for gate: String in ["snapshot", "foreign", "handshake"]:
		game.session.snapshot_applied = gate != "snapshot"
		game.owned = gate != "foreign"
		game.host = gate != "handshake"
		game.session.client = gate == "handshake"
		game.session.admitted = gate != "handshake"
		service.set("_retry_at", 0)
		service.call("_flush_receipts")
		assert_true(game.save_system.writes.is_empty(), gate)
		assert_true(game.ledger.requests.is_empty(), gate)
		assert_eq(service.get("_pending"), {MASTER:true, PORTAL:true}, gate)
