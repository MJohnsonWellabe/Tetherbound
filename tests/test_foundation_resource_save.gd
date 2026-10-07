extends "res://tests/test_case.gd"

## Actual registry stage, LedgerRpc prepared commit and WorldSave/CharacterSave
## disk writes. Physical source and encounter baseline are disclosed fixtures;
## false BOOL writers exercise rollback and original-owner retry without ENet.
const DATA := preload("res://tests/test_foundation_resources.gd")
const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const OWNER := preload("res://scripts/net/character_action_owner.gd")
const E := preload("res://scripts/creatures/essence.gd")

class FixtureGame extends Node:
	var local: RefCounted
	var world: RefCounted
	var session: Node
	var save_system: RefCounted
	func is_host() -> bool: return true

class FixtureSession extends "res://scripts/net/session.gd":
	var fixture: Node
	func _game() -> Node: return fixture
	func is_host() -> bool: return true
	func local_peer_id() -> int: return 1
	func _altar_current_epoch() -> String: return "resource-epoch"
	func training_actor_baseline_ready(_peer: int, _training: Dictionary) -> bool: return true

class FixtureRpc extends "res://scripts/net/ledger_rpc.gd":
	var fixture: Node
	func _game() -> Node: return fixture
	func _local_peer_id() -> int: return 1

class BoolWriter extends RefCounted:
	var world_store: RefCounted
	var character_store: RefCounted
	var refuse_world := false
	var refuse_owner := false
	func finish_fallback() -> void: pass
	func fallback_busy() -> bool: return false
	func save_world_prepared(game: Node, id: String) -> bool:
		return false if refuse_world else world_store.call("write", id, game.get("world").save_data()) == true
	func save_character_prepared(game: Node, id: String) -> bool:
		if refuse_owner: return false
		var payload: Dictionary = game.get("local").save_data()
		if game.get("session").call("_owner_training_snapshot_allowed", game.get("local"), payload) != true: return false
		return character_store.call("write", id, payload) == true

