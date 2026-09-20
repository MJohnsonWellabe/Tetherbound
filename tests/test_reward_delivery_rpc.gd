extends "res://tests/test_case.gd"

const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")
const WORLD_STATE := preload("res://autoload/world_state.gd")
const PLAYER_STATE := preload("res://autoload/player_state.gd")
const PEER_REGISTRY := preload("res://scripts/net/peer_registry.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const DOCK_RULES := preload("res://scripts/world/water_dock_rules.gd")
const WATER_FIELD := preload("res://scripts/world/water_heightfield.gd")


class Saver extends RefCounted:
	var fail_world := false
	var fail_character := false
	var world_writes := 0
	var character_writes := 0
	var observed_reed_fiber := -1
	var observed_repair_flag := false
	var observed_doss_flag := false
	func save_world(_game: Object, _world_id: String) -> bool:
		world_writes += 1
		var game := _game as Object
		var world: Variant = game.get("world")
		var local: Variant = game.get("local")
		observed_repair_flag = world.flags.has("water_dock_reedhaven_repaired")
		observed_doss_flag = world.flags.has("river_nest_doss_cleared")
		observed_reed_fiber = int(local.inventory.count("reed_fiber"))
		return not fail_world
	func save_character(_game: Object, _character_id: String) -> bool:
		character_writes += 1
		return not fail_character


class SessionStub extends Node:
	var host := true
	var active := false
	var admitted := true
	var peer_id := 1
	var rows: RefCounted = PEER_REGISTRY.new()
	func is_active() -> bool: return active
	func mode() -> String: return "host" if host else "client"
	func handshake_snapshot_applied() -> bool: return admitted
	func snapshot_ready() -> bool: return admitted
	func local_peer_id() -> int: return peer_id
	func registry() -> RefCounted: return rows


class GameFixture extends Node:
	var world: RefCounted = WORLD_STATE.new()
	var local: RefCounted = PLAYER_STATE.new()
	var save_system: RefCounted = Saver.new()
	var session: Node = SessionStub.new()
	var current_realm := "meadows"
	var messages: Array = []
	func _init() -> void:
		session.name = "Session"
		add_child(session)
	func is_host() -> bool: return bool(session.host)
	func is_multi_peer() -> bool: return false
	func push_world_message(message: String) -> void: messages.append(message)


class RpcFixture extends "res://scripts/net/ledger_rpc.gd":
	var fixture_game: Node
	var dock_actor: Dictionary = {}
	var delta_count := 0
	func _init() -> void:
		delta_applied.connect(func(_delta: Dictionary) -> void: delta_count += 1)
	func _game() -> Node: return fixture_game
	func _can_rpc() -> bool: return false
	func _water_actor_context(_peer_id: int, intent: Dictionary) -> Dictionary:
		var context := dock_actor.duplicate(true)
		context["inventory"] = intent.get("inventory", {})
		context["inventory_slots"] = intent.get("inventory_slots", [])
		return context


var _game: GameFixture
var _rpc: Node


func before_each() -> void:
	_game = GameFixture.new()
	_game.world.world_id = "reward-rpc-world"
	_game.local.configure(ITEM_DB.new())
	_game.local.character_id = "host-a"
	assert_false(_game.session.rows.add(1, "host-a").is_empty(),
		"the host fixture must be admitted")
	_rpc = RpcFixture.new()
	_rpc.set("fixture_game", _game)
	_rpc.set("ledger", WORLD_LEDGER.new(_game.world))


func after_each() -> void:
	if is_instance_valid(_rpc):
		_rpc.free()
	if is_instance_valid(_game):
		_game.free()


func _intent(peer: int = 1, character_id: String = "host-a") -> Dictionary:
	assert_false(_game.session.rows.add(peer, character_id).is_empty(),
		"the intended reward recipient must be admitted")
	return {"kind": "reward_grant", "realm": "meadows", "source": "rpc-reward",
		"item": "coin", "count": 3, "peers": [peer]}


func _dock_intent(id: String, inventory: Dictionary = {}) -> Dictionary:
	var action: Dictionary = {}
	for row: Dictionary in DOCK_RULES.load_data().actions:
		if str(row.id) == id:
			action = row
	var field := WATER_FIELD.new()
	var position := DOCK_RULES.action_position(action, WATER_FIELD.load_config(), field.height_at)
	(_rpc as RpcFixture).dock_actor = {"peer": 1, "character_id": "host-a",
		"realm": "water", "position": position, "inventory": inventory}
	return {"kind": "water_dock_action", "realm": "water", "action_id": id,
		"inventory": inventory}


func _doss_intent() -> Dictionary:
	(_rpc as RpcFixture).dock_actor = {"peer": 1, "character_id": "host-a",
		"realm": "meadows", "position": Vector3(72.0, 0.0, 4187.4)}
	return {"kind": "river_nest_clear", "realm": "meadows", "inventory_slots": [
		{"id": "wood", "n": 1}, {"id": "fiber", "n": 1},
	]}


func test_host_world_save_failure_rolls_back_namespace_journal_and_sequence() -> void:
	var before: Dictionary = _game.world.save_data()
	var revision_before := int(_game.world.revision)
	_game.save_system.fail_world = true
	var verdict: Dictionary = _rpc.call("_commit_here", _intent(), 1)
	assert_false(bool(verdict.get("ok")))
	assert_eq(str(verdict.get("code", "")), "journal_failed")
	assert_eq(_game.world.save_data(), before)
	assert_eq(int(_game.world.revision), revision_before)
	assert_eq(int(_rpc.get("ledger").seq), 0)
	assert_eq(int(_game.local.inventory.count("coin")), 0)
	assert_eq(_game.save_system.character_writes, 0)


func test_character_save_failure_rolls_back_personal_mutation_and_sends_no_ack() -> void:
	_game.save_system.fail_character = true
	var verdict: Dictionary = _rpc.call("_commit_here", _intent(), 1)
	assert_true(bool(verdict.get("ok")), "the durable host journal remains pending")
	assert_eq(_game.world.reward_deliveries.size(), 1)
	var row: Dictionary = _game.world.reward_deliveries.values()[0]
	assert_eq(str(row.status), "pending")
	assert_eq(int(_game.local.inventory.count("coin")), 0)
	assert_true(_game.local.satchel_escrow.is_empty())
	assert_eq(_game.save_system.character_writes, 1)
	assert_eq(_game.save_system.world_writes, 1,
		"no ACK acceptance save occurs after the character save fails")


func test_ack_sender_must_own_the_journal_character() -> void:
	assert_false(_game.session.rows.add(2, "recipient-b").is_empty())
	assert_false(_game.session.rows.add(3, "spoofer-c").is_empty())
	var verdict: Dictionary = _rpc.call("_commit_here", _intent(2, "recipient-b"), 2)
	assert_true(bool(verdict.get("ok")))
	var id := str(_game.world.reward_deliveries.keys()[0])
	var writes_before := int(_game.save_system.world_writes)
	assert_false(bool(_rpc.call("_accept_reward_delivery", id, 3)))
	assert_eq(str((_game.world.reward_deliveries[id] as Dictionary).status), "pending")
	assert_eq(_game.save_system.world_writes, writes_before)


func test_host_ack_save_failure_keeps_delivery_pending_for_retry() -> void:
	assert_false(_game.session.rows.add(2, "recipient-b").is_empty())
	var verdict: Dictionary = _rpc.call("_commit_here", _intent(2, "recipient-b"), 2)
	assert_true(bool(verdict.get("ok")))
	var id := str(_game.world.reward_deliveries.keys()[0])
	var seq_before := int(_rpc.get("ledger").seq)
	_game.save_system.fail_world = true
	assert_false(bool(_rpc.call("_accept_reward_delivery", id, 2)))
	assert_eq(str((_game.world.reward_deliveries[id] as Dictionary).status), "pending")
	assert_eq(int(_rpc.get("ledger").seq), seq_before)
	_game.save_system.fail_world = false
	assert_true(bool(_rpc.call("_accept_reward_delivery", id, 2)))
	assert_eq(str((_game.world.reward_deliveries[id] as Dictionary).status), "accepted")


func test_pre_admission_delta_stages_world_only_then_character_settles_after_gate() -> void:
	_game.session.host = false
	_game.session.active = true
	_game.session.admitted = false
	_game.session.peer_id = 2
	_game.local.character_id = "recipient-b"
	assert_false(_game.session.rows.add(2, "recipient-b").is_empty(),
		"the client fixture must be admitted beside the distinct host")
	var host_world: RefCounted = WORLD_STATE.new()
	host_world.world_id = _game.world.world_id
	var host_ledger: RefCounted = WORLD_LEDGER.new(host_world)
	var verdict: Dictionary = host_ledger.commit({"kind": "reward_grant", "realm": "meadows",
		"source": "join-replay", "item": "coin", "count": 3,
		"_reward_recipients": [{"peer": 2, "character_id": "recipient-b"}]}, 2)
	_rpc.call("apply_remote_delta", verdict.delta)
	assert_eq(_game.world.reward_deliveries.size(), 1, "the host journal can stage during bootstrap")
	assert_eq(_game.save_system.character_writes, 0)
	assert_eq(int(_game.local.inventory.count("coin")), 0)
	assert_true(_game.local.satchel_escrow.is_empty())
	_game.session.admitted = true
	_rpc.call("reconcile_reward_deliveries")
	assert_eq(_game.save_system.character_writes, 1)
	assert_eq(int(_game.local.inventory.count("coin")), 3)
	assert_eq(str((_game.local.satchel_escrow.values()[0] as Dictionary).status), "settled")


func test_paid_dock_save_failure_rolls_back_before_publication() -> void:
	_game.current_realm = "water"
	_game.world.world_id = ""
	_game.world.flags.set_flag("water_swim_lesson_complete")
	_game.local.inventory.add("reed_fiber", 6)
	_game.local.inventory.add("driftwood", 4)
	var before: Dictionary = _game.world.save_data()
	var revision_before := int(_game.world.revision)
	var saver := _game.save_system as Saver
	saver.fail_world = true
	var verdict: Dictionary = _rpc.call("_commit_here", _dock_intent("reedhaven_repair",
		{"reed_fiber": 6, "driftwood": 4}), 1)
	assert_false(bool(verdict.get("ok")))
	assert_eq(str(verdict.get("code", "")), "journal_failed")
	assert_eq(_game.world.save_data(), before)
	assert_eq(int(_game.world.revision), revision_before)
	assert_eq(int(_rpc.get("ledger").seq), 0)
	assert_eq(int(_game.local.inventory.count("reed_fiber")), 6)
	assert_eq(int(_game.local.inventory.count("driftwood")), 4)
	assert_eq(saver.observed_reed_fiber, 6)
	assert_true(saver.observed_repair_flag,
		"the save observes the candidate world flag before publication")
	assert_eq((_rpc as RpcFixture).delta_count, 0,
		"a failed dock save publishes no delta")
	assert_eq(saver.world_writes, 1, "an unnamed world cannot bypass the required save")


func test_doss_save_failure_rolls_back_flag_rewards_and_cost_before_publication() -> void:
	_game.local.inventory.add("wood", 1)
	_game.local.inventory.add("fiber", 1)
	var before: Dictionary = _game.world.save_data()
	var saver := _game.save_system as Saver
	saver.fail_world = true
	var verdict: Dictionary = _rpc.call("_commit_here", _doss_intent(), 1)
	assert_false(bool(verdict.get("ok")))
	assert_eq(str(verdict.get("code", "")), "journal_failed")
	assert_eq(_game.world.save_data(), before)
	assert_eq(int(_rpc.get("ledger").seq), 0)
	assert_eq(int(_game.local.inventory.count("wood")), 1)
	assert_eq(int(_game.local.inventory.count("fiber")), 1)
	assert_eq(int(_game.local.inventory.count("coin")), 0)
	assert_true(saver.observed_doss_flag,
		"the durable save sees the candidate flag and reward journal before publication")
	assert_eq((_rpc as RpcFixture).delta_count, 0)


func test_doss_commit_debits_and_delivers_only_after_durable_world_save() -> void:
	_game.local.inventory.add("wood", 1)
	_game.local.inventory.add("fiber", 1)
	var verdict: Dictionary = _rpc.call("_commit_here", _doss_intent(), 1)
	assert_true(bool(verdict.get("ok")))
	assert_true(_game.world.flags.has("river_nest_doss_cleared"))
	assert_eq(int(_game.local.inventory.count("wood")), 0)
	assert_eq(int(_game.local.inventory.count("fiber")), 0)
	assert_eq(int(_game.local.inventory.count("coin")), 45)
	assert_eq(int(_game.local.inventory.count("potion_large")), 1)
	assert_eq((_rpc as RpcFixture).delta_count, 3,
		"one repair delta and two durable reward acknowledgements are published")


func test_paid_dock_retry_publishes_once_and_duplicate_does_not_charge_again() -> void:
	_game.current_realm = "water"
	_game.world.flags.set_flag("water_swim_lesson_complete")
	_game.local.inventory.add("reed_fiber", 6)
	_game.local.inventory.add("driftwood", 4)
	var saver := _game.save_system as Saver
	var intent := _dock_intent("reedhaven_repair", {"reed_fiber": 6, "driftwood": 4})
	saver.fail_world = true
	var failed: Dictionary = _rpc.call("_commit_here", intent, 1)
	assert_false(bool(failed.get("ok")))
	assert_eq((_rpc as RpcFixture).delta_count, 0)
	saver.fail_world = false
	var verdict: Dictionary = _rpc.call("_commit_here", intent, 1)
	assert_true(bool(verdict.get("ok")))
	assert_true(saver.observed_repair_flag)
	assert_eq(saver.observed_reed_fiber, 6,
		"the save runs before the portable item debit is published")
	assert_true(_game.world.flags.has("water_dock_reedhaven_repaired"))
	assert_eq(int(_game.local.inventory.count("reed_fiber")), 0)
	assert_eq(int(_game.local.inventory.count("driftwood")), 0)
	assert_eq((_rpc as RpcFixture).delta_count, 1)
	var writes := saver.world_writes
	var duplicate: Dictionary = _rpc.call("_commit_here", intent, 1)
	assert_false(bool(duplicate.get("ok")))
	assert_eq(str(duplicate.get("code", "")), "already_done")
	assert_eq(saver.world_writes, writes)
	assert_eq((_rpc as RpcFixture).delta_count, 1)


func test_zero_cost_chart_save_failure_and_invalid_dock_inputs_do_not_publish() -> void:
	_game.current_realm = "water"
	_game.world.flags.set_flag("water_aquaryn_resolved")
	var saver := _game.save_system as Saver
	saver.fail_world = true
	var before: Dictionary = _game.world.save_data()
	var chart: Dictionary = _rpc.call("_commit_here", _dock_intent("salt_crown_chart"), 1)
	assert_false(bool(chart.get("ok")))
	assert_eq(str(chart.get("code", "")), "journal_failed")
	assert_eq(_game.world.save_data(), before)
	assert_eq(int(_rpc.get("ledger").seq), 0)
	assert_eq((_rpc as RpcFixture).delta_count, 0)
	saver.fail_world = false
	var far_intent := _dock_intent("salt_crown_chart")
	var actor := (_rpc as RpcFixture).dock_actor
	actor["position"] = actor.position + Vector3(20.0, 0.0, 0.0)
	(_rpc as RpcFixture).dock_actor = actor
	var far: Dictionary = _rpc.call("_commit_here", far_intent, 1)
	assert_false(bool(far.get("ok")))
	assert_eq(str(far.get("code", "")), "too_far")
	assert_eq(saver.world_writes, 1)
	_game.world.flags.set_flag("water_aquaryn_resolved", false)
	var missing: Dictionary = _rpc.call("_commit_here", _dock_intent("salt_crown_chart"), 1)
	assert_false(bool(missing.get("ok")))
	assert_eq(str(missing.get("code", "")), "prerequisite")
	assert_eq(saver.world_writes, 1)
