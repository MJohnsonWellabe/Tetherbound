extends "res://tests/test_case.gd"

const PLAYER := preload("res://autoload/player_state.gd")

class GameFixture extends Node:
	var local: RefCounted

class SessionFixture extends "res://scripts/net/session.gd":
	var fixture_game: Node
	var mutation_blocked := false
	func _game() -> Node:
		return fixture_game
	func _owner_training_mutation_blocked(player: RefCounted) -> bool:
		return player == fixture_game.local and mutation_blocked
	func _owner_training_inventory_write_allowed(index: int, stack: Variant, player: RefCounted) -> bool:
		return player == fixture_game.local and index == 2 and stack == {"id": "stone", "count": 1}
	func _owner_training_release_write_allowed(index: int, player: RefCounted) -> bool:
		return player == fixture_game.local and index == 3
	func _owner_training_release_rollback_allowed(snapshot: Dictionary, player: RefCounted) -> bool:
		return player == fixture_game.local and snapshot == {"original": true}

func test_container_guards_do_not_retain_retired_owner_and_fail_closed() -> void:
	var game := GameFixture.new()
	var session := SessionFixture.new()
	var owner: RefCounted = PLAYER.new()
	game.local = owner
	session.fixture_game = game
	session.call("_bind_training_container_guards")
	var inventory: RefCounted = owner.get("inventory")
	var party: RefCounted = owner.get("party")
	var old_owner: WeakRef = weakref(owner)
	# Replacing a character must release the old player even if another UI
	# still holds its containers. The real stored guard callbacks remain live.
	game.local = PLAYER.new()
	owner = null
	assert_eq(old_owner.get_ref(), null, "container guard callbacks must not own their player")
	assert_true(bool(inventory.call("_owner_mutation_blocked")), "retired inventory stays fenced")
	assert_true(bool(party.call("_owner_mutation_blocked")), "retired party stays fenced")
	var slot_writer: Callable = inventory.get("_typed_slot_writer")
	var release_writer: Callable = party.get("_owner_training_release_guard")
	var rollback_writer: Callable = party.get("_owner_training_release_rollback_guard")
	assert_false(bool(slot_writer.call(0, {})), "no typed slot write after owner loss")
	assert_false(bool(release_writer.call(0)), "no release after owner loss")
	assert_false(bool(rollback_writer.call({})), "no rollback after owner loss")
	game.free()
	session.free()

func test_live_guard_delegation_and_freed_session_keep_container_fences() -> void:
	var game := GameFixture.new()
	var session := SessionFixture.new()
	game.local = PLAYER.new()
	session.fixture_game = game
	session.call("_bind_training_container_guards")
	var inventory: RefCounted = game.local.get("inventory")
	var party: RefCounted = game.local.get("party")
	var slot_writer: Callable = inventory.get("_typed_slot_writer")
	var release_writer: Callable = party.get("_owner_training_release_guard")
	var rollback_writer: Callable = party.get("_owner_training_release_rollback_guard")
	assert_false(bool(inventory.call("_owner_mutation_blocked")))
	session.mutation_blocked = true
	assert_true(bool(inventory.call("_owner_mutation_blocked")))
	assert_true(bool(party.call("_owner_mutation_blocked")))
	assert_true(bool(slot_writer.call(2, {"id": "stone", "count": 1})))
	assert_false(bool(slot_writer.call(1, {"id": "stone", "count": 1})))
	assert_true(bool(release_writer.call(3)))
	assert_false(bool(release_writer.call(2)))
	assert_true(bool(rollback_writer.call({"original": true})))
	assert_false(bool(rollback_writer.call({"original": false})))
	session.free()
	assert_true(slot_writer.is_valid(), "stored static adapter survives Session teardown")
	assert_true(bool(inventory.call("_owner_mutation_blocked")))
	assert_true(bool(party.call("_owner_mutation_blocked")))
	assert_false(bool(slot_writer.call(2, {"id": "stone", "count": 1})))
	assert_false(bool(release_writer.call(3)))
	assert_false(bool(rollback_writer.call({"original": true})))
	game.free()
