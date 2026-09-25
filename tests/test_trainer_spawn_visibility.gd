extends "res://tests/test_case.gd"

const TRAINER_SPAWN := preload("res://scripts/net/trainer_spawn.gd")
const REMOTE_TRAINER := preload("res://scripts/net/remote_trainer.gd")

class FakeSession:
	extends Node

	func peers() -> Array:
		return [{"peer_id": 42, "appearance_id": "sera"}]


class FakeTransition:
	extends Node
	var pending := true
	func departure_cleanup_pending(peer_id: int, realm: String) -> bool:
		return pending and peer_id == 42 and realm == "meadows"


func test_host_receives_remote_pose_across_realm_boundary() -> void:
	assert_true(TRAINER_SPAWN.observer_may_receive(1, "meadows", "stormwood", true),
		"the listen server must receive pose updates for its Stormwood shell")


func test_non_host_observers_remain_realm_scoped() -> void:
	assert_true(TRAINER_SPAWN.observer_may_receive(42, "stormwood", "stormwood", true))
	assert_false(TRAINER_SPAWN.observer_may_receive(42, "meadows", "stormwood", true),
		"another client must not draw a trainer from a different realm")


func test_pre_handshake_and_offline_visibility_still_allow_the_spawn() -> void:
	assert_true(TRAINER_SPAWN.observer_may_receive(42, "", "stormwood", true))
	assert_true(TRAINER_SPAWN.observer_may_receive(42, "meadows", "stormwood", false))


func test_all_peers_question_is_public_only_when_every_recipient_may_receive() -> void:
	var realms := {1: "cloudreach", 42: "meadows", 77: "cloudreach"}
	var realm_for := func(peer: int) -> String: return str(realms.get(peer, ""))
	assert_false(TRAINER_SPAWN.baseline_allows(0, PackedInt32Array([42, 77]), realm_for,
		"cloudreach", true),
		"observer 0 must not make a Cloudreach body public while a guest stands in the Meadows")
	assert_false(TRAINER_SPAWN.baseline_allows(42, PackedInt32Array([42, 77]), realm_for,
		"cloudreach", true))
	assert_true(TRAINER_SPAWN.baseline_allows(77, PackedInt32Array([42, 77]), realm_for,
		"cloudreach", true), "a same-realm guest is still asked for individually")
	realms[42] = "cloudreach"
	assert_true(TRAINER_SPAWN.baseline_allows(0, PackedInt32Array([42, 77]), realm_for,
		"cloudreach", true), "public once every recipient stands in the body's realm")


func test_all_peers_question_keeps_host_pre_hello_and_offline_rules() -> void:
	var realm_for := func(peer: int) -> String: return "meadows" if peer == 1 else ""
	assert_true(TRAINER_SPAWN.baseline_allows(0, PackedInt32Array([1]), realm_for,
		"cloudreach", true), "on a client, the host recipient still receives every realm")
	assert_true(TRAINER_SPAWN.baseline_allows(0, PackedInt32Array([42]), realm_for,
		"cloudreach", true), "a recipient with no registry row yet is still shown the body")
	assert_true(TRAINER_SPAWN.baseline_allows(0, PackedInt32Array(), realm_for,
		"cloudreach", true))
	var elsewhere := func(_peer: int) -> String: return "meadows"
	assert_true(TRAINER_SPAWN.baseline_allows(0, PackedInt32Array([42]), elsewhere,
		"cloudreach", false), "no session means no realm scoping")


func test_remote_spawn_data_uses_the_selected_body_not_the_viewers_body() -> void:
	var spawner := TRAINER_SPAWN.new()
	var session := FakeSession.new()
	spawner.set("_session", session)
	assert_eq(str(spawner.call("_appearance_id_for", 42)), "sera")
	assert_eq(str(spawner.call("_appearance_id_for", 99)), "trainer")
	session.free()
	spawner.free()


func test_source_realm_defers_only_the_coordinated_departing_body() -> void:
	var spawner := TRAINER_SPAWN.new()
	var transition := FakeTransition.new()
	spawner.set("_realm", "meadows")
	spawner.set("_transition", transition)
	assert_true(spawner.call("_departure_cleanup_pending", 42, "meadows"))
	assert_false(spawner.call("_departure_cleanup_pending", 99, "meadows"))
	assert_false(spawner.call("_departure_cleanup_pending", 42, "water"))
	transition.pending = false
	assert_false(spawner.call("_departure_cleanup_pending", 42, "meadows"),
		"receiver-ready settlement permits the host-side free")
	transition.free()
	spawner.free()


func test_remote_replica_exempts_the_late_local_rig_without_losing_world_collision() -> void:
	var remote := REMOTE_TRAINER.new()
	remote.collision_layer = 1
	remote.collision_mask = 1
	var first := CharacterBody3D.new()
	var replacement := CharacterBody3D.new()

	remote.call("_bind_local_collision_exception", first)
	assert_true(remote.get_collision_exceptions().has(first),
		"the remote replica does not push the local player")
	assert_true(first.get_collision_exceptions().has(remote),
		"the local player reciprocally ignores the remote replica")
	assert_eq(remote.collision_layer, 1, "the replica remains on its authored world layer")
	assert_eq(remote.collision_mask, 1, "the replica remains solid to authored world collision")

	remote.call("_bind_local_collision_exception", replacement)
	assert_false(remote.get_collision_exceptions().has(first),
		"a rebuilt local rig does not leave a stale exception")
	assert_false(first.get_collision_exceptions().has(remote))
	assert_true(remote.get_collision_exceptions().has(replacement),
		"the late replacement rig receives the exception")
	assert_true(replacement.get_collision_exceptions().has(remote))

	remote.free()
	first.free()
	replacement.free()


func test_remote_replica_releases_reciprocal_exception_when_its_side_is_already_clear() -> void:
	var rig := CharacterBody3D.new()
	var remote := REMOTE_TRAINER.new()
	remote.call("_bind_local_collision_exception", rig)
	assert_true(remote.get_collision_exceptions().has(rig))
	assert_true(rig.get_collision_exceptions().has(remote))
	# PhysicsServer can clear the exiting body's side before script teardown.
	# The release must not remove that nonexistent relationship a second time,
	# and must still clear the surviving rig's reciprocal relationship.
	remote.remove_collision_exception_with(rig)
	remote.call("_exit_tree")
	assert_false(rig.get_collision_exceptions().has(remote),
		"teardown releases the surviving local rig's reciprocal exception")

	remote.free()
	rig.free()


func test_replicas_ignore_each_other() -> void:
	var a := REMOTE_TRAINER.new()
	var b := REMOTE_TRAINER.new()
	REMOTE_TRAINER.exempt_replica_pair(a, b)
	assert_true(a.get_collision_exceptions().has(b),
		"two stacked replicas must not pin each other while following their owners")
	assert_true(b.get_collision_exceptions().has(a), "the exemption is symmetric")
	# The other side may already have been cleared by PhysicsServer teardown.
	b.remove_collision_exception_with(a)
	REMOTE_TRAINER.release_replica_pair(a, b)
	assert_false(a.get_collision_exceptions().has(b))
	assert_false(b.get_collision_exceptions().has(a))
	a.free()
	b.free()