func test_resource_world_bool_failure_rolls_back_then_owner_disk_retry_never_pays_twice() -> void:
	var fixture := DATA.new()
	var directory := "user://test_resource_save_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	var game := FixtureGame.new()
	game.local = fixture._player()
	game.world = fixture._world()
	var session := FixtureSession.new()
	session.fixture = game
	game.session = session
	var authority := AUTHORITY.new()
	session.set("_character_authority", authority)
	var writer := BoolWriter.new()
	writer.world_store = preload("res://scripts/save/world_save.gd").new(directory.path_join("worlds"))
	writer.character_store = preload("res://scripts/save/character_save.gd").new(directory.path_join("characters"))
	game.save_system = writer
	var rpc := FixtureRpc.new()
	rpc.fixture = game
	rpc.ledger = preload("res://scripts/net/world_ledger.gd").new(game.world)
	var before := RECORD.portable_projection(game.local.save_data())
	assert_true(authority.bind_world("resource-namespace"))
	assert_true(authority.seed_admitted_character(before, DATA.CHARACTER).ok)
	assert_true(writer.save_world_prepared(game, "resource-slot"))
	assert_true(writer.save_character_prepared(game, DATA.CHARACTER))
	var world_path: String = writer.world_store.call("path_for", "resource-slot")
	var owner_path: String = writer.character_store.call("path_for", DATA.CHARACTER)
	var old_world := FileAccess.get_file_as_bytes(world_path)
	var old_owner := FileAccess.get_file_as_bytes(owner_path)
	var frozen_world: Dictionary = game.world.save_data()
	var token := authority.stage_character_action(DATA.CHARACTER, 0, "resource", fixture._intent(), fixture._context())
	assert_true(token.get("ok") == true, str(token))
	if token.get("ok") != true:
		_close(game, rpc, directory)
		return
	writer.refuse_world = true
	var failed := rpc.journal_creature_training_prepared(1, DATA.CHARACTER, authority.staged_creature_training(token))
	assert_eq(failed.get("code"), "training_journal_failed")
	assert_false(failed.get("durable", true))
	assert_true(authority.finish_creature_training(token, false))
	assert_true(E._equivalent(game.world.save_data(), frozen_world), "stock and journal roll back together")
	assert_eq(authority.state(DATA.CHARACTER), before)
	assert_eq(FileAccess.get_file_as_bytes(world_path), old_world)
	assert_eq(FileAccess.get_file_as_bytes(owner_path), old_owner)
	writer.refuse_world = false
	token = authority.stage_character_action(DATA.CHARACTER, 0, "resource", fixture._intent(), fixture._context())
	var journal := rpc.journal_creature_training_prepared(1, DATA.CHARACTER, authority.staged_creature_training(token))
	assert_true(journal.get("ok") == true and journal.get("durable") == true, str(journal))
	assert_true(authority.finish_creature_training(token, journal.get("durable") == true))
	if journal.get("durable") != true:
		_close(game, rpc, directory)
		return
	var row: Dictionary = game.world.reward_deliveries[journal.delivery_id]
	assert_eq(game.local.inventory.count("essence_ground"), 0, "hidden world preparation did not publish an owner award")
	assert_eq(game.world.renewable_stock_state("meadows", "essence_meadows_ground_01").revision, 1)
	var recovered := fixture._world()
	recovered.load_data(writer.world_store.call("read", "resource-slot"))
	assert_true(E._equivalent(recovered.reward_deliveries[row.delivery_id], row))
	writer.refuse_owner = true
	var unsaved := OWNER.apply_owner(game, row)
	assert_eq(unsaved.get("code"), "owner_action_save_failed")
	assert_true(unsaved.get("pending") == true and unsaved.get("saved") == false)
	assert_eq(game.local.inventory.count("essence_ground"), 3)
	assert_eq(FileAccess.get_file_as_bytes(owner_path), old_owner)
	assert_true(session.owns_input(), "unsaved owner retains the existing mutation fence")
	# Existing resource adapter: no first quote while the preceding real
	# transaction owns input. Reuse this test's failed writer and pending row.
	var composition := Node.new()
	session.add_child(composition)
	var resources := preload("res://scripts/net/foundation_resources.gd").new()
	composition.add_child(resources)
	var unquoted := {"operation": "node", "source_id": "essence_meadows_ground_01",
		"key": "resource:meadows:essence_meadows_ground_01", "intent": fixture._intent(), "revision": -1,
		"world": weakref(game.world), "epoch": "resource-epoch", "character_id": DATA.CHARACTER}
	resources.set("_pending", {DATA.TXN: unquoted})
	var original_unquoted := var_to_bytes(unquoted)
	var original_request_count: int = session.get("_foundation_requests").size()
	resources.call("_send_pending", DATA.TXN)
	assert_eq(var_to_bytes(unquoted), original_unquoted, "unsaved prior owner keeps the new resource request unquoted")
	assert_eq(session.get("_foundation_requests").size(), original_request_count)
	writer.refuse_owner = false
	var retry := OWNER.apply_owner(game, row)
	assert_true(retry.get("ok") == true and retry.get("saved") == true and retry.get("duplicate") == true, str(retry))
	assert_eq(game.local.inventory.count("essence_ground"), 3)
	assert_true(E._equivalent(RECORD.portable_projection(writer.character_store.call("read", DATA.CHARACTER)), row.after))
	assert_true(session.owns_input(), "disk save alone does not forge the host ACK")
	resources.call("_send_pending", DATA.TXN)
	assert_eq(var_to_bytes(unquoted), original_unquoted, "actual disk save still waits for the prior host ACK before quoting")
	assert_eq(session.get("_foundation_requests").size(), original_request_count)
	assert_false(rpc.ledger.commit_creature_training_delivery(row, 1).ok)
	_close(game, rpc, directory)

func _close(game: FixtureGame, rpc: Node, directory: String) -> void:
	rpc.free()
	game.session.free()
	game.free()
	preload("res://tests/helpers/split_save_fixture.gd").wipe(directory)
