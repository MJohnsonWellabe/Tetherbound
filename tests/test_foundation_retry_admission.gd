extends "res://tests/test_case.gd"

## Real retry scan and canonical event/delivery codecs; the counted admission
## seam refuses and the redelivery recorder writes nothing. Eligible new work
## must admit; existing pending work must redeliver its exact original row.
const DATA := preload("res://tests/test_foundation_resources.gd")
const MASTERY := preload("res://tests/test_combat_mastery_delivery.gd")
const EVENT := preload("res://scripts/net/foundation_event.gd")
const DELIVERY := preload("res://scripts/net/foundation_delivery.gd")
const ACTIONS := preload("res://scripts/net/foundation_actions.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")

class FixtureGame extends Node:
	var world: RefCounted

class DeliveryRecorder extends Node:
	var rows: Array[Dictionary] = []
	func _process_creature_training(row: Dictionary) -> void:
		rows.append(row.duplicate(true))

class CountedSession extends "res://scripts/net/session.gd":
	var fixture: Node
	var fixture_root: Node
	var fighting := false
	var admission_calls := 0
	func _game() -> Node: return fixture
	func is_host() -> bool: return true
	func _retry_combat_mastery_sources() -> void: pass
	func _foundation_realm_roots() -> Array[Node]:
		var roots: Array[Node] = []
		if fixture_root != null: roots.append(fixture_root)
		return roots
	func local_peer_id() -> int: return 1
	func _altar_peer_in_combat(peer: int) -> bool:
		return super._altar_peer_in_combat(peer) if fixture_root != null else fighting
	func admitted_character_state(_peer: int) -> Dictionary:
		admission_calls += 1
		return {} # Named seam: real scan still must consult it for eligible work.

func test_retry_skips_fighting_and_accepted_duties_before_projection_but_admits_pending() -> void:
	var before: Dictionary = DATA.new()._before()
	var world: RefCounted = DATA.new()._world()
	var helper := MASTERY.new()
	var duty: Dictionary = helper._duty(before)
	var event := EVENT.make(world, "resource-epoch", "mastery:" + MASTERY.ACTION_ID, [duty])
	assert_false(event.is_empty())
	world.reward_deliveries[event.delivery_id] = event
	var game := FixtureGame.new()
	game.world = world
	var session := CountedSession.new()
	session.fixture = game
	var redelivery := DeliveryRecorder.new()
	redelivery.name = "LedgerRpc"
	session.add_child(redelivery)
	session.set("_character_authority", preload("res://scripts/net/character_authority.gd").new())
	var peers: RefCounted = session.get("_registry")
	peers.call("add", 1, DATA.CHARACTER)
	var original := var_to_bytes(event)
	session.fighting = true
	session._retry_foundation_events()
	assert_eq(session.admission_calls, 0, "in-fight mastery is already deferred, so no full save projection is needed")
	session.fighting = false
	session._retry_foundation_events()
	assert_eq(session.admission_calls, 1, "eligible retained duty must still perform fresh authority admission")
	var proposal := ACTIONS.stage(before, 0, "combat_mastery", duty.intent, helper._context(duty, event), RECORD.errors)
	assert_true(proposal.get("ok") == true, str(proposal))
	if proposal.get("ok") == true:
		proposal.character_revision = 1
		var delivery := DELIVERY.make_record(world.world_id, world.reward_delivery_namespace, "resource-epoch", proposal, null, RECORD.errors)
		assert_false(delivery.is_empty())
		if not delivery.is_empty():
			delivery.status = "accepted"
			assert_true(DELIVERY.valid(delivery, RECORD.errors))
			world.reward_deliveries[delivery.delivery_id] = delivery
			session._retry_foundation_events()
			assert_eq(session.admission_calls, 1, "actual accepted receipt skips repeated save projection")
			assert_true(redelivery.rows.is_empty(), "an accepted row requires no owner redelivery")
			delivery.status = "pending"
			var pending_bytes := var_to_bytes(delivery)
			session._retry_foundation_events()
			assert_eq(redelivery.rows.size(), 1, "pending owner ACK must invoke actual original-row redelivery")
			if redelivery.rows.size() == 1:
				assert_eq(var_to_bytes(redelivery.rows[0]), pending_bytes, "retry cannot substitute a newly prepared row")
			assert_eq(var_to_bytes(world.reward_deliveries[delivery.delivery_id]), pending_bytes)
			assert_eq(session.admission_calls, 1, "original pending row needs redelivery, not a new baseline admission")
	assert_eq(var_to_bytes(world.reward_deliveries[event.delivery_id]), original, "original obligations stay immutable")
	session.free()
	game.free()

func test_trainer_send_out_gap_defers_mastery_and_preserves_original_pending_delivery() -> void:
	# Detached real manager/director/arbiter with explicit inter-round state;
	# this exercises scheduling, not played combat or earned mastery.
	var before: Dictionary = DATA.new()._before()
	var world: RefCounted = DATA.new()._world()
	var helper := MASTERY.new()
	var duty: Dictionary = helper._duty(before)
	var event := EVENT.make(world, "resource-epoch", "mastery:" + MASTERY.ACTION_ID, [duty])
	assert_false(event.is_empty())
	world.reward_deliveries[event.delivery_id] = event
	var original_event := var_to_bytes(event)
	var game := FixtureGame.new()
	game.world = world
	var session := CountedSession.new()
	session.fixture = game
	session.set("_character_authority", preload("res://scripts/net/character_authority.gd").new())
	var peers: RefCounted = session.get("_registry")
	peers.call("add", 2, DATA.CHARACTER)
	var redelivery := DeliveryRecorder.new()
	redelivery.name = "LedgerRpc"
	session.add_child(redelivery)
	var root := Node3D.new()
	session.fixture_root = root
	var manager := preload("res://scripts/combat/combat_manager.gd").new()
	root.add_child(manager)
	var director := preload("res://scripts/combat/encounter_director.gd").new()
	root.add_child(director)
	director.set("_session", session)
	director.set("_manager", manager)
	director.call("_ensure_encounter_arbiters")
	var host: RefCounted = director.get("_encounter_host")
	var round_record: Dictionary = host.call("open", 2, "meadows", "trainer",
		{"hp": 100.0, "hp_max": 100.0, "position": [2.0, 0.0, 0.0]}, before.party[0].uid, DATA.CHARACTER)
	assert_false(round_record.is_empty())
	host.call("close", round_record.encounter_id)
	director.set("_trainer_spec", {"id": "warden_aldis"})
	director.set("_trainer_battle_participants", {1: true, 2: true})
	director.set("_trainer_send_delay", 1.6)
	assert_false(manager.is_fighting(), "manager is actually inactive between rounds")
	assert_eq(host.call("phase", round_record.encounter_id), "done")
	assert_true(director.trainer_battle_active())
	assert_true(session._altar_peer_in_combat(1), "local host remains in the whole trainer battle")
	assert_true(session._altar_peer_in_combat(2), "retained guest remains in the same battle")
	assert_false(session._altar_peer_in_combat(3), "unrelated guest is not fenced by another battle")
	session._retry_foundation_events()
	assert_eq(session.admission_calls, 0, "round gap cannot prepare a new mastery row")
	assert_eq(world.reward_deliveries.size(), 1, "only the original hit obligation exists")
	var proposal := ACTIONS.stage(before, 0, "combat_mastery", duty.intent, helper._context(duty, event), RECORD.errors)
	assert_true(proposal.get("ok") == true, str(proposal))
	if proposal.get("ok") == true:
		proposal.character_revision = 1
		var delivery := DELIVERY.make_record(world.world_id, world.reward_delivery_namespace, "resource-epoch", proposal, null, RECORD.errors)
		assert_false(delivery.is_empty())
		if not delivery.is_empty():
			assert_eq(delivery.status, "pending")
			world.reward_deliveries[delivery.delivery_id] = delivery
			var original_pending := var_to_bytes(delivery)
			session._retry_foundation_events()
			assert_true(redelivery.rows.is_empty(), "existing pending row waits while the full battle is active")
			assert_eq(var_to_bytes(world.reward_deliveries[delivery.delivery_id]), original_pending)
			director.set("_trainer_spec", {})
			director.set("_trainer_battle_participants", {})
			assert_false(session._altar_peer_in_combat(2), "whole battle completion permits recovery")
			session._retry_foundation_events()
			assert_eq(redelivery.rows.size(), 1)
			if redelivery.rows.size() == 1: assert_eq(var_to_bytes(redelivery.rows[0]), original_pending)
			assert_eq(var_to_bytes(world.reward_deliveries[delivery.delivery_id]), original_pending, "retry does not acknowledge or rewrite the journal")
			assert_eq(session.admission_calls, 0, "original pending row never re-enters new-baseline admission")
	assert_eq(var_to_bytes(world.reward_deliveries[event.delivery_id]), original_event)
	root.free()
	session.free()
	game.free()
